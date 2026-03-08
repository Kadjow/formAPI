import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:formapi/features/posts/data/posts_api_service.dart';
import 'package:formapi/features/posts/data/posts_local_datasource.dart';
import 'package:formapi/features/posts/data/posts_repository_impl.dart';
import 'package:formapi/features/posts/model/post.dart';

class MockPostsApiService extends Mock implements PostsApiService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('fetchPosts salva cache remoto inicial', () async {
    final api = MockPostsApiService();
    final prefs = await SharedPreferences.getInstance();
    final local = PostsLocalDataSource(prefs);
    final repo = PostsRepositoryImpl(api, local);

    final page1 = [
      const Post(userId: 1, id: 1, title: 'R1', body: 'B1'),
      const Post(userId: 1, id: 2, title: 'R2', body: 'B2'),
    ];

    when(
      () => api.fetchPosts(start: 0, limit: 2),
    ).thenAnswer((_) async => page1);

    final result = await repo.fetchPosts(start: 0, limit: 2);

    expect(result.length, 2);
    expect(local.getRemoteCache().length, 2);
  });

  test('fetchPosts com start apenda proxima pagina no cache remoto', () async {
    final api = MockPostsApiService();
    final prefs = await SharedPreferences.getInstance();
    final local = PostsLocalDataSource(prefs);
    final repo = PostsRepositoryImpl(api, local);

    final page1 = [
      const Post(userId: 1, id: 1, title: 'R1', body: 'B1'),
      const Post(userId: 1, id: 2, title: 'R2', body: 'B2'),
    ];
    final page2 = [const Post(userId: 1, id: 3, title: 'R3', body: 'B3')];

    when(
      () => api.fetchPosts(start: 0, limit: 2),
    ).thenAnswer((_) async => page1);
    when(
      () => api.fetchPosts(start: 2, limit: 2),
    ).thenAnswer((_) async => page2);

    await repo.fetchPosts(start: 0, limit: 2);
    final result = await repo.fetchPosts(start: 2, limit: 2);

    expect(local.getRemoteCache().length, 3);
    expect(result.length, 3);
  });

  test('createPost persiste localmente com id unico', () async {
    final api = MockPostsApiService();
    final prefs = await SharedPreferences.getInstance();
    final local = PostsLocalDataSource(prefs);
    final repo = PostsRepositoryImpl(api, local);

    when(
      () => api.createPost(
        title: any(named: 'title'),
        body: any(named: 'body'),
      ),
    ).thenAnswer(
      (_) async => const Post(userId: 1, id: 101, title: 'Novo', body: 'Desc'),
    );

    final p1 = await repo.createPost(title: 'Novo', body: 'Desc');
    final p2 = await repo.createPost(title: 'Novo2', body: 'Desc2');

    expect(p1.id, isNotNull);
    expect(p2.id, isNotNull);
    expect(p2.id! > p1.id!, true);

    final createdCache = local.getCreatedCache();
    expect(createdCache.length, 2);
  });
}
