import 'package:flutter/material.dart';

enum SocialPlatform { facebook, instagram, whatsapp, other }

extension SocialPlatformX on SocialPlatform {
  String get key => name;

  String get label => switch (this) {
        SocialPlatform.facebook => 'Facebook',
        SocialPlatform.instagram => 'Instagram',
        SocialPlatform.whatsapp => 'WhatsApp',
        SocialPlatform.other => 'Other',
      };

  IconData get icon => switch (this) {
        SocialPlatform.facebook => Icons.facebook,
        SocialPlatform.instagram => Icons.alternate_email,
        SocialPlatform.whatsapp => Icons.chat_outlined,
        SocialPlatform.other => Icons.link,
      };
}

SocialPlatform socialPlatformFromKey(String key) {
  return SocialPlatform.values.firstWhere(
    (p) => p.key == key,
    orElse: () => SocialPlatform.other,
  );
}
