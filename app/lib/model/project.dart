import 'package:dart_mappable/dart_mappable.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/model/terminal_session.dart';
import 'package:uuid/uuid.dart';

part 'project.mapper.dart';

const _uuid = Uuid();

@MappableEnum()
enum ViewMode {
  list,
  grid,
  carousel,
}

@MappableClass()
class Project with ProjectMappable {
  final String id;
  final String name;
  final int colorValue;
  final String? icon;
  final bool isCollapsed;
  final ViewMode viewMode;
  final List<TerminalSession> sessions;
  final String? defaultWorkingDir;
  final DateTime createdAt;

  const Project({
    required this.id,
    required this.name,
    required this.colorValue,
    this.icon,
    this.isCollapsed = false,
    this.viewMode = ViewMode.list,
    this.sessions = const [],
    this.defaultWorkingDir,
    required this.createdAt,
  });

  factory Project.create({
    required String name,
    Color color = Colors.teal,
    String? defaultWorkingDir,
  }) {
    return Project(
      id: _uuid.v4(),
      name: name,
      colorValue: color.toARGB32(),
      defaultWorkingDir: defaultWorkingDir,
      createdAt: DateTime.now(),
    );
  }

  Color get color => Color(colorValue);

  static const fromJson = ProjectMapper.fromJson;
}
