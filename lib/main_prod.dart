import 'package:flutter/material.dart';

import 'core/flavor/app_config.dart';
import 'routes/pages.dart';
import 'service/service_locator.dart';

Future<void> main() async {
  AppConfig.createProduction();
  await DI.execute();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: AppConfig.currentAppName,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(AppConfig.currentSeedColor),
        ),
      ),
      routerConfig: AppPages.router,
    );
  }
}
