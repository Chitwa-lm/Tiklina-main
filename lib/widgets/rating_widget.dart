import 'package:flutter/material.dart';
import '../models/gig_models.dart';
import '../services/database_service.dart';

/// Widget for viewing and creating ratings
/// 
/// Features:
/// - Display existing ratings
/// - Create new rating with stars and comment
/// - Show average rating
/// - Submit rating to database
class RatingWidget extends StatefulWidget {
  final String userId; // User being rated
  final String raterUserId; // Current user rating
  final String raterRole; // 'Client' or 'Collector'
  final String? requestId;
  final Function(GigRating)? onRatingSubmitted;
  final bool readOnly;

  const RatingWidget({
    Key? key,
    required this.userId,
    required this.raterUserId,
    required this.raterRole,
    this.requestId,
    this.onRatingSubmitted,
    this.readOnly = false,
  }) : super(key: key);

  @override
  State<RatingWidget> createState() => _RatingWidgetState();
}

class _RatingWidgetState extends State<RatingWidget> {
  late DatabaseService _databaseService;
  int _selectedRating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;
  List<GigRating> _ratings = [];

  @override
  void initState() {
    super.initState();
    _databaseService = DatabaseService();
    _loadRatings();
  }

  Future<void> _loadRatings() async {
    try {
      final ratings = await _databaseService.getRatingsForUser(widget.userId);
      setState(() {
        _ratings = ratings;
      });
    } catch (e) {
      print('[RatingWidget] Error loading ratings: $e');
    }
  }

  Future<void> _submitRating() async {
    if (_selectedRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final rating = await _databaseService.createRating(
        requestId: widget.requestId ?? '',
        ratedById: widget.raterUserId,
        ratedToId: widget.userId,
        rating: _selectedRating,
        comment: _commentController.text,
        ratedRole: widget.raterRole,
      );

      if (rating != null) {
        widget.onRatingSubmitted?.call(rating);
        _commentController.clear();
        setState(() => _selectedRating = 0);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Rating submitted successfully')),
        );

        await _loadRatings();
      }
    } catch (e) {
      print('[RatingWidget] Error submitting rating: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final averageRating = _ratings.isNotEmpty
        ? _ratings.map((r) => r.rating).reduce((a, b) => a + b) / _ratings.length
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary
        if (_ratings.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Column(
                  children: [
                    Text(
                      averageRating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(
                        5,
                        (index) => Icon(
                          index < averageRating.toInt()
                              ? Icons.star
                              : Icons.star_outline,
                          size: 16,
                          color: Colors.amber,
                        ),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_ratings.length} ratings',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._buildRatingDistribution(),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        // Create rating form
        if (!widget.readOnly) ...[
          const Text(
            'Leave a Rating',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          // Star selector
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => GestureDetector(
                  onTap: () => setState(() => _selectedRating = index + 1),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    child: Icon(
                      index < _selectedRating
                          ? Icons.star
                          : Icons.star_outline,
                      size: 32,
                      color: Colors.amber,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Comment input
          TextField(
            controller: _commentController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Share your experience (optional)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting ? null : _submitRating,
              child: _isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Submit Rating'),
            ),
          ),

          const SizedBox(height: 16),
        ],

        // Ratings list
        if (_ratings.isNotEmpty) ...[
          const Text(
            'All Ratings',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ..._ratings.map((rating) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RatingItem(rating: rating),
            );
          }).toList(),
        ],
      ],
    );
  }

  List<Widget> _buildRatingDistribution() {
    final distribution = <int, int>{};
    for (final rating in _ratings) {
      distribution[rating.rating] = (distribution[rating.rating] ?? 0) + 1;
    }

    return List.generate(5, (index) {
      final stars = 5 - index;
      final count = distribution[stars] ?? 0;
      final percentage =
          _ratings.isEmpty ? 0 : (count / _ratings.length * 100).toInt();

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$stars',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const Icon(Icons.star, size: 12, color: Colors.amber),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              height: 6,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: percentage / 100,
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getColorForRating(stars),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 25,
              child: Text(
                '$percentage%',
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
    });
  }

  Color _getColorForRating(int rating) {
    if (rating >= 4) return Colors.green;
    if (rating == 3) return Colors.orange;
    return Colors.red;
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}

/// Individual rating item
class _RatingItem extends StatelessWidget {
  final GigRating rating;

  const _RatingItem({required this.rating});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stars and date
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: List.generate(
                  5,
                  (index) => Icon(
                    index < rating.rating ? Icons.star : Icons.star_outline,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
              ),
              Text(
                _formatDate(rating.createdAt),
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          // Comment
          if (rating.comment.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              rating.comment,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[700],
              ),
            ),
          ],

          // Role badge
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 4,
            ),
            decoration: BoxDecoration(
              color: _getRoleColor(rating.ratedRole),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'By ${rating.ratedRole}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final duration = DateTime.now().difference(date);
    if (duration.inDays < 1) {
      return 'Today';
    } else if (duration.inDays < 7) {
      return '${duration.inDays}d ago';
    } else if (duration.inDays < 30) {
      return '${(duration.inDays / 7).toStringAsFixed(0)}w ago';
    } else {
      return '${(duration.inDays / 30).toStringAsFixed(0)}m ago';
    }
  }

  Color _getRoleColor(String role) {
    return role == 'Collector' ? Colors.blue : Colors.green;
  }
}
