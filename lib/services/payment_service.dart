import 'package:supabase_flutter/supabase_flutter.dart';
import 'database_service.dart';
import '../models/gig_models.dart';

/// Service for managing wallet payments and transactions in the gig economy platform
/// 
/// MVP Implementation:
/// - No external payment processor (Stripe/PayPal)
/// - Wallet-based system with NGO manual withdrawal processing
/// - Atomic transactions via database triggers
/// - Tracks: Payment, Earning, Withdrawal, Refund, Bonus transactions
class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  
  factory PaymentService() {
    return _instance;
  }
  
  PaymentService._internal();
  
  final SupabaseClient _supabase = Supabase.instance.client;
  final DatabaseService _db = DatabaseService();

  // ==================== Wallet Management ====================
  
  /// Initialize a wallet for a new user
  /// Creates wallet with 0 balance in default currency (USD)
  /// Safe to call multiple times (idempotent via database unique constraint)
  Future<Wallet?> initializeWallet(String userId) async {
    try {
      final response = await _supabase
          .from('wallets')
          .insert({
            'user_id': userId,
            'balance': 0,
            'currency': 'USD',
          })
          .select()
          .single();
      
      return Wallet.fromJson(response);
    } catch (e) {
      // Wallet already exists (unique constraint violation) - fetch and return it
      return getWallet(userId);
    }
  }

  /// Get wallet for a user (creates if doesn't exist)
  Future<Wallet?> getWallet(String userId) async {
    try {
      final response = await _supabase
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .single();
      
      return Wallet.fromJson(response);
    } catch (e) {
      print('Error fetching wallet: $e');
      return null;
    }
  }

  /// Get current balance for a user
  Future<double> getBalance(String userId) async {
    try {
      final wallet = await getWallet(userId);
      return wallet?.balance ?? 0.0;
    } catch (e) {
      print('Error getting balance: $e');
      return 0.0;
    }
  }

  /// Get wallet by ID
  Future<Wallet?> getWalletById(String walletId) async {
    try {
      final response = await _supabase
          .from('wallets')
          .select()
          .eq('id', walletId)
          .single();
      
      return Wallet.fromJson(response);
    } catch (e) {
      print('Error fetching wallet by ID: $e');
      return null;
    }
  }

  // ==================== Payment Processing ====================
  
  /// Process payment from client to collector (atomic transaction)
  /// 
  /// Flow:
  /// 1. Debit client wallet (Payment transaction)
  /// 2. Credit collector wallet (Earning transaction)
  /// 3. Create waste_pickup record linking them
  /// 
  /// Returns true if successful, false otherwise
  /// Throws exception if insufficient balance
  Future<bool> processPayment({
    required String clientId,
    required String collectorId,
    required double amount,
    required String requestId,
  }) async {
    try {
      // Get user wallets
      final clientWallet = await getWallet(clientId);
      final collectorWallet = await getWallet(collectorId);

      if (clientWallet == null || collectorWallet == null) {
        throw Exception('One or both wallets not found');
      }

      if (clientWallet.balance < amount) {
        throw Exception('Insufficient balance. Required: $amount, Available: ${clientWallet.balance}');
      }

      // Create transactions atomically
      // Use database RPC or transaction if available, otherwise use sequential updates
      
      // 1. Debit client
      final clientTxn = await createTransaction(
        userId: clientId,
        transactionType: 'Payment',
        amount: amount,
        relatedRequestId: requestId,
        description: 'Payment for waste collection request',
      );

      // 2. Credit collector
      final collectorTxn = await createTransaction(
        userId: collectorId,
        transactionType: 'Earning',
        amount: amount,
        relatedRequestId: requestId,
        description: 'Earnings from waste collection',
      );

      // 3. Update wallet balances
      await _supabase
          .from('wallets')
          .update({'balance': clientWallet.balance - amount})
          .eq('id', clientWallet.id);

      await _supabase
          .from('wallets')
          .update({'balance': collectorWallet.balance + amount})
          .eq('id', collectorWallet.id);

      return true;
    } catch (e) {
      print('Error processing payment: $e');
      rethrow;
    }
  }

  /// Refund a payment (reverse transaction)
  /// Creates Refund transactions for both parties
  Future<bool> refundPayment({
    required String clientId,
    required String collectorId,
    required double amount,
    required String requestId,
    required String reason,
  }) async {
    try {
      final clientWallet = await getWallet(clientId);
      final collectorWallet = await getWallet(collectorId);

      if (clientWallet == null || collectorWallet == null) {
        throw Exception('One or both wallets not found');
      }

      // Create refund transactions
      await createTransaction(
        userId: clientId,
        transactionType: 'Refund',
        amount: amount,
        relatedRequestId: requestId,
        description: 'Refund: $reason',
      );

      await createTransaction(
        userId: collectorId,
        transactionType: 'Refund',
        amount: -amount,
        relatedRequestId: requestId,
        description: 'Refund reversal: $reason',
      );

      // Update wallet balances
      await _supabase
          .from('wallets')
          .update({'balance': clientWallet.balance + amount})
          .eq('id', clientWallet.id);

      await _supabase
          .from('wallets')
          .update({'balance': collectorWallet.balance - amount})
          .eq('id', collectorWallet.id);

      return true;
    } catch (e) {
      print('Error refunding payment: $e');
      rethrow;
    }
  }

  // ==================== Transaction Management ====================
  
  /// Create a transaction record
  /// 
  /// Transaction Types:
  /// - Payment: Client paying for request
  /// - Earning: Collector earning from completed job
  /// - Withdrawal: Collector requesting money out
  /// - Refund: Money returned to client/collector
  /// - Bonus: Admin bonus to collector
  Future<Transaction?> createTransaction({
    required String userId,
    required String transactionType,
    required double amount,
    String? relatedRequestId,
    String? relatedPickupId,
    String? description,
  }) async {
    try {
      final response = await _supabase
          .from('transactions')
          .insert({
            'user_id': userId,
            'transaction_type': transactionType,
            'amount': amount,
            'currency': 'USD',
            'status': 'Completed', // MVP: all transactions complete immediately
            'related_request_id': relatedRequestId,
            'related_pickup_id': relatedPickupId,
            'description': description ?? '',
          })
          .select()
          .single();

      return Transaction.fromJson(response);
    } catch (e) {
      print('Error creating transaction: $e');
      return null;
    }
  }

  /// Get transaction history for a user
  /// Returns paginated list of recent transactions
  Future<List<Transaction>> getTransactionsByUser(
    String userId, {
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  /// Get transaction details by ID
  Future<Transaction?> getTransactionById(String transactionId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('id', transactionId)
          .single();

      return Transaction.fromJson(response);
    } catch (e) {
      print('Error fetching transaction: $e');
      return null;
    }
  }

  /// Get transactions for a specific request
  Future<List<Transaction>> getTransactionsByRequest(String requestId) async {
    try {
      final response = await _supabase
          .from('transactions')
          .select()
          .eq('related_request_id', requestId);

      return (response as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching request transactions: $e');
      return [];
    }
  }

  // ==================== Withdrawal & Admin ====================
  
  /// Request withdrawal from collector wallet
  /// 
  /// Flow (MVP):
  /// 1. Create Withdrawal transaction with status "Pending"
  /// 2. NGO admin manually processes withdrawal
  /// 3. Admin updates transaction status to "Completed"
  /// 4. NGO sends money out of band to collector bank account
  /// 
  /// Future: Integrate with payment processor (M-Pesa, bank transfer API)
  Future<Transaction?> requestWithdrawal({
    required String collectorId,
    required double amount,
  }) async {
    try {
      final wallet = await getWallet(collectorId);
      if (wallet == null) {
        throw Exception('Wallet not found');
      }

      if (wallet.balance < amount) {
        throw Exception('Insufficient balance for withdrawal');
      }

      // Create pending withdrawal transaction
      final response = await _supabase
          .from('transactions')
          .insert({
            'user_id': collectorId,
            'transaction_type': 'Withdrawal',
            'amount': amount,
            'currency': 'USD',
            'status': 'Pending', // Pending manual approval
            'description': 'Withdrawal request',
          })
          .select()
          .single();

      return Transaction.fromJson(response);
    } catch (e) {
      print('Error requesting withdrawal: $e');
      rethrow;
    }
  }

  /// Get pending withdrawals (admin only)
  Future<List<Transaction>> getPendingWithdrawals() async {
    try {
      final response = await _supabase
          .from('transactions')
          .select('*, user:user_id(id, raw_user_meta_data)')
          .eq('transaction_type', 'Withdrawal')
          .eq('status', 'Pending')
          .order('created_at', ascending: true);

      return (response as List)
          .map((json) => Transaction.fromJson(json))
          .toList();
    } catch (e) {
      print('Error fetching pending withdrawals: $e');
      return [];
    }
  }

  /// Complete a withdrawal (admin only)
  /// Should only be called after money is sent to collector
  Future<bool> completeWithdrawal(String transactionId) async {
    try {
      await _supabase
          .from('transactions')
          .update({
            'status': 'Completed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transactionId);

      return true;
    } catch (e) {
      print('Error completing withdrawal: $e');
      return false;
    }
  }

  /// Reject a withdrawal request (admin only)
  Future<bool> rejectWithdrawal(String transactionId) async {
    try {
      await _supabase
          .from('transactions')
          .update({
            'status': 'Failed',
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transactionId);

      return true;
    } catch (e) {
      print('Error rejecting withdrawal: $e');
      return false;
    }
  }

  // ==================== Bonuses & Incentives ====================
  
  /// Add bonus to collector wallet (admin incentive)
  /// Used for: referrals, performance bonuses, campaign incentives
  Future<bool> addBonus({
    required String collectorId,
    required double amount,
    required String reason,
  }) async {
    try {
      final wallet = await getWallet(collectorId);
      if (wallet == null) {
        throw Exception('Wallet not found');
      }

      // Create bonus transaction
      await createTransaction(
        userId: collectorId,
        transactionType: 'Bonus',
        amount: amount,
        description: 'Bonus: $reason',
      );

      // Update wallet
      await _supabase
          .from('wallets')
          .update({'balance': wallet.balance + amount})
          .eq('id', wallet.id);

      return true;
    } catch (e) {
      print('Error adding bonus: $e');
      rethrow;
    }
  }

  // ==================== Analytics & Reporting ====================
  
  /// Get wallet summary for a user (total earned, spent, balance)
  Future<Map<String, double>> getWalletSummary(String userId) async {
    try {
      final transactions = await getTransactionsByUser(userId, limit: 1000);
      
      double totalEarned = 0;
      double totalSpent = 0;
      double totalBonuses = 0;

      for (final txn in transactions) {
        if (txn.transactionType == 'Earning' && txn.status == 'Completed') {
          totalEarned += txn.amount;
        } else if (txn.transactionType == 'Payment' && txn.status == 'Completed') {
          totalSpent += txn.amount;
        } else if (txn.transactionType == 'Bonus' && txn.status == 'Completed') {
          totalBonuses += txn.amount;
        }
      }

      final balance = await getBalance(userId);

      return {
        'balance': balance,
        'total_earned': totalEarned,
        'total_spent': totalSpent,
        'total_bonuses': totalBonuses,
      };
    } catch (e) {
      print('Error getting wallet summary: $e');
      return {};
    }
  }

  /// Get daily revenue for platform (admin analytics)
  Future<double> getDailyRevenue(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day).toIso8601String();
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();

      final response = await _supabase
          .from('transactions')
          .select('amount')
          .eq('transaction_type', 'Payment')
          .eq('status', 'Completed')
          .gte('created_at', startOfDay)
          .lte('created_at', endOfDay);

      double total = 0;
      for (final txn in (response as List)) {
        total += (txn['amount'] as num).toDouble();
      }

      return total;
    } catch (e) {
      print('Error getting daily revenue: $e');
      return 0;
    }
  }

  /// Get top earning collectors (admin dashboard)
  Future<List<Map<String, dynamic>>> getTopCollectors({
    int limit = 10,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await _supabase.rpc(
        'get_top_collectors',
        params: {
          'start_date': startDate.toIso8601String(),
          'end_date': endDate.toIso8601String(),
          'limit_count': limit,
        },
      ) as List;

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching top collectors: $e');
      return [];
    }
  }
}
