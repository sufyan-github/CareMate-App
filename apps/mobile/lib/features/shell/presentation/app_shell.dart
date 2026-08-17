import 'package:caremate/app/preferences/caremate_preferences.dart';
import 'package:caremate/features/care/presentation/care_page.dart';
import 'package:caremate/features/care/domain/care_access_gateway.dart';
import 'package:caremate/features/care/presentation/invite_caregiver_page.dart';
import 'package:caremate/features/insights/presentation/insights_page.dart';
import 'package:caremate/features/insights/domain/insights_gateway.dart';
import 'package:caremate/features/medications/application/patient_medication_coordinator.dart';
import 'package:caremate/features/medications/presentation/medications_page.dart';
import 'package:caremate/features/more/presentation/more_page.dart';
import 'package:caremate/features/more/domain/account_settings_gateway.dart';
import 'package:caremate/features/notifications/presentation/notifications_page.dart';
import 'package:caremate/features/prescription/domain/prescription_text_recognizer.dart';
import 'package:caremate/features/prescription/domain/prescription_extraction_gateway.dart';
import 'package:caremate/features/prescription/presentation/prescription_scan_page.dart';
import 'package:caremate/features/today/presentation/today_page.dart';
import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.accountSettingsGateway,
    required this.careAccessGateway,
    required this.medicationCoordinator,
    required this.insightsGateway,
    required this.onLogout,
    required this.prescriptionExtractionGateway,
    required this.prescriptionTextRecognizer,
    super.key,
  });

  final AccountSettingsGateway accountSettingsGateway;
  final CareAccessGateway careAccessGateway;
  final PatientMedicationCoordinator medicationCoordinator;
  final InsightsGateway insightsGateway;
  final Future<void> Function() onLogout;
  final PrescriptionExtractionGateway prescriptionExtractionGateway;
  final PrescriptionTextRecognizer prescriptionTextRecognizer;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final copy = CareMateStrings.of(context);
    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: Icon(Icons.today_outlined),
        selectedIcon: Icon(Icons.today),
        label: copy.pick('Today', 'আজ'),
      ),
      NavigationDestination(
        icon: Icon(Icons.medication_outlined),
        selectedIcon: Icon(Icons.medication),
        label: copy.pick('Medicines', 'ওষুধ'),
      ),
      NavigationDestination(
        icon: Icon(Icons.people_outline),
        selectedIcon: Icon(Icons.people),
        label: copy.pick('Care', 'সহায়তা'),
      ),
      NavigationDestination(
        icon: Icon(Icons.insights_outlined),
        selectedIcon: Icon(Icons.insights),
        label: copy.pick('Insights', 'তথ্য'),
      ),
      NavigationDestination(
        icon: Icon(Icons.more_horiz),
        selectedIcon: Icon(Icons.more),
        label: copy.pick('More', 'আরও'),
      ),
    ];
    final pages = <Widget>[
      TodayPage(
        canManage: widget.medicationCoordinator.profile!.canManage,
        occurrences: widget.medicationCoordinator.doseOccurrences,
        onAddCaregiver: _openCaregiverInvitation,
        onAddMedicine: _openMedicationForm,
        onDoseAction: widget.medicationCoordinator.commandDose,
        onEnableReminders:
            widget.medicationCoordinator.requestReminderPermissions,
        onSyncNow: widget.medicationCoordinator.syncNow,
        pendingSyncCount: widget.medicationCoordinator.pendingSyncCount,
        onScanPrescription: _openPrescriptionScan,
        reminderReadiness: widget.medicationCoordinator.reminderReadiness,
        syncMessage: widget.medicationCoordinator.syncMessage,
        usingOfflineCache: widget.medicationCoordinator.usingOfflineCache,
      ),
      MedicationsPage(coordinator: widget.medicationCoordinator),
      CarePage(
        accessToken: widget.medicationCoordinator.accessToken,
        canManage: widget.medicationCoordinator.profile!.canManage,
        gateway: widget.careAccessGateway,
        isActive: _selectedIndex == 2,
        onInvite: _openCaregiverInvitation,
        profileId: widget.medicationCoordinator.profile!.id,
        patientDisplayName: widget.medicationCoordinator.profile!.displayName,
      ),
      InsightsPage(
        coordinator: widget.medicationCoordinator,
        gateway: widget.insightsGateway,
        isActive: _selectedIndex == 3,
      ),
      MorePage(
        accessToken: widget.medicationCoordinator.accessToken,
        gateway: widget.accountSettingsGateway,
        onLogout: widget.onLogout,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BrandMark(),
            SizedBox(width: 10),
            Text('CareMate', style: TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            tooltip: copy.pick('Notifications', 'নোটিফিকেশন'),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => NotificationsPage(
                  coordinator: widget.medicationCoordinator,
                ),
              ),
            ),
            icon: const Icon(Icons.notifications_none),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        destinations: destinations,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
      ),
    );
  }

  Future<void> _openMedicationForm() =>
      showMedicationForm(context, coordinator: widget.medicationCoordinator);

  Future<void> _openPrescriptionScan() async {
    final result = await Navigator.push<PrescriptionDraftResult>(
      context,
      MaterialPageRoute<PrescriptionDraftResult>(
        builder: (_) => PrescriptionScanPage(
          accessToken: widget.medicationCoordinator.accessToken,
          extractionGateway: widget.prescriptionExtractionGateway,
          profileId: widget.medicationCoordinator.profile!.id,
          recognizer: widget.prescriptionTextRecognizer,
        ),
      ),
    );
    if (!mounted || result == null) return;
    await showMedicationForm(
      context,
      coordinator: widget.medicationCoordinator,
      initialName: result.medicineName,
      sourceText: result.sourceText,
    );
  }

  Future<bool> _openCaregiverInvitation() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => InviteCaregiverPage(
          accessToken: widget.medicationCoordinator.accessToken,
          gateway: widget.careAccessGateway,
          profileId: widget.medicationCoordinator.profile!.id,
        ),
      ),
    );
    if (created == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            CareMateStrings.of(context).pick(
              'Invitation created. It will appear when the caregiver signs in with the invited number.',
              'আমন্ত্রণ তৈরি হয়েছে। আমন্ত্রিত ব্যক্তি এই নম্বর দিয়ে সাইন ইন করলে এটি দেখতে পাবেন।',
            ),
          ),
        ),
      );
    }
    return created ?? false;
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: 'CareMate logo',
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: colors.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.favorite_rounded, color: colors.primary, size: 21),
      ),
    );
  }
}
