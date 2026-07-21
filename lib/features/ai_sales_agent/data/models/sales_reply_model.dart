import 'dart:convert';

import '../../domain/entities/sales_models.dart';

/// Parses the model's raw text into a [SalesReply].
///
/// The model is instructed to emit JSON `{reply, lead{...}}`; this parser is
/// deliberately tolerant — if the model returns prose or fenced JSON, the
/// user still gets the text and the lead sheet simply doesn't advance.
abstract final class SalesReplyModel {
  static SalesReply fromModelText(String raw) {
    final jsonText = _extractJson(raw);
    if (jsonText != null) {
      try {
        final decoded = jsonDecode(jsonText);
        if (decoded is Map) {
          final reply = '${decoded['reply'] ?? ''}'.trim();
          final lead = decoded['lead'];
          if (reply.isNotEmpty) {
            return SalesReply(
              text: reply,
              lead: lead is Map ? _lead(lead) : LeadProfile.empty,
            );
          }
        }
      } catch (_) {
        // Fall through to the prose fallback below.
      }
    }
    return SalesReply(text: raw);
  }

  /// Accepts bare JSON or ```json fenced blocks; returns null when the text
  /// clearly isn't JSON.
  static String? _extractJson(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    return raw.substring(start, end + 1);
  }

  static LeadProfile _lead(Map lead) => LeadProfile(
    budget: _field(lead['budget']),
    intent: _field(lead['intent']),
    timeline: _field(lead['timeline']),
    eligibility: _field(lead['eligibility']),
    preferences: _field(lead['preferences']),
  );

  static String? _field(Object? value) {
    if (value == null) return null;
    final s = '$value'.trim();
    return (s.isEmpty || s == 'null') ? null : s;
  }
}
