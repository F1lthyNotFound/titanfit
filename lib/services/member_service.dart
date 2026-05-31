import '../flavor/gym_flavor.dart';
import '../flavor/gym_flavor_service.dart';
import 'api_client.dart';

class MemberProfile {
  const MemberProfile({
    this.userId = 0,
    this.username = '',
    this.email = '',
    this.firstName = '',
    this.lastName = '',
    this.gender = '',
    this.dateOfBirth = '',
    this.phone = '',
    this.socialInstagram = '',
    this.socialFacebook = '',
    this.avatarUrl = '',
    this.onboardingComplete = false,
  });

  final int userId;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String dateOfBirth;
  final String phone;
  final String socialInstagram;
  final String socialFacebook;
  final String avatarUrl;
  final bool onboardingComplete;

  factory MemberProfile.fromJson(Map<String, dynamic> data) {
    return MemberProfile(
      userId: (data['user_id'] as num?)?.toInt() ?? 0,
      username: (data['username'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      firstName: (data['first_name'] ?? '').toString(),
      lastName: (data['last_name'] ?? '').toString(),
      gender: (data['gender'] ?? '').toString(),
      dateOfBirth: (data['date_of_birth'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      socialInstagram: (data['social_instagram'] ?? '').toString(),
      socialFacebook: (data['social_facebook'] ?? '').toString(),
      avatarUrl: (data['avatar_url'] ?? '').toString(),
      onboardingComplete: data['onboarding_complete'] == true ||
          data['onboarding_complete'] == 1,
    );
  }
}

class MemberWallet {
  const MemberWallet({
    this.balance = 0,
    this.currency = 'PHP',
    this.membershipName,
  });

  final double balance;
  final String currency;
  final String? membershipName;

  factory MemberWallet.fromJson(Map<String, dynamic> data) {
    return MemberWallet(
      balance: (data['balance'] as num?)?.toDouble() ?? 0,
      currency: (data['currency'] ?? 'PHP').toString(),
      membershipName: data['membership_name']?.toString(),
    );
  }
}

class MemberHistoryItem {
  const MemberHistoryItem({
    required this.type,
    required this.label,
    this.amount,
    required this.status,
    required this.date,
    this.iconHint = 'activity',
  });

  final String type;
  final String label;
  final double? amount;
  final String status;
  final String date;
  final String iconHint;

  factory MemberHistoryItem.fromJson(Map<String, dynamic> data) {
    return MemberHistoryItem(
      type: (data['type'] ?? '').toString(),
      label: (data['label'] ?? '').toString(),
      amount: data['amount'] == null ? null : (data['amount'] as num).toDouble(),
      status: (data['status'] ?? '').toString(),
      date: (data['date'] ?? '').toString(),
      iconHint: (data['icon_hint'] ?? 'activity').toString(),
    );
  }

  bool get isCheckIn => type == 'check_in';
  bool get isTopUp =>
      type == 'top_up' || type == 'top_up_pending' || type == 'top_up_paid';
  bool get isBooking => type == 'booking';
}

class MemberService {
  MemberService(this._client);

  final ApiClient _client;

  static MemberService forFlavor(GymFlavor flavor) {
    return MemberService(GymFlavorService.instance.apiClientFor(flavor));
  }

  Future<MemberProfile?> fetchProfile() async {
    final res = await _client.get(ApiClient.mobileApiPath, query: {
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
    String? socialInstagram,
    String? socialFacebook,
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
      if (socialInstagram != null) 'social_instagram': socialInstagram,
      if (socialFacebook != null) 'social_facebook': socialFacebook,
      if (complete) 'complete': '1',
    };

    final res = avatarBytes != null && avatarBytes.isNotEmpty
        ? await _client.postMultipart(
            ApiClient.mobileApiPath,
            fields,
            files: {'avatar': avatarBytes},
          )
        : await _client.postForm(ApiClient.mobileApiPath, fields);

    return res['success'] == true;
  }

  Future<MemberWallet?> fetchWallet() async {
    final res = await _client.get(ApiClient.mobileApiPath, query: {
      'action': 'get_member_balance',
    });
    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      return MemberWallet.fromJson(res['data'] as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<MemberHistoryItem>> fetchHistory() async {
    final res = await _client.get(ApiClient.mobileApiPath, query: {
      'action': 'get_member_history',
    });
    if (res['success'] != true || res['data'] is! Map<String, dynamic>) {
      return [];
    }
    final raw = (res['data'] as Map<String, dynamic>)['items'];
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(MemberHistoryItem.fromJson)
        .toList();
  }

  Future<WalletTopUpResult> requestTopUp(double amount) async {
    final res = await _client.postForm(ApiClient.mobileApiPath, {
      'action': 'member_wallet_topup',
      'amount': amount.toStringAsFixed(2),
    });
    return WalletTopUpResult(
      ok: res['success'] == true,
      message: (res['message'] ?? '').toString(),
      checkoutUrl: res['checkout_url']?.toString(),
    );
  }

  Future<WalletActionResult> requestRefund({
    required double amount,
    required String reason,
  }) async {
    final res = await _client.postForm(ApiClient.mobileApiPath, {
      'action': 'member_wallet_refund_request',
      'amount': amount.toStringAsFixed(2),
      'reason': reason.trim(),
    });
    return WalletActionResult(
      ok: res['success'] == true,
      message: (res['message'] ?? 'Request failed').toString(),
    );
  }
}

class WalletTopUpResult {
  const WalletTopUpResult({
    required this.ok,
    required this.message,
    this.checkoutUrl,
  });

  final bool ok;
  final String message;
  final String? checkoutUrl;
}

class WalletActionResult {
  const WalletActionResult({required this.ok, required this.message});

  final bool ok;
  final String message;
}
