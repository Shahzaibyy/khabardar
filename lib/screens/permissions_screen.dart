import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'settings_screen.dart';

class PermissionsScreen extends StatelessWidget {
  const PermissionsScreen({super.key, this.firstRun = false});

  /// On first run, Continue finishes onboarding; otherwise it just goes back.
  final bool firstRun;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final state = AppScope.of(context);
    final p = state.permissions;
    final bridge = state.bridge;

    return Scaffold(
      appBar: AppBar(title: firstRun ? null : Text(l.t('permissions'))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          children: [
            if (firstRun) ...[
              Text(
                l.t('permTitle'),
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: l.urdu ? 1.9 : 1.2,
                ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              l.t('permBody'),
              style: TextStyle(
                fontSize: 15,
                color: KColors.ink2,
                height: l.urdu ? 2 : 1.55,
              ),
            ),
            const SizedBox(height: 20),
            _PermissionCard(
              icon: Icons.phone_outlined,
              title: l.t('permCall'),
              description: l.t('permCallDesc'),
              granted: p.callScreening,
              supported: p.callScreeningSupported,
              onAllow: bridge.requestCallScreening,
            ),
            const SizedBox(height: 12),
            _PermissionCard(
              icon: Icons.sms_outlined,
              title: l.t('permSms'),
              description: l.t('permSmsDesc'),
              granted: p.sms,
              onAllow: bridge.requestSms,
            ),
            const SizedBox(height: 12),
            _PermissionCard(
              icon: Icons.notifications_none,
              title: l.t('permNotif'),
              description: l.t('permNotifDesc'),
              granted: p.notifications,
              onAllow: bridge.requestNotifications,
            ),
            const SizedBox(height: 12),
            _PermissionCard(
              icon: Icons.account_balance_wallet_outlined,
              title: l.t('permBank'),
              description: p.bankingAlerts
                  ? l.t('permBankDesc')
                  : !p.overlay
                  ? l.t('permBankOverlay')
                  : l.t('permBankUsage'),
              granted: p.bankingAlerts,
              onAllow: !p.overlay
                  ? bridge.requestOverlay
                  : bridge.requestUsageAccess,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KColors.mint,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_outline, size: 20, color: KColors.deep),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      l.t('privacyNote'),
                      style: TextStyle(
                        fontSize: 13,
                        color: KColors.deep,
                        height: l.urdu ? 2 : 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () {
                if (firstRun) {
                  state.updateSettings(
                    state.settings.copyWith(onboarded: true),
                  );
                  Navigator.of(context).popUntil((r) => r.isFirst);
                } else {
                  Navigator.of(context).pop();
                }
              },
              child: Text(l.t('continue')),
            ),
            if (firstRun)
              TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SettingsScreen(standalone: true),
                  ),
                ),
                child: Text(
                  l.t('readPrivacy'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.granted,
    required this.onAllow,
    this.supported = true,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool granted;
  final bool supported;
  final Future<void> Function() onAllow;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final Widget trailing;
    if (granted) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check, color: KColors.green, size: 20),
          const SizedBox(width: 4),
          Text(
            l.t('on'),
            style: const TextStyle(
              color: KColors.green,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );
    } else if (!supported) {
      trailing = Text(
        l.t('notSupported'),
        style: const TextStyle(fontSize: 12, color: KColors.muted),
      );
    } else {
      trailing = FilledButton(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        onPressed: () async {
          await onAllow();
          if (context.mounted) AppScope.read(context).refreshPermissions();
        },
        child: Text(l.t('allow')),
      );
    }
    return KCard(
      child: Row(
        children: [
          IconTile(icon),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: KColors.muted,
                    height: l.urdu ? 1.9 : 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}
