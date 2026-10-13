import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_state.dart';
import 'screens/event_detail_screen.dart';
import 'screens/home_shell.dart';
import 'screens/onboarding_screen.dart';
import 'screens/splash_screen.dart';
import 'theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(KhabardarApp(state: AppState()));
}

class KhabardarApp extends StatefulWidget {
  const KhabardarApp({super.key, required this.state});

  final AppState state;

  @override
  State<KhabardarApp> createState() => _KhabardarAppState();
}

class _KhabardarAppState extends State<KhabardarApp>
    with WidgetsBindingObserver {
  final _navigator = GlobalKey<NavigatorState>();
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    final minSplash = Future<void>.delayed(const Duration(milliseconds: 1200));
    Future.wait([widget.state.init(), minSplash]).then((_) {
      if (!mounted) return;
      setState(() => _splashDone = true);
      _openLaunchEvent();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState s) {
    if (s != AppLifecycleState.resumed || !widget.state.ready) return;
    // Permissions are granted in system screens, and alerts may have arrived.
    widget.state.refreshPermissions();
    widget.state.refreshHistory();
    widget.state.bridge.launchEvent().then((e) {
      if (e == null) return;
      widget.state.launchEvent = e;
      _openLaunchEvent();
    });
  }

  void _openLaunchEvent() {
    final e = widget.state.launchEvent;
    if (e == null || !widget.state.settings.onboarded) return;
    widget.state.launchEvent = null;
    _navigator.currentState?.push(
      MaterialPageRoute(builder: (_) => EventDetailScreen(event: e)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      state: widget.state,
      child: ListenableBuilder(
        listenable: widget.state,
        builder: (context, _) {
          final s = widget.state;
          final urdu = s.settings.language == 'ur';
          final Widget home = !_splashDone
              ? const SplashScreen()
              : s.settings.onboarded
              ? const HomeShell()
              : const OnboardingScreen();
          return MaterialApp(
            navigatorKey: _navigator,
            title: 'Khabardar',
            debugShowCheckedModeBanner: false,
            theme: buildTheme(urdu: urdu),
            builder: (context, child) => Directionality(
              textDirection: urdu ? TextDirection.rtl : TextDirection.ltr,
              child: child!,
            ),
            home: home,
          );
        },
      ),
    );
  }
}
