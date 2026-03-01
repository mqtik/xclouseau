import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:localsend_app/model/paired_device.dart';
import 'package:localsend_app/provider/persistence_provider.dart';
import 'package:logging/logging.dart';
import 'package:refena_flutter/refena_flutter.dart';

final _logger = Logger('TerminalAccessProvider');

final terminalAccessProvider = ReduxProvider<TerminalAccessProvider, TerminalAccessState>((ref) {
  return TerminalAccessProvider(ref.read(persistenceProvider));
});

class PendingApproval {
  final String fingerprint;
  final String alias;
  final String? deviceModel;
  final DateTime requestedAt;
  final Completer<bool> completer;

  PendingApproval({
    required this.fingerprint,
    required this.alias,
    this.deviceModel,
    required this.requestedAt,
    required this.completer,
  });
}

class TerminalAccessState {
  final List<PairedDevice> pairedDevices;
  final Map<String, PendingApproval> pendingApprovals;
  final String? activePin;
  final Map<String, Set<String>> sessionApprovals;

  const TerminalAccessState({
    this.pairedDevices = const [],
    this.pendingApprovals = const {},
    this.activePin,
    this.sessionApprovals = const {},
  });

  bool isDevicePaired(String fingerprint) {
    return pairedDevices.any((d) => d.fingerprint == fingerprint);
  }

  PairedDevice? getPairedDevice(String fingerprint) {
    for (final device in pairedDevices) {
      if (device.fingerprint == fingerprint) return device;
    }
    return null;
  }

  bool isSessionApproved(String fingerprint, String sessionId) {
    final sessions = sessionApprovals[fingerprint];
    return sessions != null && sessions.contains(sessionId);
  }

  TerminalAccessState copyWith({
    List<PairedDevice>? pairedDevices,
    Map<String, PendingApproval>? pendingApprovals,
    String? activePin,
    bool clearPin = false,
    Map<String, Set<String>>? sessionApprovals,
  }) {
    return TerminalAccessState(
      pairedDevices: pairedDevices ?? this.pairedDevices,
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      activePin: clearPin ? null : (activePin ?? this.activePin),
      sessionApprovals: sessionApprovals ?? this.sessionApprovals,
    );
  }
}

class TerminalAccessProvider extends ReduxNotifier<TerminalAccessState> {
  final PersistenceService _persistence;

  TerminalAccessProvider(this._persistence);

  @override
  TerminalAccessState init() {
    try {
      final raw = _persistence.getPairedDevices();
      final list = (jsonDecode(raw) as List)
          .map((e) => PairedDevice.fromJson(e as Map<String, dynamic>))
          .toList()
          .cast<PairedDevice>();
      return TerminalAccessState(pairedDevices: list);
    } catch (e) {
      _logger.warning('Failed to load paired devices', e);
    }
    return const TerminalAccessState();
  }

  Future<void> _persistDevices(List<PairedDevice> devices) async {
    try {
      final raw = jsonEncode(devices.map((d) => d.toJson()).toList());
      await _persistence.setPairedDevices(raw);
    } catch (e) {
      _logger.warning('Failed to persist paired devices', e);
    }
  }
}

class GeneratePairingPinAction extends ReduxAction<TerminalAccessProvider, TerminalAccessState> {
  @override
  TerminalAccessState reduce() {
    final random = Random.secure();
    final pin = List.generate(6, (_) => random.nextInt(10)).join();
    return state.copyWith(activePin: pin);
  }
}

class ClearPinAction extends ReduxAction<TerminalAccessProvider, TerminalAccessState> {
  @override
  TerminalAccessState reduce() {
    return state.copyWith(clearPin: true);
  }
}

class CompletePairingAction extends AsyncReduxAction<TerminalAccessProvider, TerminalAccessState> {
  final String fingerprint;
  final String alias;
  final String? deviceModel;
  final String deviceType;

  CompletePairingAction({
    required this.fingerprint,
    required this.alias,
    this.deviceModel,
    required this.deviceType,
  });

