# Cafe App - Claude Code Implementation Plan

## Project Information
- **Project Name**: Cafe App
- **Tech Stack**: Flutter + Firebase
- **Architecture**: MVVM (Model-View-ViewModel)
- **State Management**: Riverpod 2.x
- **Target Platforms**: Android & iOS

---

## MVVM Architecture Overview

This project uses **MVVM (Model-View-ViewModel)** architecture pattern with Riverpod for state management.

### Structure:
- **Models**: Data classes representing entities (User, MenuItem, Order, etc.) with Firestore serialization
- **Services**: Handle all Firebase/API operations and business logic
- **ViewModels**: Manage UI state using Riverpod StateNotifier, expose data streams and actions to Views
- **Views**: UI components (Screens and Widgets) that display data and handle user interactions

### Data Flow:
```
User Action → View → ViewModel → Service → Firebase
                ↑                              ↓
            State Update ← ViewModel ← Firestore Stream
```

### Benefits:
- **Simple**: Easier to understand than Clean Architecture
- **Less boilerplate**: No separate entities, use cases, or data sources
- **Testable**: ViewModels and Services can be easily unit tested
- **Reactive**: Riverpod providers automatically update UI when data changes

---

## Table of Contents
1. [Project Setup](#1-project-setup)
2. [Folder Structure](#2-folder-structure)
3. [Firebase Setup](#3-firebase-setup)
4. [Database Models](#4-database-models)
5. [Implementation Phases](#5-implementation-phases)
6. [Detailed Feature Implementation](#6-detailed-feature-implementation)
7. [Testing Strategy](#7-testing-strategy)

---

## 1. Project Setup

### 1.1 Create Flutter Project
```bash
flutter create cafe_app
cd cafe_app
```

### 1.2 Add Dependencies (pubspec.yaml)
```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # State Management
  flutter_riverpod: ^2.4.9
  
  # Firebase
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  firebase_storage: ^11.5.6
  cloud_firestore: ^4.13.6
  cloud_functions: ^4.5.12
  
  # UI Components
  google_fonts: ^6.1.0
  flutter_svg: ^2.0.9
  cached_network_image: ^3.3.0
  shimmer: ^3.0.0
  
  # Navigation
  go_router: ^12.1.3
  
  # Local Storage
  hive: ^2.2.3
  hive_flutter: ^1.1.0
  shared_preferences: ^2.2.2
  
  # Utils
  intl: ^0.18.1
  uuid: ^4.2.2
  qr_code_scanner: ^1.0.1
  qr_flutter: ^4.1.0
  
  # Maps (choose one)
  google_maps_flutter: ^2.5.0
  # OR
  flutter_map: ^6.1.0  # Free alternative
  
  # Payment
  razorpay_flutter: ^1.3.6
  
  # Image Handling
  image_picker: ^1.0.5
  flutter_image_compress: ^2.1.0
  
  # Animations
  lottie: ^2.7.0
  
  # Permissions
  permission_handler: ^11.1.0
  
  # URL Launcher
  url_launcher: ^6.2.2

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  
  # Code Generation
  build_runner: ^2.4.7
  hive_generator: ^2.0.1
  
  # Testing
  mockito: ^5.4.4
  fake_cloud_firestore: ^2.4.6
```

### 1.3 Environment Configuration

Create `lib/core/config/env_config.dart`:
```dart
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
}
```

---

## 2. Folder Structure

```
cafe_app/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   │
│   ├── core/
│   │   ├── config/
│   │   │   ├── env_config.dart
│   │   │   ├── app_config.dart
│   │   │   └── firebase_config.dart
│   │   │
│   │   ├── constants/
│   │   │   ├── app_constants.dart
│   │   │   └── firebase_constants.dart
│   │   │
│   │   ├── theme/
│   │   │   ├── app_theme.dart
│   │   │   ├── app_colors.dart
│   │   │   └── app_text_styles.dart
│   │   │
│   │   ├── services/
│   │   │   ├── firebase_service.dart
│   │   │   └── storage_service.dart
│   │   │
│   │   └── utils/
│   │       ├── date_utils.dart
│   │       ├── validators.dart
│   │       ├── string_utils.dart
│   │       └── order_id_generator.dart
│   │
│   ├── features/
│   │   │
│   │   ├── auth/
│   │   │   ├── models/
│   │   │   │   ├── user_model.dart
│   │   │   │   └── address_model.dart
│   │   │   │
│   │   │   ├── services/
│   │   │   │   └── auth_service.dart
│   │   │   │
│   │   │   ├── viewmodels/
│   │   │   │   ├── auth_viewmodel.dart
│   │   │   │   └── user_viewmodel.dart
│   │   │   │
│   │   │   ├── views/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── splash_screen.dart
│   │   │   │   │   ├── login_screen.dart
│   │   │   │   │   └── signup_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── auth_text_field.dart
│   │   │   │       └── auth_button.dart
│   │   │
│   │   ├── menu/
│   │   │   ├── models/
│   │   │   │   ├── menu_item_model.dart
│   │   │   │   ├── category_model.dart
│   │   │   │   └── cart_item_model.dart
│   │   │   │
│   │   │   ├── services/
│   │   │   │   └── menu_service.dart
│   │   │   │
│   │   │   ├── viewmodels/
│   │   │   │   ├── menu_viewmodel.dart
│   │   │   │   ├── category_viewmodel.dart
│   │   │   │   └── cart_viewmodel.dart
│   │   │   │
│   │   │   ├── views/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── menu_screen.dart
│   │   │   │   │   ├── item_detail_screen.dart
│   │   │   │   │   └── cart_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── menu_item_card.dart
│   │   │   │       ├── category_chip.dart
│   │   │   │       └── cart_item_widget.dart
│   │   │
│   │   ├── orders/
│   │   │   ├── models/
│   │   │   │   ├── order_model.dart
│   │   │   │   ├── order_item_model.dart
│   │   │   │   └── order_pricing_model.dart
│   │   │   │
│   │   │   ├── services/
│   │   │   │   └── order_service.dart
│   │   │   │
│   │   │   ├── viewmodels/
│   │   │   │   ├── orders_viewmodel.dart
│   │   │   │   ├── checkout_viewmodel.dart
│   │   │   │   └── order_tracking_viewmodel.dart
│   │   │   │
│   │   │   ├── views/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── checkout_screen.dart
│   │   │   │   │   ├── order_confirmation_screen.dart
│   │   │   │   │   ├── order_tracking_screen.dart
│   │   │   │   │   └── order_history_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── order_card.dart
│   │   │   │       ├── order_status_stepper.dart
│   │   │   │       └── tracking_map_widget.dart
│   │   │
│   │   ├── reservations/
│   │   │   ├── models/
│   │   │   │   ├── table_model.dart
│   │   │   │   └── reservation_model.dart
│   │   │   │
│   │   │   ├── services/
│   │   │   │   └── reservation_service.dart
│   │   │   │
│   │   │   ├── viewmodels/
│   │   │   │   ├── reservation_viewmodel.dart
│   │   │   │   └── table_viewmodel.dart
│   │   │   │
│   │   │   ├── views/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── reservation_screen.dart
│   │   │   │   │   ├── table_selection_screen.dart
│   │   │   │   │   └── qr_scanner_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── table_card.dart
│   │   │   │       ├── time_slot_selector.dart
│   │   │   │       └── reservation_card.dart
│   │   │
│   │   ├── feedback/
│   │   │   ├── models/
│   │   │   │   └── feedback_model.dart
│   │   │   │
│   │   │   ├── services/
│   │   │   │   └── feedback_service.dart
│   │   │   │
│   │   │   ├── viewmodels/
│   │   │   │   └── feedback_viewmodel.dart
│   │   │   │
│   │   │   ├── views/
│   │   │   │   ├── screens/
│   │   │   │   │   └── feedback_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── dish_rating_widget.dart
│   │   │   │       └── bite_rating_widget.dart
│   │   │
│   │   ├── movie_night/
│   │   │   ├── models/
│   │   │   │   ├── movie_suggestion_model.dart
│   │   │   │   └── voting_period_model.dart
│   │   │   │
│   │   │   ├── services/
│   │   │   │   └── movie_night_service.dart
│   │   │   │
│   │   │   ├── viewmodels/
│   │   │   │   ├── movie_suggestions_viewmodel.dart
│   │   │   │   └── voting_viewmodel.dart
│   │   │   │
│   │   │   ├── views/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── movie_night_screen.dart
│   │   │   │   │   ├── suggest_movie_screen.dart
│   │   │   │   │   └── voting_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── movie_card.dart
│   │   │   │       ├── voting_card.dart
│   │   │   │       └── wall_of_reels_widget.dart
│   │   │
│   │   ├── daily_specials/
│   │   │   ├── models/
│   │   │   │   └── daily_special_model.dart
│   │   │   │
│   │   │   ├── services/
│   │   │   │   └── daily_special_service.dart
│   │   │   │
│   │   │   ├── viewmodels/
│   │   │   │   └── daily_special_viewmodel.dart
│   │   │   │
│   │   │   ├── views/
│   │   │   │   ├── screens/
│   │   │   │   │   └── daily_special_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       └── special_item_card.dart
│   │   │
│   │   ├── games/
│   │   │   ├── models/
│   │   │   │   ├── game_schedule_model.dart
│   │   │   │   └── game_participation_model.dart
│   │   │   │
│   │   │   ├── services/
│   │   │   │   └── game_service.dart
│   │   │   │
│   │   │   ├── viewmodels/
│   │   │   │   ├── game_schedule_viewmodel.dart
│   │   │   │   └── participation_viewmodel.dart
│   │   │   │
│   │   │   ├── views/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── saturday_games_screen.dart
│   │   │   │   │   ├── game_registration_screen.dart
│   │   │   │   │   └── leaderboard_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── game_card.dart
│   │   │   │       └── leaderboard_item.dart
│   │   │
│   │   ├── events/
│   │   │   ├── models/
│   │   │   │   └── event_model.dart
│   │   │   │
│   │   │   ├── services/
│   │   │   │   └── event_service.dart
│   │   │   │
│   │   │   ├── viewmodels/
│   │   │   │   └── events_viewmodel.dart
│   │   │   │
│   │   │   ├── views/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── events_screen.dart
│   │   │   │   │   └── event_detail_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       └── event_card.dart
│   │   │
│   │   ├── venue/
│   │   │   ├── models/
│   │   │   │   └── venue_status_model.dart
│   │   │   │
│   │   │   ├── services/
│   │   │   │   └── venue_service.dart
│   │   │   │
│   │   │   ├── viewmodels/
│   │   │   │   └── venue_status_viewmodel.dart
│   │   │   │
│   │   │   └── views/
│   │   │       └── widgets/
│   │   │           └── venue_status_card.dart
│   │   │
│   │   ├── coins/
│   │   │   ├── models/
│   │   │   │   └── coin_transaction_model.dart
│   │   │   │
│   │   │   ├── services/
│   │   │   │   └── coin_service.dart
│   │   │   │
│   │   │   ├── viewmodels/
│   │   │   │   ├── coin_balance_viewmodel.dart
│   │   │   │   └── transaction_history_viewmodel.dart
│   │   │   │
│   │   │   ├── views/
│   │   │   │   ├── screens/
│   │   │   │   │   ├── coin_wallet_screen.dart
│   │   │   │   │   └── coin_transfer_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       ├── coin_balance_card.dart
│   │   │   │       └── transaction_item.dart
│   │   │
│   │   ├── notifications/
│   │   │   ├── models/
│   │   │   │   └── notification_model.dart
│   │   │   │
│   │   │   ├── services/
│   │   │   │   └── notification_service.dart
│   │   │   │
│   │   │   ├── viewmodels/
│   │   │   │   └── notifications_viewmodel.dart
│   │   │   │
│   │   │   ├── views/
│   │   │   │   ├── screens/
│   │   │   │   │   └── notifications_screen.dart
│   │   │   │   └── widgets/
│   │   │   │       └── notification_item.dart
│   │   │
│   │   ├── home/
│   │   │   ├── viewmodels/
│   │   │   │   └── home_viewmodel.dart
│   │   │   │
│   │   │   └── views/
│   │   │       ├── screens/
│   │   │       │   └── home_screen.dart
│   │   │       └── widgets/
│   │   │           ├── quick_action_card.dart
│   │   │           └── featured_section.dart
│   │   │
│   │   └── profile/
│   │       ├── viewmodels/
│   │       │   └── profile_viewmodel.dart
│   │       │
│   │       └── views/
│   │           ├── screens/
│   │           │   ├── profile_screen.dart
│   │           │   └── edit_profile_screen.dart
│   │           └── widgets/
│   │               └── profile_info_card.dart
│   │
│   ├── shared/
│   │   ├── widgets/
│   │   │   ├── custom_button.dart
│   │   │   ├── custom_text_field.dart
│   │   │   ├── loading_indicator.dart
│   │   │   ├── error_widget.dart
│   │   │   ├── empty_state_widget.dart
│   │   │   ├── shimmer_loading.dart
│   │   │   └── custom_app_bar.dart
│   │   │
│   │   └── providers/
│   │       └── connectivity_provider.dart
│   │
│   └── routes/
│       ├── app_router.dart
│       └── route_guards.dart
│
├── test/
│   ├── features/
│   ├── core/
│   └── shared/
│
├── assets/
│   ├── images/
│   ├── icons/
│   ├── lottie/
│   └── fonts/
│
└── firebase/
    ├── firestore.rules
    ├── storage.rules
    └── functions/
```

---

## 3. Firebase Setup

### 3.1 Firestore Database Structure

```javascript
// Collections Structure

users/
  {userId}/
    - email: string
    - name: string
    - phone: string
    - profilePhoto: string?
    - addresses: array<map>
      - id: string
      - label: string (Home/Work/Other)
      - addressLine1: string
      - addressLine2: string?
      - city: string
      - state: string
      - pincode: string
      - landmark: string?
      - isDefault: boolean
    - coinBalance: number (default: 0)
    - loyaltyTier: string (bronze/silver/gold/platinum)
    - role: string (customer/staff/waiter/admin)
    - createdAt: timestamp
    - lastActive: timestamp

menu/
  categories/
    {categoryId}/
      - name: string
      - description: string?
      - imageUrl: string?
      - order: number
      - isActive: boolean
      - createdAt: timestamp
      
  items/
    {itemId}/
      - name: string
      - description: string
      - price: number
      - categoryId: string
      - photos: array<string>
      - isAvailable: boolean
      - isVeg: boolean
      - tags: array<string> (vegan, spicy, gluten-free, etc)
      - calories: number?
      - ingredients: array<string>
      - averageRating: number
      - totalRatings: number
      - preparationTime: number (minutes)
      - createdAt: timestamp
      - updatedAt: timestamp

orders/
  {orderId}/
    - orderNumber: string (e.g., #Goku947)
    - userId: string
    - userName: string
    - userPhone: string
    - userEmail: string
    
    - items: array<map>
      - itemId: string
      - itemName: string
      - quantity: number
      - price: number
      - subtotal: number
    
    - pricing:
      - subtotal: number
      - deliveryCharges: number
      - taxAmount: number
      - coinDiscount: number
      - totalAmount: number
      - finalAmount: number
    
    - deliveryAddress: map
      - addressLine1: string
      - addressLine2: string?
      - city: string
      - pincode: string
      - landmark: string?
      - latitude: number?
      - longitude: number?
    
    - specialNotes: string?
    - orderType: string (delivery/dine-in)
    - tableId: string? (if dine-in)
    
    - status: string (placed, confirmed, preparing, out_for_delivery, delivered, cancelled)
    - statusHistory: array<map>
      - status: string
      - timestamp: timestamp
      - note: string?
    
    - payment:
      - method: string (cash/upi/card)
      - status: string (pending/completed/failed)
      - transactionId: string?
      - paidAt: timestamp?
    
    - assignedRiderId: string?
    - riderName: string?
    - riderPhone: string?
    
    - coinsUsed: number
    - coinsEarned: number
    
    - timestamps:
      - placedAt: timestamp
      - confirmedAt: timestamp?
      - preparingAt: timestamp?
      - outForDeliveryAt: timestamp?
      - deliveredAt: timestamp?
      - cancelledAt: timestamp?
    
    - estimatedDeliveryTime: timestamp?
    - actualDeliveryTime: timestamp?

tables/
  {tableId}/
    - tableNumber: string
    - capacity: number
    - location: string (window/corner/center)
    - floor: number
    - isActive: boolean
    - isOccupied: boolean
    - currentReservationId: string?
    - qrCode: string (URL)

reservations/
  {reservationId}/
    - userId: string
    - userName: string
    - userPhone: string
    - tableId: string
    - tableNumber: string
    - date: string (YYYY-MM-DD)
    - timeSlot: string (HH:mm)
    - partySize: number
    - specialRequests: string?
    - status: string (pending, confirmed, seated, completed, cancelled, no_show)
    - createdAt: timestamp
    - confirmedAt: timestamp?
    - cancelledAt: timestamp?
    - cancellationReason: string?

feedback/
  {feedbackId}/
    - orderId: string
    - orderNumber: string
    - userId: string
    - userName: string
    
    - dishRatings: array<map>
      - itemId: string
      - itemName: string
      - rating: number (1-10 bites)
    
    - overallRating: number (1-5)
    - serviceRating: number? (1-5)
    - ambienceRating: number? (1-5)
    - generalFeedback: string?
    
    - createdAt: timestamp

movieNight/
  suggestions/
    {suggestionId}/
      - movieName: string
      - movieYear: number?
      - genre: string?
      - suggestedBy: string (userId)
      - userName: string
      - suggestedAt: timestamp
      - weekIdentifier: string (YYYY-Www)
      - status: string (pending, approved, rejected, winner)
      - rejectionReason: string?
      - votes: number
      - approvedAt: timestamp?
      
  votingPeriods/
    {weekId}/ (format: YYYY-Www)
      - weekNumber: number
      - year: number
      - suggestionStartDate: timestamp
      - suggestionEndDate: timestamp
      - votingStartDate: timestamp
      - votingEndDate: timestamp
      - resultAnnouncedAt: timestamp?
      - approvedMovies: array<string> (suggestionIds)
      - winnerMovieId: string?
      - winnerMovieName: string?
      - isActive: boolean
      
  userVotes/
    {userId}_{weekId}/
      - userId: string
      - weekId: string
      - movieId: string (suggestionId)
      - movieName: string
      - votedAt: timestamp

dailySpecials/
  {date}/ (format: YYYY-MM-DD)
    - date: string
    - drinkItem: map
      - itemId: string
      - name: string
      - description: string
      - price: number
      - originalPrice: number?
      - discount: number?
      - chefNote: string?
      - media: array<string> (photos/videos)
      - tags: array<string>
      - calories: number?
      
    - dishItem: map (same structure as drinkItem)
    
    - isActive: boolean
    - createdAt: timestamp
    - createdBy: string (adminId)

saturdayGames/
  gameSchedules/
    {weekId}/ (format: YYYY-Www)
      - weekNumber: number
      - year: number
      - date: timestamp (Saturday date)
      - games: array<map>
        - gameId: string
        - gameName: string
        - description: string
        - rules: string
        - rulesVideoUrl: string?
        - startTime: string (HH:mm)
        - duration: number (minutes)
        - maxSlots: number
        - registeredUsers: array<string> (userIds)
        - entryCoins: number?
        - rewards: map
          - firstPlace: number (coins)
          - secondPlace: number
          - thirdPlace: number
          - participationReward: number
      - isActive: boolean
      - createdAt: timestamp
      
  gameParticipations/
    {participationId}/
      - userId: string
      - userName: string
      - gameId: string
      - gameName: string
      - weekId: string
      - registeredAt: timestamp
      - attended: boolean?
      - score: number?
      - rank: number?
      - rewardsEarned: map
        - coins: number
        - badges: array<string>
      - photos: array<string>
      - submittedAt: timestamp?
      
  leaderboards/
    allTime/
      - rankings: array<map>
        - userId: string
        - userName: string
        - totalWins: number
        - totalParticipations: number
        - totalCoinsWon: number
        - badges: array<string>

venueStatus/
  current/
    - isOpen: boolean
    - currentStatus: string (open/closed/busy)
    - nextChangeTime: timestamp?
    
    - regularHours: map
      - monday: map {open: string, close: string, isClosed: boolean}
      - tuesday: map
      - wednesday: map
      - thursday: map
      - friday: map
      - saturday: map
      - sunday: map
    
    - specialHours: array<map>
      - date: string (YYYY-MM-DD)
      - reason: string (Holiday/Event/etc)
      - isOpen: boolean
      - openTime: string?
      - closeTime: string?
    
    - closureAlert: map?
      - message: string
      - from: timestamp
      - to: timestamp
      - reason: string
    
    - lastUpdated: timestamp
    - updatedBy: string (adminId)

events/
  {eventId}/
    - title: string
    - description: string
    - eventType: string (celebrity/special_night/live_music/theme_night)
    - date: timestamp
    - startTime: string (HH:mm)
    - endTime: string (HH:mm)
    - location: string? (if different from main venue)
    
    - isCelebrityEvent: boolean
    - celebrityName: string?
    - celebrityPhoto: string?
    
    - teaserText: string?
    - teaserMedia: array<string>
    
    - media: array<string> (event photos/videos)
    - liveUpdates: array<map>
      - mediaUrl: string
      - caption: string
      - postedAt: timestamp
    
    - priorityAccessTier: string? (silver/gold/platinum)
    - isPublished: boolean
    - isFeatured: boolean
    
    - recap: map?
      - gallery: array<string>
      - highlights: string
      - postedAt: timestamp
    
    - createdAt: timestamp
    - publishedAt: timestamp?
    - createdBy: string (adminId)

coinTransactions/
  {transactionId}/
    - userId: string
    - userName: string
    
    - type: string (earned/spent/transferred_in/transferred_out)
    - amount: number (positive for credit, can be positive for debit too, use type to determine)
    
    - source: string (order/game/referral/bonus/transfer/admin_adjustment)
    - sourceId: string? (orderId/gameId/referralId)
    - sourceDescription: string
    
    - fromUserId: string? (for transfers)
    - fromUserName: string?
    - toUserId: string? (for transfers)
    - toUserName: string?
    
    - balanceBefore: number
    - balanceAfter: number
    
    - status: string (pending/completed/failed)
    - createdAt: timestamp
    - completedAt: timestamp?
    
    - securityPin: string? (hashed, for transfer verification)
    - failureReason: string?

notifications/
  {userId}/
    inbox/
      {notificationId}/
        - title: string
        - body: string
        - type: string (order/event/movie/special/game/coin/reservation/general)
        
        - data: map (type-specific data)
          - orderId: string?
          - eventId: string?
          - etc...
        
        - actionUrl: string? (deep link)
        - imageUrl: string?
        
        - isRead: boolean
        - readAt: timestamp?
        - createdAt: timestamp
        
        - priority: string (low/medium/high)
        - expiresAt: timestamp?

staffMembers/
  {staffId}/
    - name: string
    - email: string
    - phone: string
    - role: string (rider/waiter/manager/admin)
    - isActive: boolean
    - isOnline: boolean?
    - currentShift: string? (morning/evening/night)
    
    - assignedTables: array<string>? (tableIds for waiters)
    - activeOrders: array<string>? (orderIds for riders)
    
    - performance: map?
      - totalDeliveries: number (for riders)
      - averageRating: number
      - totalTablesServed: number (for waiters)
    
    - createdAt: timestamp
    - lastActiveAt: timestamp?

settings/
  app/
    - coinsConversionRate: number (1 coin = X rupees)
    - coinEarningRate: number (5 = 5% of order value)
    - maxCoinDiscountPercent: number (20 = max 20% discount)
    
    - minimumOrderAmount: number
    - deliveryCharges: number
    - freeDeliveryThreshold: number
    - taxPercentage: number (GST)
    
    - referralBonus: number (coins)
    - firstOrderBonus: number (coins)
    - dailyCheckInReward: number (coins)
    
    - paymentMethods: array<map>
      - method: string
      - isActive: boolean
      - displayName: string
    
    - supportPhone: string
    - supportEmail: string
    - whatsappNumber: string
    
    - lastUpdated: timestamp
```

### 3.2 Firestore Security Rules

Create `firebase/firestore.rules`:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Helper functions
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return isAuthenticated() && request.auth.uid == userId;
    }
    
    function hasRole(role) {
      return isAuthenticated() && 
             get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == role;
    }
    
    function isAdmin() {
      return hasRole('admin');
    }
    
    function isStaff() {
      return hasRole('staff') || hasRole('waiter') || hasRole('admin');
    }
    
    // Users collection
    match /users/{userId} {
      allow read: if isOwner(userId) || isStaff();
      allow create: if isAuthenticated();
      allow update: if isOwner(userId);
      allow delete: if isAdmin();
    }
    
    // Menu collections
    match /menu/categories/{categoryId} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    match /menu/items/{itemId} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    // Orders collection
    match /orders/{orderId} {
      allow read: if isOwner(resource.data.userId) || isStaff();
      allow create: if isAuthenticated() && isOwner(request.resource.data.userId);
      allow update: if isStaff();
      allow delete: if isAdmin();
    }
    
    // Tables collection
    match /tables/{tableId} {
      allow read: if isAuthenticated();
      allow write: if isStaff();
    }
    
    // Reservations collection
    match /reservations/{reservationId} {
      allow read: if isOwner(resource.data.userId) || isStaff();
      allow create: if isAuthenticated() && isOwner(request.resource.data.userId);
      allow update: if isOwner(resource.data.userId) || isStaff();
      allow delete: if isAdmin();
    }
    
    // Feedback collection
    match /feedback/{feedbackId} {
      allow read: if isStaff();
      allow create: if isAuthenticated() && isOwner(request.resource.data.userId);
      allow update: if isAdmin();
      allow delete: if isAdmin();
    }
    
    // Movie Night collections
    match /movieNight/suggestions/{suggestionId} {
      allow read: if true;
      allow create: if isAuthenticated();
      allow update: if isStaff();
      allow delete: if isAdmin();
    }
    
    match /movieNight/votingPeriods/{weekId} {
      allow read: if true;
      allow write: if isStaff();
    }
    
    match /movieNight/userVotes/{voteId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && voteId.matches('^' + request.auth.uid + '_.*');
      allow update, delete: if false;
    }
    
    // Daily Specials
    match /dailySpecials/{date} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    // Saturday Games
    match /saturdayGames/gameSchedules/{weekId} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    match /saturdayGames/gameParticipations/{participationId} {
      allow read: if isAuthenticated();
      allow create: if isAuthenticated() && isOwner(request.resource.data.userId);
      allow update: if isStaff();
      allow delete: if isAdmin();
    }
    
    match /saturdayGames/leaderboards/{document=**} {
      allow read: if true;
      allow write: if isStaff();
    }
    
    // Venue Status
    match /venueStatus/current {
      allow read: if true;
      allow write: if isStaff();
    }
    
    // Events
    match /events/{eventId} {
      allow read: if true;
      allow write: if isAdmin();
    }
    
    // Coin Transactions
    match /coinTransactions/{transactionId} {
      allow read: if isAuthenticated() && 
                  (resource.data.userId == request.auth.uid || 
                   resource.data.fromUserId == request.auth.uid || 
                   resource.data.toUserId == request.auth.uid);
      allow create: if isAuthenticated();
      allow update: if isAdmin();
      allow delete: if false;
    }
    
    // Notifications
    match /notifications/{userId}/inbox/{notificationId} {
      allow read, update: if isOwner(userId);
      allow create: if false; // Only cloud functions can create
      allow delete: if isOwner(userId);
    }
    
    // Staff Members
    match /staffMembers/{staffId} {
      allow read: if isStaff();
      allow write: if isAdmin();
    }
    
    // Settings
    match /settings/{document=**} {
      allow read: if true;
      allow write: if isAdmin();
    }
  }
}
```

### 3.3 Firebase Storage Rules

Create `firebase/storage.rules`:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    
    function isAuthenticated() {
      return request.auth != null;
    }
    
    function isOwner(userId) {
      return request.auth.uid == userId;
    }
    
    function isAdmin() {
      return request.auth.token.role == 'admin';
    }
    
    function isValidImage() {
      return request.resource.contentType.matches('image/.*') &&
             request.resource.size < 5 * 1024 * 1024; // 5MB
    }
    
    function isValidVideo() {
      return request.resource.contentType.matches('video/.*') &&
             request.resource.size < 50 * 1024 * 1024; // 50MB
    }
    
    // User profile photos
    match /user-profiles/{userId}/{fileName} {
      allow read: if true;
      allow write: if isOwner(userId) && isValidImage();
    }
    
    // Menu item photos
    match /menu-items/{itemId}/{fileName} {
      allow read: if true;
      allow write: if isAdmin() && isValidImage();
    }
    
    // Daily specials media
    match /daily-specials/{date}/{fileName} {
      allow read: if true;
      allow write: if isAdmin() && (isValidImage() || isValidVideo());
    }
    
    // Event media
    match /events/{eventId}/{fileName} {
      allow read: if true;
      allow write: if isAdmin() && (isValidImage() || isValidVideo());
    }
    
    // Saturday games
    match /saturday-games/{weekId}/{fileName} {
      allow read: if true;
      allow write: if isAuthenticated() && (isValidImage() || isValidVideo());
    }
    
    // QR codes for tables
    match /qr-codes/{tableId}.png {
      allow read: if true;
      allow write: if isAdmin();
    }
  }
}
```

---

## 4. Database Models

### 4.1 User Model

Create `lib/features/auth/data/models/user_model.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    required super.phone,
    super.profilePhoto,
    required super.addresses,
    required super.coinBalance,
    required super.loyaltyTier,
    required super.role,
    required super.createdAt,
    super.lastActive,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'] ?? '',
      profilePhoto: data['profilePhoto'],
      addresses: (data['addresses'] as List<dynamic>?)
          ?.map((addr) => AddressModel.fromMap(addr as Map<String, dynamic>))
          .toList() ?? [],
      coinBalance: (data['coinBalance'] ?? 0).toDouble(),
      loyaltyTier: data['loyaltyTier'] ?? 'bronze',
      role: data['role'] ?? 'customer',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastActive: data['lastActive'] != null 
          ? (data['lastActive'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'profilePhoto': profilePhoto,
      'addresses': addresses.map((addr) => (addr as AddressModel).toMap()).toList(),
      'coinBalance': coinBalance,
      'loyaltyTier': loyaltyTier,
      'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
    };
  }
}

class AddressModel {
  final String id;
  final String label;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String pincode;
  final String? landmark;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  const AddressModel({
    required this.id,
    required this.label,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.pincode,
    this.landmark,
    required this.isDefault,
    this.latitude,
    this.longitude,
  });

  factory AddressModel.fromMap(Map<String, dynamic> map) {
    return AddressModel(
      id: map['id'] ?? '',
      label: map['label'] ?? 'Home',
      addressLine1: map['addressLine1'] ?? '',
      addressLine2: map['addressLine2'],
      city: map['city'] ?? '',
      state: map['state'] ?? '',
      pincode: map['pincode'] ?? '',
      landmark: map['landmark'],
      isDefault: map['isDefault'] ?? false,
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'isDefault': isDefault,
      'latitude': latitude,
      'longitude': longitude,
    };
  }
}
```

### 4.2 Menu Item Model

Create `lib/features/menu/data/models/menu_item_model.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItemModel {
  final String id;
  final String name;
  final String description;
  final double price;
  final String categoryId;
  final List<String> photos;
  final bool isAvailable;
  final bool isVeg;
  final List<String> tags;
  final int? calories;
  final List<String>? ingredients;
  final double averageRating;
  final int totalRatings;
  final int preparationTime;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MenuItemModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.categoryId,
    required this.photos,
    required this.isAvailable,
    required this.isVeg,
    required this.tags,
    this.calories,
    this.ingredients,
    required this.averageRating,
    required this.totalRatings,
    required this.preparationTime,
    required this.createdAt,
    required this.updatedAt,
  });

  factory MenuItemModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return MenuItemModel(
      id: doc.id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      categoryId: data['categoryId'] ?? '',
      photos: List<String>.from(data['photos'] ?? []),
      isAvailable: data['isAvailable'] ?? true,
      isVeg: data['isVeg'] ?? true,
      tags: List<String>.from(data['tags'] ?? []),
      calories: data['calories'],
      ingredients: data['ingredients'] != null 
          ? List<String>.from(data['ingredients'])
          : null,
      averageRating: (data['averageRating'] ?? 0).toDouble(),
      totalRatings: data['totalRatings'] ?? 0,
      preparationTime: data['preparationTime'] ?? 30,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'categoryId': categoryId,
      'photos': photos,
      'isAvailable': isAvailable,
      'isVeg': isVeg,
      'tags': tags,
      'calories': calories,
      'ingredients': ingredients,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'preparationTime': preparationTime,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}
```

### 4.3 Order Model

Create `lib/features/orders/data/models/order_model.dart`:

```dart
import 'package:cloud_firestore/cloud_firestore.dart';

class OrderModel {
  final String id;
  final String orderNumber;
  final String userId;
  final String userName;
  final String userPhone;
  final String userEmail;
  
  final List<OrderItemModel> items;
  final OrderPricingModel pricing;
  final AddressModel deliveryAddress;
  final String? specialNotes;
  final String orderType;
  final String? tableId;
  
  final String status;
  final List<OrderStatusHistoryModel> statusHistory;
  
  final OrderPaymentModel payment;
  
  final String? assignedRiderId;
  final String? riderName;
  final String? riderPhone;
  
  final double coinsUsed;
  final double coinsEarned;
  
  final DateTime placedAt;
  final DateTime? confirmedAt;
  final DateTime? preparingAt;
  final DateTime? outForDeliveryAt;
  final DateTime? deliveredAt;
  final DateTime? cancelledAt;
  
  final DateTime? estimatedDeliveryTime;
  final DateTime? actualDeliveryTime;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.userEmail,
    required this.items,
    required this.pricing,
    required this.deliveryAddress,
    this.specialNotes,
    required this.orderType,
    this.tableId,
    required this.status,
    required this.statusHistory,
    required this.payment,
    this.assignedRiderId,
    this.riderName,
    this.riderPhone,
    required this.coinsUsed,
    required this.coinsEarned,
    required this.placedAt,
    this.confirmedAt,
    this.preparingAt,
    this.outForDeliveryAt,
    this.deliveredAt,
    this.cancelledAt,
    this.estimatedDeliveryTime,
    this.actualDeliveryTime,
  });

  factory OrderModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return OrderModel(
      id: doc.id,
      orderNumber: data['orderNumber'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      userPhone: data['userPhone'] ?? '',
      userEmail: data['userEmail'] ?? '',
      items: (data['items'] as List<dynamic>)
          .map((item) => OrderItemModel.fromMap(item as Map<String, dynamic>))
          .toList(),
      pricing: OrderPricingModel.fromMap(data['pricing'] as Map<String, dynamic>),
      deliveryAddress: AddressModel.fromMap(data['deliveryAddress'] as Map<String, dynamic>),
      specialNotes: data['specialNotes'],
      orderType: data['orderType'] ?? 'delivery',
      tableId: data['tableId'],
      status: data['status'] ?? 'placed',
      statusHistory: (data['statusHistory'] as List<dynamic>)
          .map((sh) => OrderStatusHistoryModel.fromMap(sh as Map<String, dynamic>))
          .toList(),
      payment: OrderPaymentModel.fromMap(data['payment'] as Map<String, dynamic>),
      assignedRiderId: data['assignedRiderId'],
      riderName: data['riderName'],
      riderPhone: data['riderPhone'],
      coinsUsed: (data['coinsUsed'] ?? 0).toDouble(),
      coinsEarned: (data['coinsEarned'] ?? 0).toDouble(),
      placedAt: (data['timestamps']['placedAt'] as Timestamp).toDate(),
      confirmedAt: data['timestamps']['confirmedAt'] != null
          ? (data['timestamps']['confirmedAt'] as Timestamp).toDate()
          : null,
      preparingAt: data['timestamps']['preparingAt'] != null
          ? (data['timestamps']['preparingAt'] as Timestamp).toDate()
          : null,
      outForDeliveryAt: data['timestamps']['outForDeliveryAt'] != null
          ? (data['timestamps']['outForDeliveryAt'] as Timestamp).toDate()
          : null,
      deliveredAt: data['timestamps']['deliveredAt'] != null
          ? (data['timestamps']['deliveredAt'] as Timestamp).toDate()
          : null,
      cancelledAt: data['timestamps']['cancelledAt'] != null
          ? (data['timestamps']['cancelledAt'] as Timestamp).toDate()
          : null,
      estimatedDeliveryTime: data['estimatedDeliveryTime'] != null
          ? (data['estimatedDeliveryTime'] as Timestamp).toDate()
          : null,
      actualDeliveryTime: data['actualDeliveryTime'] != null
          ? (data['actualDeliveryTime'] as Timestamp).toDate()
          : null,
    );
  }
}

class OrderItemModel {
  final String itemId;
  final String itemName;
  final int quantity;
  final double price;
  final double subtotal;

  const OrderItemModel({
    required this.itemId,
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.subtotal,
  });

  factory OrderItemModel.fromMap(Map<String, dynamic> map) {
    return OrderItemModel(
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      quantity: map['quantity'] ?? 0,
      price: (map['price'] ?? 0).toDouble(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'quantity': quantity,
      'price': price,
      'subtotal': subtotal,
    };
  }
}

class OrderPricingModel {
  final double subtotal;
  final double deliveryCharges;
  final double taxAmount;
  final double coinDiscount;
  final double totalAmount;
  final double finalAmount;

  const OrderPricingModel({
    required this.subtotal,
    required this.deliveryCharges,
    required this.taxAmount,
    required this.coinDiscount,
    required this.totalAmount,
    required this.finalAmount,
  });

  factory OrderPricingModel.fromMap(Map<String, dynamic> map) {
    return OrderPricingModel(
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      deliveryCharges: (map['deliveryCharges'] ?? 0).toDouble(),
      taxAmount: (map['taxAmount'] ?? 0).toDouble(),
      coinDiscount: (map['coinDiscount'] ?? 0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      finalAmount: (map['finalAmount'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subtotal': subtotal,
      'deliveryCharges': deliveryCharges,
      'taxAmount': taxAmount,
      'coinDiscount': coinDiscount,
      'totalAmount': totalAmount,
      'finalAmount': finalAmount,
    };
  }
}

class OrderStatusHistoryModel {
  final String status;
  final DateTime timestamp;
  final String? note;

  const OrderStatusHistoryModel({
    required this.status,
    required this.timestamp,
    this.note,
  });

  factory OrderStatusHistoryModel.fromMap(Map<String, dynamic> map) {
    return OrderStatusHistoryModel(
      status: map['status'] ?? '',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      note: map['note'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'note': note,
    };
  }
}

class OrderPaymentModel {
  final String method;
  final String status;
  final String? transactionId;
  final DateTime? paidAt;

  const OrderPaymentModel({
    required this.method,
    required this.status,
    this.transactionId,
    this.paidAt,
  });

  factory OrderPaymentModel.fromMap(Map<String, dynamic> map) {
    return OrderPaymentModel(
      method: map['method'] ?? 'cash',
      status: map['status'] ?? 'pending',
      transactionId: map['transactionId'],
      paidAt: map['paidAt'] != null
          ? (map['paidAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'method': method,
      'status': status,
      'transactionId': transactionId,
      'paidAt': paidAt != null ? Timestamp.fromDate(paidAt!) : null,
    };
  }
}
```

**Note**: Similar model files need to be created for all other features (Reservations, Feedback, Movie Night, Games, Events, etc.). Follow the same pattern.

---

## 5. Implementation Phases

### Phase 1: Foundation & Authentication (Week 1)

**Tasks**:
1. ✅ Project setup with dependencies
2. ✅ Create folder structure (MVVM pattern)
3. ✅ Setup Firebase project (dev environment)
4. ✅ Implement app theme and design system
5. ✅ Create core utilities and constants
6. ✅ Implement authentication flow
   - Create auth service
   - Create auth viewmodel
   - Splash screen
   - Login screen
   - Signup screen
   - Phone verification
7. ✅ Setup routing with go_router
8. ✅ Create main navigation structure

**Deliverables**:
- Working authentication system with MVVM
- Basic app shell with navigation
- Theme and design system ready

---

### Phase 2: Menu & Cart (Week 2)

**Tasks**:
1. ✅ Create menu models (MenuItem, Category, CartItem)
2. ✅ Implement menu service
3. ✅ Create menu viewmodels (categories, items, cart)
4. ✅ Build menu UI
   - Category filtering
   - Item cards
   - Item detail view
5. ✅ Implement cart functionality
   - Add/remove items
   - Quantity adjustment
   - Cart persistence with Hive
6. ✅ Create cart UI
7. ✅ Setup Hive for cart storage

**Deliverables**:
- Functional menu browsing with MVVM
- Working cart system
- Offline cart persistence

---

### Phase 3: Orders & Checkout (Week 3)

**Tasks**:
1. ✅ Create order models (Order, OrderItem, OrderPricing)
2. ✅ Implement order service
3. ✅ Create order viewmodels (checkout, tracking, history)
4. ✅ Build checkout flow
   - Address selection/addition
   - Payment method selection
   - Order summary
   - Apply reward coins
5. ✅ Implement Razorpay integration
6. ✅ Create order placement logic
7. ✅ Implement fun order ID generator
8. ✅ Build order confirmation screen
9. ✅ Create order history screen
10. ✅ Implement order status tracking UI

**Deliverables**:
- Complete checkout flow with MVVM
- Payment integration
- Order tracking system

---

### Phase 4: Venue Status & Home Screen (Week 4)

**Tasks**:
1. ✅ Create venue status models
2. ✅ Implement venue status repository
3. ✅ Build home screen layout
4. ✅ Create venue status card widget
5. ✅ Implement quick actions
6. ✅ Add featured sections
7. ✅ Build profile screen

**Deliverables**:
- Complete home screen
- Venue status display
- User profile management

---

### Phase 5: Notifications System (Week 5)

**Tasks**:
1. ✅ Create notification models
2. ✅ Implement notification service
3. ✅ Build notification viewmodels
4. ✅ Create notification UI
   - Notification bell with badge
   - Notification inbox screen
   - Mark as read functionality
5. ✅ Setup Firebase Cloud Functions for notification generation
6. ✅ Implement deep linking for notifications

**Deliverables**:
- Working in-app notification system with MVVM
- Cloud functions for auto-notifications

---

### Phase 6: Coins & Wallet (Week 6)

**Tasks**:
1. ✅ Create coin transaction models
2. ✅ Implement coin service
3. ✅ Create coin viewmodels
4. ✅ Build coin wallet UI
5. ✅ Implement coin earning logic
6. ✅ Create coin transfer functionality
7. ✅ Add security (PIN/biometric)
8. ✅ Show transaction history
9. ✅ Implement coin usage in checkout

**Deliverables**:
- Complete coin wallet system with MVVM
- Secure coin transfers
- Coin earning on orders

---

### Phase 7: Table Reservations (Week 7)

**Tasks**:
1. ✅ Create table and reservation models
2. ✅ Implement reservation service
3. ✅ Create reservation viewmodels
4. ✅ Build table selection UI
5. ✅ Implement time slot booking
6. ✅ Create reservation management screen
7. ✅ Add QR code scanner for dine-in ordering
8. ✅ Implement in-house ordering flow

**Deliverables**:
- Table reservation system with MVVM
- QR-based dine-in ordering

---

### Phase 8: Feedback System (Week 8)

**Tasks**:
1. ✅ Create feedback models
2. ✅ Implement feedback service
3. ✅ Create feedback viewmodels
4. ✅ Build feedback UI with bite rating (🍽 out of 10)
5. ✅ Implement dish-wise ratings
6. ✅ Add general feedback form
7. ✅ Link feedback to orders

**Deliverables**:
- Complete feedback system with MVVM
- Dish rating integration

---

### Phase 9: Movie Night Feature (Week 9)

**Tasks**:
1. ✅ Create movie night models
2. ✅ Implement movie night service
3. ✅ Create movie night viewmodels
4. ✅ Build suggestion UI
5. ✅ Implement voting system
6. ✅ Create winner announcement screen
7. ✅ Add Wall of Reels
8. ✅ Implement gamification (coins, badges)
9. ✅ Setup scheduled Cloud Functions for state management

**Deliverables**:
- Complete Friday Movie Night system with MVVM
- Automated voting period management

---

### Phase 10: Daily Specials (Week 10)

**Tasks**:
1. ✅ Create daily special models
2. ✅ Implement daily special service
3. ✅ Create daily special viewmodels
4. ✅ Build special item card UI
5. ✅ Implement media display (photos/videos)
6. ✅ Add rating and bookmarking
7. ✅ Create upcoming specials preview

**Deliverables**:
- Daily specials display system with MVVM
- Interactive special cards

---

### Phase 11: Saturday Games (Week 11)

**Tasks**:
1. ✅ Create game models
2. ✅ Implement game service
3. ✅ Create game viewmodels
4. ✅ Build game schedule UI
5. ✅ Implement registration system
6. ✅ Create leaderboard
7. ✅ Add rewards and badges
8. ✅ Implement photo tagging

**Deliverables**:
- Complete Saturday Games system with MVVM
- Leaderboard and rewards

---

### Phase 12: Events & Celebrities (Week 12)

**Tasks**:
1. ✅ Create event models
2. ✅ Implement event service
3. ✅ Create event viewmodels
4. ✅ Build events listing UI
5. ✅ Create event detail screen
6. ✅ Implement priority access for loyalty tiers
7. ✅ Add live updates during events
8. ✅ Create event recap gallery

**Deliverables**:
- Events and celebrity visits feature with MVVM
- Live updates system

---

### Phase 13: Staff Apps (Week 13-14)

**Tasks**:
1. ✅ Create delivery staff app
   - Order list
   - Map integration
   - Status updates
   - Navigation to customer
2. ✅ Create waiter app
   - Table assignments
   - Order alerts
   - Status management
   - Customer requests
3. ✅ Implement staff authentication

**Deliverables**:
- Delivery staff app
- Waiter app

---

### Phase 14: Admin Panel (Week 15)

**Tasks**:
1. ✅ Create admin authentication
2. ✅ Build dashboard with metrics
3. ✅ Implement menu management (CRUD)
4. ✅ Create order management interface
5. ✅ Build table and reservation management
6. ✅ Implement staff management
7. ✅ Create customer management
8. ✅ Build coin management interface
9. ✅ Implement content management (specials, events, games, movies)
10. ✅ Add reporting and analytics

**Deliverables**:
- Complete admin panel (web or desktop)

---

### Phase 15: Testing & Polish (Week 16)

**Tasks**:
1. ✅ Write unit tests for business logic
2. ✅ Write widget tests for critical components
3. ✅ Conduct integration testing
4. ✅ Performance optimization
5. ✅ Bug fixes
6. ✅ UI/UX polish
7. ✅ Offline functionality testing
8. ✅ Security audit
9. ✅ Add analytics
10. ✅ Prepare for deployment

**Deliverables**:
- Tested and polished app
- Ready for production deployment

---

## 6. Detailed Feature Implementation

### 6.1 Authentication Implementation

**Steps**:

1. **Create auth service**:

```dart
// lib/features/auth/services/auth_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  AuthService({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user data
  Stream<UserModel?> get currentUserStream {
    return _auth.authStateChanges().asyncExpand((firebaseUser) {
      if (firebaseUser == null) return Stream.value(null);
      return _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .snapshots()
          .map((doc) {
        if (!doc.exists) return null;
        return UserModel.fromFirestore(doc);
      });
    });
  }

  // Sign in with email and password
  Future<UserModel> signIn(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception('User data not found');
      }

      return UserModel.fromFirestore(userDoc);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign in failed: $e');
    }
  }

  // Sign up with email and password
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    try {
      // Create user account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Create user document
      final userData = {
        'email': email,
        'name': name,
        'phone': phone,
        'profilePhoto': null,
        'addresses': [],
        'coinBalance': 0,
        'loyaltyTier': 'bronze',
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
        'lastActive': FieldValue.serverTimestamp(),
      };

      await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .set(userData);

      // Get the created user
      final userDoc = await _firestore
          .collection('users')
          .doc(credential.user!.uid)
          .get();

      return UserModel.fromFirestore(userDoc);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception('Sign up failed: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      throw Exception('Sign out failed: $e');
    }
  }

  // Update user data
  Future<void> updateUserData(String userId, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(userId).update(data);
    } catch (e) {
      throw Exception('Update user data failed: $e');
    }
  }

  // Handle auth exceptions
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'No user found with this email';
      case 'wrong-password':
        return 'Wrong password';
      case 'email-already-in-use':
        return 'Email is already in use';
      case 'weak-password':
        return 'Password is too weak';
      case 'invalid-email':
        return 'Invalid email address';
      default:
        return e.message ?? 'Authentication failed';
    }
  }
}
```

2. **Create auth viewmodel**:

```dart
// lib/features/auth/viewmodels/auth_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

// Provider for AuthService
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

// Auth state provider - listens to Firebase auth state
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// Current user data provider - gets full user data from Firestore
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authServiceProvider).currentUserStream;
});

// Auth ViewModel for handling authentication actions
class AuthViewModel extends StateNotifier<AsyncValue<void>> {
  final AuthService _authService;

  AuthViewModel(this._authService) : super(const AsyncValue.data(null));

  // Sign in
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signIn(email, password);
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Sign up
  Future<void> signUp({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _authService.signUp(
        email: email,
        password: password,
        name: name,
        phone: phone,
      );
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  // Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _authService.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Auth ViewModel provider
final authViewModelProvider = StateNotifierProvider<AuthViewModel, AsyncValue<void>>((ref) {
  return AuthViewModel(ref.watch(authServiceProvider));
});
```

3. **Create login screen**:

```dart
// lib/features/auth/views/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../viewmodels/auth_viewmodel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authViewModelProvider.notifier).signIn(
      _emailController.text.trim(),
      _passwordController.text,
    );

    // Listen to auth state
    ref.listen(authViewModelProvider, (previous, next) {
      next.when(
        data: (_) {
          // Success - navigation handled by router
        },
        loading: () {},
        error: (error, _) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: Colors.red,
            ),
          );
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authViewModelProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo
                  const Icon(
                    Icons.restaurant_menu,
                    size: 80,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 16),
                  
                  Text(
                    'Cafe App',
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  
                  Text(
                    'Welcome back!',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 48),
                  
                  // Email field
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your email';
                      }
                      if (!value.contains('@')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Password field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                      ),
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your password';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  
                  // Login button
                  ElevatedButton(
                    onPressed: isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Login'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Sign up link
                  TextButton(
                    onPressed: () => context.push('/signup'),
                    child: const Text('Don\'t have an account? Sign up'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

### 6.2 Menu Implementation

**Steps**:

1. **Create menu service**:

```dart
// lib/features/menu/services/menu_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item_model.dart';
import '../models/category_model.dart';

class MenuService {
  final FirebaseFirestore _firestore;

  MenuService({required FirebaseFirestore firestore}) : _firestore = firestore;

  // Get categories stream
  Stream<List<CategoryModel>> getCategoriesStream() {
    return _firestore
        .collection('menu')
        .doc('categories')
        .collection('all')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CategoryModel.fromFirestore(doc))
            .toList());
  }

  // Get menu items stream (with optional category filter)
  Stream<List<MenuItemModel>> getMenuItemsStream({String? categoryId}) {
    var query = _firestore
        .collection('menu')
        .doc('items')
        .collection('all')
        .where('isAvailable', isEqualTo: true);

    if (categoryId != null && categoryId.isNotEmpty) {
      query = query.where('categoryId', isEqualTo: categoryId);
    }

    return query.orderBy('name').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => MenuItemModel.fromFirestore(doc)).toList());
  }

  // Get single item
  Future<MenuItemModel> getMenuItem(String itemId) async {
    final doc = await _firestore
        .collection('menu')
        .doc('items')
        .collection('all')
        .doc(itemId)
        .get();

    if (!doc.exists) {
      throw Exception('Item not found');
    }

    return MenuItemModel.fromFirestore(doc);
  }
}
```

2. **Create menu viewmodels**:

```dart
// lib/features/menu/viewmodels/menu_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/menu_service.dart';
import '../models/menu_item_model.dart';
import '../models/category_model.dart';

