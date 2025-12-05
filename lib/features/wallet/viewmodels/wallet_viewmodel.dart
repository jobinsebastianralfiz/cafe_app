import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../models/coin_transaction_model.dart';
import '../services/wallet_service.dart';

/// Wallet Service Provider
final walletServiceProvider = Provider<WalletService>((ref) {
  return WalletService();
});

/// Stream user transactions (real-time)
final userTransactionsProvider =
    StreamProvider.autoDispose<List<CoinTransactionModel>>((ref) {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return Stream.value([]);
  }

  final walletService = ref.watch(walletServiceProvider);
  return walletService.streamUserTransactions(user.uid);
});

/// Get transaction statistics
final transactionStatisticsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final user = ref.watch(authStateProvider).value;
  if (user == null) {
    return {};
  }

  final walletService = ref.watch(walletServiceProvider);
  return await walletService.getTransactionStatistics(user.uid);
});

/// Filter transactions by type
final transactionsByTypeProvider = Provider.autoDispose
    .family<List<CoinTransactionModel>, String>((ref, type) {
  final transactionsAsync = ref.watch(userTransactionsProvider);
  return transactionsAsync.when(
    data: (transactions) {
      if (type == 'all') return transactions;
      return transactions.where((t) => t.type == type).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Filter transactions by source
final transactionsBySourceProvider = Provider.autoDispose
    .family<List<CoinTransactionModel>, String>((ref, source) {
  final transactionsAsync = ref.watch(userTransactionsProvider);
  return transactionsAsync.when(
    data: (transactions) {
      if (source == 'all') return transactions;
      return transactions.where((t) => t.source == source).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Total earned coins
final totalEarnedCoinsProvider = Provider.autoDispose<int>((ref) {
  final transactionsAsync = ref.watch(userTransactionsProvider);
  return transactionsAsync.when(
    data: (transactions) {
      return transactions
          .where((t) => t.isCredit)
          .fold<int>(0, (sum, t) => sum + t.amount);
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Total redeemed coins
final totalRedeemedCoinsProvider = Provider.autoDispose<int>((ref) {
  final transactionsAsync = ref.watch(userTransactionsProvider);
  return transactionsAsync.when(
    data: (transactions) {
      return transactions
          .where((t) => t.isDebit)
          .fold<int>(0, (sum, t) => sum + t.amount.abs());
    },
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Current coin balance (from user model)
final currentCoinBalanceProvider = Provider.autoDispose<int>((ref) {
  final user = ref.watch(currentUserProvider);
  return user.when(
    data: (userData) => userData?.coinBalance ?? 0,
    loading: () => 0,
    error: (_, __) => 0,
  );
});

/// Wallet ViewModel - Manages wallet operations
class WalletViewModel extends StateNotifier<AsyncValue<void>> {
  final WalletService _walletService;

  WalletViewModel(this._walletService)
      : super(const AsyncValue.data(null));

  /// Add coins
  Future<bool> addCoins({
    required String userId,
    required int amount,
    required String source,
    required String description,
    String? sourceId,
    Map<String, dynamic>? metadata,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _walletService.addCoins(
        userId: userId,
        amount: amount,
        source: source,
        description: description,
        sourceId: sourceId,
        metadata: metadata,
      );

      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  /// Deduct coins
  Future<bool> deductCoins({
    required String userId,
    required int amount,
    required String source,
    required String description,
    String? sourceId,
    Map<String, dynamic>? metadata,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _walletService.deductCoins(
        userId: userId,
        amount: amount,
        source: source,
        description: description,
        sourceId: sourceId,
        metadata: metadata,
      );

      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  /// Refund coins
  Future<bool> refundCoins({
    required String userId,
    required int amount,
    required String description,
    String? sourceId,
    Map<String, dynamic>? metadata,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _walletService.refundCoins(
        userId: userId,
        amount: amount,
        description: description,
        sourceId: sourceId,
        metadata: metadata,
      );

      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  /// Give bonus coins
  Future<bool> giveBonusCoins({
    required String userId,
    required int amount,
    required String description,
    String? sourceId,
    Map<String, dynamic>? metadata,
  }) async {
    state = const AsyncValue.loading();

    try {
      await _walletService.giveBonusCoins(
        userId: userId,
        amount: amount,
        description: description,
        sourceId: sourceId,
        metadata: metadata,
      );

      state = const AsyncValue.data(null);
      return true;
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
      return false;
    }
  }

  /// Check sufficient balance
  Future<bool> hasSufficientBalance(String userId, int amount) async {
    try {
      return await _walletService.hasSufficientBalance(userId, amount);
    } catch (e) {
      return false;
    }
  }
}

/// Wallet ViewModel Provider
final walletViewModelProvider =
    StateNotifierProvider<WalletViewModel, AsyncValue<void>>((ref) {
  final walletService = ref.watch(walletServiceProvider);
  return WalletViewModel(walletService);
});