  @override
  Future<TerminalAccessState> reduce() async {
    final device = PairedDevice(
      fingerprint: fingerprint,
      alias: alias,
      deviceModel: deviceModel,
      deviceType: deviceType,
      pairedAt: DateTime.now(),
    );
    final updated = [...state.pairedDevices, device];
    await notifier._persistDevices(updated);
    return state.copyWith(pairedDevices: updated, clearPin: true);
  }
}

class UnpairDeviceAction extends AsyncReduxAction<TerminalAccessProvider, TerminalAccessState> {
  final String fingerprint;

  UnpairDeviceAction(this.fingerprint);

  @override
  Future<TerminalAccessState> reduce() async {
    final updated = state.pairedDevices.where((d) => d.fingerprint != fingerprint).toList();
    await notifier._persistDevices(updated);

    final updatedSessions = Map<String, Set<String>>.from(state.sessionApprovals)..remove(fingerprint);

    return state.copyWith(
      pairedDevices: updated,
      sessionApprovals: updatedSessions,
    );
  }
}

class RequestApprovalAction extends AsyncReduxAction<TerminalAccessProvider, TerminalAccessState> {
  final String fingerprint;
  final String alias;
  final String? deviceModel;

  RequestApprovalAction({
    required this.fingerprint,
    required this.alias,
    this.deviceModel,
  });

  late final Completer<bool> _completer;

  Future<bool> get future => _completer.future;

  @override
  Future<TerminalAccessState> reduce() async {
    _completer = Completer<bool>();
    final pending = PendingApproval(
      fingerprint: fingerprint,
      alias: alias,
      deviceModel: deviceModel,
      requestedAt: DateTime.now(),
      completer: _completer,
    );
    final updated = Map<String, PendingApproval>.from(state.pendingApprovals)
      ..[fingerprint] = pending;
    return state.copyWith(pendingApprovals: updated);
  }
}

class ApproveDeviceAction extends AsyncReduxAction<TerminalAccessProvider, TerminalAccessState> {
  final String fingerprint;
  final bool always;

  ApproveDeviceAction({required this.fingerprint, this.always = false});

  @override
  Future<TerminalAccessState> reduce() async {
    final pending = state.pendingApprovals[fingerprint];
    if (pending == null) return state;

    pending.completer.complete(true);

    final updatedPending = Map<String, PendingApproval>.from(state.pendingApprovals)..remove(fingerprint);

    var updatedDevices = state.pairedDevices;
    if (always) {
      updatedDevices = state.pairedDevices.map<PairedDevice>((d) {
        if (d.fingerprint == fingerprint) {
          return d.copyWith(alwaysAllowTerminal: true);
        }
        return d;
      }).toList();
      await notifier._persistDevices(updatedDevices);
    }

    return state.copyWith(
      pendingApprovals: updatedPending,
      pairedDevices: updatedDevices,
    );
  }
}

class DenyDeviceAction extends ReduxAction<TerminalAccessProvider, TerminalAccessState> {
  final String fingerprint;

  DenyDeviceAction(this.fingerprint);

  @override
  TerminalAccessState reduce() {
    final pending = state.pendingApprovals[fingerprint];
    if (pending == null) return state;

    pending.completer.complete(false);

    final updatedPending = Map<String, PendingApproval>.from(state.pendingApprovals)..remove(fingerprint);
    return state.copyWith(pendingApprovals: updatedPending);
  }
}

class ApproveSessionAction extends ReduxAction<TerminalAccessProvider, TerminalAccessState> {
  final String fingerprint;
  final String sessionId;

  ApproveSessionAction({required this.fingerprint, required this.sessionId});

  @override
  TerminalAccessState reduce() {
    final updated = Map<String, Set<String>>.from(state.sessionApprovals);
    final sessions = Set<String>.from(updated[fingerprint] ?? {})..add(sessionId);
    updated[fingerprint] = sessions;
    return state.copyWith(sessionApprovals: updated);
  }
}
