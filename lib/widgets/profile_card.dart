import 'package:flutter/material.dart';
import '../models/gig_models.dart';

/// Card widget displaying user profile information
/// 
/// Displays:
/// - Profile photo
/// - Name and rating
/// - For collectors: statistics (collections, response rate, earnings)
/// - For clients: member since
/// - Online status (for collectors)
class ProfileCard extends StatelessWidget {
  final CollectorProfile profile;
  final Function()? onTap;
  final bool showStats;
  final bool showOnlineStatus;

  const ProfileCard({
    Key? key,
    required this.profile,
    this.onTap,
    this.showStats = true,
    this.showOnlineStatus = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // Profile photo and online status
              Stack(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: DecorationImage(
                        image: NetworkImage(profile.photoUrl),
                        fit: BoxFit.cover,
                      ),
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                  ),
                  if (showOnlineStatus)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: profile.isOnline ? Colors.green : Colors.grey,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Name
              Text(
                profile.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 4),

              // Rating
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    profile.averageRating.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),

              if (showStats) ...[
                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 12),

                // Statistics grid
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Collections',
                      value: profile.totalCollections.toString(),
                    ),
                    _StatItem(
                      label: 'Service Radius',
                      value: '${profile.serviceRadiusKm.toStringAsFixed(0)} km',
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Online status
                if (showOnlineStatus)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: profile.isOnline
                          ? Colors.green[50]
                          : Colors.grey[100],
                      border: Border.all(
                        color: profile.isOnline
                            ? Colors.green
                            : Colors.grey,
                      ),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: profile.isOnline
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          profile.isOnline ? 'Online' : 'Offline',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: profile.isOnline
                                ? Colors.green
                                : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Helper widget for displaying statistics
class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}

/// Expanded profile view with full details
class FullProfileCard extends StatelessWidget {
  final CollectorProfile profile;
  final List<GigRating>? ratings;
  final Function()? onMessage;
  final Function()? onCall;

  const FullProfileCard({
    Key? key,
    required this.profile,
    this.ratings,
    this.onMessage,
    this.onCall,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with photo
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(profile.photoUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${profile.averageRating.toStringAsFixed(1)} • ${profile.totalCollections} collections',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status and stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatItem(
                      label: 'Collections',
                      value: profile.totalCollections.toString(),
                    ),
                    _StatItem(
                      label: 'Service Radius',
                      value: '${profile.serviceRadiusKm.toStringAsFixed(0)} km',
                    ),
                    _StatItem(
                      label: 'Status',
                      value: profile.isOnline ? 'Online' : 'Offline',
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onMessage,
                        icon: const Icon(Icons.message),
                        label: const Text('Message'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: onCall,
                        icon: const Icon(Icons.phone),
                        label: const Text('Call'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Ratings
                if (ratings != null && ratings!.isNotEmpty) ...[
                  const Text(
                    'Recent Ratings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...ratings!.take(3).map((rating) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: List.generate(
                                    5,
                                    (index) => Icon(
                                      index < rating.rating
                                          ? Icons.star
                                          : Icons.star_outline,
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
                            if (rating.comment.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                rating.comment,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ],
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
}
