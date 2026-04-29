/// Cities from the `city` table in the database dump (`dasroor_velox` SQL).
/// [id] must stay in sync with the backend `city.id` column.
class CityOption {
  final int id;
  /// Raw name as stored in SQL (trimmed for display).
  final String name;

  const CityOption({required this.id, required this.name});

  String get displayName {
    final t = name.trim();
    if (t.isEmpty) return t;
    return '${t[0].toUpperCase()}${t.substring(1).toLowerCase()}';
  }
}

/// Ordered list for signup (matches `INSERT INTO city` in the SQL dump).
const List<CityOption> kSignupCities = [
  CityOption(id: 1, name: 'hawler'),
  CityOption(id: 2, name: 'slemani'),
  CityOption(id: 3, name: 'dhok'),
  CityOption(id: 4, name: 'ranya'),
  CityOption(id: 5, name: 'karkuk'),
];
