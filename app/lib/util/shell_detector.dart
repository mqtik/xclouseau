import 'dart:io';

String detectDefaultShell() {
  if (Platform.isWindows) {
    return 'powershell.exe';
  }

  final shell = Platform.environment['SHELL'];
  if (shell != null && shell.isNotEmpty) {
    return shell;
  }

  if (Platform.isMacOS) {
    return '/bin/zsh';
  }

  return '/bin/bash';
}

List<String> defaultShellArguments(String shell) {
  final name = shell.split('/').last;
  if (name == 'zsh' || name == 'bash') {
    return ['--login'];
  }
  return [];
}