// Menu Service Provider
final menuServiceProvider = Provider<MenuService>((ref) {
  return MenuService(firestore: FirebaseFirestore.instance);
});

// Categories Provider
final categoriesProvider = StreamProvider<List<CategoryModel>>((ref) {
  return ref.watch(menuServiceProvider).getCategoriesStream();
});

// Selected Category Provider
final selectedCategoryProvider = StateProvider<String?>((ref) => null);

// Menu Items Provider (filtered by selected category)
final menuItemsProvider = StreamProvider<List<MenuItemModel>>((ref) {
  final selectedCategory = ref.watch(selectedCategoryProvider);
  return ref.watch(menuServiceProvider).getMenuItemsStream(
        categoryId: selectedCategory,
      );
});

// Single Item Provider
final menuItemProvider = FutureProvider.family<MenuItemModel, String>((ref, itemId) {
  return ref.watch(menuServiceProvider).getMenuItem(itemId);
});
```

3. **Create cart viewmodel**:

```dart
// lib/features/menu/viewmodels/cart_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart_item_model.dart';

// Cart State
class CartState {
  final List<CartItem> items;

  CartState({required this.items});

  CartState copyWith({List<CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }

  double get subtotal {
    return items.fold(0, (sum, item) => sum + (item.price * item.quantity));
  }

  int get itemCount {
    return items.fold(0, (sum, item) => sum + item.quantity);
  }
}

// Cart ViewModel
class CartViewModel extends StateNotifier<CartState> {
  final Box<CartItem> _cartBox;

