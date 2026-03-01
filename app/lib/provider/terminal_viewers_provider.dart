import 'package:refena_flutter/refena_flutter.dart';

class ViewerInfo {
  final String fingerprint;
  final String? alias;
  final String ip;
  final bool interactive;
  final DateTime connectedAt;

  const ViewerInfo({
    required this.fingerprint,
    this.alias,
    required this.ip,
    required this.interactive,
    required this.connectedAt,
  });

  ViewerInfo copyWith({
    String? fingerprint,
    String? alias,
    String? ip,
    bool? interactive,
    DateTime? connectedAt,
  }) {
    return ViewerInfo(
      fingerprint: fingerprint ?? this.fingerprint,
      alias: alias ?? this.alias,
      ip: ip ?? this.ip,
      interactive: interactive ?? this.interactive,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }
}

final terminalViewersProvider = NotifierProvider<TerminalViewersService, Map<String, List<ViewerInfo>>>((ref) {
  return TerminalViewersService();
});

class TerminalViewersService extends PureNotifier<Map<String, List<ViewerInfo>>> {
  @override
  Map<String, List<ViewerInfo>> init() => {};

  void updateViewers(String sessionId, List<ViewerInfo> viewers) {
    state = {...state, sessionId: viewers};
  }

  void removeSession(String sessionId) {
    state = Map.of(state)..remove(sessionId);
  }

  void disconnectViewer(String sessionId, String fingerprint) {
    final viewers = state[sessionId];
    if (viewers == null) return;
    state = {
      ...state,
      sessionId: viewers.where((v) => v.fingerprint != fingerprint).toList(),
    };
  }

  void disconnectAllViewers(String sessionId) {
    state = {...state, sessionId: []};
  }

  void toggleViewerMode(String sessionId, String fingerprint) {
    final viewers = state[sessionId];
    if (viewers == null) return;
    state = {
      ...state,
      sessionId: viewers.map((v) {
        if (v.fingerprint == fingerprint) {
          return v.copyWith(interactive: !v.interactive);
        }
        return v;
      }).toList(),
    };
  }
}
