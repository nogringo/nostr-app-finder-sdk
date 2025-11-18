import 'package:nostr_app_finder_sdk/src/models/nostr_app.dart';

/// Holds a single search hit together with its relevance score
/// and a list of human‑readable explanations.
class ScoredApp {
  final NostrApp app;
  final double score;
  final List<String> reasons;

  const ScoredApp({
    required this.app,
    required this.score,
    required this.reasons,
  });
}