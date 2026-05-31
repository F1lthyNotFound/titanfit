class GymFlavor {
  const GymFlavor({
    required this.gymSlug,
    required this.gymId,
    required this.gymName,
    this.logoUrl = '',
    this.primaryHue = 240,
    this.themeSlug = 'monochrome',
    this.mobileThemeSlug = 'monochrome',
    this.mobileCustomHue,
    this.mobileCustomChroma,
    this.apiBase = '',
  });

  final String gymSlug;
  final int gymId;
  final String gymName;
  final String logoUrl;
  final double primaryHue;
  final String themeSlug;
  final String mobileThemeSlug;
  final double? mobileCustomHue;
  final double? mobileCustomChroma;
  final String apiBase;

  double get effectiveHue {
    if (mobileThemeSlug == 'custom' && mobileCustomHue != null) {
      return mobileCustomHue!;
    }
    const preset = {
      'monochrome': 0.0,
      'steel': 240.0,
      'steel-gray': 240.0,
      'ember': 35.0,
      'amber-glow': 35.0,
      'forest': 145.0,
      'forest-green': 145.0,
      'electric': 280.0,
      'electric-blue': 280.0,
    };
    return preset[mobileThemeSlug] ?? primaryHue;
  }

  factory GymFlavor.fromJson(Map<String, dynamic> json, String slug) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;
    final mobileTheme = (data['mobile_theme'] ?? data['theme_slug'] ?? 'monochrome').toString();
    return GymFlavor(
      gymSlug: slug,
      gymId: (data['gym_id'] as num?)?.toInt() ?? 0,
      gymName: (data['gym_name'] ?? '').toString(),
      logoUrl: (data['logo_url'] ?? '').toString(),
      primaryHue: (data['primary_hue'] as num?)?.toDouble() ?? 240,
      themeSlug: (data['theme_slug'] ?? 'monochrome').toString(),
      mobileThemeSlug: mobileTheme,
      mobileCustomHue: data['mobile_custom_hue'] != null
          ? (data['mobile_custom_hue'] as num).toDouble()
          : null,
      mobileCustomChroma: data['mobile_custom_chroma'] != null
          ? (data['mobile_custom_chroma'] as num).toDouble()
          : null,
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
        'mobile_theme': mobileThemeSlug,
        'mobile_theme_slug': mobileThemeSlug,
        'mobile_custom_hue': mobileCustomHue,
        'mobile_custom_chroma': mobileCustomChroma,
        'api_base': apiBase,
      };

  bool get isValid => gymId > 0 && gymName.isNotEmpty;
}
