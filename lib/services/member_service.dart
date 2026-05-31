import '../flavor/gym_flavor.dart';
import 'api_client.dart';
import '../config/api_config.dart';

class MemberProfile {
  const MemberProfile({
    this.userId = 0,
    this.username = '',
    this.firstName = '',
    this.lastName = '',
    this.gender = '',
    this.dateOfBirth = '',
    this.phone = '',
    this.avatarUrl = '',
    this.onboardingComplete = false,
  });

  final int userId;
  final String username;
  final String firstName;
  final String lastName;
  final String gender;
  final String dateOfBirth;
  final String phone;
  final String avatarUrl;
  final bool onboardingComplete;

  factory MemberProfile.fromJson(Map<String, dynamic> data) {
    return MemberProfile(
      userId: (data['user_id'] as num?)?.toInt() ?? 0,
      username: (data['username'] ?? '').toString(),
      firstName: (data['first_name'] ?? '').toString(),
      lastName: (data['last_name'] ?? '').toString(),
      gender: (data['gender'] ?? '').toString(),
      dateOfBirth: (data['date_of_birth'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      avatarUrl: (data['avatar_url'] ?? '').toString(),
      onboardingComplete: data['onboarding_complete'] == true ||
          data['onboarding_complete'] == 1,
    );
  }
}

class MemberService {
  MemberService(this._client);

  final ApiClient _client;

  static MemberService forFlavor(GymFlavor flavor) {
    final base = flavor.apiBase.isNotEmpty ? flavor.apiBase : ApiConfig.defaultApiBase;
    return MemberService(ApiClient(baseUrl: base));
  }

  Future<MemberProfile?> fetchProfile() async {
    final res = await _client.get('/api/controllers/app.php', query: {
      'action': 'get_member_profile',
    });
    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      return MemberProfile.fromJson(res['data'] as Map<String, dynamic>);
    }
    return null;
  }

  Future<bool> saveProfile({
    String? firstName,
    String? lastName,
    String? gender,
    String? dateOfBirth,
    String? phone,
    List<int>? avatarBytes,
    bool complete = false,
  }) async {
    final fields = <String, String>{
      'action': 'update_member_profile',
      if (firstName != null) 'first_name': firstName,
      if (lastName != null) 'last_name': lastName,
      if (gender != null) 'gender': gender,
      if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
      if (phone != null) 'phone': phone,
      if (complete) 'complete': '1',
    };

    final res = avatarBytes != null && avatarBytes.isNotEmpty
        ? await _client.postMultipart(
            '/api/controllers/app.php',
            fields,
            files: {'avatar': avatarBytes},
          )
        : await _client.postForm('/api/controllers/app.php', fields);

    return res['success'] == true;
  }
}
