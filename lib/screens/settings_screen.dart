import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'permissions_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.standalone = false});

  /// True when pushed on its own (from onboarding) rather than as a tab.
  final bool standalone;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final state = AppScope.of(context);
    final s = state.settings;
    final p = state.permissions;

    Widget toggle(
      String title,
      String desc,
      bool value,
      ValueChanged<bool> onChanged,
    ) => SwitchListTile(
      value: value,
      onChanged: onChanged,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        desc,
        style: const TextStyle(fontSize: 12, color: KColors.muted),
      ),
    );

    const divider = Divider(height: 1, color: KColors.lineSoft);

    final list = ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        if (!standalone) ...[
          Text(
            l.t('navSettings'),
            style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
        ],
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: KColors.green,
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.lock_outline, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(
                    l.t('privacyPromise'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              for (final k in ['promise1', 'promise2', 'promise3'])
                BulletLine(
                  l.t(k),
                  color: KColors.mintText,
                  textColor: const Color(0xFFE6F4EC),
                ),
            ],
          ),
        ),
        if (!standalone) ...[
          const SizedBox(height: 16),
          KCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                toggle(
                  l.t('blockSilently'),
                  l.t('blockSilentlyDesc'),
                  s.blockScamCalls,
                  (v) => state.updateSettings(s.copyWith(blockScamCalls: v)),
                ),
                divider,
                toggle(
                  l.t('warnSuspicious'),
                  l.t('warnSuspiciousDesc'),
                  s.warnSuspiciousCalls,
                  (v) =>
                      state.updateSettings(s.copyWith(warnSuspiciousCalls: v)),
                ),
                divider,
                toggle(
                  l.t('smsShieldSetting'),
                  l.t('smsShieldDesc'),
                  s.smsShield,
                  (v) => state.updateSettings(s.copyWith(smsShield: v)),
                ),
                divider,
                toggle(
                  l.t('permBank'),
                  l.t('bankAlertsDesc'),
                  s.bankingAlerts,
                  (v) => state.updateSettings(s.copyWith(bankingAlerts: v)),
                ),
                divider,
                toggle(
                  l.t('wifiOnly'),
                  l.t('wifiOnlyDesc'),
                  s.wifiOnlyUpdates,
                  (v) => state.updateSettings(s.copyWith(wifiOnlyUpdates: v)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          KCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text(
                    l.t('permissions'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: Icon(
                    p.allCore && p.bankingAlerts
                        ? Icons.check_circle
                        : Icons.error_outline,
                    color: p.allCore && p.bankingAlerts
                        ? KColors.green
                        : KColors.suspicious,
                  ),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PermissionsScreen(),
                    ),
                  ),
                ),
                divider,
                ListTile(
                  leading: const Icon(Icons.translate),
                  title: Text(
                    l.t('language'),
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  trailing: SegmentedButton<String>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(value: 'en', label: Text('EN')),
                      ButtonSegment(
                        value: 'ur',
                        label: Text(
                          'اردو',
                          style: TextStyle(fontFamily: kUrduFont),
                        ),
                      ),
                    ],
                    selected: {s.language},
                    onSelectionChanged: (v) =>
                        state.updateSettings(s.copyWith(language: v.first)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionTitle(l.t('testAlerts')),
          const SizedBox(height: 8),
          KCard(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.phone_callback_outlined),
                  title: Text(l.t('testCall')),
                  onTap: () => _test(context, state.bridge.showTestCallAlert),
                ),
                divider,
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: Text(l.t('testBank')),
                  onTap: () =>
                      _test(context, state.bridge.showTestBankingAlert),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          KCard(
            padding: EdgeInsets.zero,
            child: ListTile(
              leading: const Icon(Icons.delete_outline, color: KColors.scam),
              title: Text(
                l.t('deleteData'),
                style: const TextStyle(
                  color: KColors.scam,
                  fontWeight: FontWeight.w700,
                ),
              ),
              onTap: () => _confirmDelete(context),
            ),
          ),
          if (state.pendingReports > 0) ...[
            const SizedBox(height: 12),
            Text(
              l.t('pendingReports', {'n': state.pendingReports}),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: KColors.muted),
            ),
          ],
        ],
      ],
    );

    if (!standalone) return SafeArea(child: list);
    return Scaffold(
      appBar: AppBar(title: Text(l.t('privacyPromise'))),
      body: SafeArea(child: list),
    );
  }

  Future<void> _test(BuildContext context, Future<void> Function() show) async {
    final state = AppScope.read(context);
    final l = L10n.of(context);
    await state.refreshPermissions();
    if (!state.permissions.overlay) {
      if (context.mounted) showToast(context, l.t('testNeedsOverlay'));
      await state.bridge.requestOverlay();
      return;
    }
    await show();
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l = L10n.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.t('deleteData')),
        content: Text(l.t('deleteConfirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l.t('cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              l.t('delete'),
              style: const TextStyle(color: KColors.scam),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await AppScope.read(context).deleteAllData();
    if (context.mounted) showToast(context, l.t('deleted'));
  }
}
