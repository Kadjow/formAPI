import '../model/post.dart';
import 'posts_api_service.dart';
import 'posts_local_datasource.dart';
import 'posts_repository.dart';

class PostsRepositoryImpl implements PostsRepository {
  PostsRepositoryImpl(this._api, this._local);

  final PostsApiService _api;
  final PostsLocalDataSource _local;

  @override
  List<Post> getCachedPosts() {
    final created = _local.getCreatedCache();
    final remote = _local.getRemoteCache();
    return [...created, ...remote];
  }

  @override
  Future<List<Post>> fetchPosts({int start = 0, int limit = 20}) async {
    final remotePage = await _api.fetchPosts(start: start, limit: limit);

    if (start == 0) {
      await _local.setRemoteCache(remotePage);
    } else {
      final current = _local.getRemoteCache();
      await _local.setRemoteCache([...current, ...remotePage]);
    }

    return getCachedPosts();
  }

  @override
  Future<Post> createPost({required String title, required String body}) async {
    final created = await _api.createPost(title: title, body: body);

    final safe = Post(
      userId: created.userId ?? 1,
      id: _nextLocalId(),
      title: created.title,
      body: created.body,
    );

    await _local.addCreated(safe);
    return safe;
  }

  @override
  Future<void> deleteLocalPost(int id) async {
    await _local.removeCreatedById(id);
  }

  int _nextLocalId() {
    final created = _local.getCreatedCache();
    final maxCreated = created.fold<int>(100, (max, p) {
      final id = p.id ?? 0;
      return id > max ? id : max;
    });
    return maxCreated + 1;
  }
}
