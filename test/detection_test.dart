import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:khabardar/detection/engine.dart';
import 'package:khabardar/detection/masking.dart';
import 'package:khabardar/detection/models.dart';
import 'package:khabardar/detection/normalizer.dart';

void main() {
  late DetectionEngine engine;

  setUpAll(() {
    engine = DetectionEngine.fromJson(
      File('assets/threat/threat_set.json').readAsStringSync(),
    );
  });

  group('normalizePhone', () {
    test('handles local, international and short codes', () {
      expect(normalizePhone('0300 0000111'), '+923000000111');
      expect(normalizePhone('+92 300 0000111'), '+923000000111');
      expect(normalizePhone('0092-300-0000111'), '+923000000111');
      expect(normalizePhone('923000000111'), '+923000000111');
      expect(normalizePhone('3000000111'), '+923000000111');
      expect(normalizePhone('8171'), '8171');
    });

    test('formats for display', () {
      expect(formatPhone('+923000000111'), '0300 0000111');
    });
  });

  group('number lookup', () {
    test('hash matches the value used to build the threat set', () {
      // Same value the Kotlin side must produce (see ThreatEngineTest).
      expect(
        engine.hashNumber('0300 0000111'),
        '18ac14f2fc86b5350ac63c5e1e12516f03e4bc76a7ec7b2f23fef63d8cf12d1a',
      );
    });

    test('listed number is a scam with its category and reports', () {
      final v = engine.checkNumber('0300-0000111');
      expect(v.level, RiskLevel.scam);
      expect(v.category, ScamCategory.bisp);
      expect(v.reports, 214);
    });

    test('unknown number is safe', () {
      expect(engine.checkNumber('0300 1234567').level, RiskLevel.safe);
    });

    test('user blocked number is a scam', () {
      final h = engine.hashNumber('03001234567');
      final v = engine.checkNumber('+923001234567', userBlocked: {h});
      expect(v.level, RiskLevel.scam);
      expect(v.category, ScamCategory.blockedByYou);
    });

    test('official short code is trusted', () {
      expect(engine.checkNumber('8171').level, RiskLevel.safe);
    });
  });

  group('message rules', () {
    test('fake BISP fee message is a scam', () {
      final v = engine.checkMessage(
        'Mubarak! Aap ki BISP raqam Rs 25,000 jari ho gayi hai. Wasooli ke '
        'liye Rs 500 fee is link par jama karwayen: bisp-payment.xyz',
        sender: '8171-BISP',
      );
      expect(v.level, RiskLevel.scam);
      expect(v.category, ScamCategory.bisp);
      expect(v.reasons, containsAll(['lookalike_sender', 'fee_request']));
    });

    test('OTP harvesting is a scam', () {
      final v = engine.checkMessage(
        'Your account will be blocked today. Share the code you received to '
        'verify immediately.',
      );
      expect(v.level, RiskLevel.scam);
      expect(v.category, ScamCategory.bank);
    });

    test('Urdu OTP request is flagged', () {
      final v = engine.checkMessage('آپ کا اکاؤنٹ بند ہو جائے گا، کوڈ بتائیں');
      expect(v.level, isNot(RiskLevel.safe));
    });

    test('ordinary message is safe', () {
      final v = engine.checkMessage('Kal shaam 7 baje milte hain, theek hai?');
      expect(v.level, RiskLevel.safe);
      expect(v.reasons, isEmpty);
    });

    test('links to trusted government domains are not penalised', () {
      final v = engine.checkMessage('Details: https://bisp.gov.pk/');
      expect(v.reasons, isNot(contains('link')));
    });

    test('listed sender wins even with harmless text', () {
      final v = engine.checkMessage('hello', sender: '03000000111');
      expect(v.level, RiskLevel.scam);
      expect(v.numberListed, isTrue);
    });
  });

  group('masking', () {
    test('hides OTPs, CNICs and account numbers but keeps 8171', () {
      final out = maskSensitive(
        'Code 482913, CNIC 35202-1234567-1, acct 01234567890123, from 8171',
      );
      expect(out, isNot(contains('482913')));
      expect(out, isNot(contains('35202')));
      expect(out, isNot(contains('01234567890123')));
      expect(out, contains('8171'));
    });
  });
}
