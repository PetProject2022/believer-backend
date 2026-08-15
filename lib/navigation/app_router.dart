import 'package:flutter/material.dart';

import '../features/business_moderation/business_moderation_screen.dart';
import '../features/mosque_moderation/mosque_moderation_screen.dart';
import '../features/super_admin/super_admin_panel_screen.dart';
import '../features/business_registration/business_registration_flow_screen.dart';
import '../features/business_registration/business_registration_models.dart';
import '../models/review.dart';
import '../models/mosque_model.dart';
import 'mosque_detail_route_args.dart';
import '../screens/event_detail_screen.dart';
import '../screens/event_search_listing.dart';
import '../screens/home_page_1.dart';
import '../screens/business_listing.dart';
import '../screens/business_leave_review.dart';
import '../screens/business_review_screen.dart';
import '../screens/leave_review.dart';
import '../screens/location_setup_screen.dart';
import '../screens/forgot_password_screen.dart';
import '../screens/login_screen.dart';
import '../screens/map_screen.dart';
import '../screens/mosque_admin_add_screen.dart';
import '../screens/mosque_admin_edit_screen.dart';
import '../screens/mosque_broadcast.dart';
import '../screens/mosque_listing.dart';
import '../screens/mosque_search_screen.dart';
import '../screens/mosque_page.dart';
import '../screens/mosque_notification_settings.dart';
import '../screens/owned_mosques_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/profile_settings_screen.dart';
import '../screens/prayer_notifications_settings_page.dart';
import '../screens/reset_password_screen.dart';
import '../screens/review_confirmation.dart';
import '../screens/review_screen.dart';
import '../screens/services_search.dart';
import '../screens/settings_detail_screens.dart';
import '../screens/sort_filter_mosque.dart';
import '../screens/signup_screen.dart';
import 'app_routes.dart';
import 'package:believer/features/khutbah/screens/khutbah_record_screen.dart';


