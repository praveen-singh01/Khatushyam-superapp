// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'खाटू श्याम बाबा';

  @override
  String get appTagline => 'शांत भक्ति, हर दिन';

  @override
  String get navHome => 'होम';

  @override
  String get navStory => 'खोजें';

  @override
  String get navChamatkar => 'समुदाय';

  @override
  String get navPosters => 'पोस्टर';

  @override
  String get navPremium => 'प्रोफ़ाइल';

  @override
  String get signInTitle => 'स्वागत है';

  @override
  String get signInSubtitle => 'जारी रखने के लिए Google से साइन इन करें';

  @override
  String get signInWithGoogle => 'Google से साइन इन करें';

  @override
  String get signOut => 'साइन आउट';

  @override
  String get profileEditName => 'नाम बदलें';

  @override
  String get profileNameHint => 'आपका नाम';

  @override
  String get profileSave => 'सेव करें';

  @override
  String get profilePolicies => 'नीतियाँ';

  @override
  String profileDaysRemaining(int days) {
    return '$days दिन शेष';
  }

  @override
  String get homeGreeting => 'जय श्याम';

  @override
  String get homeFreeFeatures => 'सभी के लिए मुफ़्त';

  @override
  String get homePremiumFeatures => 'सदस्यता के साथ';

  @override
  String get storyTitle => 'श्याम कथा';

  @override
  String get storySubtitle => 'सरल अध्याय — मुफ़्त';

  @override
  String get storyPlaceholder => 'कथा वीडियो जल्द यहाँ आएगा।';

  @override
  String get chamatkarTitle => 'चमत्कार';

  @override
  String get chamatkarSubtitle => 'भक्तों के अनुभव — मुफ़्त';

  @override
  String get chamatkarPlaceholder => 'समुदाय फ़ीड जल्द यहाँ आएगा।';

  @override
  String get chamatkarShareCta => 'अनुभव लिखें';

  @override
  String get chamatkarTitleHint => 'शीर्षक';

  @override
  String get chamatkarStoryHint => 'अपना अनुभव लिखें...';

  @override
  String get chamatkarPublish => 'प्रकाशित करें';

  @override
  String get chamatkarEmpty => 'अभी कोई अनुभव नहीं। पहले आप लिखें।';

  @override
  String get featureLiveDarshan => 'लाइव दर्शन';

  @override
  String get liveDarshanSubtitle => 'खाटू श्याम को YouTube पर लाइव देखें — मुफ़्त';

  @override
  String get liveDarshanOfflineTitle => 'लाइव दर्शन अभी बंद है';

  @override
  String get liveDarshanOfflineMessage => 'जब आरती शुरू होगी, बाबा का लाइव यहाँ दिखेगा।';

  @override
  String get liveDarshanLiveBadge => 'अभी लाइव';

  @override
  String get liveDarshanOfflineBadge => 'अभी लाइव नहीं';

  @override
  String get liveDarshanWatchCta => 'लाइव देखें';

  @override
  String get paywallTitle => 'प्रीमियम सदस्यता';

  @override
  String get paywallSubtitle => 'मासिक योजना से भक्ति सेवाएँ खोलें';

  @override
  String get paywallSubtitleTrial => 'साप्ताहिक या मासिक चुनें। ऑटोपे के लिए एक बार ₹3 लगेगा।';

  @override
  String get paywallSubtitleReturn => 'प्रीमियम के लिए साप्ताहिक या मासिक योजना चुनें';

  @override
  String get paywallCta => 'मासिक योजना शुरू करें';

  @override
  String get paywallTrialTitle => 'परिचय ट्रायल';

  @override
  String get paywallWeeklyTitle => 'साप्ताहिक';

  @override
  String get paywallMonthlyTitle => 'मासिक';

  @override
  String paywallTrialDetail(int price) {
    return 'फिर ₹$price/महीना। कभी भी रद्द करें।';
  }

  @override
  String get paywallTrialCta => '₹3 ट्रायल शुरू करें';

  @override
  String get paywallSubscribeCta => 'सब्सक्राइब करें';

  @override
  String get paywallMandateNote => 'पहला भुगतान: ऑटोपे मेंडेट सेट करने के लिए ₹3। उसके बाद चुनी योजना अपने आप रिन्यू होगी।';

  @override
  String paywallMandateAddon(int amount) {
    return 'आज ₹$amount मेंडेट सेटअप';
  }

  @override
  String get paywallPerWeek => 'प्रति सप्ताह';

  @override
  String get paywallPerMonth => 'प्रति महीना';

  @override
  String get paywallCancelAnytime => 'कभी भी रद्द करें';

  @override
  String get paywallNote => 'कथा, चमत्कार और लाइव दर्शन मुफ़्त रहेंगे।';

  @override
  String get lockedTitle => 'सदस्यता आवश्यक';

  @override
  String get lockedMessage => 'यह सुविधा मासिक सदस्यता से खुलती है।';

  @override
  String get unlockCta => 'योजना देखें';

  @override
  String get featureCalendar => 'कैलेंडर';

  @override
  String get featureAartiAlarms => 'आरती अलार्म';

  @override
  String get featureEvents => 'आयोजन';

  @override
  String get featureSingers => 'गायक';

  @override
  String get featureTempleStatus => 'मंदिर स्थिति';

  @override
  String get featureTravelGuides => 'यात्रा गाइड';

  @override
  String get featureBhajans => 'भजन';

  @override
  String get featurePosters => 'फोटो पोस्टर';

  @override
  String get featureWallpapers => 'वॉलपेपर';

  @override
  String get featureRingtones => 'रिंगटोन';

  @override
  String get featureCallerTunes => 'कॉलर ट्यून';

  @override
  String get premiumActive => 'सदस्यता सक्रिय';

  @override
  String get premiumInactive => 'मुफ़्त योजना';

  @override
  String get premiumActiveHint => 'सभी सेवाएँ खुली हैं';

  @override
  String get premiumInactiveHint => 'कैलेंडर, मीडिया और अधिक खोलें';

  @override
  String get posterHint => 'अपनी फोटो जोड़ें, नेम प्लेट संपादित करें, फिर शेयर करें।';

  @override
  String get posterEmpty => 'अभी कोई पोस्टर नहीं। जल्द वापस देखें।';

  @override
  String get posterAddPhoto => 'फोटो जोड़ें';

  @override
  String get posterChangePhoto => 'फोटो बदलें';

  @override
  String get posterAddPhotoFirst => 'पहले अपनी फोटो जोड़ें';

  @override
  String get posterShare => 'शेयर करें';

  @override
  String get posterShareWithPhoto => 'फोटो के साथ शेयर';

  @override
  String get posterShareWithoutPhoto => 'बिना फोटो शेयर';

  @override
  String get posterEditNamePlate => 'नेम प्लेट बदलें';

  @override
  String get posterNameHint => 'आपका नाम';

  @override
  String get posterSubtitleHint => 'नाम के नीचे की पंक्ति';

  @override
  String get posterSaveNamePlate => 'सेव करें';

  @override
  String get posterCropTitle => 'फोटो क्रॉप करें';

  @override
  String get posterRemovingBackground => 'बैकग्राउंड हटाया जा रहा है…';

  @override
  String get posterPreviewTitle => 'प्रीव्यू';

  @override
  String get posterUsePhoto => 'ठीक है';

  @override
  String get posterCancel => 'रद्द करें';

  @override
  String get useTemplate => 'चुनें';

  @override
  String get setWallpaper => 'सेट करें';

  @override
  String get setRingtone => 'सेट करें';

  @override
  String get activateTune => 'सक्रिय करें';

  @override
  String get comingSoon => 'जल्द आ रहा है';

  @override
  String get retry => 'फिर कोशिश करें';

  @override
  String get errorGeneric => 'कुछ गलत हो गया। कृपया पुनः प्रयास करें।';
}
