import 'package:flutter/material.dart';

/// Mirrors eventsrus-backend's {@code com.backend.eventsrus.enums.SocialMediaPlatform}.
enum SocialMediaPlatform { facebook, instagram, x, tiktok, youtube }

extension SocialMediaPlatformApi on SocialMediaPlatform {
  String toApi() {
    switch (this) {
      case SocialMediaPlatform.facebook:
        return 'FACEBOOK';
      case SocialMediaPlatform.instagram:
        return 'INSTAGRAM';
      case SocialMediaPlatform.x:
        return 'X';
      case SocialMediaPlatform.tiktok:
        return 'TIKTOK';
      case SocialMediaPlatform.youtube:
        return 'YOUTUBE';
    }
  }

  String get label {
    switch (this) {
      case SocialMediaPlatform.facebook:
        return 'Facebook';
      case SocialMediaPlatform.instagram:
        return 'Instagram';
      case SocialMediaPlatform.x:
        return 'X';
      case SocialMediaPlatform.tiktok:
        return 'TikTok';
      case SocialMediaPlatform.youtube:
        return 'YouTube';
    }
  }

  IconData get icon {
    switch (this) {
      case SocialMediaPlatform.facebook:
        return Icons.facebook;
      case SocialMediaPlatform.instagram:
        return Icons.camera_alt_outlined;
      case SocialMediaPlatform.x:
        return Icons.close;
      case SocialMediaPlatform.tiktok:
        return Icons.music_note;
      case SocialMediaPlatform.youtube:
        return Icons.play_circle_outline;
    }
  }

  static SocialMediaPlatform fromApi(String value) {
    switch (value) {
      case 'FACEBOOK':
        return SocialMediaPlatform.facebook;
      case 'INSTAGRAM':
        return SocialMediaPlatform.instagram;
      case 'X':
        return SocialMediaPlatform.x;
      case 'TIKTOK':
        return SocialMediaPlatform.tiktok;
      case 'YOUTUBE':
        return SocialMediaPlatform.youtube;
      default:
        throw FormatException('Unknown social media platform: $value');
    }
  }
}
