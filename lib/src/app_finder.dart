import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:nip77/nip77.dart';
import 'package:nostr_app_finder_sdk/src/nostr_app.dart';

enum MatchReasons {
  globalSearch,
  globalTags,
  localTags,
  globalKinds,
  localKinds,
  globalPlatform,
}

class AppFinder {
  Ndk ndk;

  AppFinder({required this.ndk});

  Future<void> fetchNewApps() async {
    // final filter = Filter(kinds: [31990]);

    // final localEvents = await ndk.config.cache.loadEvents(kinds: filter.kinds!);

    // final client = Nip77Client(relayUrl: "wss://nostr-01.uid.ovh");
    // await client.connect();

    // final syncResult = await client.syncEvents(
    //   myEvents: Map.fromEntries(
    //     localEvents.map((e) => MapEntry(e.id, e.createdAt)),
    //   ),
    //   filter: filter.toJson(),
    // );

    // await client.disconnect();

    // final query = ndk.requests.query(
    //   filters: [Filter(ids: syncResult.needIds)],
    //   explicitRelays: ["wss://nostr-01.uid.ovh"],
    // );
    // await query.future;

    final relays = [
      // "wss://nostr.mom",
      // "wss://nos.lol",
      "wss://relay.nostr.band",
    ];

    for (var relay in relays) {
      print(relay);
      await fetchRelay(relay: relay);
    }
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

  Future<List<Nip01Event>> search({
    String? search,
    List<int>? kinds,
    List<String>? tags,
    List<String>? platforms,
  }) async {
    List<Nip01Event> result = [];

    List<Nip01Event> events = await ndk.config.cache.loadEvents(kinds: [31990]);
    for (var event in events) {
      final app = NostrApp.fromEvent(event);

      Set<String> score = {};

      Map<String, dynamic> jsonEvent = event.toJson();
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
        print(score);
        result.add(event);
      }
    }

    return result;
  }
}
