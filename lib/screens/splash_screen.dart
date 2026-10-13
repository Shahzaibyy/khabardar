import 'package:flutter/material.dart';

import '../theme.dart';
import '../widgets/logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KColors.green,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(32, 96, 32, 48),
          child: Column(
            children: [
              const KhabardarLogo.onColor(size: 132),
              const SizedBox(height: 20),
              const Text(
                'Khabardar',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                ),
              ),
              const Text(
                'خبردار',
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: kUrduFont,
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  height: 1.9,
                ),
              ),
              const Text(
                'Fraud se pehle, Khabardar.',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: KColors.mintText,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 160,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: const LinearProgressIndicator(
                    minHeight: 4,
                    color: Colors.white,
                    backgroundColor: KColors.greenMid,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Loading threat list · works offline',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  color: KColors.mintText,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
