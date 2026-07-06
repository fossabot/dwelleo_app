import 'package:firebase_analytics/firebase_analytics.dart';

/// Thin, DI-registered analytics facade so features never touch the
/// Firebase API directly (swappable/testable; Amplitude/PostHog can be
/// fanned out here later per the observability plan).
class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService(this._analytics);

  /// Contact action on a listing — the app-side lead signal. The backend
  /// `leads/ingest` call is added once its payload is captured
  /// (@bodyPending discipline); analytics works today either way.
  Future<void> leadContact({
    required String method, // 'call' | 'whatsapp'
    required int propertyId,
    String? ownerType,
  }) {
    return _analytics.logEvent(
      name: 'lead_contact',
      parameters: {
        'method': method,
        'property_id': propertyId,
        'owner_type': ?ownerType,
      },
    );
  }

  Future<void> searchApplied({
    required int filterCount,
    int? resultsTotal,
  }) {
    return _analytics.logEvent(
      name: 'property_search_applied',
      parameters: {
        'filter_count': filterCount,
        'results_total': ?resultsTotal,
      },
    );
  }

  Future<void> savedSearchCreated() =>
      _analytics.logEvent(name: 'saved_search_created');
}
