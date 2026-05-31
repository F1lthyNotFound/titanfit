class GymFlavor {
  const GymFlavor({
    required this.gymSlug,
    required this.gymId,
    required this.gymName,
    this.logoUrl = '',
    this.primaryHue = 240,
    this.themeSlug = 'monochrome',
    this.apiBase = '',
  });

  final String gymSlug;
  final int gymId;
  final String gymName;
  final String logoUrl;
  final double primaryHue;
  final String themeSlug;
  final String apiBase;

  factory GymFlavor.fromJson(Map<String, dynamic> json, String slug) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    return GymFlavor(
      gymSlug: slug,
      gymId: (data['gym_id'] as num?)?.toInt() ?? 0,
      gymName: (data['gym_name'] ?? '').toString(),
      logoUrl: (data['logo_url'] ?? '').toString(),
      primaryHue: (data['primary_hue'] as num?)?.toDouble() ?? 240,
      themeSlug: (data['theme_slug'] ?? 'monochrome').toString(),
      apiBase: (data['api_base'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'gym_slug': gymSlug,
        'gym_id': gymId,
        'gym_name': gymName,
        'logo_url': logoUrl,
        'primary_hue': primaryHue,
        'theme_slug': themeSlug,
        'api_base': apiBase,
      };

  bool get isValid => gymId > 0 && gymName.isNotEmpty;
}
