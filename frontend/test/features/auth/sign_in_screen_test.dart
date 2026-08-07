import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:khatushyam_app/core/config/app_config.dart';
import 'package:khatushyam_app/core/l10n/app_localizations.dart';
import 'package:khatushyam_app/core/theme/app_theme.dart';
import 'package:khatushyam_app/features/auth/data/fake_auth_service.dart';
import 'package:khatushyam_app/features/auth/domain/auth_user.dart';
import 'package:khatushyam_app/features/auth/presentation/auth_providers.dart';
import 'package:khatushyam_app/features/auth/presentation/sign_in_screen.dart';
import 'package:khatushyam_app/features/home/presentation/home_screen.dart';
import 'package:khatushyam_app/features/subscription/data/subscription_repository.dart';
import 'package:khatushyam_app/features/subscription/domain/subscription_state.dart';
import 'package:khatushyam_app/features/subscription/presentation/subscription_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  GoogleFonts.config.allowRuntimeFetching = false;

  Widget wrap(Widget child, {List<Override> overrides = const []}) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('hi'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        home: child,
      ),
    );
  }

  testWidgets('SignInScreen shows Hindi Google CTA', (tester) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(
      wrap(
        const SignInScreen(),
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              apiBaseUrl: 'http://localhost',
              firebaseConfigured: false,
            ),
          ),
          authServiceProvider.overrideWithValue(auth),
        ],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('खाटू श्याम बाबा'), findsOneWidget);
    expect(find.text('Google से साइन इन करें'), findsOneWidget);
    auth.dispose();
  });

  testWidgets('HomeScreen shows free and premium sections', (tester) async {
    final auth = FakeAuthService(
      initialUser: const AuthUser(uid: 'u1', displayName: 'भक्त'),
    );
    final repo = FakeSubscriptionRepository(
      initial: const SubscriptionState.free(),
    );

    await tester.pumpWidget(
      wrap(
        const HomeScreen(),
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(apiBaseUrl: 'http://localhost'),
          ),
          authServiceProvider.overrideWithValue(auth),
          subscriptionRepositoryProvider.overrideWithValue(repo),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.textContaining('जय श्याम'), findsWidgets);
    expect(find.text('त्वरित पहुँच'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('सभी के लिए मुफ़्त'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('सभी के लिए मुफ़्त'), findsOneWidget);
    auth.dispose();
  });
}
