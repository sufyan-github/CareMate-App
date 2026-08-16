import 'package:caremate/features/care/presentation/care_page.dart';
import 'package:caremate/features/care/presentation/invite_caregiver_page.dart';
import 'package:caremate/features/insights/presentation/insights_page.dart';
import 'package:caremate/features/medications/application/patient_medication_coordinator.dart';
import 'package:caremate/features/medications/presentation/medications_page.dart';
import 'package:caremate/features/more/presentation/more_page.dart';
import 'package:caremate/features/notifications/presentation/notifications_page.dart';
import 'package:caremate/features/prescription/domain/prescription_text_recognizer.dart';
import 'package:caremate/features/prescription/presentation/prescription_scan_page.dart';
import 'package:caremate/features/today/presentation/today_page.dart';
import 'package:flutter/material.dart';

class AppShell extends StatefulWidget {
  const AppShell({
    required this.medicationCoordinator,
    required this.onLogout,
    required this.prescriptionTextRecognizer,
    super.key,
  });

  final PatientMedicationCoordinator medicationCoordinator;
  final Future<void> Function() onLogout;
  final PrescriptionTextRecognizer prescriptionTextRecognizer;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.today_outlined),
      selectedIcon: Icon(Icons.today),
      label: 'Today',
    ),
    NavigationDestination(
      icon: Icon(Icons.medication_outlined),
      selectedIcon: Icon(Icons.medication),
      label: 'Medicines',
    ),
    NavigationDestination(
      icon: Icon(Icons.people_outline),
      selectedIcon: Icon(Icons.people),
      label: 'Care',
    ),
    NavigationDestination(
      icon: Icon(Icons.insights_outlined),
      selectedIcon: Icon(Icons.insights),
      label: 'Insights',
    ),
    NavigationDestination(
      icon: Icon(Icons.more_horiz),
      selectedIcon: Icon(Icons.more),
      label: 'More',
    ),
  ];

  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      TodayPage(
        onAddCaregiver: _openCaregiverInvitation,
        onAddMedicine: _openMedicationForm,
        onScanPrescription: _openPrescriptionScan,
      ),
      MedicationsPage(coordinator: widget.medicationCoordinator),
      CarePage(onInvite: _openCaregiverInvitation),
      InsightsPage(coordinator: widget.medicationCoordinator),
      MorePage(onLogout: widget.onLogout),
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
            tooltip: 'Notifications',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => const NotificationsPage(),
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
        destinations: _destinations,
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
        builder: (_) =>
            PrescriptionScanPage(recognizer: widget.prescriptionTextRecognizer),
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

  Future<void> _openCaregiverInvitation() => Navigator.push<void>(
    context,
    MaterialPageRoute<void>(builder: (_) => const InviteCaregiverPage()),
  );
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
