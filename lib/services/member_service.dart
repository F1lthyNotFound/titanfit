import 'dart:convert';

import '../flavor/gym_flavor.dart';
import '../flavor/gym_flavor_service.dart';
import 'api_client.dart';
import 'session_cookies.dart';

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
    this.socialLinks = const {},
    this.avatarUrl = '',
    this.onboardingComplete = false,
    this.emailVerified = true,
    this.clientStatus = 'active',
    this.accessMode = 'full',
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
  final Map<String, String> socialLinks;
  final String avatarUrl;
  final bool onboardingComplete;
  final bool emailVerified;
  final String clientStatus;
  final String accessMode;

  bool get isWalletRefundOnly => accessMode == 'wallet_refund_only';

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
      socialLinks: _parseSocialLinks(data),
      avatarUrl: (data['avatar_url'] ?? '').toString(),
      onboardingComplete: data['onboarding_complete'] == true ||
          data['onboarding_complete'] == 1,
      emailVerified: data['email_verified'] != false && data['email_verified'] != 0,
      clientStatus: (data['client_status'] ?? 'active').toString(),
      accessMode: (data['access_mode'] ?? 'full').toString(),
    );
  }

  static Map<String, String> _parseSocialLinks(Map<String, dynamic> data) {
    final raw = data['social_links'];
    if (raw is Map) {
      return raw.map((k, v) => MapEntry(k.toString(), v.toString()));
    }
    final links = <String, String>{};
    final ig = (data['social_instagram'] ?? '').toString();
    final fb = (data['social_facebook'] ?? '').toString();
    if (ig.isNotEmpty) links['instagram'] = ig;
    if (fb.isNotEmpty) links['facebook'] = fb;
    return links;
  }
}

class ProfileSaveResult {
  const ProfileSaveResult({
    required this.ok,
    this.message = '',
    this.unauthorized = false,
  });

  final bool ok;
  final String message;
  final bool unauthorized;
}

class RefundPaymentMethod {
  const RefundPaymentMethod({
    required this.id,
    required this.label,
    required this.description,
    this.requiresDetails = false,
    this.detailsLabel = '',
  });

  final String id;
  final String label;
  final String description;
  final bool requiresDetails;
  final String detailsLabel;

