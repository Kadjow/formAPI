import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../model/post.dart';

class PostsLocalDataSource {
  PostsLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  static const _remoteKey = 'posts_remote_cache_v2';
  static const _remoteNextStartKey = 'posts_remote_next_start_v2';
  static const _remoteHasMoreKey = 'posts_remote_has_more_v2';
  static const _createdKey = 'posts_created_cache_v2';

  List<Post> getRemoteCache() => _readList(_remoteKey);

  int getRemoteNextStart() =>
      _prefs.getInt(_remoteNextStartKey) ?? getRemoteCache().length;

  bool getRemoteHasMore() => _prefs.getBool(_remoteHasMoreKey) ?? true;

  List<Post> getCreatedCache() => _readList(_createdKey);

  Future<void> setRemoteCache(List<Post> posts) async {
    await _writeList(_remoteKey, posts);
    await _prefs.setInt(_remoteNextStartKey, posts.length);
  }

  Future<void> appendRemoteCache(List<Post> newPosts) async {
    final all = [...getRemoteCache(), ...newPosts];
    await setRemoteCache(all);
  }

  Future<void> setRemoteHasMore(bool value) async {
    await _prefs.setBool(_remoteHasMoreKey, value);
  }

  Future<void> resetRemotePagination() async {
    await setRemoteCache(const <Post>[]);
    await setRemoteHasMore(true);
  }

  Future<void> addCreated(Post post) async {
    final created = getCreatedCache();
    created.insert(0, post);
    await _writeList(_createdKey, created);
  }

  Future<void> removeCreatedById(int id) async {
    final created = getCreatedCache();
    created.removeWhere((post) => (post.id ?? -1) == id);
    await _writeList(_createdKey, created);
  }

  List<Post> _readList(String key) {
    final raw = _prefs.getString(key);
    if (raw == null || raw.isEmpty) {
      return <Post>[];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>().map(Post.fromJson).toList();
    } catch (_) {
      return <Post>[];
    }
  }

  Future<void> _writeList(String key, List<Post> posts) async {
    final raw = jsonEncode(posts.map((post) => post.toJson()).toList());
    await _prefs.setString(key, raw);
  }
}
