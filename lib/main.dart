import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/ad_service.dart';
import 'core/app_theme.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Keep your existing Firebase init here:
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await AdService.init(); // loads a rewarded ad in the background
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const ZipApp());
}

class ZipApp extends StatelessWidget {
  const ZipApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppInfo.gameName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      // Phone-shaped column on Windows/web so it looks like the mobile design.
      builder: (context, child) => ColoredBox(
        color: Colors.black,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: child,
          ),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}