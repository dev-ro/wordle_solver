import 'dart:convert';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/services.dart' show rootBundle;

class DictionaryService {
  DictionaryService({FirebaseStorage? storage}) : _storage = storage;

  // Lazily accessed FirebaseStorage to avoid requiring Firebase initialization in tests.
  final FirebaseStorage? _storage;
  final Map<String, List<String>> _cache = {};

  Future<List<String>> loadDictionary(String filename) async {
    if (_cache.containsKey(filename)) return _cache[filename]!;

    // Try Firebase Storage first (if available). If Firebase isn't initialized (e.g., in tests),
    // accessing FirebaseStorage.instance will throw; swallow and fall back to assets.
    try {
      final storage = _storage ?? FirebaseStorage.instance;
      final ref = storage.ref().child('dictionaries/$filename');
      // Reasonable max size (10MB). Adjust if dictionaries grow.
      final data = await ref.getData(10 * 1024 * 1024);
      if (data != null) {
        final jsonList = json.decode(utf8.decode(data)) as List<dynamic>;
        final words = jsonList
            .map((e) => e.toString().toLowerCase())
            .toList(growable: false);
        _cache[filename] = words;
        return words;
      }
    } catch (_) {
      // Ignore and fallback to assets
    }

    // Fallback to bundled assets
    final raw = await rootBundle.loadString('assets/words/$filename');
    final List<dynamic> jsonList = json.decode(raw) as List<dynamic>;
    final words = jsonList
        .map((e) => e.toString().toLowerCase())
        .toList(growable: false);
    _cache[filename] = words;
    return words;
  }
}
