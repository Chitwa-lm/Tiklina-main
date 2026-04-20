import 'package:flutter/material.dart';
import 'database_service.dart';

/// A simple in-memory singleton that acts as shared state between
/// the Admin and Waste Collector dashboards for the duration of the session.
class JobStore extends ChangeNotifier {
  JobStore._();
  static final JobStore instance = JobStore._();

  final List<Job> _jobs = [];

  List<Job> get jobs => List.unmodifiable(_jobs);

  /// Jobs that are still open (not yet accepted by a collector)
  List<Job> get availableJobs =>
      _jobs.where((j) => j.status == JobStatus.pending).toList();

  /// Jobs that a collector has accepted
  List<Job> get acceptedJobs =>
      _jobs.where((j) => j.status == JobStatus.accepted).toList();

  void addJob(Job job) {
    _jobs.add(job);
    notifyListeners();
  }

  void acceptJob(String jobId) {
    final idx = _jobs.indexWhere((j) => j.id == jobId);
    if (idx != -1) {
      _jobs[idx] = _jobs[idx].copyWith(status: JobStatus.accepted);
      notifyListeners();

      // Update status in Supabase
      _updateJobStatusInDatabase(jobId, 'In Progress');
    }
  }

  void completeJob(String jobId) {
    final idx = _jobs.indexWhere((j) => j.id == jobId);
    if (idx != -1) {
      _jobs[idx] = _jobs[idx].copyWith(status: JobStatus.completed);
      notifyListeners();

      // Update status in Supabase
      _updateJobStatusInDatabase(jobId, 'Completed');
    }
  }

  void markAsCompleted(String jobId) => completeJob(jobId);

  /// Update job status in Supabase database
  Future<void> _updateJobStatusInDatabase(String jobId, String status) async {
    try {
      await DatabaseService.instance.updateWasteReportStatus(
        reportId: jobId,
        status: status,
      );
    } catch (e) {
      // Error updating job status - will retry on next sync
    }
  }

  /// Load all jobs from Supabase and sync to JobStore
  Future<void> syncFromDatabase() async {
    try {
      final reports = await DatabaseService.instance.getAllWasteReports();

      // Clear existing jobs
      _jobs.clear();

      // Convert Supabase reports to Job objects
      for (final report in reports) {
        final reportDate = DateTime.parse(report['reported_at'] as String);
        final date =
            '${reportDate.day} ${_monthName(reportDate.month)} ${reportDate.year}';

        // Determine status based on Supabase status
        JobStatus status = JobStatus.pending;
        final dbStatus = report['status'] as String?;
        if (dbStatus == 'In Progress' || dbStatus == 'Accepted') {
          status = JobStatus.accepted;
        } else if (dbStatus == 'Completed') {
          status = JobStatus.completed;
        }

        _jobs.add(Job(
          id: report['id'].toString(),
          marketName: report['market_name'] as String? ?? '',
          location: report['market_name'] as String? ?? 'Unknown location',
          category: 'Mixed Waste', // Default, can be enhanced later
          volume: report['est_volume'] as String? ?? 'Unknown',
          description: report['description'] as String? ?? '',
          date: date,
          status: status,
        ));
      }

      notifyListeners();
    } catch (e) {
      // Error syncing jobs from database - will retry on next login
    }
  }

  String _monthName(int month) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return months[month];
  }
}

enum JobStatus { pending, accepted, completed }

class Job {
  final String id;
  final String marketName;
  final String location;
  final String category;
  final String volume;
  final String description;
  final String date;
  JobStatus status;

  Job({
    required this.id,
    required this.marketName,
    required this.location,
    required this.category,
    required this.volume,
    required this.description,
    required this.date,
    this.status = JobStatus.pending,
  });

  Job copyWith({JobStatus? status}) => Job(
        id: id,
        marketName: marketName,
        location: location,
        category: category,
        volume: volume,
        description: description,
        date: date,
        status: status ?? this.status,
      );

  String get statusLabel {
    switch (status) {
      case JobStatus.pending:
        return 'Pending';
      case JobStatus.accepted:
        return 'In Progress';
      case JobStatus.completed:
        return 'Completed';
    }
  }

  Color get statusColor {
    switch (status) {
      case JobStatus.pending:
        return const Color(0xFF6E3A00);
      case JobStatus.accepted:
        return const Color(0xFF005C15);
      case JobStatus.completed:
        return const Color(0xFF005159);
    }
  }

  Color get statusBgColor {
    switch (status) {
      case JobStatus.pending:
        return const Color(0xFFFFC698);
      case JobStatus.accepted:
        return const Color(0xFF9DF197);
      case JobStatus.completed:
        return const Color(0xFF10EAFE);
    }
  }
}
