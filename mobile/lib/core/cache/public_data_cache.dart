import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

class PublicCacheEntry {
  const PublicCacheEntry({
    required this.data,
    required this.etag,
    required this.storedAt,
    required this.expiresAt,
  });

  final Map<String, dynamic> data;
  final String? etag;
  final DateTime storedAt;
  final DateTime expiresAt;

  bool get isFresh => DateTime.now().toUtc().isBefore(expiresAt);
}

class PublicCacheFetch {
  const PublicCacheFetch({
    this.data,
    this.etag,
    this.notModified = false,
  });

  final Map<String, dynamic>? data;
  final String? etag;
  final bool notModified;
}

class PublicDataResult<T> {
  const PublicDataResult({required this.data, required this.changed});

  final T data;
  final bool changed;
}

class PublicApiCache {
  PublicApiCache._(this._box);

  static const _boxName = 'public_api_cache_v1';
  static const _entryVersion = 1;
  static const _maxEntries = 250;

  final Box<String> _box;
  final Map<String, Future<Map<String, dynamic>>> _inFlight = {};

  static Future<PublicApiCache> open() async {
    await Hive.initFlutter();
    return PublicApiCache._(await Hive.openBox<String>(_boxName));
  }

  static PublicApiCache fromBox(Box<String> box) => PublicApiCache._(box);

  String keyFor(String path, Map<String, Object?> queryParameters) {
    final query = _canonicalJson(queryParameters);
    return 'public:$path?$query';
  }

  Future<PublicCacheEntry?> read(String key) async {
    final encoded = _box.get(key);
    if (encoded == null) return null;

    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! Map<String, dynamic> ||
          decoded['version'] != _entryVersion ||
          decoded['data'] is! Map<String, dynamic>) {
        throw const FormatException('Invalid public cache entry');
      }

      final storedAt = DateTime.tryParse(
        decoded['storedAt']?.toString() ?? '',
      );
      final expiresAt = DateTime.tryParse(
        decoded['expiresAt']?.toString() ?? '',
      );
      if (storedAt == null || expiresAt == null) {
        throw const FormatException('Invalid public cache timestamps');
      }

      return PublicCacheEntry(
        data: decoded['data'] as Map<String, dynamic>,
        etag: decoded['etag']?.toString(),
        storedAt: storedAt,
        expiresAt: expiresAt,
      );
    } on FormatException catch (error) {
      debugPrint('Discarding invalid public cache entry "$key": $error');
      await _box.delete(key);
      return null;
    }
  }

  Future<PublicDataResult<Map<String, dynamic>>> fetchJson({
    required String key,
    required Duration ttl,
    required bool forceRefresh,
    required Future<PublicCacheFetch> Function(String? etag) fetch,
  }) async {
    final cached = await read(key);
    if (!forceRefresh && cached != null && cached.isFresh) {
      return PublicDataResult(data: cached.data, changed: false);
    }

    final data = await _fetchOnce(key, () async {
      final latest = await read(key);
      if (!forceRefresh && latest != null && latest.isFresh) {
        return latest.data;
      }

      final response = await fetch(latest?.etag);
      if (response.notModified) {
        if (latest == null) {
          throw const FormatException(
            'The server returned 304 without a cached public response',
          );
        }
        await _write(
          key,
          latest.data,
          etag: response.etag ?? latest.etag,
          ttl: ttl,
        );
        return latest.data;
      }

      final freshData = response.data;
      if (freshData == null) {
        throw const FormatException('The public API response has no data');
      }
      await _write(key, freshData, etag: response.etag, ttl: ttl);
      return freshData;
    });

    final changed =
        cached == null ||
        _canonicalJson(cached.data) != _canonicalJson(data);
    if (await read(key) == null) {
      throw const FormatException('Failed to persist public API response');
    }
    return PublicDataResult(data: data, changed: changed);
  }

  Future<void> close() => _box.close();

  Future<void> _write(
    String key,
    Map<String, dynamic> data, {
    required String? etag,
    required Duration ttl,
  }) async {
    final now = DateTime.now().toUtc();
    await _box.put(
      key,
      jsonEncode({
        'version': _entryVersion,
        'data': _sortJson(data),
        'etag': etag,
        'storedAt': now.toIso8601String(),
        'expiresAt': now.add(ttl).toIso8601String(),
      }),
    );
    await _trimIfNeeded();
  }

  Future<void> _trimIfNeeded() async {
    if (_box.length <= _maxEntries) return;

    final timestamps = <String, DateTime>{};
    for (final rawKey in _box.keys) {
      if (rawKey is! String) continue;
      final entry = await read(rawKey);
      if (entry != null) timestamps[rawKey] = entry.storedAt;
    }

    final oldestFirst = timestamps.entries.toList()
      ..sort((first, second) => first.value.compareTo(second.value));
    final removeCount = _box.length - _maxEntries;
    for (final entry in oldestFirst.take(removeCount)) {
      await _box.delete(entry.key);
    }
  }

  Future<Map<String, dynamic>> _fetchOnce(
    String key,
    Future<Map<String, dynamic>> Function() fetch,
  ) async {
    final inFlight = _inFlight[key];
    if (inFlight != null) return inFlight;

    final request = fetch();
    _inFlight[key] = request;
    try {
      return await request;
    } finally {
      if (identical(_inFlight[key], request)) {
        _inFlight.remove(key);
      }
    }
  }

  static String _canonicalJson(Object? value) => jsonEncode(_sortJson(value));

  static Object? _sortJson(Object? value) {
    if (value is Map) {
      final sorted = SplayTreeMap<String, Object?>();
      for (final entry in value.entries) {
        sorted[entry.key.toString()] = _sortJson(entry.value);
      }
      return sorted;
    }
    if (value is List) {
      return value.map(_sortJson).toList(growable: false);
    }
    return value;
  }
}
