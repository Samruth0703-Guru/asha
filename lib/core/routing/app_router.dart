import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/patients/presentation/screens/patient_register_screen.dart';
import '../../features/patients/presentation/screens/patient_profile_screen.dart';
import '../../features/ai_risk/presentation/screens/risk_assessment_screen.dart';
import '../../features/ai_assistant/presentation/screens/chat_assistant_screen.dart';
import '../../features/vaccination/presentation/screens/vaccination_calendar_screen.dart';
import '../../features/inventory/presentation/screens/medicine_inventory_screen.dart';
import '../../features/mapping/presentation/screens/village_map_screen.dart';
import '../../features/emergency/presentation/screens/emergency_hud_screen.dart';
import '../../features/analytics/presentation/screens/district_analytics_screen.dart';
import '../../features/patients/presentation/screens/visit_planner_screen.dart';
import '../../features/pregnancy/presentation/screens/pregnancy_dashboard_screen.dart';
import '../../features/vaccination/presentation/screens/vaccination_dashboard_screen.dart';

// New Screen imports
import '../../features/patients/presentation/screens/patient_list_screen.dart';
import '../../features/ai_assistant/presentation/screens/ai_chat_screen.dart';
import '../../features/dashboard/presentation/screens/notifications_screen.dart';
import '../../features/analytics/presentation/screens/reports_screen.dart';
import '../../features/dashboard/presentation/screens/settings_screen.dart';
import '../../features/dashboard/presentation/screens/web_dashboard_screen.dart';
import '../../features/sms/presentation/screens/sms_history_screen.dart';
import '../../features/health_scan/presentation/screens/health_scan_screen.dart';
import '../../features/ai_health_assistant/presentation/screens/ai_health_assistant_dashboard.dart';
import '../../features/ai_health_assistant/presentation/screens/scan_skin_disease_screen.dart';
import '../../features/ai_health_assistant/presentation/screens/scan_history_screen.dart';

// Cancer Care Screen imports
import '../../features/cancer_care/presentation/screens/cancer_dashboard_screen.dart';
import '../../features/cancer_care/presentation/screens/cancer_patient_register_screen.dart';
import '../../features/cancer_care/presentation/screens/cancer_screening_screen.dart';
import '../../features/cancer_care/presentation/screens/cancer_vision_screening_screen.dart';
import '../../features/cancer_care/presentation/screens/cancer_treatment_screen.dart';
import '../../features/cancer_care/presentation/screens/cancer_follow_up_screen.dart';
import '../../features/cancer_care/presentation/screens/cancer_medicine_screen.dart';
import '../../features/cancer_care/presentation/screens/cancer_referral_screen.dart';
import '../../features/cancer_care/presentation/screens/cancer_report_print_screen.dart';
import '../../features/cancer_care/presentation/screens/cancer_audit_logs_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/dashboard',
  routes: [
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const ResponsiveDashboardLayout(),
    ),
    GoRoute(
      path: '/register-patient',
      builder: (context, state) => const PatientRegisterScreen(),
    ),
    GoRoute(
      path: '/patient-profile/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'PT001';
        return PatientProfileScreen(id: id);
      },
    ),
    GoRoute(
      path: '/risk-assessment/:id',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? 'PT001';
        return RiskAssessmentScreen(patientId: id);
      },
    ),
    GoRoute(
      path: '/chat-assistant',
      builder: (context, state) => const ChatAssistantScreen(),
    ),
    GoRoute(
      path: '/vaccination-calendar',
      builder: (context, state) => const VaccinationCalendarScreen(),
    ),
    GoRoute(
      path: '/medicine-inventory',
      builder: (context, state) => const MedicineInventoryScreen(),
    ),
    GoRoute(
      path: '/village-map',
      builder: (context, state) => const VillageMapScreen(),
    ),
    GoRoute(
      path: '/emergency-hud',
      builder: (context, state) => const EmergencyHudScreen(),
    ),
    GoRoute(
      path: '/district-analytics',
      builder: (context, state) => const DistrictAnalyticsScreen(),
    ),
    GoRoute(
      path: '/visit-planner',
      builder: (context, state) => const VisitPlannerScreen(),
    ),
    
    // Special Workflows
    GoRoute(
      path: '/pregnancy-dashboard',
      builder: (context, state) => const PregnancyDashboardScreen(),
    ),
    GoRoute(
      path: '/vaccination-dashboard',
      builder: (context, state) => const VaccinationDashboardScreen(),
    ),
    // New Routes
    GoRoute(
      path: '/patient-list',
      builder: (context, state) {
        final filter = state.uri.queryParameters['filter'];
        return PatientListScreen(initialFilter: filter);
      },
    ),
    GoRoute(
      path: '/ai-chat',
      builder: (context, state) => const AiChatScreen(),
    ),
    GoRoute(
      path: '/notifications',
      builder: (context, state) => const NotificationsScreen(),
    ),
    GoRoute(
      path: '/reports',
      builder: (context, state) => const ReportsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/sms-history',
      builder: (context, state) => const SmsHistoryScreen(),
    ),
    GoRoute(
      path: '/health-scan',
      builder: (context, state) {
        final patientId = state.uri.queryParameters['patientId'];
        return HealthScanScreen(patientId: patientId);
      },
    ),
    GoRoute(
      path: '/ai-health-assistant',
      builder: (context, state) {
        final patientId = state.uri.queryParameters['patientId'];
        return AiHealthAssistantDashboard(patientId: patientId);
      },
    ),
    GoRoute(
      path: '/scan-skin-disease',
      builder: (context, state) {
        final patientId = state.uri.queryParameters['patientId'];
        return ScanSkinDiseaseScreen(patientId: patientId);
      },
    ),
    GoRoute(
      path: '/scan-history',
      builder: (context, state) => const ScanHistoryScreen(),
    ),
    
    // Cancer Care routes
    GoRoute(
      path: '/cancer-care',
      builder: (context, state) => const CancerDashboardScreen(),
    ),
    GoRoute(
      path: '/cancer-care/register',
      builder: (context, state) => const CancerPatientRegisterScreen(),
    ),
    GoRoute(
      path: '/cancer-care/screening',
      builder: (context, state) => const CancerScreeningScreen(),
    ),
    GoRoute(
      path: '/cancer-care/vision',
      builder: (context, state) => const CancerVisionScreeningScreen(),
    ),
    GoRoute(
      path: '/cancer-care/treatment',
      builder: (context, state) => const CancerTreatmentScreen(),
    ),
    GoRoute(
      path: '/cancer-care/follow-up',
      builder: (context, state) => const CancerFollowUpScreen(),
    ),
    GoRoute(
      path: '/cancer-care/medicine',
      builder: (context, state) => const CancerMedicineScreen(),
    ),
    GoRoute(
      path: '/cancer-care/referral',
      builder: (context, state) => const CancerReferralScreen(),
    ),
    GoRoute(
      path: '/cancer-care/reports/:patientId',
      builder: (context, state) {
        final patientId = state.pathParameters['patientId'] ?? '';
        return CancerReportPrintScreen(patientId: patientId);
      },
    ),
    GoRoute(
      path: '/cancer-care/audit-logs',
      builder: (context, state) => const CancerAuditLogsScreen(),
    ),
  ],
);

class ResponsiveDashboardLayout extends StatelessWidget {
  const ResponsiveDashboardLayout({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 950) {
      return const WebDashboardScreen();
    } else {
      return const DashboardScreen();
    }
  }
}
