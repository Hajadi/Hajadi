import 'package:flutter/material.dart';

import '../localization/strings.dart';

/// The ten trades the marketplace launches with.
///
/// [id] is the value stored in Firestore — never localise it. The label always
/// comes from the catalog so a worker registered as `electrician` shows as
/// "Elektrisyen" to a Kreyòl user and "Électricien" to a French one.
enum ServiceCategory {
  electrician('electrician', Icons.electrical_services_outlined),
  plumber('plumber', Icons.plumbing_outlined),
  carpenter('carpenter', Icons.carpenter_outlined),
  mason('mason', Icons.foundation_outlined),
  mechanic('mechanic', Icons.build_outlined),
  painter('painter', Icons.format_paint_outlined),
  welder('welder', Icons.local_fire_department_outlined),
  cleaner('cleaner', Icons.cleaning_services_outlined),
  tailor('tailor', Icons.content_cut_outlined),
  acTechnician('ac_technician', Icons.ac_unit_outlined);

  const ServiceCategory(this.id, this.icon);

  final String id;
  final IconData icon;

  static ServiceCategory? fromId(String? id) {
    for (final ServiceCategory category in ServiceCategory.values) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  String label(Strings s) => switch (this) {
        ServiceCategory.electrician => s.catElectrician,
        ServiceCategory.plumber => s.catPlumber,
        ServiceCategory.carpenter => s.catCarpenter,
        ServiceCategory.mason => s.catMason,
        ServiceCategory.mechanic => s.catMechanic,
        ServiceCategory.painter => s.catPainter,
        ServiceCategory.welder => s.catWelder,
        ServiceCategory.cleaner => s.catCleaner,
        ServiceCategory.tailor => s.catTailor,
        ServiceCategory.acTechnician => s.catAcTechnician,
      };
}
