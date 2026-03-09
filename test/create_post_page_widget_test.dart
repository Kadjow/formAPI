import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:formapi/features/posts/model/post.dart';
import 'package:formapi/features/posts/state/posts_providers.dart';
import 'package:formapi/features/posts/state/posts_view_model.dart';
import 'package:formapi/features/posts/ui/create_post_page.dart';

class FakeCreatePostsViewModel extends PostsViewModel {
  int createCalls = 0;
  String? lastTitle;
  String? lastBody;
  bool shouldThrowOnCreate = false;

  @override
  Future<PostsPageData> build() async {
    return const PostsPageData(
      posts: <Post>[],
      hasMore: false,
      isLoadingMore: false,
    );
  }

  @override
  Future<void> create({required String title, required String body}) async {
    createCalls += 1;
    lastTitle = title;
    lastBody = body;

    if (shouldThrowOnCreate) {
      throw Exception('create failed');
    }
  }
}

class _CreatePostLauncher extends StatefulWidget {
  const _CreatePostLauncher();

  @override
  State<_CreatePostLauncher> createState() => _CreatePostLauncherState();
}

class _CreatePostLauncherState extends State<_CreatePostLauncher> {
  bool? lastResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text('result:${lastResult?.toString() ?? 'null'}'),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                final result = await Navigator.of(context).push<bool>(
                  MaterialPageRoute<bool>(
                    builder: (_) => const CreatePostPage(),
                  ),
                );

                if (!mounted) {
                  return;
                }

                setState(() {
                  lastResult = result;
                });
              },
              child: const Text('Abrir criacao'),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> _pumpCreatePage(
  WidgetTester tester,
  FakeCreatePostsViewModel fake,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [postsViewModelProvider.overrideWith(() => fake)],
      child: const MaterialApp(home: _CreatePostLauncher()),
    ),
  );
  await tester.tap(find.text('Abrir criacao'));
  await tester.pumpAndSettle();
}

Future<void> tapSalvar(WidgetTester tester) async {
  final btn = find.widgetWithText(FilledButton, 'Salvar post');
  await tester.ensureVisible(btn);
  await tester.tap(btn);
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('campos vazios nao chamam create nem fecham a pagina', (tester) async {
    final fake = FakeCreatePostsViewModel();

    await _pumpCreatePage(tester, fake);

    await tapSalvar(tester);

    expect(fake.createCalls, 0);
    expect(find.byType(CreatePostPage), findsOneWidget);
    expect(find.text('result:true'), findsNothing);
  });

  testWidgets('campos preenchidos chamam create e pop retorna true', (tester) async {
    final fake = FakeCreatePostsViewModel();

    await _pumpCreatePage(tester, fake);

    await tester.enterText(find.byType(TextFormField).at(0), 'Titulo teste');
    await tester.enterText(find.byType(TextFormField).at(1), 'Corpo teste');
    await tapSalvar(tester);

    expect(fake.createCalls, 1);
    expect(fake.lastTitle, 'Titulo teste');
    expect(fake.lastBody, 'Corpo teste');
    expect(find.byType(CreatePostPage), findsNothing);
    expect(find.text('result:true'), findsOneWidget);
  });

  testWidgets('erro ao criar mostra snackbar e nao fecha a pagina', (tester) async {
    final fake = FakeCreatePostsViewModel()..shouldThrowOnCreate = true;

    await _pumpCreatePage(tester, fake);

    await tester.enterText(find.byType(TextFormField).at(0), 'Titulo teste');
    await tester.enterText(find.byType(TextFormField).at(1), 'Corpo teste');
    await tapSalvar(tester);

    expect(fake.createCalls, 1);
    expect(find.byType(CreatePostPage), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('salvar o post'), findsOneWidget);
    expect(find.text('result:true'), findsNothing);
  });
}
