import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/posts_repository.dart';
import '../model/post.dart';
import 'posts_providers.dart';

class PostsViewModel extends AsyncNotifier<List<Post>> {
  static const int _pageSize = 20;
  static const int _localPostMinId = 101;

  late final PostsRepository _repo;

  void _syncUiState({required bool hasMore, required bool isLoadingMore}) {
    Future.microtask(() {
      ref.read(postsHasMoreProvider.notifier).set(hasMore);
      ref.read(postsIsLoadingMoreProvider.notifier).set(isLoadingMore);
    });
  }

  @override
  Future<List<Post>> build() async {
    _repo = ref.watch(postsRepositoryProvider);

    final cached = _repo.getCachedPosts();
    if (cached.isNotEmpty) {
      _syncUiState(
        hasMore: _inferHasMoreFromCache(cached),
        isLoadingMore: false,
      );
      return cached;
    }

    final fresh = await _repo.fetchPosts(start: 0, limit: _pageSize);
    _syncUiState(
      hasMore: _remoteCount(fresh) == _pageSize,
      isLoadingMore: false,
    );
    return fresh;
  }

  Future<void> refresh() async {
    ref.read(postsIsLoadingMoreProvider.notifier).set(false);

    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => _repo.fetchPosts(start: 0, limit: _pageSize),
    );

    final current = state.value ?? const <Post>[];
    ref.read(postsHasMoreProvider.notifier).set(_remoteCount(current) == _pageSize);
  }

  Future<void> loadMore() async {
    final hasMore = ref.read(postsHasMoreProvider);
    final isLoading = ref.read(postsIsLoadingMoreProvider);
    if (!hasMore || isLoading) {
      return;
    }

    ref.read(postsIsLoadingMoreProvider.notifier).set(true);

    try {
      final current = state.value ?? const <Post>[];
      final previousRemoteCount = _remoteCount(current);
      final more = await _repo.fetchPosts(
        start: previousRemoteCount,
        limit: _pageSize,
      );
      final fetchedRemoteCount = _remoteCount(more) - previousRemoteCount;
      state = AsyncValue.data(more);
      ref
          .read(postsHasMoreProvider.notifier)
          .set(fetchedRemoteCount == _pageSize);
    } finally {
      ref.read(postsIsLoadingMoreProvider.notifier).set(false);
    }
  }

  Future<void> create({required String title, required String body}) async {
    final current = state.value ?? const <Post>[];
    final created = await _repo.createPost(title: title, body: body);
    state = AsyncValue.data([created, ...current]);
  }

  Future<void> deleteLocal(int id) async {
    final current = state.value ?? const <Post>[];
    state = AsyncValue.data(
      current.where((post) => (post.id ?? -1) != id).toList(),
    );
    await _repo.deleteLocalPost(id);
  }

  bool _inferHasMoreFromCache(List<Post> posts) {
    final remoteCount = _remoteCount(posts);
    return remoteCount == 0 || remoteCount % _pageSize == 0;
  }

  int _remoteCount(List<Post> posts) {
    return posts.where((post) {
      final id = post.id;
      return id != null && id < _localPostMinId;
    }).length;
  }
}
