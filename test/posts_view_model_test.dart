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
  })  : _remote = initialRemote ?? <Post>[],
        _created = initialCreated ?? <Post>[];

  final List<Post> _remote;
  final List<Post> _created;
  final List<Post> moreRemote;

  @override
  List<Post> getCachedPosts() => [..._created, ..._remote];

  @override
  Future<List<Post>> fetchPosts({int start = 0, int limit = 20}) async {
    if (start > 0 && moreRemote.isNotEmpty && !_remote.contains(moreRemote.first)) {
      _remote.addAll(moreRemote);
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

  @override
  Future<void> restoreLocalPost(Post post) async {
    _created.removeWhere((item) => item.id == post.id);
    _created.insert(0, post);
  }
}

void main() {
  test('create adiciona post local no topo', () async {
    final repo = FakePostsRepository(
      initialRemote: List.generate(
        20,
        (index) => Post(
          userId: 1,
          id: index + 1,
          title: 'R${index + 1}',
          body: 'B${index + 1}',
        ),
      ),
    );

    final container = ProviderContainer(
      overrides: [postsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(postsViewModelProvider.future);

    await container.read(postsViewModelProvider.notifier).create(
          title: 'Local',
          body: 'Desc',
        );

    final state = container.read(postsViewModelProvider);
    expect(state.value!.posts.first.title, 'Local');
  });

  test('loadMore aumenta quantidade exibida quando ha mais remoto', () async {
    final repo = FakePostsRepository(
      initialRemote: List.generate(
        20,
        (index) => Post(
          userId: 1,
          id: index + 1,
          title: 'R${index + 1}',
          body: 'B${index + 1}',
        ),
      ),
      moreRemote: [
        const Post(userId: 1, id: 21, title: 'R21', body: 'B21'),
      ],
    );

    final container = ProviderContainer(
      overrides: [postsRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    await container.read(postsViewModelProvider.future);

    await container.read(postsViewModelProvider.notifier).loadMore();

    final state = container.read(postsViewModelProvider).value!;
    expect(state.posts.length >= 21, true);
  });
}
