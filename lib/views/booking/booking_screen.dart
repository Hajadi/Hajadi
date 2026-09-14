import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../core/constants/haiti_departments.dart';
import '../../core/constants/service_categories.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/routing/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/payment_labels.dart';
import '../../core/widgets/app_avatar.dart';
import '../../core/widgets/common.dart';
import '../../models/job_request.dart';
import '../../viewmodels/booking_view_model.dart';

class BookingScreen extends StatefulWidget {
  const BookingScreen({super.key});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final TextEditingController _description = TextEditingController();
  final TextEditingController _address = TextEditingController();
  final TextEditingController _budget = TextEditingController();

  @override
  void dispose() {
    _description.dispose();
    _address.dispose();
    _budget.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Strings s = context.l10n;
    final BookingViewModel booking = context.watch<BookingViewModel>();
    final ThemeData theme = Theme.of(context);
    final String localeCode = Localizations.localeOf(context).languageCode;
    final HaitiDepartment? department =
        HaitiDepartment.fromId(booking.departmentId);
    final List<String> cities =
        department?.cities ?? HaitiDepartment.allCities;

    return Scaffold(
      appBar: AppBar(title: Text(s.bookingTitle)),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: <Widget>[
          AppCard(
            child: Row(
              children: <Widget>[
                AppAvatar(
                  name: booking.worker.fullName,
                  photoUrl: booking.worker.photoUrl,
                  radius: 24,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        booking.worker.fullName,
                        style: theme.textTheme.titleMedium,
                      ),
                      Text(
                        '${Formatters.money(booking.worker.hourlyRate, localeCode)}'
                        '${s.perHour}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(s.filterCategory, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: <Widget>[
              for (final ServiceCategory category in booking
                  .worker.categoryIds
                  .map(ServiceCategory.fromId)
                  .whereType<ServiceCategory>()
                  .where((ServiceCategory category) =>
                      category != ServiceCategory.other))
                ChoiceChip(
                  avatar: Icon(category.icon, size: 16),
                  label: Text(category.label(s)),
                  selected: booking.categoryId == category.id,
                  onSelected: (_) => booking.setCategory(category.id),
                ),
              // A trade this worker named themselves is bookable like any
              // other; the job stores the `other` id plus their wording.
              for (final String trade in booking.worker.customCategories)
                ChoiceChip(
                  avatar: Icon(ServiceCategory.other.icon, size: 16),
                  label: Text(trade),
                  selected: booking.categoryId == ServiceCategory.other.id &&
                      booking.customCategory == trade,
                  onSelected: (_) => booking.setCategory(
                    ServiceCategory.other.id,
                    custom: trade,
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          TextField(
            controller: _description,
            maxLines: 4,
            onChanged: booking.setDescription,
            decoration: InputDecoration(
              labelText: s.jobDescription,
              hintText: s.jobDescriptionHint,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final DateTime now = DateTime.now();
                    final DateTime? date = await showDatePicker(
                      context: context,
                      firstDate: now,
                      lastDate: now.add(const Duration(days: 120)),
                      initialDate: booking.scheduledAt ?? now,
                    );
                    if (date != null) {
                      booking.setScheduledAt(date);
                    }
                  },
                  icon: const Icon(Icons.event_outlined, size: 20),
                  label: Text(
                    booking.scheduledAt == null
                        ? s.preferredDate
                        : Formatters.date(booking.scheduledAt, localeCode),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final TimeOfDay? time = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.fromDateTime(
                        booking.scheduledAt ?? DateTime.now(),
                      ),
                    );
                    if (time != null) {
                      final DateTime base =
                          booking.scheduledAt ?? DateTime.now();
                      booking.setScheduledAt(
                        DateTime(
                          base.year,
                          base.month,
                          base.day,
                          time.hour,
                          time.minute,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.schedule_outlined, size: 20),
                  label: Text(
                    booking.scheduledAt == null
                        ? s.preferredTime
                        : Formatters.time(booking.scheduledAt, localeCode),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            value: booking.departmentId,
            isExpanded: true,
            decoration: InputDecoration(labelText: s.filterDepartment),
            items: <DropdownMenuItem<String>>[
              for (final HaitiDepartment department in HaitiDepartment.values)
                DropdownMenuItem<String>(
                  value: department.id,
                  child: Text(department.label(s)),
                ),
            ],
            onChanged: (String? value) {
              if (value != null) {
                booking.setDepartment(value);
                final HaitiDepartment? picked = HaitiDepartment.fromId(value);
                if (picked != null) {
                  booking.setCity(picked.cities.first);
                }
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),
          DropdownButtonFormField<String>(
            value: cities.contains(booking.city) ? booking.city : null,
            isExpanded: true,
            decoration: InputDecoration(labelText: s.filterCity),
            items: <DropdownMenuItem<String>>[
              for (final String city in cities)
                DropdownMenuItem<String>(value: city, child: Text(city)),
            ],
            onChanged: (String? value) {
              if (value != null) {
                booking.setCity(value);
              }
            },
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _address,
            onChanged: booking.setAddressNote,
            decoration: InputDecoration(
              labelText: s.jobLocation,
              prefixIcon: const Icon(Icons.place_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _budget,
            keyboardType: TextInputType.number,
            onChanged: (String value) =>
                booking.setBudget(double.tryParse(value) ?? 0),
            decoration: InputDecoration(
              labelText: '${s.budget} (${s.currency})',
              prefixIcon: const Icon(Icons.payments_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(s.paymentMethod, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: <Widget>[
              for (final PaymentMethod method in booking.availableMethods)
                ChoiceChip(
                  avatar: Icon(method.icon, size: 16),
                  label: Text(method.label(s)),
                  selected: booking.paymentMethod == method,
                  onSelected: (_) => booking.setPaymentMethod(method),
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
            label: s.sendRequest,
            busy: booking.busy,
            onPressed: booking.canSubmit
                ? () async {
                    final JobRequest? job = await booking.submit();
                    if (job == null || !context.mounted) {
                      return;
                    }
                    showAppSnackBar(context, s.requestSentBody);
                    context.go(Routes.jobs);
                  }
                : null,
          ),
        ),
      ),
    );
  }
}
