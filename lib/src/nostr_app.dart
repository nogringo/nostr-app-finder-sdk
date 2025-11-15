import 'dart:convert';
import 'package:ndk/ndk.dart';

/// Represents a Nostr App (kind 31990 event)
class NostrApp {
  /// App name
  final String name;

  /// App description/about
  final String description;

  /// App picture/logo URL
  final String? picture;

  /// App website URL
  final String? web;

  /// App identifier (from 'd' tag)
  final String? identifier;

  /// Supported event kinds
  final List<int> kinds;

  /// Supported platforms (web, ios, android, etc.)
  final List<String> platforms;

  /// App tags
  final List<String> tags;

  /// Raw event content as JSON string
  final String content;

  /// Original Nostr event
  final Nip01Event event;

  NostrApp({
    required this.name,
    required this.description,
    this.picture,
    this.web,
    this.identifier,
    required this.kinds,
    required this.platforms,
    required this.tags,
    required this.content,
    required this.event,
  });

  /// Creates a NostrApp from a Nip01Event
  factory NostrApp.fromEvent(Nip01Event event, {List<String>? sources}) {
    // Parse content JSON
    Map<String, dynamic> contentJson = {};
    String name = '';
    String description = '';
    String? picture;
    List<String> platforms = [];

    try {
      contentJson = jsonDecode(event.content) as Map<String, dynamic>;
      name = contentJson['name'] as String? ?? '';
      description = contentJson['about'] as String? ?? '';
      picture = contentJson['picture'] as String?;

      // Extract platforms from NIP-89 if available
      if (contentJson.containsKey('nip89')) {
        final nip89 = contentJson['nip89'] as Map<String, dynamic>?;
        if (nip89 != null && nip89.containsKey('platforms')) {
          platforms =
              (nip89['platforms'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [];
        }
      }
    } catch (e) {
      // If content parsing fails, use empty defaults
    }

    // Extract data from tags
    final dTag = event.getTags('d').firstOrNull;
    final descriptionTag = event.getTags('description').firstOrNull;
    final webTag = event.getTags('web').firstOrNull;
    final kTags = event.getTags('k').map((e) => int.tryParse(e) ?? 0).toList();
    final tTags = event.getTags('t').map((e) => e.toLowerCase()).toList();

    // Merge tags from t tags, content JSON, and NIP-89
    List<String> allTags = [...tTags];

    // Extract tags from content JSON if available
    if (contentJson.containsKey('tags')) {
      final contentTags =
          (contentJson['tags'] as List<dynamic>?)
              ?.map((e) => e.toString().toLowerCase())
              .toList() ??
          [];
      allTags.addAll(contentTags);
    }

    // Extract tags from NIP-89 if available
    if (contentJson.containsKey('nip89')) {
      final nip89 = contentJson['nip89'] as Map<String, dynamic>?;
      if (nip89 != null && nip89.containsKey('tags')) {
        final nip89Tags =
            (nip89['tags'] as List<dynamic>?)
                ?.map((e) => e.toString().toLowerCase())
                .toList() ??
            [];
        allTags.addAll(nip89Tags);
      }
    }

    // Remove duplicates
    allTags = allTags.toSet().toList();

    // Merge kinds from k tags and NIP-89
    List<int> allKinds = [...kTags];
    if (contentJson.containsKey('nip89')) {
      final nip89 = contentJson['nip89'] as Map<String, dynamic>?;
      if (nip89 != null && nip89.containsKey('supported_kinds')) {
        final nip89Kinds =
            (nip89['supported_kinds'] as List<dynamic>?)
                ?.map((e) => e is int ? e : (int.tryParse(e.toString()) ?? 0))
                .where((k) => k != 0)
                .toList() ??
            [];
        allKinds.addAll(nip89Kinds);
      }
    }
    // Remove duplicates
    allKinds = allKinds.toSet().toList();

    // Also extract platforms from regular tags
    final platformKeywords = [
      'web',
      'ios',
      'android',
      'desktop',
      'mobile',
      'linux',
      'macos',
      'windows',
    ];
    for (var tag in event.tags) {
      if (tag.isNotEmpty && platformKeywords.contains(tag[0].toLowerCase())) {
        platforms.add(tag[0].toLowerCase());
      }
    }
    // Remove duplicates
    platforms = platforms.toSet().toList();

    return NostrApp(
      name: name,
      description: description.isNotEmpty
          ? description
          : (descriptionTag ?? 'No description'),
      picture: picture,
      web: webTag,
      identifier: dTag,
      kinds: allKinds,
      platforms: platforms,
      tags: allTags,
      content: event.content,
      event: event,
    );
  }

  /// Creates a NostrApp from the store format (with key/value structure)
  factory NostrApp.fromStoreJson(Map<String, dynamic> json) {
    final value = json['value'] as Map<String, dynamic>;
    final sources = (json['value']['sources'] as List<dynamic>?)
        ?.map((e) => e.toString())
        .toList();

    // Create a Nip01Event from the value
    final event = Nip01Event.fromJson(value);

    return NostrApp.fromEvent(event, sources: sources);
  }

  /// Converts to JSON
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    if (picture != null) 'picture': picture,
    if (web != null) 'web': web,
    if (identifier != null) 'identifier': identifier,
    'kinds': kinds,
    'platforms': platforms,
    'tags': tags,
  };

  /// Check if app supports a specific platform
  bool supportsPlatform(String platform) {
    return platforms.contains(platform.toLowerCase());
  }

  /// Check if app supports a specific event kind
  bool supportsKind(int kind) {
    return kinds.contains(kind);
  }

  /// Check if app has a specific tag
  bool hasTag(String tag) {
    return tags.contains(tag.toLowerCase());
  }

  @override
  String toString() {
    return 'NostrApp(name: $name, kinds: $kinds, platforms: $platforms)';
  }
}
