import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:sqflite/sqflite.dart';

import '../api_client.dart';
import '../local/db.dart';
import '../local/post.dart';

class PostCacheRepository {
  PostCacheRepository({Dio? dio, Future<Database> Function()? openDb})
      : _dio = dio ?? createDio(),
        _openDb = openDb ?? openNotesDb;

  final Dio _dio;
  final Future<Database> Function() _openDb;

  Future<List<Post>> readCachedPosts() async {
    final db = await _openDb();
    final rows = await db.query('cached_posts', orderBy: 'id ASC');
    return rows.map((row) {
      return Post.fromJson(
        jsonDecode(row['payload'] as String) as Map<String, dynamic>,
      );
    }).toList();
  }

  Future<List<Post>> fetchPostsFromNetwork() async {
    final response = await _dio.get<List<dynamic>>('/posts');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Post.fromJson)
        .toList();
  }

  Future<void> saveCachedPosts(List<Post> posts) async {
    final db = await _openDb();
    await db.transaction((transaction) async {
      for (final post in posts) {
        await transaction.insert(
          'cached_posts',
          {
            'id': post.id,
            'payload': jsonEncode(post.toJson()),
            'cached_at': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }
}
