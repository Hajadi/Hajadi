import 'dart:io';

import '../models/user_report.dart';
import '../models/worker_profile.dart';
import '../services/service_locator.dart';
import '../services/storage_service.dart';
import 'base_view_model.dart';

/// Profile editing, availability and identity verification for a worker.
class WorkerDashboardViewModel extends BaseViewModel {
  WorkerDashboardViewModel(this._services, this._profile);

  final Services _services;
  WorkerProfile _profile;

  WorkerProfile get profile => _profile;

  Future<void> _save(WorkerProfile updated) async {
    final WorkerProfile previous = _profile;
    _profile = updated;
    safeNotify();
    try {
      await _services.data.saveWorkerProfile(updated);
    } catch (_) {
      _profile = previous;
      setError('errorGeneric');
    }
  }

  Future<void> toggleAvailability(bool value) async {
    await _save(_profile.copyWith(availableNow: value));
    await _services.data
        .setWorkerAvailability(_profile.id, available: value);
  }

  Future<void> updateBasics({
    required String fullName,
    required String headline,
    required String bio,
    required double hourlyRate,
    required int yearsExperience,
    required String phone,
  }) =>
      _save(
        _profile.copyWith(
          fullName: fullName.trim(),
          headline: headline.trim(),
          bio: bio.trim(),
          hourlyRate: hourlyRate,
          yearsExperience: yearsExperience,
          phone: phone.trim(),
        ),
      );

  Future<void> setTrades(List<String> categoryIds) =>
      _save(_profile.copyWith(categoryIds: categoryIds));

  Future<void> setServiceAreas({
    required String departmentId,
    required String city,
    required List<String> serviceDepartmentIds,
    required List<String> serviceCities,
  }) =>
      _save(
        _profile.copyWith(
          departmentId: departmentId,
          city: city,
          serviceDepartmentIds: serviceDepartmentIds,
          serviceCities: serviceCities,
        ),
      );

  Future<void> setPaymentMethods(List<String> methods) =>
      _save(_profile.copyWith(acceptedPaymentMethods: methods));

  Future<void> uploadProfilePhoto(File file) async {
    await guard(() async {
      final String url = await _services.storage
          .upload(file, StoragePaths.profilePhoto(_profile.id));
      await _save(_profile.copyWith(photoUrl: url));
      return true;
    });
  }

  Future<void> addPortfolioItem(File file, String caption) async {
    await guard(() async {
      final String itemId =
          DateTime.now().millisecondsSinceEpoch.toRadixString(36);
      final String url = await _services.storage
          .upload(file, StoragePaths.portfolio(_profile.id, itemId));
      await _save(
        _profile.copyWith(
          portfolio: <PortfolioItem>[
            ..._profile.portfolio,
            PortfolioItem(
              id: itemId,
              imageUrl: url,
              caption: caption,
              categoryId: _profile.categoryIds.isEmpty
                  ? null
                  : _profile.categoryIds.first,
              uploadedAt: DateTime.now(),
            ),
          ],
        ),
      );
      return true;
    });
  }

  Future<void> removePortfolioItem(String itemId) => _save(
        _profile.copyWith(
          portfolio: _profile.portfolio
              .where((PortfolioItem item) => item.id != itemId)
              .toList(),
        ),
      );

  /// Sends the ID scan to the admin queue. The document itself goes to a
  /// Storage path only admins can read — the profile only ever stores status.
  Future<bool> submitVerification({
    required File idDocument,
    String idType = 'cin',
    List<File> certificates = const <File>[],
  }) async {
    final bool? done = await guard<bool>(() async {
      final String idUrl = await _services.storage
          .upload(idDocument, StoragePaths.identity(_profile.id));
      final List<String> certificateUrls = <String>[];
      for (final File certificate in certificates) {
        final String itemId =
            DateTime.now().microsecondsSinceEpoch.toRadixString(36);
        certificateUrls.add(
          await _services.storage.upload(
            certificate,
            StoragePaths.certificate(_profile.id, itemId),
            contentType: 'application/pdf',
          ),
        );
      }
      await _services.data.submitVerification(
        VerificationRequest(
          workerId: _profile.id,
          workerName: _profile.fullName,
          idDocumentUrl: idUrl,
          idType: idType,
          certificateUrls: certificateUrls,
          submittedAt: DateTime.now(),
        ),
      );
      _profile =
          _profile.copyWith(verification: VerificationStatus.pending);
      return true;
    });
    safeNotify();
    return done ?? false;
  }
}
