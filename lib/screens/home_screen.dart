import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/logo.dart';
import 'event_detail_screen.dart';
import 'home_shell.dart';
import 'permissions_screen.dart';
import 'report_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final state = AppScope.of(context);
    final protected = state.permissions.allCore;
    final recent = state.events.take(3).toList();

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: state.refreshHistory,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Row(children: [KhabardarWordmark()]),
            const SizedBox(height: 16),
            _StatusCard(protected: protected),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionCard(
                    icon: Icons.search,
                    color: KColors.green,
                    label: l.t('checkNumber'),
                    onTap: () => HomeShell.goTo(context, 2),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionCard(
                    icon: Icons.flag_outlined,
                    color: KColors.scam,
                    label: l.t('reportScam'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReportScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            KCard(
              color: KColors.scamTint,
              borderColor: KColors.scamBorder,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded, color: KColors.scam),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.t('trendingTitle'),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: KColors.scamInk,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l.t('trendingBody'),
                          style: TextStyle(
                            fontSize: 13,
                            color: KColors.scamInk,
                            height: l.urdu ? 1.9 : 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionTitle(
              l.t('recentActivity'),
              trailing: TextButton(
                onPressed: () => HomeShell.goTo(context, 1),
                child: Text(l.t('seeAll')),
              ),
            ),
            const SizedBox(height: 4),
            KCard(
              padding: EdgeInsets.zero,
              child: recent.isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l.t('noActivity'),
                        style: const TextStyle(
                          fontSize: 13,
                          color: KColors.muted,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (var i = 0; i < recent.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: KColors.lineSoft),
                          EventTile(
                            event: recent[i],
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    EventDetailScreen(event: recent[i]),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.protected});

  final bool protected;

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final state = AppScope.of(context);
    Widget stat(int n, String label) => Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: KColors.greenDark,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$n',
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: KColors.mintText, fontSize: 12),
            ),
          ],
        ),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: protected ? KColors.green : KColors.suspicious,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: Colors.white24,
                child: Icon(
                  protected ? Icons.check : Icons.priority_high,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      protected
                          ? l.t('youreProtected')
                          : l.t('partlyProtected'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      l.t('threatListInfo', {'v': state.engine?.version ?? 1}),
                      style: const TextStyle(
                        color: KColors.mintText,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (!protected)
                TextButton(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: KColors.ink,
                    minimumSize: const Size(0, 44),
                  ),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PermissionsScreen(),
                    ),
                  ),
                  child: Text(
                    l.t('turnOn'),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
            ],
          ),
          if (protected) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                stat(state.countOf('call', blocked: true), l.t('callsBlocked')),
                const SizedBox(width: 8),
                stat(state.countOf('sms'), l.t('smsFlagged')),
                const SizedBox(width: 8),
                stat(state.countOf('bank_alert'), l.t('bankAlerts')),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => KCard(
    onTap: onTap,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ],
    ),
  );
}
