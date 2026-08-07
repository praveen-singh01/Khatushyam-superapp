import 'package:equatable/equatable.dart';

import '../../../core/config/app_features.dart';

/// Subscription / entitlement snapshot from the backend.
class SubscriptionState extends Equatable {
  const SubscriptionState({
    required this.isPremium,
    this.planId,
    this.expiresAt,
    this.source = SubscriptionSource.none,
  });

  const SubscriptionState.free()
    : this(isPremium: false, source: SubscriptionSource.none);

  final bool isPremium;
  final String? planId;
  final DateTime? expiresAt;
  final SubscriptionSource source;

  bool canAccess(AppFeature feature) => feature.isFree || isPremium;

  SubscriptionState copyWith({
    bool? isPremium,
    String? planId,
    DateTime? expiresAt,
    SubscriptionSource? source,
  }) {
    return SubscriptionState(
      isPremium: isPremium ?? this.isPremium,
      planId: planId ?? this.planId,
      expiresAt: expiresAt ?? this.expiresAt,
      source: source ?? this.source,
    );
  }

  factory SubscriptionState.fromJson(Map<String, dynamic> json) {
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
    );
  }

  Map<String, dynamic> toJson() => {
    'isPremium': isPremium,
    'planId': planId,
    'expiresAt': expiresAt?.toIso8601String(),
    'source': source.name,
  };

  @override
  List<Object?> get props => [isPremium, planId, expiresAt, source];
}

enum SubscriptionSource { none, razorpay, manual, fake }
