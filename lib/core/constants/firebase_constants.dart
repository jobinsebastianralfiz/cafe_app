class FirebaseConstants {
  FirebaseConstants._();

  // Collection Names
  static const String usersCollection = 'users';
  static const String menuCollection = 'menu';
  static const String categoriesCollection = 'categories';
  static const String itemsCollection = 'items';
  static const String ordersCollection = 'orders';
  static const String venueCollection = 'venue';
  static const String tablesCollection = 'tables';
  static const String reservationsCollection = 'reservations';
  static const String feedbackCollection = 'feedback';
  static const String movieNightCollection = 'movieNight';
  static const String dailySpecialsCollection = 'dailySpecials';
  static const String saturdayGamesCollection = 'saturdayGames';
  static const String venueStatusCollection = 'venueStatus';
  static const String eventsCollection = 'events';
  static const String notificationsCollection = 'notifications';
  static const String coinsCollection = 'coinTransactions';

  // Subcollection Names
  static const String suggestionsSubcollection = 'suggestions';
  static const String votingPeriodsSubcollection = 'votingPeriods';
  static const String userVotesSubcollection = 'userVotes';
  static const String gameSchedulesSubcollection = 'gameSchedules';
  static const String gameParticipationsSubcollection = 'gameParticipations';
  static const String leaderboardsSubcollection = 'leaderboards';

  // Storage Paths
  static const String userProfilePhotos = 'user_profiles';
  static const String menuItemPhotos = 'menu_items';
  static const String dailySpecialPhotos = 'daily_specials';
  static const String eventPhotos = 'events';
  static const String gamePhotos = 'game_photos';
  static const String feedbackPhotos = 'feedback_photos';

  // User Fields
  static const String userEmail = 'email';
  static const String userName = 'name';
  static const String userPhone = 'phone';
  static const String userProfilePhoto = 'profilePhoto';
  static const String userAddresses = 'addresses';
  static const String userCoinBalance = 'coinBalance';
  static const String userLoyaltyTier = 'loyaltyTier';
  static const String userRole = 'role';
  static const String userCreatedAt = 'createdAt';
  static const String userLastActive = 'lastActive';

  // Order Fields
  static const String orderNumber = 'orderNumber';
  static const String orderUserId = 'userId';
  static const String orderItems = 'items';
  static const String orderPricing = 'pricing';
  static const String orderStatus = 'status';
  static const String orderType = 'orderType';
  static const String orderDeliveryAddress = 'deliveryAddress';
  static const String orderPayment = 'payment';
  static const String orderTimestamps = 'timestamps';

  // Menu Item Fields
  static const String itemName = 'name';
  static const String itemDescription = 'description';
  static const String itemPrice = 'price';
  static const String itemCategoryId = 'categoryId';
  static const String itemPhotos = 'photos';
  static const String itemIsAvailable = 'isAvailable';
  static const String itemIsVeg = 'isVeg';
  static const String itemTags = 'tags';
  static const String itemAverageRating = 'averageRating';
  static const String itemCreatedAt = 'createdAt';

  // Firestore Operators
  static const String whereEqualTo = '==';
  static const String whereNotEqualTo = '!=';
  static const String whereGreaterThan = '>';
  static const String whereGreaterThanOrEqualTo = '>=';
  static const String whereLessThan = '<';
  static const String whereLessThanOrEqualTo = '<=';
  static const String whereArrayContains = 'array-contains';
  static const String whereArrayContainsAny = 'array-contains-any';
  static const String whereIn = 'in';
  static const String whereNotIn = 'not-in';

  // Order By
  static const String orderByAsc = 'asc';
  static const String orderByDesc = 'desc';
}
