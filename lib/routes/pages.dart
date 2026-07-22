import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/chat/chat_screen.dart';
import '../features/splash_screen.dart';
import 'paths.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final myObserver = MyRouteObserver();

class MyRouteObserver extends NavigatorObserver {
  final List<String> visited = [];

  @override
  void didPush(Route route, Route? previousRoute) {
    final name = route.settings.name;
    if (name != null && !visited.contains(name)) {
      visited.add(name);
    }
    super.didPush(route, previousRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    final name = route.settings.name;
    if (name != null && visited.contains(name)) {
      visited.remove(name);
    }
    super.didPop(route, previousRoute);
  }
}

class AppPages {
  static final router = GoRouter(
    navigatorKey: navigatorKey,
    initialLocation: AppPaths.initial,
    observers: [myObserver],
    routes: [
      GoRoute(
        path: AppPaths.initial,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppPaths.chat,
        builder: (context, state) => const ChatScreen(),
      ),
    ],
  );
}
