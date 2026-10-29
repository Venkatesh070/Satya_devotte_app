/// Result of launching / completing an "add to device calendar" flow.
enum CalendarAddOutcome {
  /// User confirmed save (e.g. iOS EKEventEditViewController .saved).
  saved,

  /// User dismissed the editor without saving (iOS).
  cancelled,

  /// Calendar UI / insert intent was opened; save is not confirmed yet
  /// (Android / web). Caller should wait until the user returns to the app.
  opened,

  /// Could not open calendar or permission denied.
  failed,
}
