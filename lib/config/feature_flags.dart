/// Features that exist in the codebase but aren't open to users yet.
class FeatureFlags {
  FeatureFlags._();

  /// Coach accounts ("coming soon"). While false, nobody is routed to the coach
  /// screens and sign-up only offers the player role.
  static const bool coachAccounts = false;

  /// In-app subscriptions. While false, Pro is free for every account (claimTestFlightPro)
  /// and the Pro screen shows no purchase options. Turning this on also requires server-side
  /// purchase verification, since Pro fields are server-only in the Firestore rules.
  static const bool paidSubscriptions = false;
}