  CartViewModel(this._cartBox) : super(CartState(items: [])) {
    _loadCart();
  }

  void _loadCart() {
    state = CartState(items: _cartBox.values.toList());
  }

  void addItem({
    required String itemId,
    required String itemName,
    required double price,
    String? photoUrl,
  }) {
    final existingItemIndex = state.items.indexWhere((item) => item.itemId == itemId);

    if (existingItemIndex >= 0) {
      // Item exists, increase quantity
      final existingItem = state.items[existingItemIndex];
      final updatedItem = CartItem(
        itemId: existingItem.itemId,
        itemName: existingItem.itemName,
        price: existingItem.price,
        quantity: existingItem.quantity + 1,
        photoUrl: existingItem.photoUrl,
      );
      _cartBox.put(itemId, updatedItem);
    } else {
      // New item
      final newItem = CartItem(
        itemId: itemId,
        itemName: itemName,
        price: price,
        quantity: 1,
        photoUrl: photoUrl,
      );
      _cartBox.put(itemId, newItem);
    }

    _loadCart();
  }

  void removeItem(String itemId) {
    _cartBox.delete(itemId);
    _loadCart();
  }

  void updateQuantity(String itemId, int quantity) {
    if (quantity <= 0) {
      removeItem(itemId);
      return;
    }

    final item = _cartBox.get(itemId);
    if (item != null) {
      final updatedItem = CartItem(
        itemId: item.itemId,
        itemName: item.itemName,
        price: item.price,
        quantity: quantity,
        photoUrl: item.photoUrl,
      );
      _cartBox.put(itemId, updatedItem);
      _loadCart();
    }
  }

