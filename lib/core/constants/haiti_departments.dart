import '../localization/strings.dart';

/// Haiti's ten administrative departments, with their main towns and an
/// approximate centre used to seed the map camera and distance filtering.
enum HaitiDepartment {
  ouest(
    'ouest',
    18.5944,
    -72.3074,
    <String>[
      'Port-au-Prince',
      'Delmas',
      'Pétion-Ville',
      'Carrefour',
      'Croix-des-Bouquets',
      'Léogâne',
      'Gressier',
      'Kenscoff',
      'Arcahaie',
      'Cabaret',
    ],
  ),
  nord(
    'nord',
    19.7579,
    -72.2043,
    <String>[
      'Cap-Haïtien',
      'Limbé',
      'Milot',
      'Grande-Rivière-du-Nord',
      'Plaine-du-Nord',
      'Acul-du-Nord',
      'Borgne',
    ],
  ),
  nordEst(
    'nord_est',
    19.6656,
    -71.8448,
    <String>[
      'Fort-Liberté',
      'Ouanaminthe',
      'Trou-du-Nord',
      'Terrier-Rouge',
      'Caracol',
      'Ferrier',
    ],
  ),
  nordOuest(
    'nord_ouest',
    19.9318,
    -72.8300,
    <String>[
      'Port-de-Paix',
      'Saint-Louis-du-Nord',
      'Jean-Rabel',
      'Môle-Saint-Nicolas',
      'Bassin-Bleu',
      'Anse-à-Foleur',
    ],
  ),
  artibonite(
    'artibonite',
    19.4500,
    -72.6833,
    <String>[
      'Gonaïves',
      'Saint-Marc',
      'Dessalines',
      'Gros-Morne',
      'Verrettes',
      "Petite-Rivière-de-l'Artibonite",
      'Marmelade',
    ],
  ),
  centre(
    'centre',
    19.1500,
    -72.0167,
    <String>[
      'Hinche',
      'Mirebalais',
      'Lascahobas',
      'Thomassique',
      'Belladère',
      'Boucan-Carré',
    ],
  ),
  sud(
    'sud',
    18.1937,
    -73.7500,
    <String>[
      'Les Cayes',
      'Aquin',
      'Camp-Perrin',
      'Port-Salut',
      'Chantal',
      'Torbeck',
      "Saint-Louis-du-Sud",
    ],
  ),
  sudEst(
    'sud_est',
    18.2341,
    -72.5349,
    <String>[
      'Jacmel',
      'Marigot',
      'Bainet',
      'Belle-Anse',
      'Cayes-Jacmel',
      'Thiotte',
    ],
  ),
  grandAnse(
    'grand_anse',
    18.6500,
    -74.1167,
    <String>[
      'Jérémie',
      "Anse-d'Hainault",
      'Dame-Marie',
      'Corail',
      'Pestel',
      'Moron',
    ],
  ),
  nippes(
    'nippes',
    18.4461,
    -73.0906,
    <String>[
      'Miragoâne',
      'Anse-à-Veau',
      'Petite-Rivière-de-Nippes',
      'Baradères',
      'Fonds-des-Nègres',
      'Petit-Trou-de-Nippes',
    ],
  );

  const HaitiDepartment(this.id, this.latitude, this.longitude, this.cities);

  final String id;
  final double latitude;
  final double longitude;
  final List<String> cities;

  static HaitiDepartment? fromId(String? id) {
    for (final HaitiDepartment department in HaitiDepartment.values) {
      if (department.id == id) {
        return department;
      }
    }
    return null;
  }

  /// Every city in the country, sorted — used by the city filter.
  static List<String> get allCities {
    final List<String> cities = <String>[
      for (final HaitiDepartment d in HaitiDepartment.values) ...d.cities,
    ]..sort();
    return cities;
  }

  String label(Strings s) => switch (this) {
        HaitiDepartment.ouest => s.deptOuest,
        HaitiDepartment.nord => s.deptNord,
        HaitiDepartment.nordEst => s.deptNordEst,
        HaitiDepartment.nordOuest => s.deptNordOuest,
        HaitiDepartment.artibonite => s.deptArtibonite,
        HaitiDepartment.centre => s.deptCentre,
        HaitiDepartment.sud => s.deptSud,
        HaitiDepartment.sudEst => s.deptSudEst,
        HaitiDepartment.grandAnse => s.deptGrandAnse,
        HaitiDepartment.nippes => s.deptNippes,
      };
}
