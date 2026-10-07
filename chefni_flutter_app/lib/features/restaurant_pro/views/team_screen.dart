import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/repositories/team_repository.dart';
import '../../../core/services/service_locator.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/async_view.dart';
import '../../../core/widgets/chefni_ui.dart';
import 'staff_view_screen.dart';

/// Restaurant Pro's kitchen roster — up to 5 people. Staff do not sign in
/// separately; "Kitchen staff view" is a stripped-down mode the owner's app
/// shows, not a second account.
class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  final GlobalKey<AsyncViewState<({List<StaffMember> staff, int maxStaff})>> _viewKey =
      GlobalKey<AsyncViewState<({List<StaffMember> staff, int maxStaff})>>();

  Future<void> _invite(int currentCount, int maxStaff) async {
    if (currentCount >= maxStaff) {
      showApiError(
        context,
        ApiException('Restaurant Pro supports up to $maxStaff staff members.'),
      );
      return;
    }

    final result = await showModalBottomSheet<({String name, String role, String phone})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _InviteStaffSheet(),
    );
    if (result == null || !mounted) return;

    try {
      await ServiceScope.of(context).team.add(
            name: result.name,
            role: result.role,
            phone: result.phone.isEmpty ? null : result.phone,
          );
      _viewKey.currentState?.reload();
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _toggleActive(StaffMember staff) async {
    try {
      await ServiceScope.of(context).team.setActive(staff.id, !staff.isActive);
      _viewKey.currentState?.reload();
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  Future<void> _remove(StaffMember staff) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppTheme.bgWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text('Remove ${staff.name}?', style: AppTheme.display(size: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancel',
                style: AppTheme.display(size: 13.5, color: AppTheme.mutedText)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Remove',
                style: AppTheme.display(size: 13.5, color: AppTheme.alertRed)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await ServiceScope.of(context).team.remove(staff.id);
      _viewKey.currentState?.reload();
    } on ApiException catch (e) {
      if (mounted) showApiError(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = ServiceScope.of(context);

    return Scaffold(
      backgroundColor: AppTheme.bgShell,
      appBar: AppBar(
        backgroundColor: AppTheme.bgShell,
        elevation: 0,
        foregroundColor: AppTheme.darkText,
        title: Text('Team', style: AppTheme.display(size: 18)),
      ),
      body: AsyncView<({List<StaffMember> staff, int maxStaff})>(
        key: _viewKey,
        load: services.team.fetchAll,
        builder: (context, data, reload) => RefreshIndicator(
          color: AppTheme.coralPrimary,
          onRefresh: () async => reload(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 28),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Staff accounts used',
                      style: AppTheme.body(size: 13, color: AppTheme.mutedText)),
                  Text('${data.staff.length} of ${data.maxStaff}',
                      style: AppTheme.display(size: 13.5, weight: FontWeight.w700)),
                ],
              ),
              const SizedBox(height: 14),
              if (data.staff.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: Text('No staff added yet.',
                        style: AppTheme.body(size: 13, color: AppTheme.mutedText)),
                  ),
                )
              else
                for (final staff in data.staff) _buildRow(staff),
              const SizedBox(height: 6),
              ChefniPrimaryButton(
                label: 'Invite staff member',
                onPressed: () => _invite(data.staff.length, data.maxStaff),
              ),
              const SizedBox(height: 10),
              Text(
                'Staff see the kitchen view only — no billing or costs.',
                textAlign: TextAlign.center,
                style: AppTheme.body(size: 12, color: AppTheme.mutedText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow(StaffMember staff) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ChefniCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => StaffViewScreen(staff: staff)),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: staff.isActive ? AppTheme.coralPrimary : AppTheme.mutedText,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                staff.name.isNotEmpty ? staff.name[0].toUpperCase() : '?',
                style: AppTheme.display(size: 15, color: Colors.white),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(staff.name,
                      style: AppTheme.display(size: 13.5, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(
                    staff.isActive ? staff.roleLabel : '${staff.roleLabel} · inactive',
                    style: AppTheme.body(size: 11.5, color: AppTheme.mutedText),
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, size: 19, color: AppTheme.mutedText),
              onSelected: (value) {
                if (value == 'toggle') _toggleActive(staff);
                if (value == 'remove') _remove(staff);
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(staff.isActive ? 'Deactivate' : 'Reactivate'),
                ),
                const PopupMenuItem(value: 'remove', child: Text('Remove')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InviteStaffSheet extends StatefulWidget {
  const _InviteStaffSheet();

  @override
  State<_InviteStaffSheet> createState() => _InviteStaffSheetState();
}

class _InviteStaffSheetState extends State<_InviteStaffSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  String _role = 'staff';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Invite staff member', style: AppTheme.display(size: 17)),
              const SizedBox(height: 16),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'manager', child: Text('Manager')),
                  DropdownMenuItem(value: 'chef', child: Text('Head chef')),
                  DropdownMenuItem(value: 'staff', child: Text('Kitchen staff')),
                ],
                onChanged: (v) => setState(() => _role = v ?? 'staff'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone (optional)'),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 18),
              ChefniPrimaryButton(
                label: 'Add to team',
                onPressed: () {
                  if (_nameController.text.trim().isEmpty) return;
                  Navigator.pop(context, (
                    name: _nameController.text.trim(),
                    role: _role,
                    phone: _phoneController.text.trim(),
                  ));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