  void clearCart() {
    _cartBox.clear();
    _loadCart();
  }
}

// Hive Box Provider
final cartBoxProvider = Provider<Box<CartItem>>((ref) {
  return Hive.box<CartItem>('cart');
});

// Cart ViewModel Provider
final cartViewModelProvider = StateNotifierProvider<CartViewModel, CartState>((ref) {
  return CartViewModel(ref.watch(cartBoxProvider));
});

// Convenience Providers
final cartSubtotalProvider = Provider<double>((ref) {
  return ref.watch(cartViewModelProvider).subtotal;
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(cartViewModelProvider).itemCount;
});
```

4. **Create menu screen**:

```dart
// lib/features/menu/views/screens/menu_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../viewmodels/menu_viewmodel.dart';
import '../../viewmodels/cart_viewmodel.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/category_chip.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    final menuItems = ref.watch(menuItemsProvider);
    final cartItemCount = ref.watch(cartItemCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu'),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.shopping_cart),
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
              ),
              if (cartItemCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 20,
                      minHeight: 20,
                    ),
                    child: Text(
                      '$cartItemCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Categories horizontal scroll
          categories.when(
            data: (cats) {
              if (cats.isEmpty) return const SizedBox();

              return Container(
                height: 50,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: cats.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return CategoryChip(
                        label: 'All',
                        isSelected: ref.watch(selectedCategoryProvider) == null,
                        onTap: () {
                          ref.read(selectedCategoryProvider.notifier).state = null;
                        },
                      );
                    }

                    final category = cats[index - 1];
                    return CategoryChip(
                      label: category.name,
                      isSelected: ref.watch(selectedCategoryProvider) == category.id,
                      onTap: () {
                        ref.read(selectedCategoryProvider.notifier).state = category.id;
                      },
                    );
                  },
                ),
              );
            },
            loading: () => const SizedBox(height: 50),
            error: (_, __) => const SizedBox(height: 50),
          ),

          // Menu items grid
          Expanded(
            child: menuItems.when(
              data: (items) {
                if (items.isEmpty) {
                  return const Center(
                    child: Text('No items available'),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    return MenuItemCard(item: items[index]);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) => Center(
                child: Text('Error: $error'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

### 6.3 Order Placement Implementation

**Steps**:

1. **Create order service**:

```dart
// lib/features/orders/services/order_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/utils/order_id_generator.dart';
import '../models/order_model.dart';
import '../../menu/models/cart_item_model.dart';
import '../../auth/models/address_model.dart';

class OrderService {
  final FirebaseFirestore _firestore;

  OrderService({required FirebaseFirestore firestore}) : _firestore = firestore;

  Future<String> placeOrder({
    required String userId,
    required String userName,
    required String userPhone,
    required String userEmail,
    required List<CartItem> items,
    required AddressModel address,
    required double coinDiscount,
    String? specialNotes,
    required String paymentMethod,
  }) async {
    try {
      // Calculate pricing
      final subtotal = items.fold<double>(
        0,
        (sum, item) => sum + (item.price * item.quantity),
      );

      final settingsDoc = await _firestore.collection('settings').doc('app').get();
      final settings = settingsDoc.data()!;

      final deliveryCharges = subtotal >= settings['freeDeliveryThreshold']
          ? 0.0
          : settings['deliveryCharges'].toDouble();

      final taxAmount = subtotal * (settings['taxPercentage'] / 100);
      final totalAmount = subtotal + deliveryCharges + taxAmount;
      final finalAmount = totalAmount - coinDiscount;

      // Calculate coins earned (5% of order value)
      final coinsEarned = (finalAmount * 0.05).round().toDouble();

      // Generate fun order number
      final orderNumber = OrderIdGenerator.generate();

      // Create order document
      final orderRef = _firestore.collection('orders').doc();

      final orderData = {
        'orderNumber': orderNumber,
        'userId': userId,
        'userName': userName,
        'userPhone': userPhone,
        'userEmail': userEmail,
        'items': items
            .map((item) => {
                  'itemId': item.itemId,
                  'itemName': item.itemName,
                  'quantity': item.quantity,
                  'price': item.price,
                  'subtotal': item.price * item.quantity,
                })
            .toList(),
        'pricing': {
          'subtotal': subtotal,
          'deliveryCharges': deliveryCharges,
          'taxAmount': taxAmount,
          'coinDiscount': coinDiscount,
          'totalAmount': totalAmount,
          'finalAmount': finalAmount,
        },
        'deliveryAddress': address.toMap(),
        'specialNotes': specialNotes,
        'orderType': 'delivery',
        'status': 'placed',
        'statusHistory': [
          {
            'status': 'placed',
            'timestamp': FieldValue.serverTimestamp(),
            'note': 'Order placed successfully',
          }
        ],
        'payment': {
          'method': paymentMethod,
          'status': paymentMethod == 'cash' ? 'pending' : 'completed',
          'transactionId': null,
          'paidAt':
              paymentMethod != 'cash' ? FieldValue.serverTimestamp() : null,
        },
        'coinsUsed': coinDiscount,
        'coinsEarned': coinsEarned,
        'timestamps': {
          'placedAt': FieldValue.serverTimestamp(),
        },
        'estimatedDeliveryTime': Timestamp.fromDate(
          DateTime.now().add(const Duration(minutes: 45)),
        ),
      };

      // Use batch write for atomicity
      final batch = _firestore.batch();

      // Create order
      batch.set(orderRef, orderData);

      // Deduct coins from user
      if (coinDiscount > 0) {
        final userRef = _firestore.collection('users').doc(userId);
        batch.update(userRef, {
          'coinBalance': FieldValue.increment(-coinDiscount),
        });

        // Log coin transaction
        final coinTxRef = _firestore.collection('coinTransactions').doc();
        batch.set(coinTxRef, {
          'userId': userId,
          'userName': userName,
          'type': 'spent',
          'amount': coinDiscount,
          'source': 'order',
          'sourceId': orderRef.id,
          'sourceDescription': 'Coins used for order $orderNumber',
          'balanceBefore': 0, // Will be updated by cloud function
          'balanceAfter': 0, // Will be updated by cloud function
          'status': 'completed',
          'createdAt': FieldValue.serverTimestamp(),
          'completedAt': FieldValue.serverTimestamp(),
        });
      }

      // Create notification for user
      final notifRef = _firestore
          .collection('notifications')
          .doc(userId)
          .collection('inbox')
          .doc();

      batch.set(notifRef, {
        'title': 'Order Placed!',
        'body': 'Your order $orderNumber has been placed successfully',
        'type': 'order',
        'data': {
          'orderId': orderRef.id,
          'orderNumber': orderNumber,
        },
        'actionUrl': '/orders/${orderRef.id}',
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'priority': 'high',
      });

      await batch.commit();

      return orderRef.id;
    } catch (e) {
      throw Exception('Order placement failed: $e');
    }
  }

  Stream<List<OrderModel>> getActiveOrders(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: [
      'placed',
      'confirmed',
      'preparing',
      'out_for_delivery'
    ]).orderBy('timestamps.placedAt', descending: true).snapshots().map(
            (snapshot) => snapshot.docs
                .map((doc) => OrderModel.fromFirestore(doc))
                .toList());
  }

  Stream<List<OrderModel>> getOrderHistory(String userId) {
    return _firestore
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .where('status', whereIn: ['delivered', 'cancelled'])
        .orderBy('timestamps.placedAt', descending: true)
        .limit(50)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => OrderModel.fromFirestore(doc))
            .toList());
  }

  Stream<OrderModel> trackOrder(String orderId) {
    return _firestore
        .collection('orders')
        .doc(orderId)
        .snapshots()
        .map((doc) => OrderModel.fromFirestore(doc));
  }
}
```

2. **Create order viewmodels**:

```dart
// lib/features/orders/viewmodels/orders_viewmodel.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/order_service.dart';
import '../models/order_model.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';

// Order Service Provider
final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(firestore: FirebaseFirestore.instance);
});

// Active Orders Provider
final activeOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  
  return ref.watch(orderServiceProvider).getActiveOrders(user.id);
});

// Order History Provider
final orderHistoryProvider = StreamProvider<List<OrderModel>>((ref) {
  final user = ref.watch(currentUserProvider).value;
  if (user == null) return Stream.value([]);
  
  return ref.watch(orderServiceProvider).getOrderHistory(user.id);
});

// Track Order Provider
final trackOrderProvider = StreamProvider.family<OrderModel, String>((ref, orderId) {
  return ref.watch(orderServiceProvider).trackOrder(orderId);
});

// Checkout ViewModel
class CheckoutViewModel extends StateNotifier<AsyncValue<String?>> {
  final OrderService _orderService;

  CheckoutViewModel(this._orderService) : super(const AsyncValue.data(null));

  Future<void> placeOrder({
    required String userId,
    required String userName,
    required String userPhone,
    required String userEmail,
    required List items,
    required address,
    required double coinDiscount,
    String? specialNotes,
    required String paymentMethod,
  }) async {
    state = const AsyncValue.loading();
    try {
      final orderId = await _orderService.placeOrder(
        userId: userId,
        userName: userName,
        userPhone: userPhone,
        userEmail: userEmail,
        items: items,
        address: address,
        coinDiscount: coinDiscount,
        specialNotes: specialNotes,
        paymentMethod: paymentMethod,
      );
      state = AsyncValue.data(orderId);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }
}

// Checkout ViewModel Provider
final checkoutViewModelProvider = StateNotifierProvider<CheckoutViewModel, AsyncValue<String?>>((ref) {
  return CheckoutViewModel(ref.watch(orderServiceProvider));
});
```

2. **Create fun order ID generator**:

```dart
// lib/core/utils/order_id_generator.dart

import 'dart:math';

class OrderIdGenerator {
  static final List<String> _adjectives = [
    'Spicy', 'Happy', 'Crazy', 'Super', 'Epic', 'Mega', 'Ultra', 
    'Cool', 'Hot', 'Sweet', 'Tasty', 'Yummy', 'Hungry', 'Fresh',
  ];

  static final List<String> _characters = [
    'Goku', 'Naruto', 'Pikachu', 'Mario', 'Sonic', 'Link', 'Kirby',
    'Thor', 'Hulk', 'Flash', 'Batman', 'Superman', 'Spidey', 'Deadpool',
  ];

  static String generate() {
    final random = Random();
    final adjective = _adjectives[random.nextInt(_adjectives.length)];
    final character = _characters[random.nextInt(_characters.length)];
    final number = random.nextInt(1000);
    
    return '#$adjective$character${number.toString().padLeft(3, '0')}';
  }
}
```

---

## 7. Testing Strategy

### 7.1 Unit Tests

Create unit tests for:
- **Services**: Test all Firebase operations with mocked Firestore
- **ViewModels**: Test state changes and business logic
- **Utilities**: Test validators, formatters, calculators
- **Models**: Test serialization/deserialization
- **Order ID Generator**: Test format and uniqueness
- **Price Calculators**: Test calculations

Example:

```dart
// test/features/orders/services/order_service_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:cafe_app/features/orders/services/order_service.dart';

void main() {
  group('OrderService', () {
    late FakeFirebaseFirestore fakeFirestore;
    late OrderService orderService;

    setUp(() {
      fakeFirestore = FakeFirebaseFirestore();
      orderService = OrderService(firestore: fakeFirestore);
    });

    test('should place order successfully', () async {
      // Setup test data
      await fakeFirestore.collection('settings').doc('app').set({
        'deliveryCharges': 50.0,
        'freeDeliveryThreshold': 500.0,
        'taxPercentage': 5.0,
      });

      // Place order
      final orderId = await orderService.placeOrder(
        userId: 'test-user',
        userName: 'Test User',
        userPhone: '1234567890',
        userEmail: 'test@test.com',
        items: [],
        address: testAddress,
        coinDiscount: 0,
        paymentMethod: 'cash',
      );

      expect(orderId, isNotEmpty);

      // Verify order created
      final order = await fakeFirestore.collection('orders').doc(orderId).get();
      expect(order.exists, true);
    });
  });
}
```

### 7.2 ViewModel Tests

```dart
// test/features/menu/viewmodels/cart_viewmodel_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_test/hive_test.dart';
import 'package:cafe_app/features/menu/viewmodels/cart_viewmodel.dart';

void main() {
  group('CartViewModel', () {
    setUp(() async {
      await setUpTestHive();
    });

    tearDown(() async {
      await tearDownTestHive();
    });

    test('should add item to cart', () async {
      final box = await Hive.openBox<CartItem>('test_cart');
      final viewModel = CartViewModel(box);

      viewModel.addItem(
        itemId: '1',
        itemName: 'Test Item',
        price: 100.0,
      );

      expect(viewModel.state.items.length, 1);
      expect(viewModel.state.subtotal, 100.0);
    });
  });
}
```

### 7.2 Widget Tests

Create widget tests for:
- Custom buttons
- Text fields
- Cards
- Loading states
- Error states

Example:

```dart
// test/features/menu/widgets/menu_item_card_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cafe_app/features/menu/presentation/widgets/menu_item_card.dart';

void main() {
  testWidgets('MenuItemCard displays item information', (WidgetTester tester) async {
    final testItem = MenuItemModel(
      id: '1',
      name: 'Test Pizza',
      description: 'Delicious test pizza',
      price: 299.0,
      categoryId: 'pizza',
      photos: [],
      isAvailable: true,
      isVeg: true,
      tags: [],
      averageRating: 4.5,
      totalRatings: 100,
      preparationTime: 30,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MenuItemCard(item: testItem),
        ),
      ),
    );

    expect(find.text('Test Pizza'), findsOneWidget);
    expect(find.text('₹299'), findsOneWidget);
    expect(find.byIcon(Icons.circle), findsOneWidget); // Veg indicator
  });
}
```

### 7.3 Integration Tests

Create integration tests for:
- Complete order flow
- Authentication flow
- Cart functionality

---

## 8. Deployment Steps

### 8.1 Pre-deployment Checklist

- [ ] All features implemented and tested
- [ ] Firebase security rules deployed
- [ ] Environment variables configured
- [ ] API keys secured
- [ ] App signing configured
- [ ] Privacy policy and terms added
- [ ] App icons and splash screens ready
- [ ] Store listings prepared

### 8.2 Firebase Deployment

```bash
# Deploy Firestore rules
firebase deploy --only firestore:rules

# Deploy Storage rules
firebase deploy --only storage:rules

# Deploy Cloud Functions
cd firebase/functions
npm install
firebase deploy --only functions
```

### 8.3 App Build

```bash
# Android
flutter build appbundle --release

# iOS
flutter build ipa --release
```

---

## 9. Post-Development Tasks

1. **Setup Analytics**:
   - Firebase Analytics events
   - User journey tracking
   - Feature usage tracking

2. **Setup Crashlytics**:
   - Error tracking
   - Crash reporting

3. **Performance Monitoring**:
   - App startup time
   - Screen rendering time
   - Network request monitoring

4. **A/B Testing Setup**:
   - Firebase Remote Config
   - Feature flags

5. **User Feedback Collection**:
   - In-app feedback form
   - Rating prompt

---

## 10. Next Steps After Reading This Plan

1. **Review the plan** with your team/client
2. **Setup Firebase project** (dev, staging, prod)
3. **Create project structure** exactly as outlined
4. **Start with Phase 1** (Authentication)
5. **Follow the implementation order** strictly
6. **Test each phase** before moving to next
7. **Use Claude Code** to implement features one by one

---

## 11. Tips for Working with Claude Code

When using Claude Code to implement features:

1. **Be specific**: "Implement the login screen with email/password validation using MVVM pattern"
2. **Reference the plan**: "Based on section 6.1 of the plan, create the auth service and viewmodel"
3. **One feature at a time**: Don't ask to implement multiple modules together
4. **Follow MVVM**: "Create the menu service, then the menu viewmodels, then the UI"
5. **Test incrementally**: Ask Claude to help write tests after each feature
6. **Follow the structure**: Always maintain the folder structure outlined
7. **Ask for clarification**: If anything is unclear, ask before implementing

**Example prompts**:
- "Create the menu service for fetching menu items from Firestore"
- "Implement the cart viewmodel with add, remove, and update quantity methods"
- "Build the checkout screen that uses the checkout viewmodel"

---

## 12. Common Pitfalls to Avoid

1. **Don't skip authentication**: Start with auth, it's foundational
2. **Don't ignore database indexes**: Add Firestore indexes as you go
3. **Don't hardcode values**: Use constants and environment configs
4. **Don't forget offline support**: Implement cart persistence early
5. **Don't skip error handling**: Add try-catch in all services
6. **Don't forget loading states**: Show loaders for all async operations in viewmodels
7. **Don't ignore security rules**: Test them rigorously
8. **Don't mix business logic in UI**: Keep it in services and viewmodels
9. **Don't create god viewmodels**: Keep viewmodels focused on specific features
10. **Don't forget to dispose**: Properly dispose controllers and close streams

---

## Contact for Help

If you get stuck or need clarification on any part:
- Review the relevant section of this plan
- Check Firebase documentation
- Ask Claude Code specific questions
- Test in small increments

---

## 13. Why MVVM for This Project?

### Comparison with Clean Architecture

**MVVM Advantages**:
- ✅ **Simpler structure**: Fewer layers, easier to navigate
- ✅ **Less boilerplate**: No need for entities, use cases, repositories + implementations
- ✅ **Faster development**: Direct service calls from ViewModels
- ✅ **Easier to learn**: Great for solo developers or small teams
- ✅ **Still testable**: Services and ViewModels can be unit tested
- ✅ **Sufficient for most apps**: Perfect for apps like this with straightforward business logic

**When to use Clean Architecture instead**:
- ❌ Very large teams with strict separation of concerns
- ❌ Complex business rules requiring multiple layers
- ❌ Switching between multiple data sources frequently
- ❌ Enterprise applications with strict architectural requirements

**For this cafe app**: MVVM is the perfect choice. It's simple, maintainable, and gets the job done efficiently without unnecessary complexity.

---

**Good luck with your cafe app development! 🚀**
