import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'firebase_options.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(ProviderScope(child: MyApp()));
}


class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _router = ref.watch(appRouterProvider);

   return MaterialApp.router(
  debugShowCheckedModeBanner: false,
  routerConfig: _router,
  theme: ThemeData(
    fontFamily: 'LeagueSpartan',
    textTheme: const TextTheme(
      bodyLarge: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.normal),
      bodyMedium: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.normal),
      headlineLarge: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.bold),
      headlineMedium: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.bold),
      headlineSmall: TextStyle(fontFamily: 'LeagueSpartan', fontWeight: FontWeight.bold),
    ),
    colorScheme: ColorScheme.fromSeed(seedColor: Colors.lightBlueAccent),
    useMaterial3: true,
  ),
);
  }
}
