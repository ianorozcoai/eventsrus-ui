import 'package:eventsrus_ui/features/vendor/data/models/social_media_platform.dart';
import 'package:eventsrus_ui/features/vendor/data/models/vendor_social_media_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('VendorSocialMediaLink.fromJson parses a full response', () {
    final link = VendorSocialMediaLink.fromJson({
      'id': 5,
      'platform': 'INSTAGRAM',
      'url': 'https://instagram.com/eventsrus',
    });

    expect(link.id, 5);
    expect(link.platform, SocialMediaPlatform.instagram);
    expect(link.url, 'https://instagram.com/eventsrus');
  });

  test('every SocialMediaPlatform string from the backend parses correctly', () {
    expect(SocialMediaPlatformApi.fromApi('FACEBOOK'), SocialMediaPlatform.facebook);
    expect(SocialMediaPlatformApi.fromApi('INSTAGRAM'), SocialMediaPlatform.instagram);
    expect(SocialMediaPlatformApi.fromApi('X'), SocialMediaPlatform.x);
    expect(SocialMediaPlatformApi.fromApi('TIKTOK'), SocialMediaPlatform.tiktok);
    expect(SocialMediaPlatformApi.fromApi('YOUTUBE'), SocialMediaPlatform.youtube);
  });

  test('unknown platform string throws', () {
    expect(() => SocialMediaPlatformApi.fromApi('SNAPCHAT'), throwsFormatException);
  });

  test('every SocialMediaPlatform round-trips through toApi/fromApi', () {
    for (final platform in SocialMediaPlatform.values) {
      expect(SocialMediaPlatformApi.fromApi(platform.toApi()), platform);
    }
  });
}
