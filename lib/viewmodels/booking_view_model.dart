import '../models/app_user.dart';
import '../models/job_request.dart';
import '../models/worker_profile.dart';
import '../services/service_locator.dart';
import 'base_view_model.dart';

/// Builds and submits a job request. The form state lives here so a rotation
/// or a trip to the photo picker never loses what the customer typed.
class BookingViewModel extends BaseViewModel {
  BookingViewModel(this._services, this.worker, this.customer)
      : _categoryId = worker.categoryIds.isEmpty
            ? 'electrician'
            : worker.categoryIds.first,
        _departmentId = customer.departmentId ?? worker.departmentId,
        _city = customer.city ?? worker.city {
    // Never preselect a method this worker does not take.
    final List<PaymentMethod> methods = availableMethods;
    if (!methods.contains(_paymentMethod)) {
      _paymentMethod = methods.isEmpty ? PaymentMethod.cash : methods.first;
    }
  }

  final Services _services;
  final WorkerProfile worker;
  final AppUser customer;

  String _categoryId;
  String _description = '';
  String _addressNote = '';
  String? _departmentId;
  String _city;
  double _budget = 0;
  DateTime? _scheduledAt;
  PaymentMethod _paymentMethod = PaymentMethod.moncash;
  final List<String> _photoUrls = <String>[];

  String get categoryId => _categoryId;
  String get description => _description;
  String get addressNote => _addressNote;
  String? get departmentId => _departmentId;
  String get city => _city;
  double get budget => _budget;
  DateTime? get scheduledAt => _scheduledAt;
  PaymentMethod get paymentMethod => _paymentMethod;
  List<String> get photoUrls => List<String>.unmodifiable(_photoUrls);

  /// Only the methods this worker actually accepts are offered.
  List<PaymentMethod> get availableMethods => PaymentMethod.values
      .where(
        (PaymentMethod method) =>
            worker.acceptedPaymentMethods.contains(method.id),
      )
      .toList();

  bool get canSubmit => _description.trim().length >= 10;

  void setCategory(String value) {
    _categoryId = value;
    safeNotify();
  }

  void setDescription(String value) {
    _description = value;
    safeNotify();
  }

  void setAddressNote(String value) => _addressNote = value;

  void setDepartment(String? value) {
    _departmentId = value;
    safeNotify();
  }

  void setCity(String value) {
    _city = value;
    safeNotify();
  }

  void setBudget(double value) {
    _budget = value;
    safeNotify();
  }

  void setScheduledAt(DateTime? value) {
    _scheduledAt = value;
    safeNotify();
  }

  void setPaymentMethod(PaymentMethod method) {
    _paymentMethod = method;
    safeNotify();
  }

  void addPhoto(String url) {
    _photoUrls.add(url);
    safeNotify();
  }

  void removePhoto(String url) {
    _photoUrls.remove(url);
    safeNotify();
  }

  Future<JobRequest?> submit() => guard<JobRequest>(() async {
        final JobRequest job = JobRequest(
          id: '',
          customerId: customer.id,
          customerName: customer.fullName,
          customerPhotoUrl: customer.photoUrl,
          workerId: worker.id,
          workerName: worker.fullName,
          workerPhotoUrl: worker.photoUrl,
          categoryId: _categoryId,
          description: _description.trim(),
          status: JobStatus.pending,
          paymentMethod: _paymentMethod,
          departmentId: _departmentId,
          city: _city,
          addressNote: _addressNote.trim(),
          latitude: customer.latitude,
          longitude: customer.longitude,
          budget: _budget,
          photoUrls: _photoUrls,
          scheduledAt: _scheduledAt,
          createdAt: DateTime.now(),
        );
        return _services.data.createJob(job);
      });
}
