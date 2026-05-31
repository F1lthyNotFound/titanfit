import 'package:flutter_test/flutter_test.dart';
import 'package:titanfit/flavor/gym_flavor.dart';

void main() {
  test('GymFlavor parses API payload', () {
    final flavor = GymFlavor.fromJson({
      'success': true,
      'data': {
        'gym_id': 1,
        'gym_name': 'Iron Works',
        'logo_url': 'https://example.com/logo.png',
        'primary_hue': 240,
        'theme_slug': 'monochrome',
      },
    }, 'iron-works');

    expect(flavor.gymId, 1);
    expect(flavor.gymName, 'Iron Works');
    expect(flavor.isValid, true);
  });
}
