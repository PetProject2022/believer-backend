class AppRoutes {
  static const String onboarding = '/onboarding';
  static const String locationSetup = '/location-setup';
  static const String locationSetupManual = '/location-setup-manual';
  static const String locationSetupMap = '/location-setup-map';
  static const String locationSetupAsar = '/location-setup-asar';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String notifications = '/notifications';
  static const String prayerSettings = '/prayer-settings';
  static const String profileSettings = '/profile-settings';
  static const String settingsAbout = '/settings-about';
  static const String settingsPrivacy = '/settings-privacy';
  static const String settingsFaq = '/settings-faq';
  static const String settingsRateUs = '/settings-rate-us';
  static const String settingsSupport = '/settings-support';
  static const String settingsSuggestMosque = '/settings-suggest-mosque';
  static const String settingsDeleteAccount = '/settings-delete-account';
  static const String map = '/map';

  static const String mosqueSearch = '/mosque-search';
  static const String mosquesAndEvents = '/mosques-events';
  static const String businessListing = '/business-listing';
  static const String services = '/services';
  static const String mosqueDetail = '/mosque-detail';
  static const String reviews = '/reviews';
  static const String nearbyEvents = '/nearby_events';
  static const String reviewConfirmation = '/review-confirmation';
  static const String eventDetail = '/event-detail';
  static const String leaveReview = '/leave-review';
  static const String mosqueBroadcast = '/mosque-broadcast';
  static const String mosqueNotificationSettings =
      '/mosque-notification-settings';
  static const String sortFilterMosque = '/sort-filter-mosque';
  static const String adminAddMosque = '/admin-add-mosque';
  static const String adminEditMosque = '/admin-edit-mosque';
  static const String ownedMosques = '/owned-mosques';
  static const String businessRegistrationIntro = '/business-registration';
  static const String businessModeration = '/business-moderation';
  static const String mosqueModeration = '/mosque-moderation';
  static const String superAdminPanel = '/super-admin-panel';
  static const String businessRegistrationBasicDetails =
      '/business-registration/basic-details';
  static const String businessRegistrationContactLocation =
      '/business-registration/contact-location';
  static const String businessRegistrationUnderReview =
      '/business-registration/under-review';
  static const String businessRegistrationLive = '/business-registration/live';
  static const String khutbahRecord = '/khutbah-record';

  static bool isBusinessRegistrationRoute(String? routeName) {
    switch (routeName) {
      case businessRegistrationIntro:
      case businessRegistrationBasicDetails:
      case businessRegistrationContactLocation:
      case businessRegistrationUnderReview:
      case businessRegistrationLive:
        return true;
      default:
        return false;
    }
  }
}
