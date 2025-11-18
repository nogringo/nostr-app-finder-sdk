A Dart SDK for discovering and finding Nostr applications using. Provides tools to search, filter, and manage Nostr app discovery with caching support.

## Features

Search for a specific app by name, tags, kinds and platforms.

## Usage

```dart
// use sembast to get the database
final dir = await getApplicationDocumentsDirectory();
await dir.create(recursive: true);
final dbPath = join(dir.path, 'my_database.db');
final db = await databaseFactoryIo.openDatabase(dbPath);

// create you finder instance
final appFinder = AppFinder(db: db);

// load apps in memory
await appFinder.loadApps();

// search
final matchingApps = appFinder.search(
    search: "upload",
    tags: ["video"],
    kinds: [24133],
    platforms: ["linux"],
);

print("${matchingApps.length} apps match the search");
```

## Additional information

This package use Sembast and Ndk, advanced users can directly interact with it to gain more control over the research.
