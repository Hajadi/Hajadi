import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/constants/haiti_departments.dart';
import '../../core/constants/service_categories.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/common.dart';
import '../../models/job_request.dart';
import '../../models/worker_profile.dart';
import '../../viewmodels/worker_dashboard_view_model.dart';

class WorkerProfileEditScreen extends StatefulWidget {
  const WorkerProfileEditScreen({super.key});

  @override
  State<WorkerProfileEditScreen> createState() =>
      _WorkerProfileEditScreenState();
}

class _WorkerProfileEditScreenState extends State<WorkerProfileEditScreen> {
  late final WorkerDashboardViewModel _dashboard =
      context.read<WorkerDashboardViewModel>();

  late final TextEditingController _name =
      TextEditingController(text: _dashboard.profile.fullName);
  late final TextEditingController _headline =
      TextEditingController(text: _dashboard.profile.headline);
  late final TextEditingController _bio =
      TextEditingController(text: _dashboard.profile.bio);
  late final TextEditingController _phone =
      TextEditingController(text: _dashboard.profile.phone ?? '');
  late final TextEditingController _rate = TextEditingController(
    text: _dashboard.profile.hourlyRate.toStringAsFixed(0),
  );
  late final TextEditingController _years = TextEditingController(
    text: '${_dashboard.profile.yearsExperience}',
  );

  late Set<String> _trades = _dashboard.profile.categoryIds.toSet();
  late Set<String> _serviceDepartments =
      <String>{..._dashboard.profile.serviceDepartmentIds}
        ..add(_dashboard.profile.departmentId);
  late Set<String> _serviceCities =
      _dashboard.profile.serviceCities.toSet()..add(_dashboard.profile.city);
  late Set<String> _methods =
      _dashboard.profile.acceptedPaymentMethods.toSet();
  late HaitiDepartment _department =
      HaitiDepartment.fromId(_dashboard.profile.departmentId) ??
          HaitiDepartment.ouest;
  late String _city = _dashboard.profile.city;

  @override
  void dispose() {
    _name.dispose();
    _headline.dispose();
    _bio.dispose();
    _phone.dispose();
    _rate.dispose();
    _years.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (picked != null) {
      await _dashboard.uploadProfilePhoto(File(picked.path));
    }
  }

  Future<void> _addPortfolio() async {
    final XFile? picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked != null) {
      await _dashboard.addPortfolioItem(File(picked.path), '');
    }
  }

  Future<void> _save() async {
    final Strings s = context.l10n;
    await _dashboard.updateBasics(
      fullName: _name.text,
      headline: _headline.text,
      bio: _bio.text,
      hourlyRate: double.tryParse(_rate.text) ?? _dashboard.profile.hourlyRate,
      yearsExperience:
          int.tryParse(_years.text) ?? _dashboard.profile.yearsExperience,
      phone: _phone.text,
    );
    await _dashboard.setTrades(_trades.toList());
    await _dashboard.setServiceAreas(
      departmentId: _department.id,
      city: _city,
      serviceDepartmentIds: _serviceDepartments.toList(),
      serviceCities: _serviceCities.toList(),
    );
    await _dashboard.setPaymentMethods(_methods.toList());
    if (mounted) {
      showAppSnackBar(context, s.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final WorkerDashboardViewModel dashboard =
        context.watch<WorkerDashboardViewModel>();
    final WorkerProfile profile = dashboard.profile;

    return Scaffold(
      appBar: AppBar(title: Text(s.editProfile)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          Center(
            child: Stack(
              children: <Widget>[
                AppAvatar(
                  name: profile.fullName,
                  photoUrl: profile.photoUrl,
                  radius: 44,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: Theme.of(context).colorScheme.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _pickPhoto,
                      child: const Padding(
                        padding: EdgeInsets.all(6),
                        child: Icon(
                          Icons.photo_camera_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _name,
            decoration: InputDecoration(labelText: s.fullName),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _headline,
            decoration: InputDecoration(labelText: s.servicesOffered),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _bio,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: s.about,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _rate,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: '${s.hourlyRate} (${s.currency})',
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _years,
                  keyboardType: TextInputType.number,
                  decoration:
                      InputDecoration(labelText: s.yearsExperienceLabel),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(labelText: s.phone),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(s.myTrades, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final ServiceCategory category in ServiceCategory.values)
                FilterChip(
                  avatar: Icon(category.icon, size: 16),
                  label: Text(category.label(s)),
                  selected: _trades.contains(category.id),
                  onSelected: (bool value) => setState(() {
                    if (value) {
                      _trades.add(category.id);
                    } else {
                      _trades.remove(category.id);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(s.serviceAreas, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          DropdownButtonFormField<HaitiDepartment>(
            initialValue: _department,
            isExpanded: true,
            decoration: InputDecoration(labelText: s.filterDepartment),
            items: <DropdownMenuItem<HaitiDepartment>>[
              for (final HaitiDepartment department in HaitiDepartment.values)
                DropdownMenuItem<HaitiDepartment>(
                  value: department,
                  child: Text(department.label(s)),
                ),
            ],
            onChanged: (HaitiDepartment? value) {
              if (value != null) {
                setState(() {
                  _department = value;
                  _city = value.cities.first;
                  _serviceDepartments.add(value.id);
                });
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            initialValue:
                _department.cities.contains(_city) ? _city : _department.cities.first,
            isExpanded: true,
            decoration: InputDecoration(labelText: s.filterCity),
            items: <DropdownMenuItem<String>>[
              for (final String city in _department.cities)
                DropdownMenuItem<String>(value: city, child: Text(city)),
            ],
            onChanged: (String? value) {
              if (value != null) {
                setState(() {
                  _city = value;
                  _serviceCities.add(value);
                });
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final String city in _department.cities)
                FilterChip(
                  label: Text(city),
                  selected: _serviceCities.contains(city),
                  onSelected: (bool value) => setState(() {
                    if (value) {
                      _serviceCities.add(city);
                    } else {
                      _serviceCities.remove(city);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(s.paymentMethod, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: <Widget>[
              for (final PaymentMethod method in PaymentMethod.values)
                FilterChip(
                  label: Text(switch (method) {
                    PaymentMethod.moncash => s.moncash,
                    PaymentMethod.natcash => s.natcash,
                    PaymentMethod.cash => s.cash,
                  }),
                  selected: _methods.contains(method.id),
                  onSelected: (bool value) => setState(() {
                    if (value) {
                      _methods.add(method.id);
                    } else {
                      _methods.remove(method.id);
                    }
                  }),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  s.portfolio,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: _addPortfolio,
                icon: const Icon(Icons.add_photo_alternate_outlined, size: 20),
                label: Text(s.uploadPortfolio),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final PortfolioItem item in profile.portfolio)
                InputChip(
                  avatar: const Icon(Icons.image_outlined, size: 16),
                  label: Text(
                    item.caption.isEmpty ? item.id : item.caption,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onDeleted: () => dashboard.removePortfolioItem(item.id),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: BusyButton(
            label: s.save,
            busy: dashboard.busy,
            onPressed: _save,
          ),
        ),
      ),
    );
  }
}
