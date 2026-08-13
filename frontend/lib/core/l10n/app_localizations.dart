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
  /// **'Khatu Shyam Baba'**
  String get appName;

  /// No description provided for @appTagline.
  ///
  /// In hi, this message translates to:
  /// **'Shaant bhakti, har din'**
  String get appTagline;

  /// No description provided for @navHome.
  ///
  /// In hi, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navStory.
  ///
  /// In hi, this message translates to:
  /// **'Khojein'**
  String get navStory;

  /// No description provided for @navChamatkar.
  ///
  /// In hi, this message translates to:
  /// **'Samuday'**
  String get navChamatkar;

  /// No description provided for @navPosters.
  ///
  /// In hi, this message translates to:
  /// **'Poster'**
  String get navPosters;

  /// No description provided for @navPremium.
  ///
  /// In hi, this message translates to:
  /// **'Profile'**
  String get navPremium;

  /// No description provided for @signInTitle.
  ///
  /// In hi, this message translates to:
  /// **'Swagat hai'**
  String get signInTitle;

  /// No description provided for @signInSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'Aage badhne ke liye Google se sign in karein'**
  String get signInSubtitle;

  /// No description provided for @signInWithGoogle.
  ///
  /// In hi, this message translates to:
  /// **'Google se sign in karein'**
  String get signInWithGoogle;

  /// No description provided for @signOut.
  ///
  /// In hi, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @profileEditName.
  ///
  /// In hi, this message translates to:
  /// **'Naam badlein'**
  String get profileEditName;

  /// No description provided for @profileNameHint.
  ///
  /// In hi, this message translates to:
  /// **'Aapka naam'**
  String get profileNameHint;

  /// No description provided for @profileSave.
  ///
  /// In hi, this message translates to:
  /// **'Save karein'**
  String get profileSave;

  /// No description provided for @profilePolicies.
  ///
  /// In hi, this message translates to:
  /// **'Neetiyan'**
  String get profilePolicies;

  /// No description provided for @profileDaysRemaining.
  ///
  /// In hi, this message translates to:
  /// **'{days} din shesh'**
  String profileDaysRemaining(int days);

  /// No description provided for @homeGreeting.
  ///
  /// In hi, this message translates to:
  /// **'Jai Shyam'**
  String get homeGreeting;

  /// No description provided for @homeFreeFeatures.
  ///
  /// In hi, this message translates to:
  /// **'Sabhi ke liye muft'**
  String get homeFreeFeatures;

  /// No description provided for @homePremiumFeatures.
  ///
  /// In hi, this message translates to:
  /// **'Sadasyata ke saath'**
  String get homePremiumFeatures;

  /// No description provided for @storyTitle.
  ///
  /// In hi, this message translates to:
  /// **'Shyam Katha'**
  String get storyTitle;

  /// No description provided for @storySubtitle.
  ///
  /// In hi, this message translates to:
  /// **'Saral adhyay — muft'**
  String get storySubtitle;

  /// No description provided for @storyPlaceholder.
  ///
  /// In hi, this message translates to:
  /// **'Katha video jald yahan aayega.'**
  String get storyPlaceholder;

  /// No description provided for @chamatkarTitle.
  ///
  /// In hi, this message translates to:
  /// **'Chamatkar'**
  String get chamatkarTitle;

  /// No description provided for @chamatkarSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'Bhakton ke anubhav — muft'**
  String get chamatkarSubtitle;

  /// No description provided for @chamatkarPlaceholder.
  ///
  /// In hi, this message translates to:
  /// **'Samuday feed jald yahan aayega.'**
  String get chamatkarPlaceholder;

  /// No description provided for @chamatkarShareCta.
  ///
  /// In hi, this message translates to:
  /// **'Anubhav likhein'**
  String get chamatkarShareCta;

  /// No description provided for @chamatkarTitleHint.
  ///
  /// In hi, this message translates to:
  /// **'Shirshak'**
  String get chamatkarTitleHint;

  /// No description provided for @chamatkarStoryHint.
  ///
  /// In hi, this message translates to:
  /// **'Apna anubhav likhein...'**
  String get chamatkarStoryHint;

  /// No description provided for @chamatkarPublish.
  ///
  /// In hi, this message translates to:
  /// **'Prakashit karein'**
  String get chamatkarPublish;

  /// No description provided for @chamatkarEmpty.
  ///
  /// In hi, this message translates to:
  /// **'Abhi koi anubhav nahi. Pehle aap likhein.'**
  String get chamatkarEmpty;

  /// No description provided for @featureLiveDarshan.
  ///
  /// In hi, this message translates to:
  /// **'Live Darshan'**
  String get featureLiveDarshan;

  /// No description provided for @liveDarshanSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'Khatu Shyam ko YouTube par live dekhein — muft'**
  String get liveDarshanSubtitle;

  /// No description provided for @liveDarshanOfflineTitle.
  ///
  /// In hi, this message translates to:
  /// **'Live Darshan abhi band hai'**
  String get liveDarshanOfflineTitle;

  /// No description provided for @liveDarshanOfflineMessage.
  ///
  /// In hi, this message translates to:
  /// **'Jab aarti shuru hogi, Baba ka live yahan dikhega.'**
  String get liveDarshanOfflineMessage;

  /// No description provided for @liveDarshanLiveBadge.
  ///
  /// In hi, this message translates to:
  /// **'Abhi live'**
  String get liveDarshanLiveBadge;

  /// No description provided for @liveDarshanOfflineBadge.
  ///
  /// In hi, this message translates to:
  /// **'Abhi live nahi'**
  String get liveDarshanOfflineBadge;

  /// No description provided for @liveDarshanWatchCta.
  ///
  /// In hi, this message translates to:
  /// **'Live dekhein'**
  String get liveDarshanWatchCta;

  /// No description provided for @paywallTitle.
  ///
  /// In hi, this message translates to:
  /// **'Premium sadasyata'**
  String get paywallTitle;

  /// No description provided for @paywallSubtitle.
  ///
  /// In hi, this message translates to:
  /// **'Masik yojana se bhakti sevayein kholen'**
  String get paywallSubtitle;

  /// No description provided for @paywallSubtitleTrial.
  ///
  /// In hi, this message translates to:
  /// **'₹3 trial se shuru karein, phir ₹199/mahina. Kabhi bhi radd karein.'**
  String get paywallSubtitleTrial;

  /// No description provided for @paywallSubtitleReturn.
  ///
  /// In hi, this message translates to:
  /// **'Premium ke liye saptahik ya masik yojana chunein'**
  String get paywallSubtitleReturn;

  /// No description provided for @paywallCta.
  ///
  /// In hi, this message translates to:
  /// **'Masik yojana shuru karein'**
  String get paywallCta;

  /// No description provided for @paywallTrialTitle.
  ///
  /// In hi, this message translates to:
  /// **'Parichay trial'**
  String get paywallTrialTitle;

  /// No description provided for @paywallWeeklyTitle.
  ///
  /// In hi, this message translates to:
  /// **'Saptahik'**
  String get paywallWeeklyTitle;

  /// No description provided for @paywallMonthlyTitle.
  ///
  /// In hi, this message translates to:
  /// **'Masik'**
  String get paywallMonthlyTitle;

  /// No description provided for @paywallTrialDetail.
  ///
  /// In hi, this message translates to:
  /// **'Phir ₹{price}/mahina. Kabhi bhi radd karein.'**
  String paywallTrialDetail(int price);

  /// No description provided for @paywallTrialCta.
  ///
  /// In hi, this message translates to:
  /// **'₹3 trial shuru karein'**
  String get paywallTrialCta;

  /// No description provided for @paywallSubscribeCta.
  ///
  /// In hi, this message translates to:
  /// **'Subscribe karein'**
  String get paywallSubscribeCta;

  /// No description provided for @paywallMandateNote.
  ///
  /// In hi, this message translates to:
  /// **'Pehla bhugtan: autopay mandate set karne ke liye ₹3. Uske baad chuni yojana apne aap renew hogi.'**
  String get paywallMandateNote;

  /// No description provided for @paywallMandateAddon.
  ///
  /// In hi, this message translates to:
  /// **'Aaj ₹{amount} mandate setup'**
  String paywallMandateAddon(int amount);

  /// No description provided for @paywallPerWeek.
  ///
  /// In hi, this message translates to:
  /// **'prati saptah'**
  String get paywallPerWeek;

  /// No description provided for @paywallPerMonth.
  ///
  /// In hi, this message translates to:
  /// **'prati mahina'**
  String get paywallPerMonth;

  /// No description provided for @paywallCancelAnytime.
  ///
  /// In hi, this message translates to:
  /// **'Kabhi bhi radd karein'**
  String get paywallCancelAnytime;

  /// No description provided for @paywallNote.
  ///
  /// In hi, this message translates to:
  /// **'Katha, Chamatkar aur Live Darshan muft rahenge.'**
  String get paywallNote;

  /// No description provided for @lockedTitle.
  ///
  /// In hi, this message translates to:
  /// **'Sadasyata zaroori'**
  String get lockedTitle;

  /// No description provided for @lockedMessage.
  ///
  /// In hi, this message translates to:
  /// **'Yeh suvidha masik sadasyata se khulti hai.'**
  String get lockedMessage;

  /// No description provided for @unlockCta.
  ///
  /// In hi, this message translates to:
  /// **'Yojana dekhein'**
  String get unlockCta;

  /// No description provided for @featureCalendar.
  ///
  /// In hi, this message translates to:
  /// **'Calendar'**
  String get featureCalendar;

  /// No description provided for @featureAartiAlarms.
  ///
  /// In hi, this message translates to:
  /// **'Alarm'**
  String get featureAartiAlarms;

  /// No description provided for @featureEvents.
  ///
  /// In hi, this message translates to:
  /// **'Aayojan'**
  String get featureEvents;

  /// No description provided for @featureTravelGuides.
  ///
  /// In hi, this message translates to:
  /// **'Yatra guide'**
  String get featureTravelGuides;

  /// No description provided for @featureBhajans.
  ///
  /// In hi, this message translates to:
  /// **'Bhajan'**
  String get featureBhajans;

  /// No description provided for @featurePosters.
  ///
  /// In hi, this message translates to:
  /// **'Photo poster'**
  String get featurePosters;

  /// No description provided for @featureWallpapers.
  ///
  /// In hi, this message translates to:
  /// **'Wallpaper'**
  String get featureWallpapers;

  /// No description provided for @featureRingtones.
  ///
  /// In hi, this message translates to:
  /// **'Ringtone'**
  String get featureRingtones;

  /// No description provided for @featureCallerTunes.
  ///
  /// In hi, this message translates to:
  /// **'Caller tune'**
  String get featureCallerTunes;

  /// No description provided for @premiumActive.
  ///
  /// In hi, this message translates to:
  /// **'Sadasyata sakriya'**
  String get premiumActive;

  /// No description provided for @premiumInactive.
  ///
  /// In hi, this message translates to:
  /// **'Muft yojana'**
  String get premiumInactive;

  /// No description provided for @premiumActiveHint.
  ///
  /// In hi, this message translates to:
  /// **'Saari sevayein khuli hain'**
  String get premiumActiveHint;

  /// No description provided for @premiumInactiveHint.
  ///
  /// In hi, this message translates to:
  /// **'Calendar, media aur zyada kholen'**
  String get premiumInactiveHint;

  /// No description provided for @posterHint.
  ///
  /// In hi, this message translates to:
  /// **'Apni photo jodein, name plate badlein, phir share karein.'**
  String get posterHint;

  /// No description provided for @posterEmpty.
  ///
  /// In hi, this message translates to:
  /// **'Abhi koi poster nahi. Jald wapas dekhein.'**
  String get posterEmpty;

  /// No description provided for @posterAddPhoto.
  ///
  /// In hi, this message translates to:
  /// **'Photo jodein'**
  String get posterAddPhoto;

  /// No description provided for @posterChangePhoto.
  ///
  /// In hi, this message translates to:
  /// **'Photo badlein'**
  String get posterChangePhoto;

  /// No description provided for @posterAddPhotoFirst.
  ///
  /// In hi, this message translates to:
  /// **'Pehle apni photo jodein'**
  String get posterAddPhotoFirst;

  /// No description provided for @posterShare.
  ///
  /// In hi, this message translates to:
  /// **'Share karein'**
  String get posterShare;

  /// No description provided for @posterShareWithPhoto.
  ///
  /// In hi, this message translates to:
  /// **'Photo ke saath share'**
  String get posterShareWithPhoto;

  /// No description provided for @posterShareWithoutPhoto.
  ///
  /// In hi, this message translates to:
  /// **'Bina photo share'**
  String get posterShareWithoutPhoto;

  /// No description provided for @posterEditNamePlate.
  ///
  /// In hi, this message translates to:
  /// **'Name plate badlein'**
  String get posterEditNamePlate;

  /// No description provided for @posterNameHint.
  ///
  /// In hi, this message translates to:
  /// **'Aapka naam'**
  String get posterNameHint;

  /// No description provided for @posterSubtitleHint.
  ///
  /// In hi, this message translates to:
  /// **'Naam ke neeche ki pankti'**
  String get posterSubtitleHint;

  /// No description provided for @posterSaveNamePlate.
  ///
  /// In hi, this message translates to:
  /// **'Save karein'**
  String get posterSaveNamePlate;

  /// No description provided for @posterCropTitle.
  ///
  /// In hi, this message translates to:
  /// **'Photo crop karein'**
  String get posterCropTitle;

  /// No description provided for @posterRemovingBackground.
  ///
  /// In hi, this message translates to:
  /// **'Background hataya ja raha hai…'**
  String get posterRemovingBackground;

  /// No description provided for @posterPreviewTitle.
  ///
  /// In hi, this message translates to:
  /// **'Preview'**
  String get posterPreviewTitle;

  /// No description provided for @posterUsePhoto.
  ///
  /// In hi, this message translates to:
  /// **'Theek hai'**
  String get posterUsePhoto;

  /// No description provided for @posterCancel.
  ///
  /// In hi, this message translates to:
  /// **'Radd karein'**
  String get posterCancel;

  /// No description provided for @useTemplate.
  ///
  /// In hi, this message translates to:
  /// **'Chunein'**
  String get useTemplate;

  /// No description provided for @setWallpaper.
  ///
  /// In hi, this message translates to:
  /// **'Set karein'**
  String get setWallpaper;

  /// No description provided for @setRingtone.
  ///
  /// In hi, this message translates to:
  /// **'Set karein'**
  String get setRingtone;

  /// No description provided for @activateTune.
  ///
  /// In hi, this message translates to:
  /// **'Sakriya karein'**
  String get activateTune;

  /// No description provided for @comingSoon.
  ///
  /// In hi, this message translates to:
  /// **'Jald aa raha hai'**
  String get comingSoon;

  /// No description provided for @retry.
  ///
  /// In hi, this message translates to:
  /// **'Phir koshish karein'**
  String get retry;

  /// No description provided for @errorGeneric.
  ///
  /// In hi, this message translates to:
  /// **'Kuch galat ho gaya. Kripya phir koshish karein.'**
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
