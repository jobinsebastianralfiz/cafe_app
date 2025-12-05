class AppConfig {
  static const String appName = 'Cafe App';
  static const String appVersion = '1.0.0';

  // Pagination
  static const int pageSize = 20;
  static const int maxPageSize = 100;

  // Cache Duration
  static const Duration shortCacheDuration = Duration(minutes: 5);
  static const Duration mediumCacheDuration = Duration(minutes: 30);
  static const Duration longCacheDuration = Duration(hours: 24);

  // Timeouts
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration uploadTimeout = Duration(minutes: 5);

  // Image Upload
  static const int maxImageSizeMB = 5;
  static const int imageQuality = 80;
  static const int maxImagesPerUpload = 5;

  // Payment Gateway (Razorpay)
  // TODO: Replace with your actual Razorpay key in production
  static const String razorpayKeyId = 'rzp_test_1DP5mmOlF5G5ag'; // Test key - replace with actual key
  static const String razorpayKeySecret = 'YOUR_KEY_SECRET'; // Keep this on backend only

  // Order Settings
  static const int minOrderAmount = 50;
  static const double deliveryCharges = 30.0;
  static const double freeDeliveryThreshold = 300.0;
  static const double gstPercentage = 5.0;

  // Coins & Loyalty
  static const int coinsPerRupee = 1; // Earn 1 coin per rupee spent
  static const int coinValue = 1; // 1 coin = ₹1
  static const int maxCoinsPerOrder = 500; // Max coins that can be used
  static const int minOrderForCoins = 100; // Min order to earn coins
  static const int referralBonus = 100; // Coins for referral
  static const int signupBonus = 50; // Welcome bonus

  // Reservation Settings
  static const int minReservationAdvance = 30; // minutes
  static const int maxReservationAdvance = 30; // days
  static const int reservationSlotDuration = 30; // minutes
  static const int maxPartySize = 12;

  // Movie Night Settings
  static const int maxMovieSuggestionsPerUser = 3;
  static const int minMoviesForVoting = 3;
  static const int maxMoviesForVoting = 10;

  // Games Settings
  static const int minPlayersPerGame = 2;
  static const int maxPlayersPerGame = 50;

  // Feedback Settings
  static const int maxBiteRating = 10;
  static const int feedbackCoinReward = 20;

  // Animation Durations
  static const Duration shortAnimationDuration = Duration(milliseconds: 200);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Shimmer Settings
  static const Duration shimmerDuration = Duration(milliseconds: 1500);

  // Debounce Durations
  static const Duration searchDebounce = Duration(milliseconds: 500);
  static const Duration buttonDebounce = Duration(milliseconds: 300);

  // Support
  static const String supportEmail = 'support@cafeapp.com';
  static const String supportPhone = '+91-1234567890';

  // Social Links
  static const String instagramUrl = 'https://instagram.com/cafeapp';
  static const String facebookUrl = 'https://facebook.com/cafeapp';
  static const String twitterUrl = 'https://twitter.com/cafeapp';
}
