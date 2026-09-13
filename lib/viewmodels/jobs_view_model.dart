import 'dart:async';

import '../core/config/app_config.dart';
import '../models/invoice.dart';
import '../models/job_request.dart';
import '../services/service_locator.dart';
import 'base_view_model.dart';

/// The job list for whichever side of the marketplace is looking at it.
class JobsViewModel extends BaseViewModel {
  JobsViewModel(this._services, {required this.userId, required this.asWorker}) {
    _subscription = (asWorker
            ? _services.data.watchJobsForWorker(userId)
            : _services.data.watchJobsForCustomer(userId))
        .listen((List<JobRequest> jobs) {
      _jobs = jobs;
      _loading = false;
      safeNotify();
    }, onError: (Object error) {
      setError('errorGeneric');
      _loading = false;
      safeNotify();
    });
  }

  final Services _services;
  final String userId;
  final bool asWorker;

  StreamSubscription<List<JobRequest>>? _subscription;
  List<JobRequest> _jobs = const <JobRequest>[];
  bool _loading = true;

  List<JobRequest> get jobs => _jobs;
  bool get loading => _loading;

  List<JobRequest> get pending => _jobs
      .where((JobRequest job) => job.status == JobStatus.pending)
      .toList();

  List<JobRequest> get active =>
      _jobs.where((JobRequest job) => job.status.isOpen).toList();

  List<JobRequest> get completed => _jobs
      .where((JobRequest job) => job.status == JobStatus.completed)
      .toList();

  double get totalEarnings => completed.fold<double>(
        0,
        (double sum, JobRequest job) => sum + job.billableAmount,
      );

  double get monthEarnings {
    final DateTime now = DateTime.now();
    return completed
        .where(
          (JobRequest job) =>
              job.completedAt != null &&
              job.completedAt!.year == now.year &&
              job.completedAt!.month == now.month,
        )
        .fold<double>(
          0,
          (double sum, JobRequest job) => sum + job.billableAmount,
        );
  }

  /// Share of decided requests that were accepted — the number workers are
  /// ranked on, so it ignores requests still waiting for an answer.
  double get acceptanceRate {
    final int decided = _jobs
        .where(
          (JobRequest job) =>
              job.status != JobStatus.pending &&
              job.status != JobStatus.cancelled,
        )
        .length;
    if (decided == 0) {
      return 0;
    }
    final int accepted = _jobs
        .where(
          (JobRequest job) =>
              job.status != JobStatus.pending &&
              job.status != JobStatus.cancelled &&
              job.status != JobStatus.rejected,
        )
        .length;
    return accepted / decided;
  }

  Future<void> accept(JobRequest job) =>
      _update(job, JobStatus.accepted, agreedPrice: job.budget);

  Future<void> reject(JobRequest job) => _update(job, JobStatus.rejected);

  Future<void> start(JobRequest job) => _update(job, JobStatus.inProgress);

  Future<void> cancel(JobRequest job) => _update(job, JobStatus.cancelled);

  /// Completing a job is also what issues its invoice — the two must never
  /// drift apart, so they happen in one call.
  Future<Invoice?> complete(JobRequest job, {double? finalPrice}) async {
    final double subtotal = finalPrice ?? job.billableAmount;
    return guard<Invoice>(() async {
      await _services.data.updateJobStatus(
        job.id,
        JobStatus.completed,
        agreedPrice: subtotal,
      );
      return _services.data.createInvoice(
        Invoice(
          id: '',
          number: _invoiceNumber(job),
          jobId: job.id,
          customerId: job.customerId,
          customerName: job.customerName,
          workerId: job.workerId,
          workerName: job.workerName,
          subtotal: subtotal,
          serviceFee:
              double.parse((subtotal * AppConfig.serviceFeeRate).toStringAsFixed(2)),
          method: job.paymentMethod,
          status: PaymentStatus.unpaid,
          issuedAt: DateTime.now(),
        ),
      );
    });
  }

  static String _invoiceNumber(JobRequest job) {
    final DateTime now = DateTime.now();
    final String suffix = job.id.length >= 4
        ? job.id.substring(job.id.length - 4).toUpperCase()
        : job.id.toUpperCase();
    return 'JM-${now.year}-$suffix';
  }

  Future<void> _update(
    JobRequest job,
    JobStatus status, {
    double? agreedPrice,
  }) async {
    await guard(() async {
      await _services.data
          .updateJobStatus(job.id, status, agreedPrice: agreedPrice);
      return true;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
