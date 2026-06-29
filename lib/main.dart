import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/storage/token_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
    ),
  );
  final tokenStorage = TokenStorage();
  final accessToken = await tokenStorage.readAccessToken();
  final refreshToken = await tokenStorage.readRefreshToken();
  final seenOnboarding = await tokenStorage.readOnboardingSeen();

  runApp(
    ProviderScope(
      overrides: [
        bootstrapTokensProvider.overrideWithValue(
          (accessToken: accessToken, refreshToken: refreshToken),
        ),
        bootstrapOnboardingSeenProvider.overrideWithValue(seenOnboarding),
      ],
      child: const VibeLinkApp(),
    ),
  );
}
