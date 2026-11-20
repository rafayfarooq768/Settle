import 'package:firebase_core/firebase_core.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/ui/profile_providers.dart';
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
import 'l10n/l10n_delegates.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: SettleApp()));
}

class SettleApp extends ConsumerWidget {
  const SettleApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(ensureProfileProvider);
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Settle',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: appLocalizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
