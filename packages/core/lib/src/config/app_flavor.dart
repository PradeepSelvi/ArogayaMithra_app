/// Which channel of the platform is running.
///
/// Each Flutter app declares its own flavor so shared code can adapt without
/// inspecting the widget tree.
enum AppFlavor {
  /// Citizen application (PRD 5.1).
  citizen,

  /// ASHA / ANM field application (PRD 5.2).
  fieldWorker,

  /// Facility console for medical officers and facility admins (PRD 5.3).
  facility,

  /// District and state oversight dashboard (PRD 5.4).
  oversight,
}

extension AppFlavorX on AppFlavor {
  /// Offline capture is only a requirement for the field application (PRD 15).
  bool get requiresOfflineSupport => this == AppFlavor.fieldWorker;

  /// Channel recorded on triage assessments so analytics can segment by entry
  /// point (PRD 19).
  String get triageChannel => switch (this) {
        AppFlavor.citizen => 'citizen_app',
        AppFlavor.fieldWorker => 'asha_app',
        AppFlavor.facility => 'facility',
        AppFlavor.oversight => 'facility',
      };
}
