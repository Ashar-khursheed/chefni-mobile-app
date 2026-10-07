import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/repositories/haccp_repository.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/chefni_ui.dart';

/// Digital HACCP checklist — temperature and hygiene entries a Restaurant Pro
/// kitchen keeps for inspections. Entries are append-only, matching how a
/// physical inspection binder works: nothing is edited after the fact.
class HaccpScreen extends StatefulWidget {
  const HaccpScreen({super.key});

  @override
  State<HaccpScreen> createState() => _HaccpScreenState();
}

class _HaccpScreenState extends State<HaccpScreen> {
  final GlobalKey<AsyncViewState<({List<HaccpLog> logs, int failCount})>> _viewKey =
      GlobalKey<AsyncViewState<({List<HaccpLog> logs, int failCount})>>();

  Future<void> _logEntry() async {
    final result = await showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _LogEntrySheet(),
    );
    if (result == null || !mounted) return;

    try {
      await ServiceScope.of(context).haccp.log(
            type: result['type']!,
            label: result['label']!,
            status: result['status']!,
            value: result['value'],
            loggedBy: result['logged_by'],
            notes: result['notes'],
          );
      _viewKey.currentState?.reload();
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      appBar: AppBar(
        backgroundColor: AppTheme.bgShell,
        elevation: 0,
        foregroundColor: AppTheme.darkText,
        title: Text('HACCP logs', style: AppTheme.display(size: 18)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppTheme.coralPrimary,
        onPressed: _logEntry,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: AsyncView<({List<HaccpLog> logs, int failCount})>(
        key: _viewKey,
        load: () => ServiceScope.of(context).haccp.fetchAll(),
        builder: (context, data, reload) => RefreshIndicator(
          color: AppTheme.coralPrimary,
          onRefresh: () async => reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 90),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: data.failCount == 0 ? AppTheme.tintGreen : AppTheme.tintCoral,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      data.failCount == 0 ? Icons.check_circle : Icons.error_outline,
                      color: data.failCount == 0
                          ? AppTheme.successDeep
                          : AppTheme.coralPrimaryDark,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        data.failCount == 0
                            ? "Today's checks look good"
                            : '${data.failCount} check${data.failCount == 1 ? '' : 's'} failed recently',
                        style: AppTheme.display(size: 13, weight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              if (data.logs.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text('No entries logged yet.',
                        style: AppTheme.body(size: 13, color: AppTheme.mutedText)),
                  ),
                )
              else
                for (final log in data.logs) _buildRow(log),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(HaccpLog log) {
    final color = switch (log.status) {
      'pass' => AppTheme.successDeep,
      'warning' => AppTheme.accentGold,
      _ => AppTheme.alertRed,
    };
    final icon = log.type == 'temperature' ? Icons.thermostat : Icons.cleaning_services_outlined;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ChefniCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(log.label,
                      style: AppTheme.display(size: 12.5, weight: FontWeight.w700)),
                  if (log.notes != null) ...[
                    const SizedBox(height: 2),
                    Text(log.notes!,
                        style: AppTheme.body(size: 11, color: AppTheme.mutedText)),
                  ],
                  if (log.loggedBy != null) ...[
                    const SizedBox(height: 2),
                    Text('Logged by ${log.loggedBy}',
                        style: AppTheme.body(size: 10.5, color: AppTheme.mutedText)),
                  ],
                ],
              ),
            ),
            if (log.value != null)
              Text(log.value!,
                  style: AppTheme.display(size: 13, color: color)),
          ],
        ),
      ),
    );
  }
}

class _LogEntrySheet extends StatefulWidget {
  const _LogEntrySheet();

  @override
  State<_LogEntrySheet> createState() => _LogEntrySheetState();
}

class _LogEntrySheetState extends State<_LogEntrySheet> {
  final _labelController = TextEditingController();
  final _valueController = TextEditingController();
  final _notesController = TextEditingController();
  String _type = 'temperature';
  String _status = 'pass';

  @override
  void dispose() {
    _labelController.dispose();
    _valueController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.bgWhite,
            borderRadius: BorderRadius.circular(22),
            boxShadow: AppTheme.cardShadow,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Log a check', style: AppTheme.display(size: 17)),
                const SizedBox(height: 16),
                ChefniSegmented(
                  labels: const ['Temperature', 'Hygiene'],
                  selectedIndex: _type == 'temperature' ? 0 : 1,
                  onChanged: (i) =>
                      setState(() => _type = i == 0 ? 'temperature' : 'hygiene'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _labelController,
                  decoration: InputDecoration(
                    labelText: _type == 'temperature'
                        ? 'What (e.g. Walk-in chiller)'
                        : 'What (e.g. Handwashing station)',
                  ),
                ),
                const SizedBox(height: 12),
                if (_type == 'temperature')
                  TextField(
                    controller: _valueController,
                    decoration: const InputDecoration(labelText: 'Reading (e.g. 4°C)'),
                  ),
                if (_type == 'temperature') const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _status,
                  decoration: const InputDecoration(labelText: 'Result'),
                  items: const [
                    DropdownMenuItem(value: 'pass', child: Text('Pass')),
                    DropdownMenuItem(value: 'warning', child: Text('Warning')),
                    DropdownMenuItem(value: 'fail', child: Text('Fail')),
                  ],
                  onChanged: (v) => setState(() => _status = v ?? 'pass'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(labelText: 'Notes (optional)'),
                  maxLines: 2,
                ),
                const SizedBox(height: 18),
                ChefniPrimaryButton(
                  label: 'Save entry',
                  onPressed: () {
                    if (_labelController.text.trim().isEmpty) return;
                    Navigator.pop(context, {
                      'type': _type,
                      'label': _labelController.text.trim(),
                      'status': _status,
                      if (_valueController.text.trim().isNotEmpty)
                        'value': _valueController.text.trim(),
                      if (_notesController.text.trim().isNotEmpty)
                        'notes': _notesController.text.trim(),
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
