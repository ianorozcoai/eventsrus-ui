import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/app.dart';
import 'app/theme_controller.dart';
import 'core/network/api_client.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/storage/secure_token_storage.dart';
import 'features/auth/data/auth_api.dart';
import 'features/auth/data/google_auth_gateway.dart';
import 'features/auth/state/auth_controller.dart';
import 'features/coordinator/data/coordinator_api.dart';
import 'features/marketplace/data/booking_amendment_api.dart';
import 'features/marketplace/data/booking_api.dart';
import 'features/marketplace/data/calendar_api.dart';
import 'features/marketplace/data/conversation_api.dart';
import 'features/marketplace/data/lead_api.dart';
import 'features/marketplace/data/notification_api.dart';
import 'features/marketplace/data/quotation_api.dart';
import 'features/marketplace/data/vendor_directory_api.dart';
import 'features/marketplace/data/vendor_package_api.dart';
import 'features/marketplace/data/vendor_package_group_api.dart';
import 'features/marketplace/data/vendor_package_image_api.dart';
import 'features/notifications/data/device_token_api.dart';
import 'features/planner/data/event_api.dart';
import 'features/profile/data/user_api.dart';
import 'features/reviews/data/review_api.dart';
import 'features/subscription/data/subscription_api.dart';
import 'features/support/data/support_ticket_api.dart';
import 'features/vendor/data/google_calendar_api.dart';
import 'features/vendor/data/vendor_api.dart';
import 'features/vendor/data/vendor_dashboard_api.dart';
import 'features/vendor/data/vendor_gallery_api.dart';
import 'features/vendor/data/vendor_image_tag_api.dart';
import 'features/vendor/data/vendor_legal_document_api.dart';
import 'features/vendor/data/vendor_payment_method_api.dart';
import 'features/vendor/data/vendor_referral_api.dart';
import 'features/vendor/data/vendor_settings_api.dart';
import 'features/vendor/data/vendor_social_media_api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GoogleAuthGateway.instance.ensureInitialized();
  // No-ops until google-services.json is in place - see
  // PushNotificationService's own doc comment.
  await PushNotificationService.instance.initialize();

  final themeController = ThemeController();
  await themeController.load();

  final storage = SecureTokenStorage();
  final apiClient = ApiClient(storage: storage);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeController>.value(value: themeController),
        Provider<VendorApi>(create: (_) => VendorApi(apiClient)),
        Provider<SubscriptionApi>(create: (_) => SubscriptionApi(apiClient)),
        Provider<EventApi>(create: (_) => EventApi(apiClient)),
        Provider<ConversationApi>(create: (_) => ConversationApi(apiClient)),
        Provider<QuotationApi>(create: (_) => QuotationApi(apiClient)),
        Provider<BookingApi>(create: (_) => BookingApi(apiClient)),
        Provider<BookingAmendmentApi>(create: (_) => BookingAmendmentApi(apiClient)),
        Provider<VendorPackageApi>(create: (_) => VendorPackageApi(apiClient)),
        Provider<VendorPackageGroupApi>(create: (_) => VendorPackageGroupApi(apiClient)),
        Provider<VendorPackageImageApi>(create: (_) => VendorPackageImageApi(apiClient)),
        Provider<NotificationApi>(create: (_) => NotificationApi(apiClient)),
        Provider<CalendarApi>(create: (_) => CalendarApi(apiClient)),
        Provider<GoogleCalendarApi>(create: (_) => GoogleCalendarApi(apiClient)),
        Provider<LeadApi>(create: (_) => LeadApi(apiClient)),
        Provider<VendorDirectoryApi>(create: (_) => VendorDirectoryApi(apiClient)),
        Provider<VendorSettingsApi>(create: (_) => VendorSettingsApi(apiClient)),
        Provider<VendorDashboardApi>(create: (_) => VendorDashboardApi(apiClient)),
        Provider<VendorSocialMediaApi>(create: (_) => VendorSocialMediaApi(apiClient)),
        Provider<VendorPaymentMethodApi>(create: (_) => VendorPaymentMethodApi(apiClient)),
        Provider<VendorReferralApi>(create: (_) => VendorReferralApi(apiClient)),
        Provider<VendorGalleryApi>(create: (_) => VendorGalleryApi(apiClient)),
        Provider<VendorImageTagApi>(create: (_) => VendorImageTagApi(apiClient)),
        Provider<VendorLegalDocumentApi>(create: (_) => VendorLegalDocumentApi(apiClient)),
        Provider<DeviceTokenApi>(create: (_) => DeviceTokenApi(apiClient)),
        Provider<UserApi>(create: (_) => UserApi(apiClient)),
        Provider<SupportTicketApi>(create: (_) => SupportTicketApi(apiClient)),
        Provider<ReviewApi>(create: (_) => ReviewApi(apiClient)),
        Provider<CoordinatorApi>(create: (_) => CoordinatorApi(apiClient)),
        ChangeNotifierProvider(
          create: (_) => AuthController(
            authApi: AuthApi(apiClient),
            storage: storage,
            deviceTokenApi: DeviceTokenApi(apiClient),
          ),
        ),
      ],
      child: const EventsRusApp(),
    ),
  );
}
