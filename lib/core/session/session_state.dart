/// In-memory snapshot of auth/onboarding state, populated once at boot from
/// [SecureStorage] and updated on onboarding-complete / login / logout.
///
/// The GoRouter redirect reads this synchronously so navigation never awaits a
/// secure-storage read (avoids per-navigation jank while still surviving hot
/// restart, since bootstrap re-reads the persisted values).
class SessionState {
  bool onboardingDone;
  bool isLoggedIn;

  SessionState({this.onboardingDone = false, this.isLoggedIn = false});
}
