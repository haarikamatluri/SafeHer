import 'package:flutter/material.dart';

import '../screens/ai_safety_screen.dart';
import '../screens/checkin_screen.dart';
import '../screens/contacts_screen.dart';
import '../screens/home_screen.dart';
import '../screens/incident_history_screen.dart';
import '../screens/journey/checkin_prompt_screen.dart';
import '../screens/journey/journey_active_screen.dart';
import '../screens/journey/journey_home_screen.dart';
import '../screens/journey/journey_summary_screen.dart';
import '../screens/journey/missed_checkin_screen.dart';
import '../screens/journey/plan_journey_screen.dart';
import '../screens/journey/route_preview_screen.dart';
import '../screens/location_sharing_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/resilience/auto_sms_screen.dart';
import '../screens/resilience/auto_sync_screen.dart';
import '../screens/resilience/battery_alerts_screen.dart';
import '../screens/resilience/device_status_screen.dart';
import '../screens/resilience/local_backup_screen.dart';
import '../screens/resilience/offline_mode_screen.dart';
import '../screens/resilience/resilience_home_screen.dart';
import '../screens/safe_haven/community_reports_screen.dart';
import '../screens/safe_haven/emergency_services_screen.dart';
import '../screens/safe_haven/nearby_places_screen.dart';
import '../screens/safe_haven/place_details_screen.dart';
import '../screens/safe_haven/route_to_safe_place_screen.dart';
import '../screens/safe_haven/safe_haven_filters_screen.dart';
import '../screens/safe_haven/safe_haven_home_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/sos_activation_screen.dart';
import '../screens/sos_sending_screen.dart';
import '../screens/sos_sent_screen.dart';
import '../screens/splash_screen.dart';
import '../utils/constants.dart';
import 'routes.dart';
import 'theme.dart';

class SafeHerApp extends StatelessWidget {
  const SafeHerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: SafeHerTheme.lightTheme,
      initialRoute: AppRoutes.splash,
      routes: {
        // Core existing SafeHer screens
        AppRoutes.splash: (context) => const SplashScreen(),
        AppRoutes.onboarding: (context) => const OnboardingScreen(),
        AppRoutes.home: (context) => const HomeScreen(),
        AppRoutes.locationSharing: (context) => const LocationSharingScreen(),
        AppRoutes.contacts: (context) => const ContactsScreen(),
        AppRoutes.sosActivation: (context) => const SosActivationScreen(),
        AppRoutes.sosSending: (context) => const SosSendingScreen(),
        AppRoutes.sosSent: (context) => const SosSentScreen(),
        AppRoutes.incident: (context) => const SosSentScreen(),
        AppRoutes.checkin: (context) => const CheckinScreen(),
        AppRoutes.incidentHistory: (context) => const IncidentHistoryScreen(),
        AppRoutes.settings: (context) => const SettingsScreen(),
        AppRoutes.profile: (context) => const SettingsScreen(),
        AppRoutes.aiSafety: (context) => const AiSafetyScreen(),

        // Feature A — AI Journey Guardian
        AppRoutes.journeyHome: (context) => const JourneyHomeScreen(),
        AppRoutes.planJourney: (context) => const PlanJourneyScreen(),
        AppRoutes.journeyActive: (context) => const JourneyActiveScreen(),
        AppRoutes.checkinPrompt: (context) => const CheckinPromptScreen(),
        AppRoutes.missedCheckin: (context) => const MissedCheckinScreen(),

        // Feature B — SOS Resilience Mode
        AppRoutes.resilienceHome: (context) => const ResilienceHomeScreen(),
        AppRoutes.deviceStatus: (context) => const DeviceStatusScreen(),
        AppRoutes.offlineMode: (context) => const OfflineModeScreen(),
        AppRoutes.autoSms: (context) => const AutoSmsScreen(),
        AppRoutes.localBackup: (context) => const LocalBackupScreen(),
        AppRoutes.autoSync: (context) => const AutoSyncScreen(),
        AppRoutes.batteryAlerts: (context) => const BatteryAlertsScreen(),

        // Feature C — Verified Safe Haven Network
        AppRoutes.safeHavenHome: (context) => const SafeHavenHomeScreen(),
        AppRoutes.nearbyPlaces: (context) => const NearbyPlacesScreen(),
        AppRoutes.communityReports: (context) => const CommunityReportsScreen(),
        AppRoutes.emergencyServices: (context) => const EmergencyServicesScreen(),
        AppRoutes.safeHavenFilters: (context) => const SafeHavenFiltersScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.routePreview) {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => RoutePreviewScreen(arguments: args),
          );
        }
        if (settings.name == AppRoutes.journeySummary) {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => JourneySummaryScreen(arguments: args),
          );
        }
        if (settings.name == AppRoutes.placeDetails) {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => PlaceDetailsScreen(arguments: args),
          );
        }
        if (settings.name == AppRoutes.routeToSafePlace) {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => RouteToSafePlaceScreen(arguments: args),
          );
        }
        return null;
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (context) => const HomeScreen());
      },
    );
  }
}
