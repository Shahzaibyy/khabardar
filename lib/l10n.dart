import 'package:flutter/widgets.dart';

import 'app_state.dart';
import 'detection/models.dart';

/// English and Urdu copy. Each entry is `[english, urdu]`.
const Map<String, List<String>> _strings = {
  'appName': ['Khabardar', 'خبردار'],
  'tagline': ['Fraud se pehle, Khabardar.', 'فراڈ سے پہلے، خبردار۔'],
  'loadingThreats': [
    'Loading threat list · works offline',
    'خطرات کی فہرست لوڈ ہو رہی ہے · آف لائن',
  ],
  'skip': ['Skip', 'چھوڑیں'],
  'next': ['Next', 'آگے'],
  'back': ['Back', 'واپس'],
  'getProtected': ['Get protected', 'تحفظ شروع کریں'],
  'onb1Title': [
    'Scam calls get caught before you pick up',
    'فراڈ کالز اٹھانے سے پہلے پکڑی جاتی ہیں',
  ],
  'onb1Body': [
    'Khabardar checks every call and SMS on your phone, even without internet.',
    'خبردار ہر کال اور ایس ایم ایس آپ کے فون پر ہی چیک کرتا ہے، انٹرنیٹ کے بغیر بھی۔',
  ],
  'onb2Title': [
    'Fake BISP and bank messages are flagged instantly',
    'جعلی بی آئی ایس پی اور بینک پیغامات فوراً پکڑے جاتے ہیں',
  ],
  'onb2Body': [
    'We spot fee requests, OTP tricks and fake links in English, Urdu and Roman Urdu.',
    'ہم فیس کے مطالبے، او ٹی پی کے دھوکے اور جعلی لنکس پہچانتے ہیں۔',
  ],
  'onb3Title': ['A warning when it matters most', 'سب سے اہم لمحے پر خبردار'],
  'onb3Body': [
    'If a flagged caller is on the line while you open your wallet app, we step in before you send money.',
    'اگر مشکوک کالر لائن پر ہو اور آپ والٹ ایپ کھولیں تو ہم پیسے بھیجنے سے پہلے خبردار کرتے ہیں۔',
  ],
  'featureOffline': [
    'Works offline in under a blink',
    'آف لائن بھی پلک جھپکتے کام کرتا ہے',
  ],
  'featurePrivate': [
    'Your contacts never leave your phone',
    'آپ کے رابطے آپ کے فون سے باہر نہیں جاتے',
  ],
  'permTitle': ['Turn on your shield', 'اپنی حفاظت آن کریں'],
  'permBody': [
    'Each permission does one job. Everything is checked on your phone; nothing personal is uploaded.',
    'ہر اجازت ایک کام کرتی ہے۔ سب کچھ آپ کے فون پر چیک ہوتا ہے، کچھ ذاتی اپ لوڈ نہیں ہوتا۔',
  ],
  'permCall': ['Call screening', 'کال اسکریننگ'],
  'permCallDesc': [
    'Label scam calls before they ring',
    'فراڈ کالز کو بجنے سے پہلے پہچانیں',
  ],
  'permSms': ['SMS check', 'ایس ایم ایس چیک'],
  'permSmsDesc': [
    'Spot fake BISP and OTP messages',
    'جعلی بی آئی ایس پی اور او ٹی پی پیغامات پکڑیں',
  ],
  'permNotif': ['Alerts', 'الرٹس'],
  'permNotifDesc': [
    'Show a warning when something is caught',
    'خطرہ پکڑے جانے پر اطلاع دیں',
  ],
  'permBank': ['Banking app alerts', 'بینکنگ ایپ الرٹس'],
  'permBankDesc': [
    'Warn you if a scammer is on the line while your wallet is open',
    'والٹ کھلا ہو اور فراڈیا لائن پر ہو تو خبردار کریں',
  ],
  'permBankOverlay': [
    'Step 1: allow "Display over other apps"',
    'مرحلہ 1: دوسری ایپس کے اوپر دکھانے کی اجازت دیں',
  ],
  'permBankUsage': [
    'Step 2: allow "Usage access"',
    'مرحلہ 2: استعمال تک رسائی کی اجازت دیں',
  ],
  'allow': ['Allow', 'اجازت دیں'],
  'on': ['On', 'آن'],
  'notSupported': ['Needs Android 10+', 'اینڈرائیڈ 10 درکار'],
  'privacyNote': [
    "We never read your banking app's screen, and never upload your contacts, call log or messages.",
    'ہم آپ کی بینکنگ ایپ کی اسکرین نہیں پڑھتے، نہ ہی رابطے، کال لاگ یا پیغامات اپ لوڈ کرتے ہیں۔',
  ],
  'continue': ['Continue', 'جاری رکھیں'],
  'readPrivacy': ['Read our privacy promise', 'ہمارا پرائیویسی وعدہ پڑھیں'],
  'youreProtected': ["You're protected", 'آپ محفوظ ہیں'],
  'partlyProtected': ['Protection is partly off', 'حفاظت جزوی طور پر بند ہے'],
  'turnOn': ['Turn on', 'آن کریں'],
  'threatListInfo': [
    'Threat list v{v} · works offline',
    'خطرات کی فہرست ورژن {v} · آف لائن',
  ],
  'callsBlocked': ['Calls blocked', 'بلاک کالز'],
  'smsFlagged': ['SMS flagged', 'مشکوک ایس ایم ایس'],
  'bankAlerts': ['Bank alerts', 'بینک الرٹس'],
  'checkNumber': ['Check a number', 'نمبر چیک کریں'],
  'reportScam': ['Report a scam', 'فراڈ رپورٹ کریں'],
  'trendingTitle': [
    'Trending: fake BISP payment SMS',
    'رجحان: جعلی بی آئی ایس پی ادائیگی ایس ایم ایس',
  ],
  'trendingBody': [
    'BISP never asks for a fee or your OTP. Only trust 8171.',
    'بی آئی ایس پی کبھی فیس یا او ٹی پی نہیں مانگتا۔ صرف 8171 پر بھروسہ کریں۔',
  ],
  'recentActivity': ['Recent activity', 'حالیہ سرگرمی'],
  'seeAll': ['See all', 'سب دیکھیں'],
  'noActivity': [
    "Nothing caught yet. Blocked calls and flagged messages will show here.",
    'ابھی کچھ نہیں پکڑا گیا۔ بلاک کالز اور مشکوک پیغامات یہاں نظر آئیں گے۔',
  ],
  'navShield': ['Shield', 'حفاظت'],
  'navMessages': ['Activity', 'سرگرمی'],
  'navCheck': ['Check', 'چیک'],
  'navSettings': ['Settings', 'ترتیبات'],
  'activity': ['Activity', 'سرگرمی'],
  'filterSms': ['Messages', 'پیغامات'],
  'filterCalls': ['Calls', 'کالز'],
  'filterAll': ['All', 'سب'],
  'whyFlagged': ['Why Khabardar flagged this', 'خبردار نے اسے کیوں پکڑا'],
  'deleteBlock': ['Delete & block', 'ڈیلیٹ اور بلاک'],
  'report': ['Report', 'رپورٹ'],
  'noFlagged': [
    'Nothing here yet. New calls and SMS are checked as they arrive.',
    'ابھی یہاں کچھ نہیں۔ نئی کالز اور ایس ایم ایس آتے ہی چیک ہوتے ہیں۔',
  ],
  'checkTitle': ['Check a number or message', 'نمبر یا پیغام چیک کریں'],
  'checkBody': [
    'Got a strange call or message? Paste the number, link or text before you reply.',
    'جواب دینے سے پہلے نمبر، لنک یا پیغام یہاں چیک کریں۔',
  ],
  'checkLabel': ['Phone number, link or message', 'فون نمبر، لنک یا پیغام'],
  'check': ['Check', 'چیک کریں'],
  'checkPrivacy': [
    'Checked on your phone. Nothing is sent.',
    'آپ کے فون پر چیک ہوا۔ کچھ نہیں بھیجا گیا۔',
  ],
  'scamNumber': ['Scam number', 'فراڈ نمبر'],
  'likelyScam': ['Likely scam', 'ممکنہ فراڈ'],
  'beCareful': ['Be careful', 'محتاط رہیں'],
  'noRisk': ['No known risk', 'کوئی معلوم خطرہ نہیں'],
  'noRiskBody': [
    'We have no reports for this. Still, never share your PIN or OTP.',
    'اس کی کوئی رپورٹ نہیں۔ پھر بھی اپنا پن یا او ٹی پی کسی کو نہ بتائیں۔',
  ],
  'highConfidence': ['High confidence', 'زیادہ یقین'],
  'riskScore': ['Risk score {s}/100', 'خطرہ {s}/100'],
  'scamType': ['Scam type', 'فراڈ کی قسم'],
  'reports': ['Reports', 'رپورٹس'],
  'peopleN': ['{n} people', '{n} افراد'],
  'blockNumber': ['Block number', 'نمبر بلاک کریں'],
  'unblock': ['Unblock', 'ان بلاک'],
  'blocked': ['Number blocked on this phone', 'یہ نمبر اس فون پر بلاک ہو گیا'],
  'shareWarning': ['Share warning', 'دوسروں کو خبردار کریں'],
  'shareText': [
    'Khabardar! {number} is a reported scam ({category}). Never share your OTP or PIN.',
    'خبردار! {number} ایک رپورٹ شدہ فراڈ نمبر ہے ({category})۔ اپنا او ٹی پی یا پن کبھی نہ بتائیں۔',
  ],
  'officialNumbers': ['Official numbers to trust', 'قابل اعتماد سرکاری نمبر'],
  'bispSms': ['BISP SMS', 'بی آئی ایس پی ایس ایم ایس'],
  'bankHelpline': ["Your bank's helpline", 'آپ کے بینک کی ہیلپ لائن'],
  'backOfCard': ['Back of your card', 'کارڈ کی پشت پر'],
  'number': ['Number', 'نمبر'],
  'pretendedTo': [
    'What did they pretend to be?',
    'انہوں نے خود کو کیا ظاہر کیا؟',
  ],
  'messageOptional': ['Message (optional)', 'پیغام (اختیاری)'],
  'maskNote': [
    'Codes, CNIC and account numbers are hidden automatically before saving.',
    'کوڈ، شناختی کارڈ اور اکاؤنٹ نمبر محفوظ کرنے سے پہلے خود بخود چھپ جاتے ہیں۔',
  ],
  'reportPrivacy': [
    'Only a scrambled version of the number is shared. Your own number and contacts never are.',
    'صرف نمبر کا خفیہ ورژن شیئر ہوتا ہے۔ آپ کا اپنا نمبر اور رابطے کبھی نہیں۔',
  ],
  'sendReport': ['Send report', 'رپورٹ بھیجیں'],
  'lostMoney': [
    'Lost money? File a complaint with NCCIA',
    'پیسے گئے؟ این سی سی آئی اے میں شکایت درج کریں',
  ],
  'reportSaved': [
    'Report saved and number blocked. It will be shared when sync is available.',
    'رپورٹ محفوظ اور نمبر بلاک ہو گیا۔ سنک دستیاب ہونے پر شیئر ہو گی۔',
  ],
  'enterNumber': ['Enter a valid phone number', 'درست فون نمبر درج کریں'],
  'pendingReports': ['{n} reports waiting to sync', '{n} رپورٹس سنک کی منتظر'],
  'privacyPromise': ['Our privacy promise', 'ہمارا پرائیویسی وعدہ'],
  'promise1': [
    'Contacts, call log and messages never leave your phone',
    'رابطے، کال لاگ اور پیغامات آپ کے فون سے باہر نہیں جاتے',
  ],
  'promise2': [
    'Phone numbers are hashed with a secret key before any check or report',
    'ہر چیک یا رپورٹ سے پہلے نمبر خفیہ کلید سے ہیش ہوتے ہیں',
  ],
  'promise3': ['No ads, no selling of data', 'نہ اشتہارات، نہ ڈیٹا کی فروخت'],
  'blockSilently': [
    'Block scam calls silently',
    'فراڈ کالز خاموشی سے بلاک کریں',
  ],
  'blockSilentlyDesc': ['Scam calls never ring', 'فراڈ کالز بجیں گی ہی نہیں'],
  'warnSuspicious': ['Warn on scam calls', 'فراڈ کالز پر خبردار کریں'],
  'warnSuspiciousDesc': [
    'Show a warning over the incoming call',
    'آنے والی کال کے اوپر انتباہ دکھائیں',
  ],
  'smsShieldSetting': ['Check incoming SMS', 'آنے والے ایس ایم ایس چیک کریں'],
  'smsShieldDesc': [
    'Flag fake BISP, bank and prize messages',
    'جعلی بی آئی ایس پی، بینک اور انعام کے پیغامات پکڑیں',
  ],
  'bankAlertsDesc': [
    'Warn if a flagged caller is on the line',
    'مشکوک کالر لائن پر ہو تو خبردار کریں',
  ],
  'wifiOnly': ['Update on Wi-Fi only', 'صرف وائی فائی پر اپ ڈیٹ'],
  'wifiOnlyDesc': [
    'For threat list updates once sync is live',
    'سنک شروع ہونے پر فہرست کی اپ ڈیٹس کے لیے',
  ],
  'language': ['Language', 'زبان'],
  'testAlerts': ['Test alerts', 'الرٹس آزمائیں'],
  'testCall': ['Show a test call warning', 'آزمائشی کال انتباہ دکھائیں'],
  'testBank': ['Show a test banking alert', 'آزمائشی بینکنگ الرٹ دکھائیں'],
  'testNeedsOverlay': [
    'Allow "Display over other apps" first',
    'پہلے دوسری ایپس کے اوپر دکھانے کی اجازت دیں',
  ],
  'permissions': ['Permissions', 'اجازتیں'],
  'deleteData': ['Delete all my data', 'میرا سارا ڈیٹا ڈیلیٹ کریں'],
  'deleteConfirm': [
    'This removes blocked numbers, history and saved reports from this phone.',
    'اس سے بلاک نمبر، تاریخ اور محفوظ رپورٹس اس فون سے ہٹ جائیں گی۔',
  ],
  'cancel': ['Cancel', 'منسوخ'],
  'delete': ['Delete', 'ڈیلیٹ'],
  'deleted': ['Your data was deleted', 'آپ کا ڈیٹا ڈیلیٹ ہو گیا'],
  'callAlert': ['Call alert', 'کال الرٹ'],
  'smsAlert': ['Message alert', 'پیغام الرٹ'],
  'bankAlertTitle': ['Banking alert', 'بینکنگ الرٹ'],
  'likelyScamCall': ['Likely scam call', 'ممکنہ فراڈ کال'],
  'likelyScamSms': ['Likely scam message', 'ممکنہ فراڈ پیغام'],
  'bankAlertBody': [
    'You opened a wallet app while a flagged caller was on the line. We showed a warning.',
    'مشکوک کالر کے دوران آپ نے والٹ ایپ کھولی۔ ہم نے انتباہ دکھایا۔',
  ],
  'callBody': [
    'This number is reported for {category} scams. Reported by {n} people.',
    'یہ نمبر {category} فراڈ کے لیے رپورٹ ہوا ہے۔ {n} افراد نے رپورٹ کیا۔',
  ],
  'callBodyBlocked': [
    'You blocked this number earlier.',
    'آپ نے یہ نمبر پہلے بلاک کیا تھا۔',
  ],
  'callBlockedNote': ['This call was blocked', 'یہ کال بلاک کر دی گئی'],
  'remember': ['Remember', 'یاد رکھیں'],
  'bankNeverOtp': [
    'Banks never ask for your PIN or OTP on a call',
    'بینک کبھی کال پر پن یا او ٹی پی نہیں مانگتے',
  ],
  'bispNoFee': [
    'BISP payments never need a fee',
    'بی آئی ایس پی ادائیگی کے لیے کبھی فیس نہیں لگتی',
  ],
  'callBank': ["Call my bank's helpline", 'بینک کی ہیلپ لائن پر کال کریں'],
  'done': ['Done', 'ٹھیک ہے'],
  'justNow': ['just now', 'ابھی'],
  'minutesAgo': ['{n} min ago', '{n} منٹ پہلے'],
  'hoursAgo': ['{n} h ago', '{n} گھنٹے پہلے'],
  'daysAgo': ['{n} d ago', '{n} دن پہلے'],
  'scamBadge': ['SCAM', 'فراڈ'],
  'checkBadge': ['CHECK', 'مشکوک'],
  'evCallBlocked': ['Call blocked', 'کال بلاک'],
  'evCallWarned': ['Scam call warned', 'فراڈ کال پر انتباہ'],
  'evSms': ['Message flagged', 'پیغام مشکوک'],
  'evBank': ['Banking alert shown', 'بینکنگ الرٹ دکھایا گیا'],
  // Categories
  'cat_bisp': ['BISP / Ehsaas', 'بی آئی ایس پی / احساس'],
  'cat_bank': ['Bank / wallet', 'بینک / والٹ'],
  'cat_prize': ['Prize / lottery', 'انعام / لاٹری'],
  'cat_official': ['Police / official', 'پولیس / سرکاری'],
  'cat_courier': ['Courier / parcel', 'کوریئر / پارسل'],
  'cat_other': ['Something else', 'کچھ اور'],
  'cat_blockedByYou': ['Blocked by you', 'آپ نے بلاک کیا'],
  // Reasons
  'r_listed_number': [
    'This number is on the scam list',
    'یہ نمبر فراڈ فہرست میں ہے',
  ],
  'r_blocked_by_you': ['You blocked this number', 'آپ نے یہ نمبر بلاک کیا'],
  'r_lookalike_sender': [
    "Sender imitates BISP's official 8171",
    'بھیجنے والا 8171 کی نقل کر رہا ہے',
  ],
  'r_bisp_mention': [
    'Mentions BISP or Ehsaas',
    'بی آئی ایس پی یا احساس کا ذکر',
  ],
  'r_fee_request': [
    'Asks for a fee to release money',
    'رقم جاری کرنے کے لیے فیس مانگتا ہے',
  ],
  'r_otp_request': [
    'Asks you to share a code or OTP',
    'کوڈ یا او ٹی پی بتانے کو کہتا ہے',
  ],
  'r_account_threat': [
    'Threatens to block your account or SIM',
    'اکاؤنٹ یا سم بند کرنے کی دھمکی',
  ],
  'r_prize_lure': [
    'Promises a prize or lucky draw',
    'انعام یا لکی ڈرا کا وعدہ',
  ],
  'r_urgency': ['Pushes you to act immediately', 'فوری عمل پر زور'],
  'r_official_impersonation': [
    'Claims to be police, FIA or another official',
    'پولیس، ایف آئی اے یا سرکاری ادارہ ہونے کا دعویٰ',
  ],
  'r_courier_fee': [
    'Asks for a parcel or customs fee',
    'پارسل یا کسٹم فیس مانگتا ہے',
  ],
  'r_link': ['Contains a link', 'اس میں لنک ہے'],
  'r_risky_domain': [
    'Link uses a domain often used by scammers',
    'لنک ایسی ویب سائٹ کا ہے جو فراڈ میں عام ہے',
  ],
};

/// Looks up copy in the current language.
class L10n {
  const L10n(this.urdu);

  final bool urdu;

  static L10n of(BuildContext context) =>
      L10n(AppScope.of(context).settings.language == 'ur');

  String t(String key, [Map<String, Object> args = const {}]) {
    final pair = _strings[key];
    var s = pair == null ? key : pair[urdu ? 1 : 0];
    args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }

  String category(ScamCategory? c) =>
      t('cat_${(c ?? ScamCategory.other).name}');

  String reason(String id) => t('r_$id');

  String ago(DateTime time) {
    final d = DateTime.now().difference(time);
    if (d.inMinutes < 1) return t('justNow');
    if (d.inHours < 1) return t('minutesAgo', {'n': d.inMinutes});
    if (d.inDays < 1) return t('hoursAgo', {'n': d.inHours});
    return t('daysAgo', {'n': d.inDays});
  }

  TextDirection get direction => urdu ? TextDirection.rtl : TextDirection.ltr;
}
