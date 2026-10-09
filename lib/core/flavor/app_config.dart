/// Represents the available application build flavors.
enum AppFlavor { development, production }

/// Holds all flavor-specific configuration values.
///
/// Initialise once via [AppConfig.createDevelopment] or
/// [AppConfig.createProduction] in the corresponding main entry point,
/// then access anywhere in the app through [AppConfig.instance].
class AppConfig {
  AppConfig._({
    required this.flavor,
    required this.appName,
    required this.apiKey,
    required this.baseUrl,
    required this.seedColor,
  });

  /// The active build flavor.
  final AppFlavor flavor;

  /// Human-readable display name of the app.
  final String appName;

  /// Gemini API key for this flavor.
  final String apiKey;

  /// Gemini API base URL for this flavor.
  final String baseUrl;

  /// Primary seed color used for the Material theme (ARGB int).
  final int seedColor;

  // ---------------------------------------------------------------------------
  // Singleton access
  // ---------------------------------------------------------------------------

  static AppConfig? _instance;

  /// The active [AppConfig]. Throws if [create] has not been called yet.
  static AppConfig get instance {
    assert(
      _instance != null,
      'AppConfig must be initialised before accessing AppConfig.instance.',
    );
    return _instance!;
  }

  /// Convenience static getters delegating to [instance].
  static AppFlavor get currentFlavor => instance.flavor;
  static String get currentAppName => instance.appName;
  static String get currentApiKey => instance.apiKey;
  static String get currentBaseUrl => instance.baseUrl;
  static int get currentSeedColor => instance.seedColor;
  static bool get isDevelopment => instance.flavor == AppFlavor.development;
  static bool get isProduction => instance.flavor == AppFlavor.production;

  // ---------------------------------------------------------------------------
  // Factory constructors
  // ---------------------------------------------------------------------------

  /// Creates and stores the [AppConfig] for the **development** flavor.
  static AppConfig createDevelopment() {
    return _instance = AppConfig._(
      flavor: AppFlavor.development,
      appName: 'Chat Dev',
      // API key is injected at build time via --dart-define=GEMINI_API_KEY_DEV=<value>
      // Never hardcode production keys in source code.
      apiKey: const String.fromEnvironment(
        'GEMINI_API_KEY_DEV',
        defaultValue: 'YOUR_DEV_API_KEY_HERE',
      ),
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/models/',
      seedColor: 0xFF1565C0, // Deep Blue accent for dev builds
    );
  }

  /// Creates and stores the [AppConfig] for the **production** flavor.
  static AppConfig createProduction() {
    return _instance = AppConfig._(
      flavor: AppFlavor.production,
      appName: 'Chat',
      // API key is injected at build time via --dart-define=GEMINI_API_KEY_PROD=<value>
      apiKey: const String.fromEnvironment(
        'GEMINI_API_KEY_PROD',
        defaultValue: 'YOUR_PROD_API_KEY_HERE',
      ),
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/models/',
      seedColor: 0xFF0D47A1, // Standard Blue for production builds
    );
  }

  @override
  String toString() =>
      'AppConfig(flavor: $flavor, appName: $appName, baseUrl: $baseUrl)';
}
