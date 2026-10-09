import 'social_media_platform.dart';

/// Mirrors eventsrus-backend's {@code VendorSocialMediaLinkResponse}.
class VendorSocialMediaLink {
  final int id;
  final SocialMediaPlatform platform;
  final String url;

  const VendorSocialMediaLink({
    required this.id,
    required this.platform,
    required this.url,
  });

  factory VendorSocialMediaLink.fromJson(Map<String, dynamic> json) => VendorSocialMediaLink(
        id: json['id'] as int,
        platform: SocialMediaPlatformApi.fromApi(json['platform'] as String),
        url: json['url'] as String,
      );
}
