import 'package:flutter/material.dart';

import '../app_state.dart';
import '../l10n.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/logo.dart';
import 'permissions_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _page = 0;

  void _toPermissions() => Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const PermissionsScreen(firstRun: true)),
  );

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = L10n.of(context);
    final state = AppScope.of(context);
    final slides = [
      (l.t('onb1Title'), l.t('onb1Body'), const _CallIllustration()),
      (l.t('onb2Title'), l.t('onb2Body'), const _SmsIllustration()),
      (l.t('onb3Title'), l.t('onb3Body'), const _WalletIllustration()),
    ];
    final last = _page == slides.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  _LanguageToggle(
                    urdu: l.urdu,
                    onChanged: (ur) => state.updateSettings(
                      state.settings.copyWith(language: ur ? 'ur' : 'en'),
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: _toPermissions,
                    child: Text(
                      l.t('skip'),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: PageView.builder(
                  controller: _pages,
                  itemCount: slides.length,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemBuilder: (context, i) {
                    final (title, body, art) = slides[i];
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          art,
                          const SizedBox(height: 24),
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              height: l.urdu ? 1.9 : 1.2,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            body,
                            style: TextStyle(
                              fontSize: 16,
                              color: KColors.ink2,
                              height: l.urdu ? 2 : 1.55,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _Feature(Icons.check, l.t('featureOffline')),
                          const SizedBox(height: 10),
                          _Feature(Icons.lock_outline, l.t('featurePrivate')),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < slides.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _page ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page
                            ? KColors.green
                            : const Color(0xFFB9CCC3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: last
                    ? _toPermissions
                    : () => _pages.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOut,
                      ),
                child: Text(last ? l.t('getProtected') : l.t('next')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageToggle extends StatelessWidget {
  const _LanguageToggle({required this.urdu, required this.onChanged});

  final bool urdu;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, bool selected, bool value, String? font) =>
        Semantics(
          button: true,
          selected: selected,
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: Container(
              constraints: const BoxConstraints(minHeight: 40),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: selected ? KColors.green : Colors.transparent,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: font,
                  color: selected ? Colors.white : KColors.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  height: font == null ? 1.2 : 1.6,
                ),
              ),
            ),
          ),
        );
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: KColors.line),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          chip('English', !urdu, false, 'Manrope'),
          chip('اردو', urdu, true, kUrduFont),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  const _Feature(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      IconTile(icon, size: 36),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    ],
  );
}

class _ArtFrame extends StatelessWidget {
  const _ArtFrame({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    height: 260,
    decoration: BoxDecoration(
      color: KColors.green,
      borderRadius: BorderRadius.circular(28),
    ),
    clipBehavior: Clip.antiAlias,
    child: Stack(
      children: [
        const PositionedDirectional(
          top: 24,
          end: 28,
          child: KhabardarLogo.onColor(size: 56),
        ),
        Align(alignment: Alignment.bottomCenter, child: child),
      ],
    ),
  );
}

class _PhoneCard extends StatelessWidget {
  const _PhoneCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    width: 220,
    height: 200,
    padding: const EdgeInsets.fromLTRB(14, 18, 14, 0),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    ),
  );
}

class _Pill extends StatelessWidget {
  const _Pill(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: KColors.scam,
      borderRadius: BorderRadius.circular(999),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.warning_amber_rounded, size: 13, color: Colors.white),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'Manrope',
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

const _small = TextStyle(
  fontFamily: 'Manrope',
  fontSize: 11,
  fontWeight: FontWeight.w700,
  color: KColors.muted,
);
const _big = TextStyle(
  fontFamily: 'Manrope',
  fontSize: 16,
  fontWeight: FontWeight.w800,
  color: KColors.ink,
);

class _CallIllustration extends StatelessWidget {
  const _CallIllustration();

  @override
  Widget build(BuildContext context) => const _ArtFrame(
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: _PhoneCard(
        children: [
          Text('Incoming call', style: _small),
          SizedBox(height: 8),
          Text('0300 0000111', style: _big),
          SizedBox(height: 10),
          _Pill('Likely BISP scam'),
          SizedBox(height: 10),
          Text('Reported by 214 users', style: _small),
        ],
      ),
    ),
  );
}

class _SmsIllustration extends StatelessWidget {
  const _SmsIllustration();

  @override
  Widget build(BuildContext context) => const _ArtFrame(
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: _PhoneCard(
        children: [
          Text('SMS · 8171-BISP', style: _small),
          SizedBox(height: 8),
          Text(
            'Aap ki raqam jari ho gayi. Rs 500 fee jama karwayen…',
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 12,
              color: KColors.ink2,
              height: 1.4,
            ),
          ),
          SizedBox(height: 10),
          _Pill('Fake BISP message'),
        ],
      ),
    ),
  );
}

class _WalletIllustration extends StatelessWidget {
  const _WalletIllustration();

  @override
  Widget build(BuildContext context) => const _ArtFrame(
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: _PhoneCard(
        children: [
          Text('Wallet app', style: _small),
          SizedBox(height: 8),
          Text('Stop! Flagged caller', style: _big),
          SizedBox(height: 10),
          _Pill('End the call first'),
          SizedBox(height: 10),
          Text('No bank asks for your OTP', style: _small),
        ],
      ),
    ),
  );
}
