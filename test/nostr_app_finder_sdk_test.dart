import 'package:ndk/ndk.dart';
import 'package:nostr_app_finder_sdk/src/app_finder.dart';
import 'package:sembast_cache_manager/sembast_cache_manager.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as p;

void main() {
  test('Sync with relays', () async {
    final cache = await SembastCacheManager.create(databasePath: p.current);
    final ndk = Ndk(
      NdkConfig(eventVerifier: Bip340EventVerifier(), cache: cache),
    );

    final appFinder = AppFinder(ndk: ndk);

    await appFinder.fetchNewApps();
    await appFinder.loadApps();

    print(
      "We have ${appFinder.apps.length} apps locally",
    );

    ndk.destroy();
  });

  test('Search by name', () async {
    final cache = await SembastCacheManager.create(databasePath: p.current);
    final ndk = Ndk(
      NdkConfig(eventVerifier: Bip340EventVerifier(), cache: cache),
    );

    final appFinder = AppFinder(ndk: ndk);
    await appFinder.loadApps();

    final matchingApps = appFinder.search(search: "gitw");
    print("${matchingApps.length} apps match the search");

    ndk.destroy();
  });

  test('Search app by kinds', () async {
    final cache = await SembastCacheManager.create(databasePath: p.current);
    final ndk = Ndk(
      NdkConfig(eventVerifier: Bip340EventVerifier(), cache: cache),
    );

    final appFinder = AppFinder(ndk: ndk);
    await appFinder.loadApps();

    final matchingApps = appFinder.search(kinds: [24133]);
    print("${matchingApps.length} apps match the search");

    ndk.destroy();
  });

  test('Search app by tags', () async {
    final cache = await SembastCacheManager.create(databasePath: p.current);
    final ndk = Ndk(
      NdkConfig(eventVerifier: Bip340EventVerifier(), cache: cache),
    );

    final appFinder = AppFinder(ndk: ndk);
    await appFinder.loadApps();

    final matchingApps = appFinder.search(tags: ["video", "music"]);
    print("${matchingApps.length} apps match the search");

    ndk.destroy();
  });

  test('Search app by platforms', () async {
    final cache = await SembastCacheManager.create(databasePath: p.current);
    final ndk = Ndk(
      NdkConfig(eventVerifier: Bip340EventVerifier(), cache: cache),
    );

    final appFinder = AppFinder(ndk: ndk);
    await appFinder.loadApps();

    final matchingApps = appFinder.search(platforms: ["macos"]);
    print("${matchingApps.length} apps match the search");

    ndk.destroy();
  });

  test('Search app by name + kinds', () async {
    final cache = await SembastCacheManager.create(databasePath: p.current);
    final ndk = Ndk(
      NdkConfig(eventVerifier: Bip340EventVerifier(), cache: cache),
    );

    final appFinder = AppFinder(ndk: ndk);
    await appFinder.loadApps();

    final matchingApps = appFinder.search(
      search: "camelus",
      // kinds: [24133],
    );
    print("${matchingApps.length} apps match the search");

    ndk.destroy();
  });
}
