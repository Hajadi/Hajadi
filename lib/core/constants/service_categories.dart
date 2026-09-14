import 'package:flutter/material.dart';

import '../localization/strings.dart';

/// How the trade list is grouped on the browse and filter screens.
///
/// Sixteen trades is past the point where one undifferentiated grid reads, so
/// the groups exist to make the list scannable — they are presentation only and
/// are never stored.
enum TradeGroup {
  trades,
  home,
  beauty,
  other;

  /// The trades in this group, in declaration order.
  List<ServiceCategory> get categories => ServiceCategory.values
      .where((ServiceCategory category) => category.group == this)
      .toList(growable: false);

  String label(Strings s) => switch (this) {
        TradeGroup.trades => s.groupTrades,
        TradeGroup.home => s.groupHome,
        TradeGroup.beauty => s.groupBeauty,
        TradeGroup.other => s.groupOther,
      };
}

/// The trades the marketplace lists.
///
/// [id] is the value stored in Firestore — never localise it. The label always
/// comes from the catalog so a worker registered as `electrician` shows as
/// "Elektrisyen" to a Kreyòl user and "Électricien" to a French one.
///
/// [aliases] are the folded (lowercase, accent-stripped) names the trade is
/// known by across all three languages. They do two jobs: free-text search
/// matches on them, so a Kreyòl speaker searching "plonbye" finds plumbers; and
/// a trade someone types into the "Other" box is checked against them, so
/// typing "Coiffeuse" lands the worker in the real Hair stylist bucket instead
/// of a private one nobody browses.
enum ServiceCategory {
  // ----------------------------------------------------- building & repair
  electrician(
    'electrician',
    Icons.electrical_services_outlined,
    TradeGroup.trades,
    <String>['electrician', 'electricien', 'elektrisyen', 'electricity'],
  ),
  plumber(
    'plumber',
    Icons.plumbing_outlined,
    TradeGroup.trades,
    <String>['plumber', 'plumbing', 'plombier', 'plonbye', 'plonberi'],
  ),
  carpenter(
    'carpenter',
    Icons.carpenter_outlined,
    TradeGroup.trades,
    <String>['carpenter', 'menuisier', 'ebeniste', 'chapantye', 'bos chapant'],
  ),
  mason(
    'mason',
    Icons.foundation_outlined,
    TradeGroup.trades,
    <String>['mason', 'masonry', 'macon', 'maconnerie', 'bos mason'],
  ),
  painter(
    'painter',
    Icons.format_paint_outlined,
    TradeGroup.trades,
    <String>['painter', 'painting', 'peintre', 'peinture', 'pent', 'penti'],
  ),
  welder(
    'welder',
    Icons.local_fire_department_outlined,
    TradeGroup.trades,
    <String>['welder', 'welding', 'soudeur', 'soudure', 'soude', 'soudaj'],
  ),
  acTechnician(
    'ac_technician',
    Icons.ac_unit_outlined,
    TradeGroup.trades,
    <String>[
      'ac technician',
      'air conditioning',
      'climatisation',
      'frigoriste',
      'teknisyen ac',
      'klimatizasyon',
      'frijide',
    ],
  ),
  mechanic(
    'mechanic',
    Icons.build_outlined,
    TradeGroup.trades,
    <String>['mechanic', 'mecanicien', 'mecanique', 'mekanisyen', 'mekanik'],
  ),

  // ------------------------------------------------------ home & everyday
  cleaner(
    'cleaner',
    Icons.cleaning_services_outlined,
    TradeGroup.home,
    <String>['cleaner', 'cleaning', 'menage', 'nettoyage', 'netwayaj'],
  ),
  tailor(
    'tailor',
    Icons.content_cut_outlined,
    TradeGroup.home,
    <String>[
      'tailor',
      'seamstress',
      'sewing',
      'couturier',
      'couturiere',
      'couture',
      'taye',
      'koutirye',
    ],
  ),

