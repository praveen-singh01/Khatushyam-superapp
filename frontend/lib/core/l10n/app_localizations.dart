import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_hi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('hi'),
    Locale('en')
  ];

  /// No description provided for @appName.
  ///
  /// In hi, this message translates to:
  /// **'खाटू श्याम बाबा'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In hi, this message translates to:
  /// **'शांत भक्ति, हर दिन'**
  String get appTagline;

  /// No description provided for @navHome.
  ///
  /// In hi, this message translates to:
  /// **'होम'**
  String get navHome;

  /// No description provided for @navStory.
  ///
  /// In hi, this message translates to:
  /// **'खोजें'**
  String get navStory;

  /// No description provided for @navChamatkar.
  ///
  /// In hi, this message translates to:
  /// **'समुदाय'**
  String get navChamatkar;

  /// No description provided for @navPosters.
  ///
  /// In hi, this message translates to:
  /// **'पोस्टर'**
  String get navPosters;

  /// No description provided for @navPremium.
  ///
  /// In hi, this message translates to:
  /// **'प्रोफ़ाइल'**
  String get navPremium;

  /// No description provided for @signInTitle.
  ///
  /// In hi, this message translates to:
  /// **'स्वागत है'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'जारी रखने के लिए Google से साइन इन करें'**
  String get signInSubtitle;

  /// No description provided for @signInWithGoogle.
  ///
  /// In hi, this message translates to:
  /// **'Google से साइन इन करें'**
  String get signInWithGoogle;

  /// No description provided for @signOut.
  ///
  /// In hi, this message translates to:
  /// **'साइन आउट'**
  String get signOut;

  /// No description provided for @profileEditName.
  ///
  /// In hi, this message translates to:
  /// **'नाम बदलें'**
  String get profileEditName;

  /// No description provided for @profileNameHint.
  ///
  /// In hi, this message translates to:
  /// **'आपका नाम'**
  String get profileNameHint;

  /// No description provided for @profileSave.
  ///
  /// In hi, this message translates to:
  /// **'सेव करें'**
  String get profileSave;

  /// No description provided for @profilePolicies.
  ///
  /// In hi, this message translates to:
  /// **'नीतियाँ'**
  String get profilePolicies;

  /// No description provided for @profileDaysRemaining.
  ///
  /// In hi, this message translates to:
  /// **'{days} दिन शेष'**
  String profileDaysRemaining(int days);

  /// No description provided for @homeGreeting.
  ///
  /// In hi, this message translates to:
  /// **'जय श्याम'**
  String get homeGreeting;

  /// No description provided for @homeFreeFeatures.
  ///
  /// In hi, this message translates to:
  /// **'सभी के लिए मुफ़्त'**
  String get homeFreeFeatures;

  /// No description provided for @homePremiumFeatures.
  ///
  /// In hi, this message translates to:
  /// **'सदस्यता के साथ'**
  String get homePremiumFeatures;

  /// No description provided for @storyTitle.
  ///
  /// In hi, this message translates to:
  /// **'श्याम कथा'**
  String get storyTitle;

  /// No description provided for @storySubtitle.
  ///
  /// In hi, this message translates to:
  /// **'सरल अध्याय — मुफ़्त'**
  String get storySubtitle;

  /// No description provided for @storyPlaceholder.
  ///
  /// In hi, this message translates to:
  /// **'कथा वीडियो जल्द यहाँ आएगा।'**
  String get storyPlaceholder;

  /// No description provided for @chamatkarTitle.
  ///
  /// In hi, this message translates to:
  /// **'चमत्कार'**
  String get chamatkarTitle;

  /// No description provided for @chamatkarSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'भक्तों के अनुभव — मुफ़्त'**
  String get chamatkarSubtitle;

  /// No description provided for @chamatkarPlaceholder.
  ///
  /// In hi, this message translates to:
  /// **'समुदाय फ़ीड जल्द यहाँ आएगा।'**
  String get chamatkarPlaceholder;

  /// No description provided for @chamatkarShareCta.
  ///
  /// In hi, this message translates to:
  /// **'अनुभव लिखें'**
  String get chamatkarShareCta;

  /// No description provided for @chamatkarTitleHint.
  ///
  /// In hi, this message translates to:
  /// **'शीर्षक'**
  String get chamatkarTitleHint;

  /// No description provided for @chamatkarStoryHint.
  ///
  /// In hi, this message translates to:
  /// **'अपना अनुभव लिखें...'**
  String get chamatkarStoryHint;

  /// No description provided for @chamatkarPublish.
  ///
  /// In hi, this message translates to:
  /// **'प्रकाशित करें'**
  String get chamatkarPublish;

  /// No description provided for @chamatkarEmpty.
  ///
  /// In hi, this message translates to:
  /// **'अभी कोई अनुभव नहीं। पहले आप लिखें।'**
  String get chamatkarEmpty;

  /// No description provided for @featureLiveDarshan.
  ///
  /// In hi, this message translates to:
  /// **'लाइव दर्शन'**
  String get featureLiveDarshan;

  /// No description provided for @liveDarshanSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'खाटू श्याम को YouTube पर लाइव देखें — मुफ़्त'**
  String get liveDarshanSubtitle;

  /// No description provided for @liveDarshanOfflineTitle.
  ///
  /// In hi, this message translates to:
  /// **'लाइव दर्शन अभी बंद है'**
  String get liveDarshanOfflineTitle;

  /// No description provided for @liveDarshanOfflineMessage.
  ///
  /// In hi, this message translates to:
  /// **'जब आरती शुरू होगी, बाबा का लाइव यहाँ दिखेगा।'**
  String get liveDarshanOfflineMessage;

  /// No description provided for @liveDarshanLiveBadge.
  ///
  /// In hi, this message translates to:
  /// **'अभी लाइव'**
  String get liveDarshanLiveBadge;

  /// No description provided for @liveDarshanOfflineBadge.
  ///
  /// In hi, this message translates to:
  /// **'अभी लाइव नहीं'**
  String get liveDarshanOfflineBadge;

  /// No description provided for @liveDarshanWatchCta.
  ///
  /// In hi, this message translates to:
  /// **'लाइव देखें'**
  String get liveDarshanWatchCta;

  /// No description provided for @paywallTitle.
  ///
  /// In hi, this message translates to:
  /// **'प्रीमियम सदस्यता'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'मासिक योजना से भक्ति सेवाएँ खोलें'**
  String get paywallSubtitle;

  /// No description provided for @paywallSubtitleTrial.
  ///
  /// In hi, this message translates to:
  /// **'साप्ताहिक या मासिक चुनें। ऑटोपे के लिए एक बार ₹3 लगेगा।'**
  String get paywallSubtitleTrial;

  /// No description provided for @paywallSubtitleReturn.
  ///
  /// In hi, this message translates to:
  /// **'प्रीमियम के लिए साप्ताहिक या मासिक योजना चुनें'**
  String get paywallSubtitleReturn;

  /// No description provided for @paywallCta.
  ///
  /// In hi, this message translates to:
  /// **'मासिक योजना शुरू करें'**
  String get paywallCta;

  /// No description provided for @paywallTrialTitle.
  ///
  /// In hi, this message translates to:
  /// **'परिचय ट्रायल'**
  String get paywallTrialTitle;

  /// No description provided for @paywallWeeklyTitle.
  ///
  /// In hi, this message translates to:
  /// **'साप्ताहिक'**
  String get paywallWeeklyTitle;

  /// No description provided for @paywallMonthlyTitle.
  ///
  /// In hi, this message translates to:
  /// **'मासिक'**
  String get paywallMonthlyTitle;

  /// No description provided for @paywallTrialDetail.
  ///
  /// In hi, this message translates to:
  /// **'फिर ₹{price}/महीना। कभी भी रद्द करें।'**
  String paywallTrialDetail(int price);

  /// No description provided for @paywallTrialCta.
  ///
  /// In hi, this message translates to:
  /// **'₹3 ट्रायल शुरू करें'**
  String get paywallTrialCta;

  /// No description provided for @paywallSubscribeCta.
  ///
  /// In hi, this message translates to:
  /// **'सब्सक्राइब करें'**
  String get paywallSubscribeCta;

  /// No description provided for @paywallMandateNote.
  ///
  /// In hi, this message translates to:
  /// **'पहला भुगतान: ऑटोपे मेंडेट सेट करने के लिए ₹3। उसके बाद चुनी योजना अपने आप रिन्यू होगी।'**
  String get paywallMandateNote;

  /// No description provided for @paywallMandateAddon.
  ///
  /// In hi, this message translates to:
  /// **'आज ₹{amount} मेंडेट सेटअप'**
  String paywallMandateAddon(int amount);

  /// No description provided for @paywallPerWeek.
  ///
  /// In hi, this message translates to:
  /// **'प्रति सप्ताह'**
  String get paywallPerWeek;

  /// No description provided for @paywallPerMonth.
  ///
  /// In hi, this message translates to:
  /// **'प्रति महीना'**
  String get paywallPerMonth;

  /// No description provided for @paywallCancelAnytime.
  ///
  /// In hi, this message translates to:
  /// **'कभी भी रद्द करें'**
  String get paywallCancelAnytime;

  /// No description provided for @paywallNote.
  ///
  /// In hi, this message translates to:
  /// **'कथा, चमत्कार और लाइव दर्शन मुफ़्त रहेंगे।'**
  String get paywallNote;

  /// No description provided for @lockedTitle.
  ///
  /// In hi, this message translates to:
  /// **'सदस्यता आवश्यक'**
  String get lockedTitle;

  /// No description provided for @lockedMessage.
  ///
  /// In hi, this message translates to:
  /// **'यह सुविधा मासिक सदस्यता से खुलती है।'**
  String get lockedMessage;

  /// No description provided for @unlockCta.
  ///
  /// In hi, this message translates to:
  /// **'योजना देखें'**
  String get unlockCta;

  /// No description provided for @featureCalendar.
  ///
  /// In hi, this message translates to:
  /// **'कैलेंडर'**
  String get featureCalendar;

  /// No description provided for @featureAartiAlarms.
  ///
  /// In hi, this message translates to:
  /// **'आरती अलार्म'**
  String get featureAartiAlarms;

  /// No description provided for @featureEvents.
  ///
  /// In hi, this message translates to:
  /// **'आयोजन'**
  String get featureEvents;

  /// No description provided for @featureSingers.
  ///
  /// In hi, this message translates to:
  /// **'गायक'**
  String get featureSingers;

  /// No description provided for @featureTempleStatus.
  ///
  /// In hi, this message translates to:
  /// **'मंदिर स्थिति'**
  String get featureTempleStatus;

  /// No description provided for @featureTravelGuides.
  ///
  /// In hi, this message translates to:
  /// **'यात्रा गाइड'**
  String get featureTravelGuides;

  /// No description provided for @featureBhajans.
  ///
  /// In hi, this message translates to:
  /// **'भजन'**
  String get featureBhajans;

  /// No description provided for @featurePosters.
  ///
  /// In hi, this message translates to:
  /// **'फोटो पोस्टर'**
  String get featurePosters;

  /// No description provided for @featureWallpapers.
  ///
  /// In hi, this message translates to:
  /// **'वॉलपेपर'**
  String get featureWallpapers;

  /// No description provided for @featureRingtones.
  ///
  /// In hi, this message translates to:
  /// **'रिंगटोन'**
  String get featureRingtones;

  /// No description provided for @featureCallerTunes.
  ///
  /// In hi, this message translates to:
  /// **'कॉलर ट्यून'**
  String get featureCallerTunes;

  /// No description provided for @premiumActive.
  ///
  /// In hi, this message translates to:
  /// **'सदस्यता सक्रिय'**
  String get premiumActive;

  /// No description provided for @premiumInactive.
  ///
  /// In hi, this message translates to:
  /// **'मुफ़्त योजना'**
  String get premiumInactive;

  /// No description provided for @premiumActiveHint.
  ///
  /// In hi, this message translates to:
  /// **'सभी सेवाएँ खुली हैं'**
  String get premiumActiveHint;

  /// No description provided for @premiumInactiveHint.
  ///
  /// In hi, this message translates to:
  /// **'कैलेंडर, मीडिया और अधिक खोलें'**
  String get premiumInactiveHint;

  /// No description provided for @posterHint.
  ///
  /// In hi, this message translates to:
  /// **'अपनी फोटो जोड़ें, नेम प्लेट संपादित करें, फिर शेयर करें।'**
  String get posterHint;

  /// No description provided for @posterEmpty.
  ///
  /// In hi, this message translates to:
  /// **'अभी कोई पोस्टर नहीं। जल्द वापस देखें।'**
  String get posterEmpty;

  /// No description provided for @posterAddPhoto.
  ///
  /// In hi, this message translates to:
  /// **'फोटो जोड़ें'**
  String get posterAddPhoto;

  /// No description provided for @posterChangePhoto.
  ///
  /// In hi, this message translates to:
  /// **'फोटो बदलें'**
  String get posterChangePhoto;

  /// No description provided for @posterAddPhotoFirst.
  ///
  /// In hi, this message translates to:
  /// **'पहले अपनी फोटो जोड़ें'**
  String get posterAddPhotoFirst;

  /// No description provided for @posterShare.
  ///
  /// In hi, this message translates to:
  /// **'शेयर करें'**
  String get posterShare;

  /// No description provided for @posterShareWithPhoto.
  ///
  /// In hi, this message translates to:
  /// **'फोटो के साथ शेयर'**
  String get posterShareWithPhoto;

  /// No description provided for @posterShareWithoutPhoto.
  ///
  /// In hi, this message translates to:
  /// **'बिना फोटो शेयर'**
  String get posterShareWithoutPhoto;

  /// No description provided for @posterEditNamePlate.
  ///
  /// In hi, this message translates to:
  /// **'नेम प्लेट बदलें'**
  String get posterEditNamePlate;

  /// No description provided for @posterNameHint.
  ///
  /// In hi, this message translates to:
  /// **'आपका नाम'**
  String get posterNameHint;

  /// No description provided for @posterSubtitleHint.
  ///
  /// In hi, this message translates to:
  /// **'नाम के नीचे की पंक्ति'**
  String get posterSubtitleHint;

  /// No description provided for @posterSaveNamePlate.
  ///
  /// In hi, this message translates to:
  /// **'सेव करें'**
  String get posterSaveNamePlate;

  /// No description provided for @posterCropTitle.
  ///
  /// In hi, this message translates to:
  /// **'फोटो क्रॉप करें'**
  String get posterCropTitle;

  /// No description provided for @posterRemovingBackground.
  ///
  /// In hi, this message translates to:
  /// **'बैकग्राउंड हटाया जा रहा है…'**
  String get posterRemovingBackground;

  /// No description provided for @posterPreviewTitle.
  ///
  /// In hi, this message translates to:
  /// **'प्रीव्यू'**
  String get posterPreviewTitle;

  /// No description provided for @posterUsePhoto.
  ///
  /// In hi, this message translates to:
  /// **'ठीक है'**
  String get posterUsePhoto;

  /// No description provided for @posterCancel.
  ///
  /// In hi, this message translates to:
  /// **'रद्द करें'**
  String get posterCancel;

  /// No description provided for @useTemplate.
  ///
  /// In hi, this message translates to:
  /// **'चुनें'**
  String get useTemplate;

  /// No description provided for @setWallpaper.
  ///
  /// In hi, this message translates to:
  /// **'सेट करें'**
  String get setWallpaper;

  /// No description provided for @setRingtone.
  ///
  /// In hi, this message translates to:
  /// **'सेट करें'**
  String get setRingtone;

  /// No description provided for @activateTune.
  ///
  /// In hi, this message translates to:
  /// **'सक्रिय करें'**
  String get activateTune;

  /// No description provided for @comingSoon.
  ///
  /// In hi, this message translates to:
  /// **'जल्द आ रहा है'**
  String get comingSoon;

  /// No description provided for @retry.
  ///
  /// In hi, this message translates to:
  /// **'फिर कोशिश करें'**
  String get retry;

  /// No description provided for @errorGeneric.
  ///
  /// In hi, this message translates to:
  /// **'कुछ गलत हो गया। कृपया पुनः प्रयास करें।'**
  String get errorGeneric;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'hi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'hi': return AppLocalizationsHi();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
