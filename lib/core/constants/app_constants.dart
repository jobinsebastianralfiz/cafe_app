class AppConstants {
  AppConstants._();

  // Asset Paths
  static const String imagePath = 'assets/images/';
  static const String iconPath = 'assets/icons/';
  static const String lottiePath = 'assets/lottie/';

  // Lottie Animations
  static const String loadingAnimation = '${lottiePath}loading.json';
  static const String successAnimation = '${lottiePath}success.json';
  static const String errorAnimation = '${lottiePath}error.json';
  static const String emptyCartAnimation = '${lottiePath}empty_cart.json';
  static const String celebrationAnimation = '${lottiePath}celebration.json';

  // Images
  static const String logoImage = '${imagePath}logo.png';
  static const String placeholderImage = '${imagePath}placeholder.png';
  static const String emptyStateImage = '${imagePath}empty_state.png';

  // Order Status
  static const String orderStatusPlaced = 'placed';
  static const String orderStatusConfirmed = 'confirmed';
  static const String orderStatusPreparing = 'preparing';
  static const String orderStatusOutForDelivery = 'out_for_delivery';
  static const String orderStatusDelivered = 'delivered';
  static const String orderStatusCancelled = 'cancelled';

  // Order Types
  static const String orderTypeDelivery = 'delivery';
  static const String orderTypeDineIn = 'dine-in';
  static const String orderTypeTakeaway = 'takeaway';

  // Payment Methods
  static const String paymentCash = 'cash';
  static const String paymentUPI = 'upi';
  static const String paymentCard = 'card';
  static const String paymentWallet = 'wallet';

  // Payment Status
  static const String paymentPending = 'pending';
  static const String paymentCompleted = 'completed';
  static const String paymentFailed = 'failed';
  static const String paymentRefunded = 'refunded';

  // User Roles
  static const String roleCustomer = 'customer';
  static const String roleStaff = 'staff';
  static const String roleWaiter = 'waiter';
  static const String roleKitchen = 'kitchen';
  static const String roleDelivery = 'delivery';
  static const String roleAdmin = 'admin';

  // Loyalty Tiers
  static const String tierBronze = 'bronze';
  static const String tierSilver = 'silver';
  static const String tierGold = 'gold';
  static const String tierPlatinum = 'platinum';

  // Reservation Status
  static const String reservationPending = 'pending';
  static const String reservationConfirmed = 'confirmed';
  static const String reservationSeated = 'seated';
  static const String reservationCompleted = 'completed';
  static const String reservationCancelled = 'cancelled';
  static const String reservationNoShow = 'no_show';

  // Movie Night Status
  static const String movieStatusPending = 'pending';
  static const String movieStatusApproved = 'approved';
  static const String movieStatusRejected = 'rejected';
  static const String movieStatusWinner = 'winner';

  // Event Types
  static const String eventTypeCelebrity = 'celebrity';
  static const String eventTypeSpecialNight = 'special_night';
  static const String eventTypeLiveMusic = 'live_music';
  static const String eventTypeThemeNight = 'theme_night';

  // Notification Types
  static const String notificationOrder = 'order';
  static const String notificationReservation = 'reservation';
  static const String notificationPromo = 'promo';
  static const String notificationEvent = 'event';
  static const String notificationMovieNight = 'movie_night';
  static const String notificationGame = 'game';
  static const String notificationCoin = 'coin';

  // Date Formats
  static const String dateFormatFull = 'dd MMM yyyy, hh:mm a';
  static const String dateFormatShort = 'dd MMM yyyy';
  static const String dateFormatTime = 'hh:mm a';
  static const String dateFormatISO = 'yyyy-MM-dd';

  // Regular Expressions
  static final RegExp emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp phoneRegex = RegExp(
    r'^[6-9]\d{9}$', // Indian phone number
  );

  static final RegExp nameRegex = RegExp(
    r'^[a-zA-Z ]+$',
  );

  // Error Messages
  static const String errorGeneric = 'Something went wrong. Please try again.';
  static const String errorNetwork = 'No internet connection. Please check your network.';
  static const String errorServer = 'Server error. Please try again later.';
  static const String errorAuth = 'Authentication failed. Please login again.';
  static const String errorPermission = 'Permission denied. Please enable required permissions.';

  // Success Messages
  static const String successOrderPlaced = 'Order placed successfully!';
  static const String successReservationMade = 'Reservation confirmed!';
  static const String successFeedbackSubmitted = 'Thank you for your feedback!';
  static const String successProfileUpdated = 'Profile updated successfully!';

  // Shared Preferences Keys
  static const String keyUserData = 'user_data';
  static const String keyAuthToken = 'auth_token';
  static const String keyCartData = 'cart_data';
  static const String keyIsFirstTime = 'is_first_time';
  static const String keyThemeMode = 'theme_mode';
  static const String keyLanguage = 'language';

  // Fun Order ID Prefixes (Dragon Ball Z Characters)
  static const List<String> orderIdPrefixes = [
    'Goku',
    'Vegeta',
    'Gohan',
    'Piccolo',
    'Trunks',
    'Frieza',
    'Cell',
    'Buu',
    'Krillin',
    'Yamcha',
    'Tien',
    'Bulma',
    'Videl',
    'Android18',
    'Broly',
  ];

  // Days of Week
  static const List<String> weekDays = [
    'monday',
    'tuesday',
    'wednesday',
    'thursday',
    'friday',
    'saturday',
    'sunday',
  ];
}
