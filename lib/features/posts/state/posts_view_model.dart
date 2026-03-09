import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/posts_repository.dart';
import '../model/post.dart';
import 'posts_dependencies.dart';

class PostsPageData {
  const PostsPageData({
    required this.posts,
    required this.hasMore,
    required this.isLoadingMore,
    this.loadMoreErrorId = 0,
    this.loadMoreError,
  });

  static const Object _loadMoreErrorSentinel = Object();

  final List<Post> posts;
  final bool hasMore;
  final bool isLoadingMore;
  final int loadMoreErrorId;
  final String? loadMoreError;

  PostsPageData copyWith({
    List<Post>? posts,
    bool? hasMore,
    bool? isLoadingMore,
    int? loadMoreErrorId,
    Object? loadMoreError = _loadMoreErrorSentinel,
  }) {
    return PostsPageData(
      posts: posts ?? this.posts,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreErrorId: loadMoreErrorId ?? this.loadMoreErrorId,
      loadMoreError: identical(loadMoreError, _loadMoreErrorSentinel)
          ? this.loadMoreError
          : loadMoreError as String?,
    );
  }
}

class PostsViewModel extends AsyncNotifier<PostsPageData> {
  static const int _pageSize = 20;
  static const int _remoteTotal = 100;
  static const int _localMinId = 101;

  late final PostsRepository _repo;

  int _remoteShown = 0;
  int _loadMoreErrorId = 0;
  String? _loadMoreError;

  bool _isLocal(Post post) => (post.id ?? 0) >= _localMinId;
  bool _isRemote(Post post) => (post.id ?? 0) > 0 && (post.id ?? 0) < _localMinId;

  List<Post> _localsFrom(List<Post> all) => all.where(_isLocal).toList();
  List<Post> _remotesFrom(List<Post> all) => all.where(_isRemote).toList();

  PostsPageData _makeData(List<Post> all, {required bool isLoadingMore}) {
    final locals = _localsFrom(all);
    final remotes = _remotesFrom(all);
    final shown = math.min(_remoteShown, remotes.length);
    final composed = <Post>[...locals, ...remotes.take(shown)];

    final canRevealMore = remotes.length > _remoteShown;
    final canFetchMore = remotes.length < _remoteTotal;

    return PostsPageData(
      posts: composed,
      hasMore: canRevealMore || canFetchMore,
      isLoadingMore: isLoadingMore,
      loadMoreErrorId: _loadMoreErrorId,
      loadMoreError: _loadMoreError,
    );
  }

  @override
  Future<PostsPageData> build() async {
    _repo = ref.watch(postsRepositoryProvider);

    final cached = _repo.getCachedPosts();
    final cachedRemotes = _remotesFrom(cached);

    if (cached.isNotEmpty) {
      _remoteShown = math.min(_pageSize, cachedRemotes.length);
      _loadMoreError = null;
      return _makeData(cached, isLoadingMore: false);
    }

    await _repo.fetchPosts(start: 0, limit: _pageSize);
    final all = _repo.getCachedPosts();
    final remotes = _remotesFrom(all);
    _remoteShown = math.min(_pageSize, remotes.length);
    _loadMoreError = null;

    return _makeData(all, isLoadingMore: false);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      await _repo.fetchPosts(start: 0, limit: _pageSize);
      final all = _repo.getCachedPosts();
      final remotes = _remotesFrom(all);
      _remoteShown = math.min(_pageSize, remotes.length);
      _loadMoreError = null;
      return _makeData(all, isLoadingMore: false);
    });
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) {
      return;
    }

    _loadMoreError = null;
    state = AsyncValue.data(
      current.copyWith(
        isLoadingMore: true,
        loadMoreError: null,
      ),
    );

    try {
      final cachedNow = _repo.getCachedPosts();
      final cachedRemotes = _remotesFrom(cachedNow);

      if (cachedRemotes.length > _remoteShown) {
        _remoteShown = math.min(_remoteShown + _pageSize, cachedRemotes.length);
        state = AsyncValue.data(_makeData(cachedNow, isLoadingMore: false));
        return;
      }

      final beforeRemoteCount = cachedRemotes.length;
      if (beforeRemoteCount >= _remoteTotal) {
        state = AsyncValue.data(_makeData(cachedNow, isLoadingMore: false));
        return;
      }

      await _repo.fetchPosts(start: beforeRemoteCount, limit: _pageSize);

      final all = _repo.getCachedPosts();
      final afterRemoteCount = _remotesFrom(all).length;
      _remoteShown = math.min(_remoteShown + _pageSize, afterRemoteCount);

      state = AsyncValue.data(_makeData(all, isLoadingMore: false));
    } catch (_) {
      _loadMoreErrorId++;
      _loadMoreError = 'Não foi possível carregar mais posts. Tente novamente.';
      state = AsyncValue.data(
        current.copyWith(
          isLoadingMore: false,
          loadMoreErrorId: _loadMoreErrorId,
          loadMoreError: _loadMoreError,
        ),
      );
    }
  }

  Future<void> create({required String title, required String body}) async {
    if (state.value == null) {
      return;
    }

    await _repo.createPost(title: title, body: body);

    final all = _repo.getCachedPosts();
    _loadMoreError = null;
    state = AsyncValue.data(_makeData(all, isLoadingMore: false));
  }

  Future<void> deleteLocal(int id) async {
    final current = state.value;
    if (current == null) {
      return;
    }

    final optimistic = current.posts.where((post) => (post.id ?? -1) != id).toList();
    state = AsyncValue.data(current.copyWith(posts: optimistic));

    await _repo.deleteLocalPost(id);

    final all = _repo.getCachedPosts();
    _loadMoreError = null;
    state = AsyncValue.data(_makeData(all, isLoadingMore: false));
  }

  Future<void> restoreLocal(Post post) async {
    await _repo.restoreLocalPost(post);
    final all = _repo.getCachedPosts();
    _loadMoreError = null;
    state = AsyncValue.data(_makeData(all, isLoadingMore: false));
  }
}
