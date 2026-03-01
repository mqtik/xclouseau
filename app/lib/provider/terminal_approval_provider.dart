import 'dart:async';

import 'package:refena_flutter/refena_flutter.dart';

enum ApprovalResult { approved, denied, approvedAlways }

class PendingTerminalApproval {
  final String id;
  final String fingerprint;
  final String alias;
  final String? deviceModel;
  final String sessionId;
  final String sessionName;
  final DateTime requestedAt;
  final Completer<ApprovalResult> completer;

  PendingTerminalApproval({
    required this.id,
    required this.fingerprint,
    required this.alias,
    this.deviceModel,
    required this.sessionId,
    required this.sessionName,
    required this.requestedAt,
    required this.completer,
  });
}

final terminalApprovalProvider = NotifierProvider<TerminalApprovalService, List<PendingTerminalApproval>>((ref) {
  return TerminalApprovalService();
});

class TerminalApprovalService extends PureNotifier<List<PendingTerminalApproval>> {
  @override
  List<PendingTerminalApproval> init() => [];

  Future<ApprovalResult> requestApproval({
    required String id,
    required String fingerprint,
    required String alias,
    String? deviceModel,
    required String sessionId,
    required String sessionName,
  }) {
    final completer = Completer<ApprovalResult>();
    final pending = PendingTerminalApproval(
      id: id,
      fingerprint: fingerprint,
      alias: alias,
      deviceModel: deviceModel,
      sessionId: sessionId,
      sessionName: sessionName,
      requestedAt: DateTime.now(),
      completer: completer,
    );
    state = [...state, pending];
    return completer.future;
  }

  void approve(String id) {
    final pending = state.where((r) => r.id == id).firstOrNull;
    if (pending == null) return;
    pending.completer.complete(ApprovalResult.approved);
    state = state.where((r) => r.id != id).toList();
  }

  void deny(String id) {
    final pending = state.where((r) => r.id == id).firstOrNull;
    if (pending == null) return;
    pending.completer.complete(ApprovalResult.denied);
    state = state.where((r) => r.id != id).toList();
  }

  void approveAlways(String id) {
    final pending = state.where((r) => r.id == id).firstOrNull;
    if (pending == null) return;
    pending.completer.complete(ApprovalResult.approvedAlways);
    state = state.where((r) => r.id != id).toList();
  }

  void removeExpired() {
    final now = DateTime.now();
    final expired = state.where(
      (r) => now.difference(r.requestedAt).inSeconds >= 60,
    );
    for (final request in expired) {
      if (!request.completer.isCompleted) {
        request.completer.complete(ApprovalResult.denied);
      }
    }
    state = state.where(
      (r) => now.difference(r.requestedAt).inSeconds < 60,
    ).toList();
  }
}
