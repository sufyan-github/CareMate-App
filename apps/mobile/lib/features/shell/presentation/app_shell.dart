import 'package:caremate/app/preferences/caremate_preferences.dart';
import 'package:caremate/features/care/presentation/care_page.dart';
import 'package:caremate/features/care/domain/care_access_gateway.dart';
import 'package:caremate/features/care/domain/caregiver_alert_notifier.dart';
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
import 'package:caremate/features/simple_mode/domain/dose_announcement_service.dart';
import 'package:caremate/features/simple_mode/presentation/simple_today_page.dart';
import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.accountSettingsGateway,
    required this.careAccessGateway,
    required this.caregiverAlertNotifier,
    required this.competitionDemo,
    required this.doseAnnouncementService,
    required this.medicationCoordinator,
    required this.insightsGateway,
    required this.onLogout,
    required this.prescriptionExtractionGateway,
    required this.prescriptionTextRecognizer,
    super.key,
  });

  final AccountSettingsGateway accountSettingsGateway;
  final CareAccessGateway careAccessGateway;
  final CaregiverAlertNotifier caregiverAlertNotifier;
  final bool competitionDemo;
  final DoseAnnouncementService doseAnnouncementService;
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
  void initState() {
    super.initState();
    if (!widget.medicationCoordinator.profile!.canViewMedicationPlan) {
      _selectedIndex = 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = CareMateStrings.of(context);
    final preferences = CareMatePreferencesScope.of(context);
    final simpleMode = preferences.simpleMode;
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
        canReceiveMissedDoseAlerts:
            widget.medicationCoordinator.profile!.canReceiveMissedDoseAlerts,
        competitionDemo: widget.competitionDemo,
        gateway: widget.careAccessGateway,
        isActive: _selectedIndex == 2,
        missedDoseGraceMinutes:
            widget.medicationCoordinator.profile!.missedDoseGraceMinutes,
        notifier: widget.caregiverAlertNotifier,
        onInvite: _openCaregiverInvitation,
        profileId: widget.medicationCoordinator.profile!.id,
        profileVersion: widget.medicationCoordinator.profile!.version,
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
        leading: simpleMode
            ? IconButton(
                key: const Key('exit-simple-mode-button'),
                tooltip: copy.pick('Exit Simple Mode', 'বড় মোড বন্ধ করুন'),
                onPressed: _exitSimpleMode,
                icon: const Icon(Icons.arrow_back),
              )
            : null,
        title: simpleMode
            ? Text(
                copy.pick('Simple Mode', 'বড় মোড'),
                style: const TextStyle(fontWeight: FontWeight.w800),
              )
            : const Row(
                children: [
                  _BrandMark(),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'CareMate',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
        actions: simpleMode
            ? const []
            : [
                if (widget.competitionDemo)
                  IconButton(
                    key: const Key('competition-demo-guide-button'),
                    tooltip: 'Competition demo guide',
                    onPressed: _openCompetitionDemoGuide,
                    icon: const Icon(Icons.emoji_events_outlined),
                  ),
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
      body: simpleMode
          ? SimpleTodayPage(
              announcementService: widget.doseAnnouncementService,
              canManage: widget.medicationCoordinator.profile!.canManage,
              medications: widget.medicationCoordinator.medications,
              occurrences: widget.medicationCoordinator.doseOccurrences,
              onDoseAction: widget.medicationCoordinator.commandDose,
              voicePromptsEnabled: preferences.voicePromptsEnabled,
            )
          : IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: simpleMode
          ? null
          : NavigationBar(
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

  Future<void> _exitSimpleMode() async {
    final preferences = CareMatePreferencesScope.of(context);
    await preferences.setSimpleMode(false);
    try {
      await widget.accountSettingsGateway.updatePreferences(
        accessToken: widget.medicationCoordinator.accessToken,
        simpleMode: false,
      );
    } on AccountSettingsFailure catch (failure) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  Future<void> _openCompetitionDemoGuide() async {
    final destination = await showModalBottomSheet<_CompetitionDestination>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _CompetitionDemoGuide(),
    );
    if (!mounted || destination == null) return;
    switch (destination) {
      case _CompetitionDestination.prescription:
        await _openPrescriptionScan();
      case _CompetitionDestination.today:
        setState(() => _selectedIndex = 0);
      case _CompetitionDestination.care:
        setState(() => _selectedIndex = 2);
      case _CompetitionDestination.insights:
        setState(() => _selectedIndex = 3);
      case _CompetitionDestination.language:
        setState(() => _selectedIndex = 4);
    }
  }

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

enum _CompetitionDestination { prescription, today, care, insights, language }

class _CompetitionDemoGuide extends StatelessWidget {
  const _CompetitionDemoGuide();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final steps =
        <
          ({
            _CompetitionDestination destination,
            IconData icon,
            String subtitle,
            String title,
          })
        >[
          (
            destination: _CompetitionDestination.prescription,
            icon: Icons.document_scanner_outlined,
            title: '1. Review-first prescription',
            subtitle: 'Show evidence, correct one field, then save explicitly.',
          ),
          (
            destination: _CompetitionDestination.today,
            icon: Icons.cloud_off_outlined,
            title: '2. Today and offline proof',
            subtitle:
                'Act on a due dose offline, reopen, restore, and sync once.',
          ),
          (
            destination: _CompetitionDestination.care,
            icon: Icons.people_outline,
            title: '3. Live caregiver loop',
            subtitle:
                'Force a synthetic miss, then show alert, acknowledge, late-confirm, resolve, and revocation.',
          ),
          (
            destination: _CompetitionDestination.insights,
            icon: Icons.inventory_2_outlined,
            title: '4. Inventory and insight',
            subtitle:
                'Show stock movement, run-out estimate, and transparent math.',
          ),
          (
            destination: _CompetitionDestination.language,
            icon: Icons.translate_outlined,
            title: '5. Bangladesh-first close',
            subtitle:
                'Switch Bangla or larger text and restate the safety boundary.',
          ),
        ];

    return SafeArea(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 680),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colors.primaryContainer,
                  child: Icon(
                    Icons.emoji_events_outlined,
                    color: colors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Five-minute demo guide',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text('Presenter aid â€¢ synthetic data only'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              color: colors.secondaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Text(
                  'Be explicit: demo OTP sends no SMS, OCR is unverified, and dose outcomes are self-reported.',
                ),
              ),
            ),
            const SizedBox(height: 8),
            for (final step in steps)
              Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  leading: Icon(step.icon),
                  title: Text(
                    step.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(step.subtitle),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () => Navigator.pop(context, step.destination),
                ),
              ),
          ],
        ),
      ),
    );
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
