import 'package:equatable/equatable.dart';

import '../../../core/config/app_features.dart';

enum SubscriptionPlanId { weekly, monthly }

enum SubscriptionOfferPeriod { week, month }

class SubscriptionOffer extends Equatable {
  const SubscriptionOffer({
    required this.id,
    required this.priceInr,
    required this.period,
    this.mandateAddonInr,
  });

  final SubscriptionPlanId id;
  final int priceInr;
  final SubscriptionOfferPeriod period;
  /// ₹3 first-time Razorpay mandate setup (not the plan price).
  final int? mandateAddonInr;

  bool get hasMandateAddon =>
      mandateAddonInr != null && mandateAddonInr! > 0;

  factory SubscriptionOffer.fromJson(Map<String, dynamic> json) {
    final rawId = json['id'] as String? ?? 'monthly';
    final id =
        rawId == 'weekly'
            ? SubscriptionPlanId.weekly
            : SubscriptionPlanId.monthly;
    final period =
        (json['period'] as String?) == 'week'
            ? SubscriptionOfferPeriod.week
            : SubscriptionOfferPeriod.month;
    final addon =
        (json['mandateAddonInr'] as num?)?.toInt() ??
        (json['trialPriceInr'] as num?)?.toInt();
    return SubscriptionOffer(
      id: id,
      priceInr: (json['priceInr'] as num?)?.toInt() ?? 199,
      period: period,
      mandateAddonInr: addon,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id == SubscriptionPlanId.weekly ? 'weekly' : 'monthly',
    'priceInr': priceInr,
    'period': period == SubscriptionOfferPeriod.week ? 'week' : 'month',
    if (mandateAddonInr != null) 'mandateAddonInr': mandateAddonInr,
  };

  @override
  List<Object?> get props => [id, priceInr, period, mandateAddonInr];
}

const kDefaultOffersWithMandate = [
  SubscriptionOffer(
    id: SubscriptionPlanId.weekly,
    priceInr: 49,
    period: SubscriptionOfferPeriod.week,
    mandateAddonInr: 3,
  ),
  SubscriptionOffer(
    id: SubscriptionPlanId.monthly,
    priceInr: 199,
    period: SubscriptionOfferPeriod.month,
    mandateAddonInr: 3,
  ),
];

const kDefaultOffersReturning = [
  SubscriptionOffer(
    id: SubscriptionPlanId.weekly,
    priceInr: 49,
    period: SubscriptionOfferPeriod.week,
  ),
  SubscriptionOffer(
    id: SubscriptionPlanId.monthly,
    priceInr: 199,
    period: SubscriptionOfferPeriod.month,
  ),
];

/// Subscription / entitlement snapshot from the backend.
class SubscriptionState extends Equatable {
  const SubscriptionState({
    required this.isPremium,
    this.planId,
    this.expiresAt,
    this.source = SubscriptionSource.none,
    this.trialUsed = false,
    this.trialEligible = true,
    this.subscriptionStatus,
    this.offers = const [],
    this.checkoutSubscriptionId,
    this.checkoutKeyId,
  });

  const SubscriptionState.free()
    : this(
        isPremium: false,
        source: SubscriptionSource.none,
        trialUsed: false,
        trialEligible: true,
        offers: kDefaultOffersWithMandate,
      );

  final bool isPremium;
  final String? planId;
  final DateTime? expiresAt;
  final SubscriptionSource source;
  final bool trialUsed;
  final bool trialEligible;
  final String? subscriptionStatus;
  final List<SubscriptionOffer> offers;
  final String? checkoutSubscriptionId;
  final String? checkoutKeyId;

  bool canAccess(AppFeature feature) => feature.isFree || isPremium;

  List<SubscriptionOffer> get displayOffers {
    if (offers.isNotEmpty) return offers;
    return trialEligible ? kDefaultOffersWithMandate : kDefaultOffersReturning;
  }

  SubscriptionState copyWith({
    bool? isPremium,
    String? planId,
    DateTime? expiresAt,
    SubscriptionSource? source,
    bool? trialUsed,
    bool? trialEligible,
    String? subscriptionStatus,
    List<SubscriptionOffer>? offers,
    String? checkoutSubscriptionId,
    String? checkoutKeyId,
    bool clearCheckout = false,
  }) {
    return SubscriptionState(
      isPremium: isPremium ?? this.isPremium,
      planId: planId ?? this.planId,
      expiresAt: expiresAt ?? this.expiresAt,
      source: source ?? this.source,
      trialUsed: trialUsed ?? this.trialUsed,
      trialEligible: trialEligible ?? this.trialEligible,
      subscriptionStatus: subscriptionStatus ?? this.subscriptionStatus,
      offers: offers ?? this.offers,
      checkoutSubscriptionId:
          clearCheckout
              ? null
              : (checkoutSubscriptionId ?? this.checkoutSubscriptionId),
      checkoutKeyId:
          clearCheckout ? null : (checkoutKeyId ?? this.checkoutKeyId),
    );
  }

  factory SubscriptionState.fromJson(Map<String, dynamic> json) {
    final trialUsed = json['trialUsed'] as bool? ?? false;
    final trialEligible = json['trialEligible'] as bool? ?? !trialUsed;
    final rawOffers = json['offers'];
    final offers =
        rawOffers is List
            ? rawOffers
                .whereType<Map>()
                .map(
                  (e) => SubscriptionOffer.fromJson(
                    Map<String, dynamic>.from(e),
                  ),
                )
                .toList()
            : <SubscriptionOffer>[];

    return SubscriptionState(
      isPremium: json['isPremium'] as bool? ?? false,
      planId: json['planId'] as String?,
      expiresAt:
          json['expiresAt'] != null
              ? DateTime.tryParse(json['expiresAt'] as String)
              : null,
      source: SubscriptionSource.values.firstWhere(
        (s) => s.name == (json['source'] as String? ?? 'none'),
        orElse: () => SubscriptionSource.none,
      ),
      trialUsed: trialUsed,
      trialEligible: trialEligible,
      subscriptionStatus: json['subscriptionStatus'] as String?,
      offers: offers,
      checkoutSubscriptionId: json['subscriptionId'] as String?,
      checkoutKeyId: json['keyId'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'isPremium': isPremium,
    'planId': planId,
    'expiresAt': expiresAt?.toIso8601String(),
    'source': source.name,
    'trialUsed': trialUsed,
    'trialEligible': trialEligible,
    'subscriptionStatus': subscriptionStatus,
    'offers': offers.map((o) => o.toJson()).toList(),
    if (checkoutSubscriptionId != null)
      'subscriptionId': checkoutSubscriptionId,
    if (checkoutKeyId != null) 'keyId': checkoutKeyId,
  };

  @override
  List<Object?> get props => [
    isPremium,
    planId,
    expiresAt,
    source,
    trialUsed,
    trialEligible,
    subscriptionStatus,
    offers,
    checkoutSubscriptionId,
    checkoutKeyId,
  ];
}

enum SubscriptionSource { none, razorpay, manual, fake }
