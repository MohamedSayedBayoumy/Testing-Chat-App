import 'package:flutter/material.dart';

import 'routes/pages.dart';
import 'service/service_locator.dart';

Future<void> main() async {
  await DI.execute();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(title: 'Chat App', routerConfig: AppPages.router);
  }
}
