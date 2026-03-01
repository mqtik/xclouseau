import 'package:dart_mappable/dart_mappable.dart';
import 'package:localsend_app/model/terminal_session.dart';

part 'closed_tab.mapper.dart';

@MappableClass()
class ClosedTab with ClosedTabMappable {
  final TerminalSession session;
  final String projectId;
  final DateTime closedAt;

  const ClosedTab({
    required this.session,
    required this.projectId,
    required this.closedAt,
  });

  static const fromJson = ClosedTabMapper.fromJson;
}