  factory RefundPaymentMethod.fromJson(Map<String, dynamic> data) {
    return RefundPaymentMethod(
      id: (data['id'] ?? '').toString(),
      label: (data['label'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      requiresDetails: data['requires_details'] == true,
      detailsLabel: (data['details_label'] ?? '').toString(),
    );
  }
}

class MemberWallet {
  const MemberWallet({
    this.balance = 0,
    this.currency = 'PHP',
    this.membershipName,
    this.clientStatus = 'active',
    this.accessMode = 'full',
    this.refundMethods = const [],
    this.pendingRefund = 0,
  });

  final double balance;
  final String currency;
  final String? membershipName;
  final String clientStatus;
  final String accessMode;
  final List<RefundPaymentMethod> refundMethods;
  final double pendingRefund;

  bool get isWalletRefundOnly => accessMode == 'wallet_refund_only';

  double get availableRefund => (balance - pendingRefund).clamp(0, double.infinity);

  factory MemberWallet.fromJson(Map<String, dynamic> data) {
    final rawMethods = data['refund_methods'];
    final methods = rawMethods is List
        ? rawMethods
            .whereType<Map<String, dynamic>>()
            .map(RefundPaymentMethod.fromJson)
            .toList()
        : <RefundPaymentMethod>[];
    return MemberWallet(
      balance: (data['balance'] as num?)?.toDouble() ?? 0,
      currency: (data['currency'] ?? 'PHP').toString(),
      membershipName: data['membership_name']?.toString(),
      clientStatus: (data['client_status'] ?? 'active').toString(),
      accessMode: (data['access_mode'] ?? 'full').toString(),
      refundMethods: methods,
      pendingRefund: (data['pending_refund'] as num?)?.toDouble() ?? 0,
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

class MemberDashboardDay {
  const MemberDashboardDay({
    required this.date,
    required this.weekday,
    required this.day,
    required this.isToday,
  });

  final String date;
  final String weekday;
  final int day;
  final bool isToday;

  factory MemberDashboardDay.fromJson(Map<String, dynamic> data) {
    return MemberDashboardDay(
      date: (data['date'] ?? '').toString(),
      weekday: (data['weekday'] ?? '').toString(),
      day: (data['day'] as num?)?.toInt() ?? 0,
      isToday: data['is_today'] == true,
    );
  }
}

class MemberDashboardSession {
  const MemberDashboardSession({
    required this.time,
    required this.label,
  });

  final String time;
  final String label;

  factory MemberDashboardSession.fromJson(Map<String, dynamic> data) {
    return MemberDashboardSession(
      time: (data['time'] ?? '').toString(),
      label: (data['label'] ?? '').toString(),
    );
  }
}

class MemberDashboardAlert {
  const MemberDashboardAlert({
    required this.kind,
    required this.title,
    required this.message,
  });

  final String kind;
  final String title;
  final String message;

  factory MemberDashboardAlert.fromJson(Map<String, dynamic> data) {
    return MemberDashboardAlert(
      kind: (data['kind'] ?? '').toString(),
      title: (data['title'] ?? '').toString(),
      message: (data['message'] ?? '').toString(),
    );
  }
}

class MemberDashboard {
  const MemberDashboard({
    this.branchName = '',
    this.balance = 0,
    this.currency = 'PHP',
    this.checkInStatus = 'outside',
    this.checkInLabel = 'Out of gym',
    this.checkInSubtext = 'Not checked in',
    this.membershipName,
    this.membershipDaysLeft = 0,
    this.weekDays = const [],
    this.sessionsByDate = const {},
    this.alerts = const [],
    this.clientStatus = 'active',
    this.accessMode = 'full',
  });

  final String branchName;
  final double balance;
  final String currency;
  final String checkInStatus;
  final String checkInLabel;
  final String checkInSubtext;
  final String? membershipName;
  final int membershipDaysLeft;
  final List<MemberDashboardDay> weekDays;
  final Map<String, List<MemberDashboardSession>> sessionsByDate;
  final List<MemberDashboardAlert> alerts;
  final String clientStatus;
  final String accessMode;

  bool get isInside => checkInStatus == 'inside';
  bool get isWalletRefundOnly => accessMode == 'wallet_refund_only';

  factory MemberDashboard.fromJson(Map<String, dynamic> data) {
    final week = data['week'];
    final days = <MemberDashboardDay>[];
    final sessions = <String, List<MemberDashboardSession>>{};
    if (week is Map<String, dynamic>) {
      final rawDays = week['days'];
      if (rawDays is List) {
        for (final d in rawDays) {
          if (d is Map<String, dynamic>) {
            days.add(MemberDashboardDay.fromJson(d));
          }
        }
      }
      final rawSessions = week['sessions_by_date'];
      if (rawSessions is Map) {
        rawSessions.forEach((key, value) {
          if (value is List) {
            sessions[key.toString()] = value
                .whereType<Map<String, dynamic>>()
                .map(MemberDashboardSession.fromJson)
                .toList();
          }
        });
      }
    }
    final rawAlerts = data['alerts'];
    final alerts = rawAlerts is List
        ? rawAlerts
            .whereType<Map<String, dynamic>>()
            .map(MemberDashboardAlert.fromJson)
            .toList()
        : <MemberDashboardAlert>[];

    return MemberDashboard(
      branchName: (data['branch_name'] ?? '').toString(),
      balance: (data['balance'] as num?)?.toDouble() ?? 0,
      currency: (data['currency'] ?? 'PHP').toString(),
      checkInStatus: (data['check_in_status'] ?? 'outside').toString(),
      checkInLabel: (data['check_in_label'] ?? 'Out of gym').toString(),
      checkInSubtext: (data['check_in_subtext'] ?? 'Not checked in').toString(),
      membershipName: data['membership_name']?.toString(),
      membershipDaysLeft: (data['membership_days_left'] as num?)?.toInt() ?? 0,
      weekDays: days,
      sessionsByDate: sessions,
      alerts: alerts,
      clientStatus: (data['client_status'] ?? 'active').toString(),
      accessMode: (data['access_mode'] ?? 'full').toString(),
    );
  }
}

class MembershipTimeframe {
  const MembershipTimeframe({
    required this.id,
    required this.label,
    this.days = 0,
    this.isLifetime = false,
  });

  final String id;
  final String label;
  final int days;
  final bool isLifetime;

  factory MembershipTimeframe.fromJson(Map<String, dynamic> data) {
    return MembershipTimeframe(
      id: (data['id'] ?? '').toString(),
      label: (data['label'] ?? '').toString(),
      days: (data['days'] as num?)?.toInt() ?? 0,
      isLifetime: data['is_lifetime'] == true || data['is_lifetime'] == 1,
    );
  }
}

class MembershipPlan {
  const MembershipPlan({
    required this.id,
    required this.categoryId,
    required this.name,
    this.description = '',
    this.coverImage = '',
    this.color = 'default',
    this.prices = const {},
    this.priority = 0,
  });

  final int id;
  final int categoryId;
  final String name;
  final String description;
  final String coverImage;
  final String color;
  final Map<String, double> prices;
  final int priority;

  factory MembershipPlan.fromJson(Map<String, dynamic> data) {
    final rawPrices = data['prices'];
    final prices = <String, double>{};
    if (rawPrices is Map) {
      rawPrices.forEach((k, v) {
        prices[k.toString()] = (v as num?)?.toDouble() ?? 0;
      });
    }
    return MembershipPlan(
      id: (data['id'] as num?)?.toInt() ?? 0,
      categoryId: (data['category_id'] as num?)?.toInt() ?? 0,
      name: (data['name'] ?? '').toString(),
      description: (data['description'] ?? '').toString(),
      coverImage: (data['cover_image'] ?? '').toString(),
      color: (data['color'] ?? 'default').toString(),
      prices: prices,
      priority: (data['priority'] as num?)?.toInt() ?? 0,
    );
  }

  double? priceFor(String timeframeId) => prices[timeframeId];
}

class ActiveMembership {
  const ActiveMembership({
    required this.membershipId,
    required this.planId,
    required this.planName,
    this.expiresAt,
    this.daysRemaining = 0,
  });

  final int membershipId;
  final int planId;
  final String planName;
  final String? expiresAt;
  final int daysRemaining;

  factory ActiveMembership.fromJson(Map<String, dynamic> data) {
    return ActiveMembership(
      membershipId: (data['membership_id'] as num?)?.toInt() ?? 0,
      planId: (data['plan_id'] as num?)?.toInt() ?? 0,
      planName: (data['plan_name'] ?? '').toString(),
      expiresAt: data['expires_at']?.toString(),
      daysRemaining: (data['days_remaining'] as num?)?.toInt() ?? 0,
    );
  }
}

class MembershipCategory {
  const MembershipCategory({
    required this.id,
    required this.name,
    this.plans = const [],
    this.timeframes = const [],
    this.activeMembership,
  });

  final int id;
  final String name;
  final List<MembershipPlan> plans;
  final List<MembershipTimeframe> timeframes;
  final ActiveMembership? activeMembership;

  factory MembershipCategory.fromJson(Map<String, dynamic> data) {
    return MembershipCategory(
      id: (data['id'] as num?)?.toInt() ?? 0,
      name: (data['name'] ?? '').toString(),
      plans: (data['plans'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(MembershipPlan.fromJson)
              .toList() ??
          const [],
      timeframes: (data['timeframes'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(MembershipTimeframe.fromJson)
              .toList() ??
          const [],
      activeMembership: data['active_membership'] is Map<String, dynamic>
          ? ActiveMembership.fromJson(data['active_membership'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MemberCatalog {
  const MemberCatalog({
    this.balance = 0,
    this.currency = 'PHP',
    this.categories = const [],
  });

  final double balance;
  final String currency;
  final List<MembershipCategory> categories;

  factory MemberCatalog.fromJson(Map<String, dynamic> data) {
    return MemberCatalog(
      balance: (data['balance'] as num?)?.toDouble() ?? 0,
      currency: (data['currency'] ?? 'PHP').toString(),
      categories: (data['categories'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(MembershipCategory.fromJson)
              .toList() ??
          const [],
    );
  }
}

class MembershipPurchasePreview {
  const MembershipPurchasePreview({
    required this.action,
    required this.amountToPay,
    this.planName = '',
    this.newPrice = 0,
    this.remainingCredit = 0,
    this.oldMembershipId,
    this.oldPlanName,
  });

  final String action;
  final double amountToPay;
  final String planName;
  final double newPrice;
  final double remainingCredit;
  final int? oldMembershipId;
  final String? oldPlanName;

  factory MembershipPurchasePreview.fromJson(Map<String, dynamic> data) {
    return MembershipPurchasePreview(
      action: (data['action'] ?? 'new').toString(),
      amountToPay: (data['amount_to_pay'] as num?)?.toDouble() ?? 0,
      planName: (data['plan_name'] ?? '').toString(),
      newPrice: (data['new_price'] as num?)?.toDouble() ?? 0,
      remainingCredit: (data['remaining_credit'] as num?)?.toDouble() ?? 0,
      oldMembershipId: (data['old_membership_id'] as num?)?.toInt(),
      oldPlanName: data['old_plan_name']?.toString(),
    );
  }
}

class MembershipPurchaseResult {
  const MembershipPurchaseResult({
    required this.ok,
    this.message = '',
    this.preview,
    this.balance,
    this.action,
  });

  final bool ok;
  final String message;
  final MembershipPurchasePreview? preview;
  final double? balance;
  final String? action;
}

class MemberClass {
  const MemberClass({
    required this.id,
    required this.title,
    required this.startsAt,
    required this.endsAt,
    this.coachName = '',
    this.maxCapacity = 0,
    this.enrolled = 0,
    this.spotsLeft = 0,
    this.isEnrolled = false,
    this.enrollmentId,
    this.coverPhoto = '',
    this.exclusiveMode = false,
  });

  final int id;
  final String title;
  final String startsAt;
  final String endsAt;
  final String coachName;
  final int maxCapacity;
  final int enrolled;
  final int spotsLeft;
  final bool isEnrolled;
  final int? enrollmentId;
  final String coverPhoto;
  final bool exclusiveMode;

  factory MemberClass.fromJson(Map<String, dynamic> data) {
    return MemberClass(
      id: (data['id'] as num?)?.toInt() ?? 0,
      title: (data['title'] ?? '').toString(),
      startsAt: (data['starts_at'] ?? '').toString(),
      endsAt: (data['ends_at'] ?? '').toString(),
      coachName: (data['coach_name'] ?? '').toString(),
      maxCapacity: (data['max_capacity'] as num?)?.toInt() ?? 0,
      enrolled: (data['enrolled'] as num?)?.toInt() ?? 0,
      spotsLeft: (data['spots_left'] as num?)?.toInt() ?? 0,
      isEnrolled: data['is_enrolled'] == true,
      enrollmentId: (data['enrollment_id'] as num?)?.toInt(),
      coverPhoto: (data['cover_photo'] ?? '').toString(),
      exclusiveMode: data['exclusive_mode'] == true || data['exclusive_mode'] == 1,
    );
  }

  String get timeLabel {
    if (startsAt.length >= 16) return startsAt.substring(11, 16);
    return startsAt;
  }

  String get endTimeLabel {
    if (endsAt.length >= 16) return endsAt.substring(11, 16);
    return endsAt;
  }

  bool get isFull => maxCapacity > 0 && enrolled >= maxCapacity;
}

class MemberCoach {
  const MemberCoach({
    required this.id,
    this.displayName = '',
    this.avatarUrl = '',
    this.bookingMode = 0,
  });

  final int id;
  final String displayName;
  final String avatarUrl;
  final int bookingMode;

  factory MemberCoach.fromJson(Map<String, dynamic> data) {
    return MemberCoach(
      id: (data['id'] as num?)?.toInt() ?? 0,
      displayName: (data['display_name'] ?? '').toString(),
      avatarUrl: (data['avatar_url'] ?? '').toString(),
      bookingMode: (data['booking_mode'] as num?)?.toInt() ?? 0,
    );
  }
}

class CoachPricingTier {
  const CoachPricingTier({
    required this.id,
    this.name = '',
    this.basePrice = 0,
    this.baseMinutes = 60,
    this.extraPrice = 0,
    this.extraMinutes = 30,
    this.isDefault = false,
  });

  final int id;
  final String name;
  final double basePrice;
  final int baseMinutes;
  final double extraPrice;
  final int extraMinutes;
  final bool isDefault;

  factory CoachPricingTier.fromJson(Map<String, dynamic> data) {
    return CoachPricingTier(
      id: (data['id'] as num?)?.toInt() ?? 0,
      name: (data['name'] ?? '').toString(),
      basePrice: (data['base_price'] as num?)?.toDouble() ?? 0,
      baseMinutes: (data['base_minutes'] as num?)?.toInt() ?? 60,
      extraPrice: (data['extra_price'] as num?)?.toDouble() ?? 0,
      extraMinutes: (data['extra_minutes'] as num?)?.toInt() ?? 30,
      isDefault: data['is_default'] == true || data['is_default'] == 1,
    );
  }
}

class CoachSlot {
  const CoachSlot({
    required this.startMin,
    required this.endMin,
    this.start = '',
    this.end = '',
    this.status = '',
    this.occupied = 0,
    this.capacity = 1,
  });

  final int startMin;
  final int endMin;
  final String start;
  final String end;
  final String status;
  final int occupied;
  final int capacity;

  bool get isFree => status == 'free';

  factory CoachSlot.fromJson(Map<String, dynamic> data) {
    return CoachSlot(
      startMin: (data['start_min'] as num?)?.toInt() ?? 0,
      endMin: (data['end_min'] as num?)?.toInt() ?? 0,
      start: (data['start'] ?? '').toString(),
      end: (data['end'] ?? '').toString(),
      status: (data['status'] ?? '').toString(),
      occupied: (data['occupied'] as num?)?.toInt() ?? 0,
      capacity: (data['capacity'] as num?)?.toInt() ?? 1,
    );
  }
}

class BranchInfo {
  const BranchInfo({
    this.id = 0,
    this.branchName = '',
    this.address = '',
    this.city = '',
    this.province = '',
    this.fullAddress = '',
    this.phone = '',
    this.mapsUrl = '',
    this.logoUrl = '',
    this.coverUrl = '',
    this.gymWebsite = '',
    this.gymSlug = '',
  });

  final int id;
  final String branchName;
  final String address;
  final String city;
  final String province;
  final String fullAddress;
  final String phone;
  final String mapsUrl;
  final String logoUrl;
  final String coverUrl;
  final String gymWebsite;
  final String gymSlug;

  String get displayAddress {
    if (fullAddress.isNotEmpty) return fullAddress;
    return [address, city, province].where((s) => s.isNotEmpty).join(', ');
  }

  factory BranchInfo.fromJson(Map<String, dynamic> data) {
    return BranchInfo(
      id: (data['id'] as num?)?.toInt() ?? 0,
      branchName: (data['branch_name'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
      city: (data['city'] ?? '').toString(),
      province: (data['province'] ?? '').toString(),
      fullAddress: (data['full_address'] ?? '').toString(),
      phone: (data['phone'] ?? '').toString(),
      mapsUrl: (data['maps_url'] ?? '').toString(),
      logoUrl: (data['logo_url'] ?? '').toString(),
      coverUrl: (data['cover_url'] ?? '').toString(),
      gymWebsite: (data['gym_website'] ?? '').toString(),
      gymSlug: (data['gym_slug'] ?? '').toString(),
    );
  }
}

class BranchListItem {
  const BranchListItem({
    required this.id,
    this.name = '',
    this.address = '',
    this.city = '',
    this.province = '',
    this.isCurrent = false,
  });

  final int id;
  final String name;
  final String address;
  final String city;
  final String province;
  final bool isCurrent;

  String get subtitle => [address, city, province].where((s) => s.isNotEmpty).join(', ');

  factory BranchListItem.fromJson(Map<String, dynamic> data) {
    return BranchListItem(
      id: (data['id'] as num?)?.toInt() ?? 0,
      name: (data['name'] ?? '').toString(),
      address: (data['address'] ?? '').toString(),
      city: (data['city'] ?? '').toString(),
      province: (data['province'] ?? '').toString(),
      isCurrent: data['is_current'] == true,
    );
  }
}

class MemberIdType {
  const MemberIdType({
    required this.id,
    required this.label,
    this.requirements = const [],
  });

  final int id;
  final String label;
  final List<IdPhotoRequirement> requirements;

  factory MemberIdType.fromJson(Map<String, dynamic> data) {
    final reqs = data['requirements'];
    return MemberIdType(
      id: (data['id'] as num?)?.toInt() ?? 0,
      label: (data['label'] ?? '').toString(),
      requirements: reqs is List
          ? reqs
              .whereType<Map<String, dynamic>>()
              .map(IdPhotoRequirement.fromJson)
              .toList()
          : const [],
    );
  }
}

class IdPhotoRequirement {
  const IdPhotoRequirement({required this.label});

  final String label;

  factory IdPhotoRequirement.fromJson(Map<String, dynamic> data) {
    return IdPhotoRequirement(label: (data['label'] ?? 'Photo').toString());
  }
}

class MemberIdSubmission {
  const MemberIdSubmission({
    required this.id,
    required this.idTypeId,
    required this.typeLabel,
    required this.status,
    required this.statusLabel,
    this.daysRemaining,
    this.createdAt = '',
    this.rejectionComment = '',
  });

  final int id;
  final int idTypeId;
  final String typeLabel;
  final int status;
  final String statusLabel;
  final int? daysRemaining;
  final String createdAt;
  final String rejectionComment;

  bool get isApproved => status == 1;
  bool get isPending => status == 0;
  bool get isRejected => status == 2;

  factory MemberIdSubmission.fromJson(Map<String, dynamic> data) {
    return MemberIdSubmission(
      id: (data['id'] as num?)?.toInt() ?? 0,
      idTypeId: (data['id_type_id'] as num?)?.toInt() ?? 0,
      typeLabel: (data['type_label'] ?? '').toString(),
      status: (data['status'] as num?)?.toInt() ?? 0,
      statusLabel: (data['status_label'] ?? '').toString(),
      daysRemaining: (data['days_remaining'] as num?)?.toInt(),
      createdAt: (data['created_at'] ?? '').toString(),
      rejectionComment: (data['rejection_comment'] ?? '').toString(),
    );
  }
}

class MemberIdSubmissionBundle {
  const MemberIdSubmissionBundle({
    this.items = const [],
    this.earned = const [],
  });

  final List<MemberIdSubmission> items;
  final List<MemberIdSubmission> earned;

  factory MemberIdSubmissionBundle.fromJson(Map<String, dynamic> data) {
    List<MemberIdSubmission> parseList(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(MemberIdSubmission.fromJson)
          .toList();
    }

    return MemberIdSubmissionBundle(
      items: parseList(data['items']),
      earned: parseList(data['earned']),
    );
  }
}

class UpcomingBooking {
  const UpcomingBooking({
    required this.id,
    required this.title,
    required this.startsAt,
    this.endsAt = '',
    this.coachName = '',
    this.kind = '',
    this.canCancel = false,
  });

  final int id;
  final String title;
  final String startsAt;
  final String endsAt;
  final String coachName;
  final String kind;
  final bool canCancel;

  factory UpcomingBooking.fromJson(Map<String, dynamic> data) {
    return UpcomingBooking(
      id: (data['id'] as num?)?.toInt() ?? 0,
      title: (data['title'] ?? '').toString(),
      startsAt: (data['starts_at'] ?? '').toString(),
      endsAt: (data['ends_at'] ?? '').toString(),
      coachName: (data['coach_name'] ?? '').toString(),
      kind: (data['kind'] ?? '').toString(),
      canCancel: data['can_cancel'] == true,
    );
  }
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
    await _persistCookies(res);
    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      return MemberProfile.fromJson(res['data'] as Map<String, dynamic>);
    }
    return null;
  }

  Future<void> _persistCookies([Map<String, dynamic>? res]) async {
    var header = _client.cookieHeader;
    if (res != null) {
      if (await GymFlavorService.instance.handleUnauthorizedResponse(res)) {
        return;
      }
      final tok = SessionCookies.tokenFromResponse(res);
      if (tok != null) {
        header = SessionCookies.upsert(header, SessionCookies.sessionName, tok);
        _client.cookieHeader = header;
      }
    }
    if (header.isNotEmpty) {
      await GymFlavorService.instance.saveCookies(header);
    }
  }

  Future<ProfileSaveResult> _resultFromResponse(Map<String, dynamic> res) async {
    await _persistCookies(res);
    final message = (res['message'] ?? '').toString();
    if (res['success'] == true) {
      return ProfileSaveResult(ok: true, message: message);
    }
    if (message.toLowerCase().contains('unauthorized')) {
      return const ProfileSaveResult(
        ok: false,
        message: 'Session expired — go back to sign in',
        unauthorized: true,
      );
    }
    return ProfileSaveResult(
      ok: false,
      message: message.isNotEmpty ? message : 'Could not save — try again',
    );
  }

  Future<ProfileSaveResult> saveProfile({
    String? firstName,
    String? lastName,
    String? gender,
    String? dateOfBirth,
    String? phone,
    String? socialInstagram,
    String? socialFacebook,
    Map<String, String>? socialLinks,
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
      if (socialLinks != null) 'social_links_json': jsonEncode(socialLinks),
      if (complete) 'complete': '1',
    };

    final res = avatarBytes != null && avatarBytes.isNotEmpty
        ? await _client.postMultipart(
            ApiClient.mobileApiPath,
            fields,
            files: {'avatar': avatarBytes},
          )
        : await _client.postForm(ApiClient.mobileApiPath, fields);

    return _resultFromResponse(res);
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

  Future<MemberDashboard?> fetchDashboard() async {
    final res = await _client.get(ApiClient.mobileApiPath, query: {
      'action': 'get_member_dashboard',
    });
    await _persistCookies(res);
    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      return MemberDashboard.fromJson(res['data'] as Map<String, dynamic>);
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

  Future<MemberCatalog?> fetchMembershipCatalog() async {
    final res = await _client.get(ApiClient.mobileApiPath, query: {
      'action': 'get_member_memberships',
    });
    await _persistCookies(res);
    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      return MemberCatalog.fromJson(res['data'] as Map<String, dynamic>);
    }
    return null;
  }

  Future<MembershipPurchaseResult> purchaseMembership({
    required int planId,
    required String timeframeId,
    bool dryRun = false,
    bool isUpgrade = false,
    int? oldMembershipId,
  }) async {
    final fields = <String, String>{
      'action': 'member_purchase_membership',
      'plan_id': planId.toString(),
      'timeframe_id': timeframeId,
      if (dryRun) 'dry_run': '1',
      if (isUpgrade) 'is_upgrade': '1',
      if (oldMembershipId != null) 'old_membership_id': oldMembershipId.toString(),
    };
    final res = await _client.postForm(ApiClient.mobileApiPath, fields);
    await _persistCookies(res);
    final message = (res['message'] ?? '').toString();
    if (res['success'] == true) {
      MembershipPurchasePreview? preview;
      final data = res['data'];
      if (data is Map<String, dynamic> && data['upgrade_preview'] is Map) {
        preview = MembershipPurchasePreview.fromJson(
          data['upgrade_preview'] as Map<String, dynamic>,
        );
      }
      double? balance;
      String? action;
      if (data is Map<String, dynamic>) {
        balance = (data['balance'] as num?)?.toDouble();
        action = data['action']?.toString();
      }
      return MembershipPurchaseResult(
        ok: true,
        message: message,
        preview: preview,
        balance: balance,
        action: action,
      );
    }
    return MembershipPurchaseResult(ok: false, message: message.isNotEmpty ? message : 'Purchase failed');
  }

  Future<List<MemberClass>> fetchClasses({required String date}) async {
    final res = await _client.get(ApiClient.mobileApiPath, query: {
      'action': 'get_member_classes',
      'date': date,
    });
    if (res['success'] != true || res['data'] is! Map<String, dynamic>) return [];
    final raw = (res['data'] as Map<String, dynamic>)['classes'];
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map(MemberClass.fromJson).toList();
  }

  Future<({bool ok, String message})> enrollClass(int classId) async {
    final res = await _client.postForm(ApiClient.mobileApiPath, {
      'action': 'member_enroll_class',
      'class_id': classId.toString(),
    });
    return (
      ok: res['success'] == true,
      message: (res['message'] ?? '').toString(),
    );
  }

  Future<({bool ok, String message})> unenrollClass(int enrollmentId) async {
    final res = await _client.postForm(ApiClient.mobileApiPath, {
      'action': 'member_unenroll_class',
      'enrollment_id': enrollmentId.toString(),
    });
    return (
      ok: res['success'] == true,
      message: (res['message'] ?? '').toString(),
    );
  }

  Future<List<UpcomingBooking>> fetchUpcomingBookings() async {
    final res = await _client.get(ApiClient.mobileApiPath, query: {
      'action': 'get_member_upcoming_bookings',
    });
    if (res['success'] != true || res['data'] is! Map<String, dynamic>) return [];
    final raw = (res['data'] as Map<String, dynamic>)['items'];
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map(UpcomingBooking.fromJson).toList();
  }

  Future<List<MemberCoach>> fetchCoaches() async {
    final res = await _client.get(ApiClient.mobileApiPath, query: {
      'action': 'get_member_coaches',
    });
    if (res['success'] != true || res['data'] is! Map<String, dynamic>) return [];
    final raw = (res['data'] as Map<String, dynamic>)['coaches'];
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map(MemberCoach.fromJson).toList();
  }

  Future<List<CoachPricingTier>> fetchCoachPricing(int coachId) async {
    final res = await _client.get(ApiClient.mobileApiPath, query: {
      'action': 'get_member_coach_pricing',
      'coach_id': coachId.toString(),
    });
    if (res['success'] != true || res['data'] is! Map<String, dynamic>) return [];
    final raw = (res['data'] as Map<String, dynamic>)['items'];
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map(CoachPricingTier.fromJson).toList();
  }

  Future<List<CoachSlot>> fetchCoachAvailability({
    required int coachId,
    required String date,
  }) async {
    final res = await _client.get(ApiClient.mobileApiPath, query: {
      'action': 'get_member_coach_availability',
      'coach_id': coachId.toString(),
      'date': date,
    });
    if (res['success'] != true || res['data'] is! Map<String, dynamic>) return [];
    final raw = (res['data'] as Map<String, dynamic>)['slots'];
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map(CoachSlot.fromJson).toList();
  }

  Future<({bool ok, String message, int? bookingId, double? price})> bookAppointment({
    required int coachId,
    required int pricingId,
    required String startsAt,
    required String endsAt,
  }) async {
    final res = await _client.postForm(ApiClient.mobileApiPath, {
      'action': 'member_book_appointment',
      'coach_id': coachId.toString(),
      'pricing_id': pricingId.toString(),
      'starts_at': startsAt,
      'ends_at': endsAt,
    });
    final data = res['data'];
    return (
      ok: res['success'] == true,
      message: (res['message'] ?? '').toString(),
      bookingId: data is Map ? (data['booking_id'] as num?)?.toInt() : null,
      price: data is Map ? (data['calculated_price'] as num?)?.toDouble() : null,
    );
  }

  Future<BranchInfo?> fetchBranchInfo() async {
    final res = await _client.get(ApiClient.mobileApiPath, query: {
      'action': 'get_member_branch_info',
    });
    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      return BranchInfo.fromJson(res['data'] as Map<String, dynamic>);
    }
    return null;
  }

  Future<List<BranchListItem>> fetchBranches({String search = ''}) async {
    final res = await _client.get(ApiClient.mobileApiPath, query: {
      'action': 'get_member_branches',
      if (search.isNotEmpty) 'search': search,
    });
    if (res['success'] != true || res['data'] is! Map<String, dynamic>) return [];
    final raw = (res['data'] as Map<String, dynamic>)['items'];
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map(BranchListItem.fromJson).toList();
  }

  Future<({bool ok, String message, String branchName})> switchBranch(int branchId) async {
    final res = await _client.postForm(ApiClient.mobileApiPath, {
      'action': 'switch_member_branch',
      'branch_id': branchId.toString(),
    });
    final data = res['data'];
    return (
      ok: res['success'] == true,
      message: (res['message'] ?? '').toString(),
      branchName: data is Map ? (data['branch_name'] ?? '').toString() : '',
    );
  }

  Future<List<MemberIdType>> fetchIdTypes() async {
    final res = await _client.get(ApiClient.mobileApiPath, query: {
      'action': 'get_member_id_types',
    });
    if (res['success'] != true || res['data'] is! Map<String, dynamic>) return [];
    final raw = (res['data'] as Map<String, dynamic>)['items'];
    if (raw is! List) return [];
    return raw.whereType<Map<String, dynamic>>().map(MemberIdType.fromJson).toList();
  }

  Future<MemberIdSubmissionBundle?> fetchIdSubmissions() async {
    final res = await _client.get(ApiClient.mobileApiPath, query: {
      'action': 'get_member_id_submissions',
    });
    await _persistCookies(res);
    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      return MemberIdSubmissionBundle.fromJson(res['data'] as Map<String, dynamic>);
    }
    return null;
  }

  Future<({bool ok, String message})> submitId({
    required int idTypeId,
    required List<List<int>> images,
  }) async {
    final files = <({String field, List<int> bytes, String filename})>[];
    for (var i = 0; i < images.length; i++) {
      files.add((
        field: 'id_images[]',
        bytes: images[i],
        filename: 'id_${i + 1}.jpg',
      ));
    }
    final res = await _client.postMultipartFiles(
      ApiClient.mobileApiPath,
      {
        'action': 'member_submit_id',
        'id_type_id': idTypeId.toString(),
      },
      files: files,
    );
    await _persistCookies(res);
    return (
      ok: res['success'] == true,
      message: (res['message'] ?? '').toString(),
    );
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
      topupId: (res['topup_id'] as num?)?.toInt(),
    );
  }

  Future<TopUpStatusResult> pollTopUpStatus(int topupId) async {
    final res = await _client.postForm(ApiClient.mobileApiPath, {
      'action': 'member_wallet_topup_status',
      'topup_id': topupId.toString(),
    });
    return TopUpStatusResult(
      ok: res['success'] == true,
      paid: res['paid'] == true,
      message: (res['message'] ?? '').toString(),
      balance: (res['balance'] as num?)?.toDouble(),
    );
  }

  Future<WalletActionResult> sendVerificationCode() async {
    final res = await _client.postForm(ApiClient.mobileApiPath, {
      'action': 'member_send_verification',
    });
    return WalletActionResult(
      ok: res['success'] == true,
      message: (res['message'] ?? 'Could not send code').toString(),
    );
  }

  Future<WalletActionResult> verifyEmailCode(String code) async {
    final res = await _client.postForm(ApiClient.mobileApiPath, {
      'action': 'member_verify_email',
      'code': code.trim(),
    });
    return WalletActionResult(
      ok: res['success'] == true,
      message: (res['message'] ?? 'Verification failed').toString(),
    );
  }

  Future<WalletActionResult> requestRefund({
    required double amount,
    required String reason,
    required String paymentMethod,
    String payoutDetails = '',
  }) async {
    final res = await _client.postForm(ApiClient.mobileApiPath, {
      'action': 'member_wallet_refund_request',
      'amount': amount.toStringAsFixed(2),
      'reason': reason.trim(),
      'payment_method': paymentMethod,
      'payout_details': payoutDetails.trim(),
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
    this.topupId,
  });

  final bool ok;
  final String message;
  final String? checkoutUrl;
  final int? topupId;
}

class TopUpStatusResult {
  const TopUpStatusResult({
    required this.ok,
    required this.paid,
    required this.message,
    this.balance,
  });

  final bool ok;
  final bool paid;
  final String message;
  final double? balance;
}

class WalletActionResult {
  const WalletActionResult({required this.ok, required this.message});

  final bool ok;
  final String message;
}
