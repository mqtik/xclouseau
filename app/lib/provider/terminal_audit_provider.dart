import 'package:refena_flutter/refena_flutter.dart';
import 'package:uuid/uuid.dart';

const _maxEvents = 1000;
const _uuid = Uuid();

enum AuditEventType {
  devicePaired,
  deviceUnpaired,
  terminalAttached,
  terminalDetached,
  modeChangedToInteractive,
  modeChangedToViewOnly,
  accessDeniedNotPaired,
  accessDeniedPinFailed,
  accessDeniedMaxViewers,
  accessApproved,
  accessDenied,
  pairingAttemptFailed,
}

class AuditEvent {
  final String id;
  final AuditEventType type;
  final String fingerprint;
  final String? alias;
  final String? ip;
  final String? sessionId;
  final String? sessionName;
  final String? details;
  final DateTime timestamp;

  AuditEvent({
    required this.id,
    required this.type,
    required this.fingerprint,
    this.alias,
    this.ip,
    this.sessionId,
    this.sessionName,
    this.details,
    required this.timestamp,
  });
}

final terminalAuditProvider = NotifierProvider<TerminalAuditService, List<AuditEvent>>((ref) {
  return TerminalAuditService();
});

class TerminalAuditService extends PureNotifier<List<AuditEvent>> {
  @override
  List<AuditEvent> init() => [];

  void log(
    AuditEventType type, {
    required String fingerprint,
    String? alias,
    String? ip,
    String? sessionId,
    String? sessionName,
    String? details,
  }) {
    final event = AuditEvent(
      id: _uuid.v4(),
      type: type,
      fingerprint: fingerprint,
      alias: alias,
      ip: ip,
      sessionId: sessionId,
      sessionName: sessionName,
      details: details,
      timestamp: DateTime.now(),
    );

    final updated = [...state, event];
    if (updated.length > _maxEvents) {
      state = updated.sublist(updated.length - _maxEvents);
    } else {
      state = updated;
    }
  }

  void clear() {
    state = [];
  }

  List<AuditEvent> getEventsForDevice(String fingerprint) {
    return state.where((e) => e.fingerprint == fingerprint).toList();
  }

  List<AuditEvent> getEventsForSession(String sessionId) {
    return state.where((e) => e.sessionId == sessionId).toList();
  }
}