  // ----------------------------------------------------- beauty & wellness
  hairStylist(
    'hair_stylist',
    Icons.content_cut_rounded,
    TradeGroup.beauty,
    <String>[
      'hair stylist',
      'hairstylist',
      'hairdresser',
      'hair',
      'coiffeur',
      'coiffeuse',
      'coiffure',
      'kwafe',
      'kwafez',
      'cheve',
    ],
  ),
  barber(
    'barber',
    Icons.face_retouching_natural_outlined,
    TradeGroup.beauty,
    <String>['barber', 'barbershop', 'barbier', 'barbye'],
  ),
  makeupArtist(
    'makeup_artist',
    Icons.brush_outlined,
    TradeGroup.beauty,
    <String>[
      'makeup artist',
      'makeup',
      'make up',
      'maquilleur',
      'maquilleuse',
      'maquillage',
      'makiye',
      'makiyaj',
    ],
  ),
  nailTechnician(
    'nail_technician',
    Icons.back_hand_outlined,
    TradeGroup.beauty,
    <String>[
      'nail technician',
      'nails',
      'manicure',
      'pedicure',
      'manucure',
      'maniki',
      'pedikir',
      'zong',
    ],
  ),
  massageTherapist(
    'massage_therapist',
    Icons.spa_outlined,
    TradeGroup.beauty,
    <String>[
      'massage therapist',
      'massage',
      'masseur',
      'masseuse',
      'masaj',
      'mase',
    ],
  ),

  // ------------------------------------------------------------------ other
  /// The escape hatch. A worker who picks this types their own trade, which is
  /// stored in `WorkerProfile.customCategories` — see [CustomTrade].
  other(
    'other',
    Icons.more_horiz_rounded,
    TradeGroup.other,
    <String>['other', 'autre', 'lot'],
  );

  const ServiceCategory(this.id, this.icon, this.group, this.aliases);

  final String id;
  final IconData icon;
  final TradeGroup group;
  final List<String> aliases;

  /// Every trade except [other] — the list to offer where a free-text trade
  /// makes no sense, such as the home-screen shelf of browsable categories.
  static List<ServiceCategory> get listed => ServiceCategory.values
      .where((ServiceCategory category) => category != ServiceCategory.other)
      .toList(growable: false);

  static ServiceCategory? fromId(String? id) {
    for (final ServiceCategory category in ServiceCategory.values) {
      if (category.id == id) {
        return category;
      }
    }
    return null;
  }

  /// The listed trade [raw] names, if any — matched across all three languages
  /// and ignoring case, accents and separators. `null` when it names nothing we
  /// already list, which is exactly when a custom trade is warranted.
  ///
  /// It can return [other], meaning someone typed the word "Other" itself.
  /// That names no trade, so callers turning free text into a custom trade
  /// should reject it rather than store it.
  static ServiceCategory? match(String raw) {
    final String needle = TradeText.fold(raw);
    if (needle.isEmpty) {
      return null;
    }
    for (final ServiceCategory category in ServiceCategory.values) {
      if (TradeText.fold(category.id) == needle ||
          category.aliases.contains(needle)) {
        return category;
      }
    }
    return null;
  }

  /// Whether an already-folded search needle matches this trade's name in any
  /// of the three languages.
  bool matchesNeedle(String foldedNeedle) =>
      foldedNeedle.isNotEmpty &&
      (TradeText.fold(id).contains(foldedNeedle) ||
          aliases.any((String alias) => alias.contains(foldedNeedle)));

  String label(Strings s) => switch (this) {
        ServiceCategory.electrician => s.catElectrician,
        ServiceCategory.plumber => s.catPlumber,
        ServiceCategory.carpenter => s.catCarpenter,
        ServiceCategory.mason => s.catMason,
        ServiceCategory.painter => s.catPainter,
        ServiceCategory.welder => s.catWelder,
        ServiceCategory.acTechnician => s.catAcTechnician,
        ServiceCategory.mechanic => s.catMechanic,
        ServiceCategory.cleaner => s.catCleaner,
        ServiceCategory.tailor => s.catTailor,
        ServiceCategory.hairStylist => s.catHairStylist,
        ServiceCategory.barber => s.catBarber,
        ServiceCategory.makeupArtist => s.catMakeupArtist,
        ServiceCategory.nailTechnician => s.catNailTechnician,
        ServiceCategory.massageTherapist => s.catMassageTherapist,
        ServiceCategory.other => s.catOther,
      };
}

