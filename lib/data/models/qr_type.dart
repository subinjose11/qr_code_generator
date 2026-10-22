import 'package:flutter/material.dart';

enum QrCategory {
  web,
  contact,
  social,
  access,
  payment,
  utility,
}

enum QrType {
  url,
  multiUrl,
  vCard,
  email,
  phone,
  sms,
  whatsapp,
  telegram,
  instagram,
  facebook,
  twitter,
  youtube,
  linkedin,
  tiktok,
  spotify,
  wifi,
  map,
  text,
  upi,
  calendar,
}

extension QrCategoryExtension on QrCategory {
  String get title {
    switch (this) {
      case QrCategory.web:
        return 'Web & Links';
      case QrCategory.contact:
        return 'Contacts & Business';
      case QrCategory.social:
        return 'Social & Messaging';
      case QrCategory.access:
        return 'Location & Access';
      case QrCategory.payment:
        return 'Payments & Finance';
      case QrCategory.utility:
        return 'Utilities & Events';
    }
  }

  IconData get icon {
    switch (this) {
      case QrCategory.web:
        return Icons.link;
      case QrCategory.contact:
        return Icons.contact_phone_outlined;
      case QrCategory.social:
        return Icons.share_outlined;
      case QrCategory.access:
        return Icons.wifi;
      case QrCategory.payment:
        return Icons.account_balance_wallet_outlined;
      case QrCategory.utility:
        return Icons.widgets_outlined;
    }
  }
}

extension QrTypeExtension on QrType {
  String get title {
    switch (this) {
      case QrType.url:
        return 'Website / URL';
      case QrType.multiUrl:
        return 'Multi-Link Hub';
      case QrType.vCard:
        return 'vCard Contact';
      case QrType.email:
        return 'E-mail';
      case QrType.phone:
        return 'Phone Call';
      case QrType.sms:
        return 'SMS Message';
      case QrType.whatsapp:
        return 'WhatsApp Chat';
      case QrType.telegram:
        return 'Telegram';
      case QrType.instagram:
        return 'Instagram';
      case QrType.facebook:
        return 'Facebook';
      case QrType.twitter:
        return 'X (Twitter)';
      case QrType.youtube:
        return 'YouTube';
      case QrType.linkedin:
        return 'LinkedIn';
      case QrType.tiktok:
        return 'TikTok';
      case QrType.spotify:
        return 'Spotify';
      case QrType.wifi:
        return 'Wi-Fi Network';
      case QrType.map:
        return 'Map Location';
      case QrType.text:
        return 'Plain Text';
      case QrType.upi:
        return 'UPI Payment';
      case QrType.calendar:
        return 'Calendar Event';
    }
  }

  String get subtitle {
    switch (this) {
      case QrType.url:
        return 'Direct link to any website or page';
      case QrType.multiUrl:
        return 'Bundle multiple links into one QR';
      case QrType.vCard:
        return 'Full business card with 1-tap save';
      case QrType.email:
        return 'Pre-filled recipient, subject, and body';
      case QrType.phone:
        return 'Instant phone dialer trigger';
      case QrType.sms:
        return 'Pre-written text message to a number';
      case QrType.whatsapp:
        return 'Direct chat link with optional message';
      case QrType.telegram:
        return 'Link to username or channel';
      case QrType.instagram:
        return 'Profile, post, or reels link';
      case QrType.facebook:
        return 'Page, group, or profile link';
      case QrType.twitter:
        return 'Profile or post link';
      case QrType.youtube:
        return 'Video, playlist, or channel URL';
      case QrType.linkedin:
        return 'Professional profile or company page';
      case QrType.tiktok:
        return 'Creator profile or video link';
      case QrType.spotify:
        return 'Track, album, or playlist link';
      case QrType.wifi:
        return 'Instant network connect without typing';
      case QrType.map:
        return 'Exact GPS coordinates or address';
      case QrType.text:
        return 'Notes, instructions, or raw codes';
      case QrType.upi:
        return 'Instant digital payment request';
      case QrType.calendar:
        return 'Event with time, place, and notes';
    }
  }

  QrCategory get category {
    switch (this) {
      case QrType.url:
      case QrType.multiUrl:
        return QrCategory.web;
      case QrType.vCard:
      case QrType.email:
      case QrType.phone:
      case QrType.sms:
        return QrCategory.contact;
      case QrType.whatsapp:
      case QrType.telegram:
      case QrType.instagram:
      case QrType.facebook:
      case QrType.twitter:
      case QrType.youtube:
      case QrType.linkedin:
      case QrType.tiktok:
      case QrType.spotify:
        return QrCategory.social;
      case QrType.wifi:
      case QrType.map:
        return QrCategory.access;
      case QrType.upi:
        return QrCategory.payment;
      case QrType.text:
      case QrType.calendar:
        return QrCategory.utility;
    }
  }

  IconData get icon {
    switch (this) {
      case QrType.url:
        return Icons.link;
      case QrType.multiUrl:
        return Icons.hub_outlined;
      case QrType.vCard:
        return Icons.badge_outlined;
      case QrType.email:
        return Icons.email_outlined;
      case QrType.phone:
        return Icons.phone_outlined;
      case QrType.sms:
        return Icons.sms_outlined;
      case QrType.whatsapp:
        return Icons.chat_bubble_outline;
      case QrType.telegram:
        return Icons.send_outlined;
      case QrType.instagram:
        return Icons.camera_alt_outlined;
      case QrType.facebook:
        return Icons.thumb_up_outlined;
      case QrType.twitter:
        return Icons.tag;
      case QrType.youtube:
        return Icons.play_circle_outline;
      case QrType.linkedin:
        return Icons.business_center_outlined;
      case QrType.tiktok:
        return Icons.music_video_outlined;
      case QrType.spotify:
        return Icons.music_note_outlined;
      case QrType.wifi:
        return Icons.wifi;
      case QrType.map:
        return Icons.location_on_outlined;
      case QrType.text:
        return Icons.text_snippet_outlined;
      case QrType.upi:
        return Icons.payments_outlined;
      case QrType.calendar:
        return Icons.event_outlined;
    }
  }

  Color get brandColor {
    switch (this) {
      case QrType.url:
      case QrType.multiUrl:
        return const Color(0xFF2563EB);
      case QrType.vCard:
        return const Color(0xFF0D9488);
      case QrType.email:
        return const Color(0xFFEA4335);
      case QrType.phone:
        return const Color(0xFF10B981);
      case QrType.sms:
        return const Color(0xFF0284C7);
      case QrType.whatsapp:
        return const Color(0xFF25D366);
      case QrType.telegram:
        return const Color(0xFF0088CC);
      case QrType.instagram:
        return const Color(0xFFE1306C);
      case QrType.facebook:
        return const Color(0xFF1877F2);
      case QrType.twitter:
        return const Color(0xFF1DA1F2);
      case QrType.youtube:
        return const Color(0xFFFF0000);
      case QrType.linkedin:
        return const Color(0xFF0A66C2);
      case QrType.tiktok:
        return const Color(0xFF000000);
      case QrType.spotify:
        return const Color(0xFF1DB954);
      case QrType.wifi:
        return const Color(0xFF6366F1);
      case QrType.map:
        return const Color(0xFFF59E0B);
      case QrType.text:
        return const Color(0xFF64748B);
      case QrType.upi:
        return const Color(0xFF059669);
      case QrType.calendar:
        return const Color(0xFF8B5CF6);
    }
  }
}
