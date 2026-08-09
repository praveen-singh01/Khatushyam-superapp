import 'package:equatable/equatable.dart';

class LegalPolicy extends Equatable {
  const LegalPolicy({required this.title, required this.body});

  final String title;
  final String body;

  factory LegalPolicy.fromJson(Map<String, dynamic> json) => LegalPolicy(
    title: json['title'] as String? ?? '',
    body: json['body'] as String? ?? '',
  );

  @override
  List<Object?> get props => [title, body];
}

class LegalPolicies extends Equatable {
  const LegalPolicies({
    required this.privacyPolicy,
    required this.deleteAccountPolicy,
    required this.cancellationRefundPolicy,
  });

  final LegalPolicy privacyPolicy;
  final LegalPolicy deleteAccountPolicy;
  final LegalPolicy cancellationRefundPolicy;

  factory LegalPolicies.fromJson(Map<String, dynamic> json) => LegalPolicies(
    privacyPolicy: LegalPolicy.fromJson(
      Map<String, dynamic>.from(json['privacyPolicy'] as Map? ?? const {}),
    ),
    deleteAccountPolicy: LegalPolicy.fromJson(
      Map<String, dynamic>.from(
        json['deleteAccountPolicy'] as Map? ?? const {},
      ),
    ),
    cancellationRefundPolicy: LegalPolicy.fromJson(
      Map<String, dynamic>.from(
        json['cancellationRefundPolicy'] as Map? ?? const {},
      ),
    ),
  );

  @override
  List<Object?> get props => [
    privacyPolicy,
    deleteAccountPolicy,
    cancellationRefundPolicy,
  ];
}