/// Case-, accent- and separator-insensitive comparison for trade names.
///
/// Kreyòl and French both carry diacritics a customer will not reliably type,
/// so "Électricien", "electricien" and "ELECTRICIEN" must all fold to the same
/// thing before anything is compared.
abstract final class TradeText {
  static const Map<String, String> _accents = <String, String>{
    'à': 'a', 'á': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a',
    'ç': 'c',
    'è': 'e', 'é': 'e', 'ê': 'e', 'ë': 'e',
    'ì': 'i', 'í': 'i', 'î': 'i', 'ï': 'i',
    'ñ': 'n',
    'ò': 'o', 'ó': 'o', 'ô': 'o', 'ö': 'o', 'õ': 'o',
    'ù': 'u', 'ú': 'u', 'û': 'u', 'ü': 'u',
    'ý': 'y', 'ÿ': 'y',
  };

  static final RegExp _separators = RegExp(r'[_\-‐-―/]+');
  static final RegExp _whitespace = RegExp(r'\s+');

  /// Lowercase, accent-stripped, separator-normalised, whitespace-collapsed.
  static String fold(String raw) {
    final StringBuffer buffer = StringBuffer();
    for (final int rune in raw.toLowerCase().runes) {
      final String char = String.fromCharCode(rune);
      buffer.write(_accents[char] ?? char);
    }
    return buffer
        .toString()
        .replaceAll(_separators, ' ')
        .replaceAll(_whitespace, ' ')
        .trim();
  }
}

/// The rules for a trade a worker typed themselves.
///
/// Custom trades are the marketplace's way of learning what it is missing: the
/// text a worker types is the demand signal that says which trade to promote
/// into [ServiceCategory] next. They are deliberately constrained — a worker
/// gets a handful of short ones, not a free-form advertisement.
abstract final class CustomTrade {
  /// How many a single worker may add.
  static const int maxPerWorker = 3;

  /// Characters allowed in one. Long enough for "Refrigeration technician",
  /// short enough that the chip still fits a phone.
  static const int maxLength = 40;

  /// Trim, collapse whitespace and cap the length. Returns `null` when nothing
  /// usable is left, so callers can reject in one check.
  static String? clean(String raw) {
    final String trimmed =
        raw.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return trimmed.length <= maxLength
        ? trimmed
        : trimmed.substring(0, maxLength).trim();
  }

  /// Whether [candidate] is already in [existing], ignoring case and accents.
  static bool isDuplicate(String candidate, Iterable<String> existing) {
    final String needle = TradeText.fold(candidate);
    return existing.any((String other) => TradeText.fold(other) == needle);
  }
}

/// Renders the trades on a profile or a job in the reader's language.
abstract final class TradeLabels {
  /// Listed trades first, in catalog order, then whatever the worker typed.
  ///
  /// The literal "Other" label is only used when a worker selected it and typed
  /// nothing, which a saved profile should never contain — but a document
  /// written by an older build might, and "Other" beats a blank chip.
  static List<String> forWorker({
    required List<String> categoryIds,
    required List<String> customCategories,
    required Strings s,
  }) {
    final List<String> labels = <String>[];
    for (final ServiceCategory category in ServiceCategory.values) {
      if (category == ServiceCategory.other || !categoryIds.contains(category.id)) {
        continue;
      }
      labels.add(category.label(s));
    }
    labels.addAll(customCategories);
    if (labels.isEmpty && categoryIds.contains(ServiceCategory.other.id)) {
      labels.add(ServiceCategory.other.label(s));
    }
    return labels;
  }

  /// What one job is for: the listed trade, or the text the customer typed.
  static String forJob({
    required String categoryId,
    String? customCategory,
    required Strings s,
  }) {
    final String? custom = customCategory?.trim();
    if (categoryId == ServiceCategory.other.id &&
        custom != null &&
        custom.isNotEmpty) {
      return custom;
    }
    return ServiceCategory.fromId(categoryId)?.label(s) ?? custom ?? '';
  }
}
