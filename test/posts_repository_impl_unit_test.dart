import 'package:flutter_test/flutter_test.dart';

import 'package:formapi/features/posts/data/posts_api_service.dart';
import 'package:formapi/features/posts/data/posts_local_datasource.dart';
import 'package:formapi/features/posts/data/posts_repository_impl.dart';
import 'package:formapi/features/posts/model/post.dart';

class InMemoryPostsApiService implements PostsApiService {
  InMemoryPostsApiService({
    Map<String, List<Post>>? fetchPages,
  }) : _fetchPages = fetchPages ?? <String, List<Post>>{};

  final Map<String, List<Post>> _fetchPages;
  final List<({int start, int limit})> fetchCalls = <({int start, int limit})>[];
  final List<({String title, String body})> createCalls = <({String title, String body})>[];

  String _key(int start, int limit) => '$start:$limit';

  @override
  Future<List<Post>> fetchPosts({int start = 0, int limit = 20}) async {
    fetchCalls.add((start: start, limit: limit));
    return List<Post>.from(_fetchPages[_key(start, limit)] ?? const <Post>[]);
  }

  @override
  Future<Post> createPost({required String title, required String body}) async {
    createCalls.add((title: title, body: body));
    return Post(userId: 1, id: 999, title: title, body: body);
  }
}

class InMemoryPostsLocalDataSource implements PostsLocalDataSource {
  InMemoryPostsLocalDataSource({
    List<Post>? remoteCache,
    List<Post>? createdCache,
    bool remoteHasMore = true,
  }) : _remoteCache = List<Post>.from(remoteCache ?? const <Post>[]),
       _createdCache = List<Post>.from(createdCache ?? const <Post>[]),
       _remoteHasMore = remoteHasMore,
       _remoteNextStart = (remoteCache ?? const <Post>[]).length;

  List<Post> _remoteCache;
  List<Post> _createdCache;
  bool _remoteHasMore;
  int _remoteNextStart;

  @override
  Future<void> addCreated(Post post) async {
    _createdCache = <Post>[post, ..._createdCache];
  }

  @override
  Future<void> appendRemoteCache(List<Post> newPosts) async {
    _remoteCache = <Post>[..._remoteCache, ...newPosts];
    _remoteNextStart = _remoteCache.length;
  }

  @override
  List<Post> getCreatedCache() => List<Post>.from(_createdCache);

  @override
  List<Post> getRemoteCache() => List<Post>.from(_remoteCache);

  @override
  bool getRemoteHasMore() => _remoteHasMore;

  @override
  int getRemoteNextStart() => _remoteNextStart;

  @override
  Future<void> removeCreatedById(int id) async {
    _createdCache = _createdCache.where((post) => post.id != id).toList();
  }

  @override
  Future<void> resetRemotePagination() async {
    _remoteCache = <Post>[];
    _remoteNextStart = 0;
    _remoteHasMore = true;
  }

  @override
  Future<void> setRemoteCache(List<Post> posts) async {
    _remoteCache = List<Post>.from(posts);
    _remoteNextStart = _remoteCache.length;
  }

  @override
  Future<void> setRemoteHasMore(bool value) async {
    _remoteHasMore = value;
  }

  @override
  Future<void> upsertCreated(Post post) async {
    _createdCache = <Post>[
      post,
      ..._createdCache.where((item) => item.id != post.id),
    ];
  }
}

List<Post> _remotePosts(int startId, int total) {
  return List<Post>.generate(
    total,
    (index) => Post(
      userId: 1,
      id: startId + index,
      title: 'Remote ${startId + index}',
      body: 'Body ${startId + index}',
    ),
  );
}

void main() {
  test('fetchPosts start 0 popula o remote cache', () async {
    final api = InMemoryPostsApiService(
      fetchPages: <String, List<Post>>{'0:20': _remotePosts(1, 20)},
    );
    final local = InMemoryPostsLocalDataSource();
    final repo = PostsRepositoryImpl(api, local);

    final result = await repo.fetchPosts(start: 0, limit: 20);

    expect(api.fetchCalls, orderedEquals([(start: 0, limit: 20)]));
    expect(local.getRemoteCache().length, 20);
    expect(local.getRemoteCache().first.id, 1);
    expect(result.length, 20);
  });

  test('fetchPosts start 20 apenda a proxima pagina remota', () async {
    final api = InMemoryPostsApiService(
      fetchPages: <String, List<Post>>{
        '0:20': _remotePosts(1, 20),
        '20:20': _remotePosts(21, 20),
      },
    );
    final local = InMemoryPostsLocalDataSource();
    final repo = PostsRepositoryImpl(api, local);

    await repo.fetchPosts(start: 0, limit: 20);
    final result = await repo.fetchPosts(start: 20, limit: 20);

    expect(local.getRemoteCache().length, 40);
    expect(local.getRemoteCache().first.id, 1);
    expect(local.getRemoteCache().last.id, 40);
    expect(result.length, 40);
  });

  test('createPost gera id local unico e adiciona no created cache', () async {
    final api = InMemoryPostsApiService();
    final local = InMemoryPostsLocalDataSource(
      createdCache: <Post>[
        const Post(userId: 1, id: 101, title: 'Existente', body: 'Body'),
      ],
    );
    final repo = PostsRepositoryImpl(api, local);

    final first = await repo.createPost(title: 'Novo 1', body: 'Body 1');
    final second = await repo.createPost(title: 'Novo 2', body: 'Body 2');

    expect(first.id, 102);
    expect(second.id, 103);
    expect(second.id! >= 101, isTrue);
    expect(
      local.getCreatedCache().map((post) => post.id).toList(),
      orderedEquals([103, 102, 101]),
    );
    expect(local.getCreatedCache().first.title, 'Novo 2');
  });

  test('deleteLocalPost remove somente o alvo', () async {
    final api = InMemoryPostsApiService();
    final local = InMemoryPostsLocalDataSource(
      createdCache: <Post>[
        const Post(userId: 1, id: 103, title: 'C', body: 'C body'),
        const Post(userId: 1, id: 102, title: 'B', body: 'B body'),
        const Post(userId: 1, id: 101, title: 'A', body: 'A body'),
      ],
    );
    final repo = PostsRepositoryImpl(api, local);

    await repo.deleteLocalPost(102);

    expect(
      local.getCreatedCache().map((post) => post.id).toList(),
      orderedEquals([103, 101]),
    );
  });

  test('restoreLocalPost reinsere usando upsert', () async {
    final api = InMemoryPostsApiService();
    final local = InMemoryPostsLocalDataSource(
      createdCache: <Post>[
        const Post(userId: 1, id: 103, title: 'Outro', body: 'Outro body'),
        const Post(userId: 1, id: 101, title: 'Antigo', body: 'Body antigo'),
      ],
    );
    final repo = PostsRepositoryImpl(api, local);

    await repo.restoreLocalPost(
      const Post(userId: 1, id: 101, title: 'Restaurado', body: 'Body novo'),
    );

    final created = local.getCreatedCache();

    expect(created.map((post) => post.id).toList(), orderedEquals([101, 103]));
    expect(created.first.title, 'Restaurado');
    expect(created.first.body, 'Body novo');
  });
}
