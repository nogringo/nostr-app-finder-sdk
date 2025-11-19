import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:nip77/nip77.dart';
import 'package:nostr_app_finder_sdk/src/models/nostr_app.dart';
import 'package:nostr_app_finder_sdk/src/models/scored_app.dart';
import 'package:nostr_app_finder_sdk/src/models/scored_kind.dart';
import 'package:nostr_app_finder_sdk/src/models/scored_platform.dart';
import 'package:nostr_app_finder_sdk/src/models/scored_tag.dart';
import 'package:sembast/sembast.dart' hide Filter;
import 'package:sembast_cache_manager/sembast_cache_manager.dart';

class AppFinder {
  late Ndk ndk;

  List<NostrApp> apps = [];
  List<ScoredTag> tags = [];
  List<ScoredKind> kinds = [];
  List<ScoredPlatform> platforms = [];

  AppFinder({Database? db, Ndk? ndk}) {
    if (db == null && ndk == null) {
      throw ArgumentError("Either db or ndk must be provided");
    }

    this.ndk =
        ndk ??
        Ndk(
          NdkConfig(
            eventVerifier: Bip340EventVerifier(),
            cache: SembastCacheManager(db!),
          ),
        );
  }

  Future<void> loadApps() async {
    final events = await ndk.config.cache.loadEvents(kinds: [31990]);
    apps = events.map((e) => NostrApp.fromEvent(e)).toList();
    getStats();
  }

  void getStats() {
    List<String> tags = [];
    List<int> kinds = [];
    List<String> platforms = [];

    for (var app in apps) {
      tags.addAll(app.tags);
      kinds.addAll(app.kinds);
      platforms.addAll(app.platforms);
    }

    Map<String, int> scoredTagsMap = Map.fromEntries(
      tags.map((tag) => MapEntry(tag, 0)),
    );
    for (var tag in tags) {
      scoredTagsMap[tag] = scoredTagsMap[tag]! + 1;
    }
    List<ScoredTag> scoredTags = [];
    scoredTagsMap.forEach((tag, score) {
      scoredTags.add(ScoredTag(tag: tag, score: score));
    });
    scoredTags.sort((a, b) => b.score.compareTo(a.score));

    Map<int, int> scoredKindsMap = Map.fromEntries(
      kinds.map((kind) => MapEntry(kind, 0)),
    );
    for (var kind in kinds) {
      scoredKindsMap[kind] = scoredKindsMap[kind]! + 1;
    }
    List<ScoredKind> scoredKinds = [];
    scoredKindsMap.forEach((kind, score) {
      scoredKinds.add(ScoredKind(kind: kind, score: score));
    });
    scoredKinds.sort((a, b) => b.score.compareTo(a.score));

    Map<String, int> scoredPlatformsMap = Map.fromEntries(
      platforms.map((platform) => MapEntry(platform, 0)),
    );
    for (var platform in platforms) {
      scoredPlatformsMap[platform] = scoredPlatformsMap[platform]! + 1;
    }
    List<ScoredPlatform> scoredPlatforms = [];
    scoredPlatformsMap.forEach((platform, score) {
      scoredPlatforms.add(ScoredPlatform(platform: platform, score: score));
    });
    scoredPlatforms.sort((a, b) => b.score.compareTo(a.score));

    this.tags = scoredTags;
    this.kinds = scoredKinds;
    this.platforms = scoredPlatforms;
  }

  Future<void> fetchNewApps() async {
    final filter = Filter(kinds: [31990]);

    final localEvents = await ndk.config.cache.loadEvents(kinds: filter.kinds!);

    final client = Nip77Client(relayUrl: "wss://nostr-01.uid.ovh");
    await client.connect();

    final syncResult = await client.syncEvents(
      myEvents: Map.fromEntries(
        localEvents.map((e) => MapEntry(e.id, e.createdAt)),
      ),
      filter: filter.toJson(),
    );

    await client.disconnect();

    const chunkSize = 400;
    for (var i = 0; i < syncResult.needIds.length / chunkSize; i++) {
      final startIndex = 0 + chunkSize * i;
      final endIndex = chunkSize + chunkSize * i;

      final query = ndk.requests.query(
        filters: [
          Filter(
            ids: syncResult.needIds.sublist(
              startIndex,
              syncResult.needIds.length > endIndex ? endIndex : null,
            ),
          ),
        ],
        explicitRelays: ["wss://nostr-01.uid.ovh"],
      );
      await query.future;
    }

    await loadApps();

    // final relays = [
    //   // "wss://nostr.mom",
    //   // "wss://nos.lol",
    //   "wss://relay.nostr.band",
    // ];

    // for (var relay in relays) {
    //   print(relay);
    //   await fetchRelay(relay: relay);
    // }
  }

  Future<void> fetchRelay({required String relay}) async {
    int? until;
    while (true) {
      final query = ndk.requests.query(
        filters: [
          Filter(kinds: [31990], until: until),
        ],
        explicitRelays: [relay],
      );
      final events = await query.future;
      print(events.length);

      final dates = events.map((e) => e.createdAt).toList();
      dates.sort();

      if (events.isEmpty || dates.where((e) => e != dates.first).isEmpty) break;

      until = dates.first + 1;
    }
  }

  List<ScoredApp> search({
    String? search,
    List<String>? tags,
    List<int>? kinds,
    List<String>? platforms,
  }) {
    int maxScore = 1;
    if (tags != null) maxScore += tags.length;
    if (kinds != null) maxScore += kinds.length;
    if (platforms != null) maxScore += platforms.length;

    List<ScoredApp> result = [];

    for (var app in apps) {
      Set<String> score = {};

      Map<String, dynamic> jsonEvent = app.event.toJson();
      jsonEvent.remove("id");
      jsonEvent.remove("pubkey");
      jsonEvent.remove("sig");
      final eventString = jsonEncode(jsonEvent).toLowerCase();

      if (search != null) {
        search = search.toLowerCase();

        if (eventString.contains(search)) score.add("global search");
      }

      if (kinds != null) {
        for (var kind in kinds) {
          if (app.supportsKind(kind)) {
            score.add("local kind $kind");
          }
        }
      }

      if (tags != null) {
        for (var tag in tags) {
          if (app.hasTag(tag)) {
            score.add("local tag $tag");
          } else if (eventString.contains(tag)) {
            score.add("global tag $tag");
          }
        }
      }

      if (platforms != null) {
        for (var platform in platforms) {
          if (app.supportsPlatform(platform)) {
            score.add("local platform $platform");
          } else if (eventString.contains(platform)) {
            score.add("global platform $platform");
          }
        }
      }

      if (score.isNotEmpty) {
        result.add(
          ScoredApp(
            app: app,
            score: score.length / maxScore,
            reasons: score.toList(),
          ),
        );
      }
    }

    result.sort((a, b) => b.score.compareTo(a.score));

    return result;
  }
}
