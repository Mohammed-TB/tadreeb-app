import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:project_1/core/cache/public_data_cache.dart';

void main() {
  late Directory directory;
  late PublicApiCache cache;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('tadreeb-cache-');
    Hive.init(directory.path);
    cache = PublicApiCache.fromBox(
      await Hive.openBox<String>('public_cache_test'),
    );
  });

  tearDown(() async {
    await cache.close();
    await Hive.close();
    await directory.delete(recursive: true);
  });

  test('keeps stale data available and treats a 304 as unchanged', () async {
    const key = 'public:/api/courses?page=1';
    const data = {
      'success': true,
      'data': [
        {'id': 'course-1', 'title': 'Flutter'},
      ],
    };

    final initial = await cache.fetchJson(
      key: key,
      ttl: const Duration(minutes: 5),
      forceRefresh: true,
      fetch: (_) async =>
          const PublicCacheFetch(data: data, etag: 'W/"courses-v1"'),
    );
    expect(initial.changed, isTrue);

    final entry = await cache.read(key);
    expect(entry?.data['data'], data['data']);

    final refreshed = await cache.fetchJson(
      key: key,
      ttl: const Duration(minutes: 5),
      forceRefresh: true,
      fetch: (etag) async {
        expect(etag, 'W/"courses-v1"');
        return const PublicCacheFetch(
          etag: 'W/"courses-v1"',
          notModified: true,
        );
      },
    );
    expect(refreshed.changed, isFalse);
    expect(refreshed.data, data);
  });

  test('coalesces concurrent fetches with the same cache key', () async {
    var requestCount = 0;
    Future<void> fetch() async {
      await cache.fetchJson(
        key: 'public:/api/institutes?page=1',
        ttl: const Duration(minutes: 5),
        forceRefresh: true,
        fetch: (_) async {
          requestCount++;
          await Future<void>.delayed(const Duration(milliseconds: 10));
          return const PublicCacheFetch(data: {'success': true, 'data': []});
        },
      );
    }

    await Future.wait([fetch(), fetch()]);

    expect(requestCount, 1);
  });

  test('updates stored public data only when the payload changes', () async {
    const key = 'public:/api/courses?page=1';
    await cache.fetchJson(
      key: key,
      ttl: const Duration(minutes: 5),
      forceRefresh: true,
      fetch: (_) async => const PublicCacheFetch(
        data: {
          'success': true,
          'data': [
            {'id': 'course-1', 'title': 'Old title'},
          ],
        },
        etag: '"courses-v1"',
      ),
    );

    final refreshed = await cache.fetchJson(
      key: key,
      ttl: const Duration(minutes: 5),
      forceRefresh: true,
      fetch: (etag) async {
        expect(etag, '"courses-v1"');
        return const PublicCacheFetch(
          data: {
            'success': true,
            'data': [
              {'id': 'course-1', 'title': 'New title'},
            ],
          },
          etag: '"courses-v2"',
        );
      },
    );

    expect(refreshed.changed, isTrue);
    expect((await cache.read(key))?.data['data'], [
      {'id': 'course-1', 'title': 'New title'},
    ]);
  });

  test('persists public data across cache reopen', () async {
    const key = 'public:/api/institutes?page=1';
    await cache.fetchJson(
      key: key,
      ttl: const Duration(minutes: 5),
      forceRefresh: true,
      fetch: (_) async =>
          const PublicCacheFetch(data: {'success': true, 'data': []}),
    );
    await cache.close();
    await Hive.close();

    Hive.init(directory.path);
    cache = PublicApiCache.fromBox(
      await Hive.openBox<String>('public_cache_test'),
    );

    expect((await cache.read(key))?.data, {'success': true, 'data': []});
  });
}
