import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tiklini/services/job_store.dart';
import 'job_execution_screen.dart';

class JobDetailsScreen extends StatelessWidget {
  final bool embedded;
  final Job? job;

  const JobDetailsScreen({super.key, this.embedded = false, this.job});

  @override
  Widget build(BuildContext context) {
    return embedded
        ? _buildContent(context)
        : Scaffold(
            appBar: AppBar(
              title: const Text('Job Details'),
              backgroundColor: const Color(0xFFF5F6F7),
              elevation: 0,
              foregroundColor: const Color(0xFF2C2F30),
            ),
            backgroundColor: const Color(0xFFF5F6F7),
            body: _buildContent(context),
          );
  }

  Widget _buildContent(BuildContext context) {
    if (job == null) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Select a job from the Market tab to view details.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 16,
              color: Color(0xFF595C5D),
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2C2F30).withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        job!.location,
                        style: const TextStyle(
                          fontFamily: 'Manrope',
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: Color(0xFF2C2F30),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: job!.statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        job!.statusLabel.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: job!.statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _infoRow(Icons.category_outlined, job!.category),
                const SizedBox(height: 6),
                _infoRow(Icons.local_shipping_outlined, job!.volume),
                const SizedBox(height: 6),
                _infoRow(Icons.calendar_today_outlined, job!.date),
                if (job!.description.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Divider(color: Color(0xFFEFF1F2)),
                  const SizedBox(height: 12),
                  const Text(
                    'Notes',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF2C2F30),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    job!.description,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: Color(0xFF595C5D),
                      height: 1.5,
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          if (job!.status == JobStatus.pending)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFB02500),
                      side: const BorderSide(color: Color(0xFFB02500)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Decline',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF176A21),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      context.read<JobStore>().acceptJob(job!.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Job accepted! Check Activity tab.'),
                          backgroundColor: Color(0xFF176A21),
                        ),
                      );
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Accept Job',
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFD1FFC8),
                      ),
                    ),
                  ),
                ),
              ],
            )
          else if (job!.status == JobStatus.accepted)
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF176A21),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const JobExecutionScreen()),
                );
              },
              child: const Text(
                'Start Collection',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.bold,
                  color: Color(0xFFD1FFC8),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: const Color(0xFF595C5D)),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: Color(0xFF595C5D),
          ),
        ),
      ],
    );
  }
}
