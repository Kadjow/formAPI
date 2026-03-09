import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:formapi/core/storage/shared_preferences_provider.dart';
import 'package:formapi/features/posts/model/post.dart';
import 'package:formapi/features/posts/state/posts_providers.dart';
import 'package:formapi/features/posts/state/posts_view_model.dart';
import 'package:formapi/features/posts/ui/post_detail_page.dart';
import 'package:formapi/features/posts/ui/posts_list_page.dart';

class FakePostsListViewModel extends PostsViewModel {
  FakePostsListViewModel(this.initialData);

  final PostsPageData initialData;
  final List<int> deletedIds = <int>[];
  final List<Post> restoredPosts = <Post>[];

  @override
  Future<PostsPageData> build() async => initialData;

  @override
  Future<void> deleteLocal(int id) async {
    deletedIds.add(id);
    final current = state.value ?? initialData;
    state = AsyncValue.data(
      current.copyWith(
        posts: current.posts.where((post) => post.id != id).toList(),
      ),
    );
  }

  @override
  Future<void> restoreLocal(Post post) async {
    restoredPosts.add(post);
    final current = state.value ?? initialData;
    state = AsyncValue.data(
      current.copyWith(
        posts: <Post>[
          post,
          ...current.posts.where((item) => item.id != post.id),
        ],
      ),
    );
  }
}

List<Post> _remotePosts() {
  return List<Post>.generate(
    20,
    (index) => Post(
      userId: 1,
      id: index + 1,
      title: 'Remote ${index + 1}',
      body: 'Body ${index + 1}',
    ),
  );
}

List<Post> _localPosts() {
  return const <Post>[
    Post(userId: 1, id: 101, title: 'Local 101', body: 'Local body 101'),
    Post(userId: 1, id: 102, title: 'Local 102', body: 'Local body 102'),
  ];
}

Future<void> _pumpPostsListPage(
  WidgetTester tester,
  FakePostsListViewModel fake,
  SharedPreferences prefs,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        postsViewModelProvider.overrideWith(() => fake),
      ],
      child: const MaterialApp(home: PostsListPage()),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late FakePostsListViewModel fake;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    fake = FakePostsListViewModel(
      PostsPageData(
        posts: <Post>[..._localPosts(), ..._remotePosts()],
        hasMore: true,
        isLoadingMore: false,
      ),
    );
  });

  testWidgets('tabs mostram contagem e botao carregar mais aparece', (tester) async {
    await _pumpPostsListPage(tester, fake, prefs);

    expect(find.text('Todos (20)'), findsOneWidget);
    expect(find.text('Locais (2)'), findsOneWidget);
    final loadMore = find.text('Carregar mais');
    final remoteListScrollable = find.descendant(
      of: find.byType(RefreshIndicator).first,
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(
      loadMore,
      300,
      scrollable: remoteListScrollable,
    );
    expect(find.text('Carregar mais'), findsOneWidget);
  });

  testWidgets('swipe delete em local mostra DESFAZER e restaura o item', (tester) async {
    await _pumpPostsListPage(tester, fake, prefs);

    await tester.tap(find.text('Locais (2)'));
    await tester.pumpAndSettle();

    expect(find.text('Local 101'), findsOneWidget);

    await tester.drag(find.byKey(const ValueKey<String>('local_101')), const Offset(-600, 0));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Excluir'));
    await tester.pumpAndSettle();

    expect(fake.deletedIds, orderedEquals([101]));
    expect(find.text('DESFAZER'), findsOneWidget);
    expect(find.text('Local 101'), findsNothing);

    await tester.tap(find.text('DESFAZER'));
    await tester.pumpAndSettle();

    expect(fake.restoredPosts.map((post) => post.id).toList(), orderedEquals([101]));
    expect(find.text('Local 101'), findsOneWidget);
  });

  testWidgets('tap em card abre a PostDetailPage', (tester) async {
    await _pumpPostsListPage(tester, fake, prefs);

    await tester.tap(find.text('Remote 1'));
    await tester.pumpAndSettle();

    expect(find.byType(PostDetailPage), findsOneWidget);
    expect(find.text('Detalhes'), findsOneWidget);
    expect(find.text('Body 1'), findsOneWidget);
  });
}
