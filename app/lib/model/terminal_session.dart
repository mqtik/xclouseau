import 'package:dart_mappable/dart_mappable.dart';
import 'package:localsend_app/model/terminal_session_source.dart';
import 'package:uuid/uuid.dart';

part 'terminal_session.mapper.dart';

const _uuid = Uuid();

@MappableClass()
class TerminalSession with TerminalSessionMappable {
  final String id;
  final String name;
  final String? workingDir;
  final SessionSource source;
  final bool isPinned;
  final int order;
  final DateTime createdAt;

  const TerminalSession({
    required this.id,
    required this.name,
    this.workingDir,
    required this.source,
    this.isPinned = false,
    required this.order,
    required this.createdAt,
  });

  factory TerminalSession.create({
    required String name,
    String? workingDir,
    required SessionSource source,
    int order = 0,
  }) {
    return TerminalSession(
      id: _uuid.v4(),
      name: name,
      workingDir: workingDir,
      source: source,
      isPinned: false,
      order: order,
      createdAt: DateTime.now(),
    );
  }

  static const fromJson = TerminalSessionMapper.fromJson;
}
