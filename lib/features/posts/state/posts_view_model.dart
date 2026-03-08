import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/posts_repository.dart';
import '../model/post.dart';
import 'posts_dependencies.dart';

class PostsViewModel extends AsyncNotifier<List<Post>> {
  late final PostsRepository _repo;

  @override
  Future<List<Post>> build() async {
    _repo = ref.watch(postsRepositoryProvider);

    final cached = _repo.getCachedPosts();
    if (cached.isNotEmpty) {
      Future.microtask(_syncRemoteSilently);
      return cached;
    }

    return _repo.fetchPosts();
  }

  Future<void> _syncRemoteSilently() async {
    try {
      final fresh = await _repo.fetchPosts();
      state = AsyncValue.data(fresh);
    } catch (_) {
      // Mantem o cache atual se a sincronizacao falhar.
    }
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _repo.fetchPosts());
  }

  Future<void> create({required String title, required String body}) async {
    final current = state.value ?? const <Post>[];
    final created = await _repo.createPost(title: title, body: body);
    state = AsyncValue.data([created, ...current]);
  }
}
