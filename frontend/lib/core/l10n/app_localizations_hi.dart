// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appName => 'Khatu Shyam Baba';

  @override
  String get appTagline => 'Shaant bhakti, har din';

  @override
  String get navHome => 'Home';

  @override
  String get navStory => 'Khojein';

  @override
  String get navChamatkar => 'Samuday';

  @override
  String get navPosters => 'Poster';

  @override
  String get navPremium => 'Profile';

  @override
  String get signInTitle => 'Swagat hai';

  @override
  String get signInSubtitle => 'Aage badhne ke liye Google se sign in karein';

  @override
  String get signInWithGoogle => 'Google se sign in karein';

  @override
  String get signOut => 'Sign out';

  @override
  String get profileEditName => 'Naam badlein';

  @override
  String get profileNameHint => 'Aapka naam';

  @override
  String get profileSave => 'Save karein';

  @override
  String get profilePolicies => 'Neetiyan';

  @override
  String profileDaysRemaining(int days) {
    return '$days din shesh';
  }

  @override
  String get homeGreeting => 'Jai Shyam';

  @override
  String get homeFreeFeatures => 'Sabhi ke liye muft';

  @override
  String get homePremiumFeatures => 'Sadasyata ke saath';

  @override
  String get storyTitle => 'Shyam Katha';

  @override
  String get storySubtitle => 'Saral adhyay — muft';

  @override
  String get storyPlaceholder => 'Katha video jald yahan aayega.';

  @override
  String get chamatkarTitle => 'Chamatkar';

  @override
  String get chamatkarSubtitle => 'Bhakton ke anubhav — muft';

  @override
  String get chamatkarPlaceholder => 'Samuday feed jald yahan aayega.';

  @override
  String get chamatkarShareCta => 'Anubhav likhein';

  @override
  String get chamatkarTitleHint => 'Shirshak';

  @override
  String get chamatkarStoryHint => 'Apna anubhav likhein...';

  @override
  String get chamatkarPublish => 'Prakashit karein';

  @override
  String get chamatkarEmpty => 'Abhi koi anubhav nahi. Pehle aap likhein.';

  @override
  String get featureLiveDarshan => 'Live Darshan';

  @override
  String get liveDarshanSubtitle => 'Khatu Shyam ko YouTube par live dekhein — muft';

  @override
  String get liveDarshanOfflineTitle => 'Live Darshan abhi band hai';

  @override
  String get liveDarshanOfflineMessage => 'Jab aarti shuru hogi, Baba ka live yahan dikhega.';

  @override
  String get liveDarshanLiveBadge => 'Abhi live';

  @override
  String get liveDarshanOfflineBadge => 'Abhi live nahi';

  @override
  String get liveDarshanWatchCta => 'Live dekhein';

  @override
  String get paywallTitle => 'Premium sadasyata';

  @override
  String get paywallSubtitle => 'Masik yojana se bhakti sevayein kholen';

  @override
  String get paywallSubtitleTrial => '₹3 trial se shuru karein, phir ₹199/mahina. Kabhi bhi radd karein.';

  @override
  String get paywallSubtitleReturn => 'Premium ke liye saptahik ya masik yojana chunein';

  @override
  String get paywallCta => 'Masik yojana shuru karein';

  @override
  String get paywallTrialTitle => 'Parichay trial';

  @override
  String get paywallWeeklyTitle => 'Saptahik';

  @override
  String get paywallMonthlyTitle => 'Masik';

  @override
  String paywallTrialDetail(int price) {
    return 'Phir ₹$price/mahina. Kabhi bhi radd karein.';
  }

  @override
  String get paywallTrialCta => '₹3 trial shuru karein';

  @override
  String get paywallSubscribeCta => 'Subscribe karein';

  @override
  String get paywallMandateNote => 'Pehla bhugtan: autopay mandate set karne ke liye ₹3. Uske baad chuni yojana apne aap renew hogi.';

  @override
  String paywallMandateAddon(int amount) {
    return 'Aaj ₹$amount mandate setup';
  }

  @override
  String get paywallPerWeek => 'prati saptah';

  @override
  String get paywallPerMonth => 'prati mahina';

  @override
  String get paywallCancelAnytime => 'Kabhi bhi radd karein';

  @override
  String get paywallNote => 'Katha, Chamatkar aur Live Darshan muft rahenge.';

  @override
  String get lockedTitle => 'Sadasyata zaroori';

  @override
  String get lockedMessage => 'Yeh suvidha masik sadasyata se khulti hai.';

  @override
  String get unlockCta => 'Yojana dekhein';

  @override
  String get featureCalendar => 'Calendar';

  @override
  String get featureAartiAlarms => 'Alarm';

  @override
  String get featureEvents => 'Aayojan';

  @override
  String get featureTravelGuides => 'Yatra guide';

  @override
  String get featureBhajans => 'Bhajan';

  @override
  String get featurePosters => 'Photo poster';

  @override
  String get featureWallpapers => 'Wallpaper';

  @override
  String get featureRingtones => 'Ringtone';

  @override
  String get featureCallerTunes => 'Caller tune';

  @override
  String get premiumActive => 'Sadasyata sakriya';

  @override
  String get premiumInactive => 'Muft yojana';

  @override
  String get premiumActiveHint => 'Saari sevayein khuli hain';

  @override
  String get premiumInactiveHint => 'Calendar, media aur zyada kholen';

  @override
  String get posterHint => 'Apni photo jodein, name plate badlein, phir share karein.';

  @override
  String get posterEmpty => 'Abhi koi poster nahi. Jald wapas dekhein.';

  @override
  String get posterAddPhoto => 'Photo jodein';

  @override
  String get posterChangePhoto => 'Photo badlein';

  @override
  String get posterAddPhotoFirst => 'Pehle apni photo jodein';

  @override
  String get posterShare => 'Share karein';

  @override
  String get posterShareWithPhoto => 'Photo ke saath share';

  @override
  String get posterShareWithoutPhoto => 'Bina photo share';

  @override
  String get posterEditNamePlate => 'Name plate badlein';

  @override
  String get posterNameHint => 'Aapka naam';

  @override
  String get posterSubtitleHint => 'Naam ke neeche ki pankti';

  @override
  String get posterSaveNamePlate => 'Save karein';

  @override
  String get posterCropTitle => 'Photo crop karein';

  @override
  String get posterRemovingBackground => 'Background hataya ja raha hai…';

  @override
  String get posterPreviewTitle => 'Preview';

  @override
  String get posterUsePhoto => 'Theek hai';

  @override
  String get posterCancel => 'Radd karein';

  @override
  String get useTemplate => 'Chunein';

  @override
  String get setWallpaper => 'Set karein';

  @override
  String get setRingtone => 'Set karein';

  @override
  String get activateTune => 'Sakriya karein';

  @override
  String get comingSoon => 'Jald aa raha hai';

  @override
  String get retry => 'Phir koshish karein';

  @override
  String get errorGeneric => 'Kuch galat ho gaya. Kripya phir koshish karein.';
}
