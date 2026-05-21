import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/gig_models.dart';
import '../../services/database_service.dart';
import '../../services/payment_service.dart';
import '../../widgets/rating_widget.dart';
import '../../widgets/photo_upload_widget.dart';

/// Request Completion screen - shown after waste collection is completed
/// 
/// Allows client to:
/// - View after photos from collector
/// - Rate the collector
/// - Submit payment
/// - Download receipt
class RequestCompletionScreen extends StatefulWidget {
  final WasteRequest request;
  final WastePickup pickup;

  const RequestCompletionScreen({
    Key? key,
    required this.request,
    required this.pickup,
  }) : super(key: key);

  @override
  State<RequestCompletionScreen> createState() => _RequestCompletionScreenState();
}

class _RequestCompletionScreenState extends State<RequestCompletionScreen> {
  late DatabaseService _databaseService;
  late PaymentService _paymentService;

  CollectorProfile? _collector;
  List<RequestPhoto>? _beforePhotos;
  List<RequestPhoto>? _afterPhotos;
  bool _isLoading = true;
  bool _isPaymentProcessing = false;
  bool _paymentCompleted = false;
  String? _collectorCompletionPhotoUrl;

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
    _paymentService = PaymentService();
    _loadCompletionData();
  }

  Future<void> _loadCompletionData() async {
    try {
      // Load collector profile
      final user = await _databaseService.getProfileById(widget.pickup.collectorId);
      if (user != null) {
        _collector = CollectorProfile(
          id: user['id'],
          userId: widget.pickup.collectorId,
          name: user['full_name'] ?? 'Collector',
          photoUrl: user['photo_url'] ?? '',
          averageRating: (user['average_rating'] as num?)?.toDouble() ?? 0,
          totalCollections: user['total_collections'] ?? 0,
          serviceRadiusKm: (user['service_radius_km'] as num?)?.toDouble() ?? 10,
          isOnline: user['is_online'] ?? false,
          lastLocationLat: (user['last_location_lat'] as num?)?.toDouble() ?? 0,
          lastLocationLng: (user['last_location_lng'] as num?)?.toDouble() ?? 0,
          onlineSince: DateTime.now(),
          bankAccount: user['bank_account_number'] ?? '',
        );
      }

      // Load request photos
      final photos = await _databaseService.getRequestPhotos(widget.request.id);
      _beforePhotos = photos.where((p) => p.photoType == 'client_submitted').toList();
      _afterPhotos = photos.where((p) => p.photoType == 'collector_after').toList();

      // Get completion photo from pickup
      _collectorCompletionPhotoUrl = widget.pickup.completionPhotoUrl;

      setState(() => _isLoading = false);
    } catch (e) {
      print('[RequestCompletion] Error loading data: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Process payment
  Future<void> _processPayment() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() => _isPaymentProcessing = true);

    try {
      final success = await _paymentService.processPayment(
        clientId: userId,
        collectorId: widget.pickup.collectorId,
        amount: widget.request.estimatedCost,
        requestId: widget.request.id,
      );

      if (success) {
        setState(() => _paymentCompleted = true);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment completed successfully'),
            duration: Duration(seconds: 2),
          ),
        );

        // Update pickup status to Completed
        await _databaseService.completePickup(
          pickupId: widget.pickup.id,
          completionPhotoUrl: _collectorCompletionPhotoUrl ?? '',
        );
      }
    } catch (e) {
      print('[RequestCompletion] Payment error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isPaymentProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Collection Complete')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collection Complete'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Success banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[400]!, Colors.green[600]!],
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 48),
                  const SizedBox(height: 12),
                  const Text(
                    'Thank You!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Your waste has been successfully collected',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Collector card
                  if (_collector != null) ...[
                    const Text(
                      'Collector',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: NetworkImage(_collector!.photoUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _collector!.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star, size: 14, color: Colors.amber),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${_collector!.averageRating.toStringAsFixed(1)}',
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Photos section
                  if (_beforePhotos != null && _beforePhotos!.isNotEmpty ||
                      _afterPhotos != null && _afterPhotos!.isNotEmpty) ...[
                    const Text(
                      'Photos',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (_beforePhotos != null && _beforePhotos!.isNotEmpty) ...[
                      const Text(
                        'Before Collection',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _beforePhotos!.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(_beforePhotos![index].photoUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],

                    if (_afterPhotos != null && _afterPhotos!.isNotEmpty) ...[
                      const Text(
                        'After Collection',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 120,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _afterPhotos!.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              width: 120,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                image: DecorationImage(
                                  image: NetworkImage(_afterPhotos![index].photoUrl),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ],

                  // Payment section
                  const Text(
                    'Payment',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Amount'),
                            Text(
                              '\$${widget.request.estimatedCost.toStringAsFixed(2)}',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Status'),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: _paymentCompleted
                                    ? Colors.green[100]
                                    : Colors.orange[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _paymentCompleted ? 'Paid' : 'Pending',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: _paymentCompleted ? Colors.green : Colors.orange,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Payment button
                  if (!_paymentCompleted)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isPaymentProcessing ? null : _processPayment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: _isPaymentProcessing
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Pay Now'),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // Rating section
                  const Text(
                    'Rate Your Experience',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  RatingWidget(
                    userId: widget.pickup.collectorId,
                    raterUserId: Supabase.instance.client.auth.currentUser?.id ?? '',
                    raterRole: 'Client',
                    requestId: widget.request.id,
                  ),

                  const SizedBox(height: 24),

                  // Done button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