class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.onboarding:
        return MaterialPageRoute<void>(
          builder: (_) => const OnboardingScreen(),
        );
      case AppRoutes.locationSetup:
        final args = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => LocationSetupScreen(
            flowArgs: args is LocationSetupFlowArgs
                ? args
                : const LocationSetupFlowArgs(nextRoute: AppRoutes.home),
          ),
        );
      case AppRoutes.locationSetupManual:
        final args = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => ManualLocationSetupScreen(
            flowArgs: args is LocationSetupFlowArgs
                ? args
                : const LocationSetupFlowArgs(nextRoute: AppRoutes.home),
          ),
        );
      case AppRoutes.locationSetupMap:
        final args = settings.arguments;
        if (args is LocationSetupMapArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => LocationSetupMapScreen(flowArgs: args),
          );
        }
        return MaterialPageRoute<void>(
          builder: (_) => const _UnknownRouteScreen(
            routeName: AppRoutes.locationSetupMap,
          ),
        );
      case AppRoutes.locationSetupAsar:
        final args = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => LocationSetupAsarScreen(
            flowArgs: args is LocationSetupFlowArgs
                ? args
                : const LocationSetupFlowArgs(nextRoute: AppRoutes.home),
          ),
        );
      case AppRoutes.login:
        final args = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => LoginScreen(
            initialAccountType: args is LoginScreenRouteArgs
                ? args.initialAccountType
                : LoginAccountType.user,
          ),
        );
      case AppRoutes.forgotPassword:
        return MaterialPageRoute<void>(
          builder: (_) => const ForgotPasswordScreen(),
        );
      case AppRoutes.resetPassword:
        return MaterialPageRoute<void>(
          builder: (_) => const ResetPasswordScreen(),
        );
      case AppRoutes.signup:
        final args = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => SignUpScreen(
            initialAccountType: args is SignUpScreenRouteArgs
                ? args.initialAccountType
                : SignupAccountType.user,
          ),
        );
      case AppRoutes.home:
        return MaterialPageRoute<void>(builder: (_) => const HomePage1());
      case AppRoutes.notifications:
        return MaterialPageRoute<void>(
            builder: (_) => const NotificationsScreen());
      case AppRoutes.prayerSettings:
        return MaterialPageRoute<void>(
          builder: (_) => const PrayerNotificationsSettingsPage(),
        );
      case AppRoutes.profileSettings:
        return MaterialPageRoute<void>(
          builder: (_) => const ProfileSettingsScreen(),
        );
      case AppRoutes.settingsAbout:
        return MaterialPageRoute<void>(
          builder: (_) => const SettingsAboutScreen(),
        );
      case AppRoutes.settingsPrivacy:
        return MaterialPageRoute<void>(
          builder: (_) => const SettingsPrivacyScreen(),
        );
      case AppRoutes.settingsFaq:
        return MaterialPageRoute<void>(
          builder: (_) => const SettingsFaqScreen(),
        );
      case AppRoutes.settingsRateUs:
        return MaterialPageRoute<void>(
          builder: (_) => const SettingsRateUsScreen(),
        );
      case AppRoutes.settingsSupport:
        return MaterialPageRoute<void>(
          builder: (_) => const SettingsSupportScreen(),
        );
      case AppRoutes.settingsSuggestMosque:
        return MaterialPageRoute<void>(
          builder: (_) => const SettingsSuggestMosqueScreen(),
        );
      case AppRoutes.settingsDeleteAccount:
        return MaterialPageRoute<void>(
          builder: (_) => const SettingsDeleteAccountScreen(),
        );
      case AppRoutes.map:
        return MaterialPageRoute<void>(builder: (_) => const MapScreen());
      case AppRoutes.mosqueSearch:
        return MaterialPageRoute<void>(
          builder: (_) => const MosqueSearchScreen(),
        );
      case AppRoutes.mosquesAndEvents:
        final args = settings.arguments;
        final mosques =
            args is List<MosqueModel> ? args : const <MosqueModel>[];
        return MaterialPageRoute<void>(
          builder: (_) => MosqueListing(initialMosques: mosques),
        );
      case AppRoutes.businessListing:
        final args = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => BusinessListing(
            args: args is BusinessListingRouteArgs
                ? args
                : const BusinessListingRouteArgs(),
          ),
        );
      case AppRoutes.services:
        return MaterialPageRoute<void>(builder: (_) => const ServicesSearch());
      case AppRoutes.mosqueDetail:
        final args = settings.arguments;
        if (args is MosqueDetailRouteArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => MosquePage(args: args),
          );
        }
        return MaterialPageRoute<void>(
          builder: (_) => const _UnknownRouteScreen(
            routeName: AppRoutes.mosqueDetail,
          ),
        );
      case AppRoutes.reviews:
        final args = settings.arguments;
        if (args is BusinessReviewScreenRouteArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => BusinessReviewScreen(
              reviews: args.initialReviews,
              businessListingId: args.businessListingId,
              businessName: args.businessName,
            ),
          );
        }
        if (args is ReviewScreenRouteArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => ReviewScreen(
              reviews: args.initialReviews,
              mosqueId: args.mosqueId,
              mosqueName: args.mosqueName,
            ),
          );
        }
        final reviews = args is List<Review> ? args : const <Review>[];
        return MaterialPageRoute<void>(
          builder: (_) => ReviewScreen(reviews: reviews),
        );
      case AppRoutes.nearbyEvents:
        final args = settings.arguments;
        if (args is EventSearchListingRouteArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => EventSearchListing(args: args),
          );
        }
        final mosques =
            args is List<MosqueModel> ? args : const <MosqueModel>[];
        return MaterialPageRoute<void>(
          builder: (_) => EventSearchListing(
            args: EventSearchListingRouteArgs(initialEvents: mosques),
          ),
        );
      case AppRoutes.reviewConfirmation:
        return MaterialPageRoute<void>(
          builder: (_) => const ReviewConfirmation(),
        );
      case AppRoutes.eventDetail:
        final args = settings.arguments;
        if (args is EventDetailRouteArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => EventDetailScreen(args: args),
          );
        }
        return MaterialPageRoute<void>(
          builder: (_) => const _UnknownRouteScreen(
            routeName: AppRoutes.eventDetail,
          ),
        );
      case AppRoutes.leaveReview:
        final args = settings.arguments;
        if (args is BusinessLeaveReviewRouteArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => BusinessLeaveReview(
              businessListingId: args.businessListingId,
              businessName: args.businessName,
            ),
          );
        }
        if (args is LeaveReviewRouteArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => LeaveReview(
              mosqueId: args.mosqueId,
              mosqueName: args.mosqueName,
            ),
          );
        }
        return MaterialPageRoute<void>(
          builder: (_) => const LeaveReview(),
        );
      case AppRoutes.mosqueBroadcast:
        final args = settings.arguments;
        if (args is MosqueBroadcastRouteArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => MosqueBroadcast(args: args),
          );
        }
        return MaterialPageRoute<void>(
          builder: (_) => const MosqueBroadcast(),
        );
      case AppRoutes.mosqueNotificationSettings:
        final args = settings.arguments;
        if (args is MosqueNotificationSettingsRouteArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => MosqueNotificationSettings(
              mosqueId: args.mosqueId,
              mosqueName: args.mosqueName,
            ),
          );
        }
        return MaterialPageRoute<void>(
          builder: (_) => const MosqueNotificationSettings(),
        );
      case AppRoutes.sortFilterMosque:
        final args = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => SortFilterMosque(
            initialFilters: args is Map<String, dynamic> ? args : null,
          ),
          fullscreenDialog: true,
        );
      case AppRoutes.adminAddMosque:
        return MaterialPageRoute<void>(
          builder: (_) => const MosqueAdminAddScreen(),
        );
      case AppRoutes.adminEditMosque:
        final args = settings.arguments;
        if (args is MosqueAdminEditRouteArgs) {
          return MaterialPageRoute<void>(
            builder: (_) => MosqueAdminEditScreen(args: args),
          );
        }
        return MaterialPageRoute<void>(
          builder: (_) => const _UnknownRouteScreen(
            routeName: AppRoutes.adminEditMosque,
          ),
        );
      case AppRoutes.ownedMosques:
        final args = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => OwnedMosquesScreen(
            routeArgs: args is OwnedMosquesRouteArgs
                ? args
                : const OwnedMosquesRouteArgs(),
          ),
        );
      case AppRoutes.businessModeration:
        return MaterialPageRoute<void>(
          builder: (_) => const BusinessModerationScreen(),
        );
      case AppRoutes.mosqueModeration:
        return MaterialPageRoute<void>(
          builder: (_) => const MosqueModerationScreen(),
        );
      case AppRoutes.superAdminPanel:
        return MaterialPageRoute<void>(
          builder: (_) => const SuperAdminPanelScreen(),
        );
      case AppRoutes.businessRegistrationIntro:
        final args = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => BusinessRegistrationFlowScreen(
            step: BusinessRegistrationFlowStep.intro,
            routeArgs: args is BusinessRegistrationFlowRouteArgs
                ? args
                : const BusinessRegistrationFlowRouteArgs(),
          ),
        );
      case AppRoutes.businessRegistrationBasicDetails:
        final args = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => BusinessRegistrationFlowScreen(
            step: BusinessRegistrationFlowStep.basicDetails,
            routeArgs: args is BusinessRegistrationFlowRouteArgs
                ? args
                : const BusinessRegistrationFlowRouteArgs(),
          ),
        );
      case AppRoutes.businessRegistrationContactLocation:
        final args = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => BusinessRegistrationFlowScreen(
            step: BusinessRegistrationFlowStep.contactAndLocation,
            routeArgs: args is BusinessRegistrationFlowRouteArgs
                ? args
                : const BusinessRegistrationFlowRouteArgs(),
          ),
        );
      case AppRoutes.businessRegistrationUnderReview:
        final args = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => BusinessRegistrationFlowScreen(
            step: BusinessRegistrationFlowStep.underReview,
            routeArgs: args is BusinessRegistrationFlowRouteArgs
                ? args
                : const BusinessRegistrationFlowRouteArgs(),
          ),
        );
      case AppRoutes.businessRegistrationLive:
        final args = settings.arguments;
        return MaterialPageRoute<void>(
          builder: (_) => BusinessRegistrationFlowScreen(
            step: BusinessRegistrationFlowStep.live,
            routeArgs: args is BusinessRegistrationFlowRouteArgs
                ? args
                : const BusinessRegistrationFlowRouteArgs(),
          ),
        );
        case AppRoutes.khutbahRecord:
  return MaterialPageRoute<void>(
    builder: (_) => const KhutbahRecordScreen(),
  );
      default:
        return MaterialPageRoute<void>(
          builder: (_) => _UnknownRouteScreen(routeName: settings.name),
        );
    }
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen({required this.routeName});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    final name = routeName ?? '<null>';
    return Scaffold(
      appBar: AppBar(title: const Text('Route not found')),
      body: Center(
        child: Text(
          'No route is configured for: $name',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
