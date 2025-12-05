class EnvConfig {
  static const String environment = String.fromEnvironment(
    'ENV',
    defaultValue: 'dev',
  );

  static bool get isDev => environment == 'dev';
  static bool get isStaging => environment == 'staging';
  static bool get isProd => environment == 'prod';

  // Firebase project IDs for different environments
  static String get firebaseProjectId {
    switch (environment) {
      case 'prod':
        return 'cafe-app-prod';
      case 'staging':
        return 'cafe-app-staging';
      default:
        return 'cafe-app-dev';
    }
  }

  // API URLs
  static String get baseUrl {
    switch (environment) {
      case 'prod':
        return 'https://api.cafeapp.com';
      case 'staging':
        return 'https://staging-api.cafeapp.com';
      default:
        return 'https://dev-api.cafeapp.com';
    }
  }

  // Razorpay Keys (use environment-specific keys in production)
  static String get razorpayKeyId {
    switch (environment) {
      case 'prod':
        return 'YOUR_PROD_RAZORPAY_KEY';
      case 'staging':
        return 'YOUR_STAGING_RAZORPAY_KEY';
      default:
        return 'YOUR_DEV_RAZORPAY_KEY';
    }
  }

  static String get razorpayKeySecret {
    switch (environment) {
      case 'prod':
        return 'YOUR_PROD_RAZORPAY_SECRET';
      case 'staging':
        return 'YOUR_STAGING_RAZORPAY_SECRET';
      default:
        return 'YOUR_DEV_RAZORPAY_SECRET';
    }
  }

  // Feature Flags
  static bool get enableAnalytics => isProd;
  static bool get enableCrashReporting => isProd || isStaging;
  static bool get showDebugBanner => isDev;
}
