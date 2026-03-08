import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:formapi/features/posts/data/posts_repository.dart';
import 'package:formapi/features/posts/model/post.dart';
import 'package:formapi/features/posts/state/posts_providers.dart';

class FakePostsRepository implements PostsRepository {
  FakePostsRepository({
    List<Post>? initialRemote,
    List<Post>? initialCreated,
    this.moreRemote = const <Post>[],
  }) : _remote = initialRemote ?? <Post>[],
       _created = initialCreated ?? <Post>[];

  final List<Post> _remote;
  final List<Post> _created;
  final List<Post> moreRemote;
  bool _appendedMore = false;

  @override
  List<Post> getCachedPosts() => [..._created, ..._remote];

  @override
  Future<List<Post>> fetchPosts({int start = 0, int limit = 20}) async {
    if (start > 0 && !_appendedMore && moreRemote.isNotEmpty) {
      _remote.addAll(moreRemote);
      _appendedMore = true;
    }

    return getCachedPosts();
  }

  @override
  Future<Post> createPost({required String title, required String body}) async {
    final id = (_created.isEmpty ? 101 : (_created.first.id ?? 101) + 1);
    final post = Post(userId: 1, id: id, title: title, body: body);
    _created.insert(0, post);
    return post;
  }

  @override
  Future<void> deleteLocalPost(int id) async {
    _created.removeWhere((post) => post.id == id);
  }
}

void main() {
  test('create adiciona no topo', () async {
    final repo = FakePostsRepository(
      initialRemote: [const Post(userId: 1, id: 1, title: 'R1', body: 'B1')],
    );

    final container = ProviderContainer(
      overrides: [postsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(postsViewModelProvider.future);
    await Future<void>.delayed(Duration.zero);

    await container
        .read(postsViewModelProvider.notifier)
        .create(title: 'Local', body: 'Desc');

    final state = container.read(postsViewModelProvider);
    expect(state.value!.first.title, 'Local');
  });

  test('loadMore apenda itens e desliga hasMore', () async {
    final initialRemote = List.generate(
      20,
      (index) => Post(
        userId: 1,
        id: index + 1,
        title: 'R${index + 1}',
        body: 'B${index + 1}',
      ),
    );
    final repo = FakePostsRepository(
      initialRemote: initialRemote,
      moreRemote: [const Post(userId: 1, id: 2, title: 'R2', body: 'B2')],
    );

    final container = ProviderContainer(
      overrides: [postsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(postsViewModelProvider.future);
    await Future<void>.delayed(Duration.zero);

    await container.read(postsViewModelProvider.notifier).loadMore();

    final state = container.read(postsViewModelProvider);
    expect(state.value!.length, 21);
    expect(container.read(postsHasMoreProvider), false);
  });
}
