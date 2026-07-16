import '../../domain/entities/listing_result.dart';
import '../../domain/entities/sales_models.dart';

/// Sealed union for the AI Sales Agent screen (Dart 3, no codegen).
sealed class SalesAgentState {
  const SalesAgentState();
}

/// Welcome view — disclosure, value copy and conversation starters.
class SalesAgentIdle extends SalesAgentState {
  const SalesAgentIdle();
}

/// Active conversation plus the cumulative BITEP lead sheet and any
/// Serper listing results surfaced so far.
class SalesAgentChat extends SalesAgentState {
  final List<SalesTurn> turns;
  final LeadProfile lead;
  final List<ListingResult> listings;

  const SalesAgentChat(
    this.turns, {
    this.lead = LeadProfile.empty,
    this.listings = const [],
  });
}
