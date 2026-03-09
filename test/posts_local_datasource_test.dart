import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:formapi/features/posts/data/posts_local_datasource.dart';
import 'package:formapi/features/posts/model/post.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late PostsLocalDataSource dataSource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    dataSource = PostsLocalDataSource(prefs);
  });

  test('salva e le o cache de created', () async {
    const first = Post(userId: 1, id: 101, title: 'Primeiro', body: 'Body 1');
    const second = Post(userId: 1, id: 102, title: 'Segundo', body: 'Body 2');

    await dataSource.addCreated(first);
    await dataSource.addCreated(second);

    final created = dataSource.getCreatedCache();

    expect(created.map((post) => post.id).toList(), orderedEquals([102, 101]));
    expect(created.map((post) => post.title).toList(), orderedEquals(['Segundo', 'Primeiro']));
  });

  test('removeCreatedById remove somente o post alvo', () async {
    await dataSource.addCreated(
      const Post(userId: 1, id: 101, title: 'A', body: 'A body'),
    );
    await dataSource.addCreated(
      const Post(userId: 1, id: 102, title: 'B', body: 'B body'),
    );
    await dataSource.addCreated(
      const Post(userId: 1, id: 103, title: 'C', body: 'C body'),
    );

    await dataSource.removeCreatedById(102);

    final created = dataSource.getCreatedCache();

    expect(created.map((post) => post.id).toList(), orderedEquals([103, 101]));
    expect(created.any((post) => post.id == 102), isFalse);
  });

  test('upsertCreated substitui ou insere e mantem o post no topo', () async {
    await dataSource.addCreated(
      const Post(userId: 1, id: 101, title: 'Original', body: 'Old body'),
    );
    await dataSource.addCreated(
      const Post(userId: 1, id: 102, title: 'Outro', body: 'Body 2'),
    );

    await dataSource.upsertCreated(
      const Post(userId: 1, id: 101, title: 'Atualizado', body: 'New body'),
    );

    var created = dataSource.getCreatedCache();

    expect(created.map((post) => post.id).toList(), orderedEquals([101, 102]));
    expect(created.first.title, 'Atualizado');
    expect(created.first.body, 'New body');

    await dataSource.upsertCreated(
      const Post(userId: 1, id: 103, title: 'Novo topo', body: 'Body 3'),
    );

    created = dataSource.getCreatedCache();

    expect(created.map((post) => post.id).toList(), orderedEquals([103, 101, 102]));
  });

  test('gerencia remote cache e flags de paginacao', () async {
    expect(dataSource.getRemoteCache(), isEmpty);
    expect(dataSource.getRemoteNextStart(), 0);
    expect(dataSource.getRemoteHasMore(), isTrue);

    await dataSource.setRemoteCache([
      const Post(userId: 1, id: 1, title: 'R1', body: 'B1'),
      const Post(userId: 1, id: 2, title: 'R2', body: 'B2'),
    ]);

    expect(
      dataSource.getRemoteCache().map((post) => post.id).toList(),
      orderedEquals([1, 2]),
    );
    expect(dataSource.getRemoteNextStart(), 2);

    await dataSource.appendRemoteCache([
      const Post(userId: 1, id: 3, title: 'R3', body: 'B3'),
    ]);

    expect(
      dataSource.getRemoteCache().map((post) => post.id).toList(),
      orderedEquals([1, 2, 3]),
    );
    expect(dataSource.getRemoteNextStart(), 3);

    await dataSource.setRemoteHasMore(false);
    expect(dataSource.getRemoteHasMore(), isFalse);

    await dataSource.resetRemotePagination();

    expect(dataSource.getRemoteCache(), isEmpty);
    expect(dataSource.getRemoteNextStart(), 0);
    expect(dataSource.getRemoteHasMore(), isTrue);
  });
}
