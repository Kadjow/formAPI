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
  Future<List<Post>> fetchPosts() async {
    final remote = await _api.fetchPosts();
    await _local.setRemoteCache(remote);

    final created = _local.getCreatedCache();
    return [...created, ...remote];
  }

  @override
  Future<Post> createPost({required String title, required String body}) async {
    final created = await _api.createPost(title: title, body: body);

    final safe = Post(
      userId: created.userId ?? 1,
      id: created.id ?? _nextLocalId(),
      title: created.title,
      body: created.body,
    );

    await _local.addCreated(safe);
    return safe;
  }

  int _nextLocalId() {
    final created = _local.getCreatedCache();
    final maxCreated = created.fold<int>(100, (maxId, post) {
      final id = post.id ?? 0;
      return id > maxId ? id : maxId;
    });
    return maxCreated + 1;
  }
}
