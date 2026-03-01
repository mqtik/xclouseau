import 'package:common/model/device.dart';
import 'package:flutter/material.dart';
import 'package:localsend_app/model/terminal_session_source.dart';
import 'package:localsend_app/provider/project_provider.dart';
import 'package:localsend_app/provider/remote_terminal_provider.dart';
import 'package:localsend_app/provider/security_provider.dart';
import 'package:refena_flutter/refena_flutter.dart';

class DeviceTerminalsPage extends StatefulWidget {
  final Device device;

  const DeviceTerminalsPage({required this.device, super.key});

  @override
  State<DeviceTerminalsPage> createState() => _DeviceTerminalsPageState();
}

class _DeviceTerminalsPageState extends State<DeviceTerminalsPage> with Refena {
  List<Map<String, dynamic>> _sessions = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchSessions());
  }

  Future<void> _fetchSessions() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final ourFingerprint = ref.read(securityProvider).certificateHash;
      final sessions = await RemoteTerminalService.fetchRemoteSessions(widget.device, fingerprint: ourFingerprint);
      if (mounted) {
        setState(() {
          _sessions = sessions;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _createRemoteTerminal() async {
    setState(() => _loading = true);
    try {
      final ourFingerprint = ref.read(securityProvider).certificateHash;
      final session = await RemoteTerminalService.createRemoteSession(
        widget.device,
        fingerprint: ourFingerprint,
      );
      if (session != null && mounted) {
        _attachToSession(session);
      } else if (mounted) {
        setState(() {
          _error = 'Failed to create terminal on ${widget.device.alias}';
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _attachToSession(Map<String, dynamic> session) {
    final projectState = context.ref.read(projectProvider);
    final activeProject = projectState.activeProject;
    if (activeProject == null) return;

    final remoteSessionId = session['id'] as String;
    final sessionName = session['name'] as String? ?? 'remote';

    context.ref.redux(projectProvider).dispatchAsync(
      AddSessionAction(
        projectId: activeProject.id,
        name: '${widget.device.alias}: $sessionName',
        workingDir: session['currentWorkingDir'] as String?,
        source: RemoteSource(
          deviceFingerprint: widget.device.fingerprint,
          remoteSessionId: remoteSessionId,
        ),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.device.alias),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'New Terminal',
            onPressed: _createRemoteTerminal,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchSessions,
          ),
        ],
      ),
      body: _buildBody(colorScheme),
    );
  }

  Widget _buildBody(ColorScheme colorScheme) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 48,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _fetchSessions,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_sessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.terminal,
              size: 64,
              color: colorScheme.onSurface.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No terminal sessions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
            ),
            const SizedBox(height: 8),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _createRemoteTerminal,
              icon: const Icon(Icons.add),
              label: const Text('New Terminal'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _fetchSessions,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _sessions.length,
      itemBuilder: (context, index) => _buildSessionCard(_sessions[index]),
    );
  }

  Widget _buildSessionCard(Map<String, dynamic> session) {
    final name = session['name'] as String? ?? 'terminal';
    final project = session['project'] as String? ?? '';
    final cols = session['cols'] as int? ?? 80;
    final rows = session['rows'] as int? ?? 24;
    final cwd = session['currentWorkingDir'] as String?;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _attachToSession(session),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.terminal,
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (project.isNotEmpty)
                      Text(
                        project,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (cwd != null)
                      Text(
                        cwd,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                      ),
                  ],
                ),
              ),
              Text(
                '$cols\u00d7$rows',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: colorScheme.onSurface.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
