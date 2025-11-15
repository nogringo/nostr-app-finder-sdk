import 'package:ndk/ndk.dart';
import 'package:nip77/nip77.dart';
import 'package:path/path.dart' as p;
import 'package:sembast_cache_manager/sembast_cache_manager.dart';

void main() async {
  final filter = Filter(kinds: [31990]);

  final cache = await SembastCacheManager.create(databasePath: p.current);
  final ndk = Ndk(
    NdkConfig(eventVerifier: Bip340EventVerifier(), cache: cache),
  );

  final localEvents = await ndk.config.cache.loadEvents(kinds: [31990]);

  final client = Nip77Client(relayUrl: "wss://nostr-01.uid.ovh");
  await client.connect();

  final syncResult = await client.syncEvents(
    myEvents: Map.fromEntries(
      localEvents.map((e) => MapEntry(e.id, e.createdAt)),
    ),
    filter: filter.toJson(),
  );

  await client.disconnect();

  print(syncResult.haveIds.length);
  for (var eventId in syncResult.haveIds) {
    final event = await ndk.config.cache.loadEvent(eventId);
    if (event == null) continue;
    final broadcast = ndk.broadcast.broadcast(
      nostrEvent: event,
      specificRelays: ["wss://nostr-01.uid.ovh"],
    );
    await broadcast.broadcastDoneFuture;
  }

  ndk.destroy();
}
