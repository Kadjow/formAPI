import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/theme_mode_controller.dart';
import '../../../core/ui/app_snackbar.dart';
import '../model/post.dart';
import '../state/posts_providers.dart';
import 'create_post_page.dart';
import 'post_detail_page.dart';

class PostsListPage extends ConsumerStatefulWidget {
  const PostsListPage({super.key});

  @override
  ConsumerState<PostsListPage> createState() => _PostsListPageState();
}

class _PostsListPageState extends ConsumerState<PostsListPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  int _lastLoadMoreErrorId = 0;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  bool _isLocal(Post post) => (post.id ?? 0) > 100;

  Future<void> _openCreate() async {
    final created = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const CreatePostPage()),
    );

    if (!mounted || created != true) {
      return;
    }

    _tabs.animateTo(1);
    AppSnackBar.show(
      context,
      'Post criado! Confira na guia "Locais".',
      icon: Icons.check_circle_outline,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(postsViewModelProvider, (prev, next) {
      final data = next.asData?.value;
      if (data == null) {
        return;
      }

      if (data.loadMoreError != null && data.loadMoreErrorId != _lastLoadMoreErrorId) {
        _lastLoadMoreErrorId = data.loadMoreErrorId;
        AppSnackBar.show(
          context,
          data.loadMoreError!,
          icon: Icons.error_outline,
        );
      }
    });

    final state = ref.watch(postsViewModelProvider);
    final mode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Posts'),
        actions: [
          IconButton(
            tooltip: 'Alternar tema',
            onPressed: () => ref.read(themeModeProvider.notifier).toggleLightDark(),
            icon: Icon(
              mode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(
              child: state.maybeWhen(
                data: (data) {
                  final remoteCount =
                      data.posts.where((post) => (post.id ?? 0) <= 100).length;
                  return Text('Todos ($remoteCount)');
                },
                orElse: () => const Text('Todos'),
              ),
            ),
            Tab(
              child: state.maybeWhen(
                data: (data) {
                  final localsCount =
                      data.posts.where((post) => (post.id ?? 0) > 100).length;
                  return Text('Locais ($localsCount)');
                },
                orElse: () => const Text('Locais'),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreate,
        child: const Icon(Icons.add),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => _ErrorState(
          message: err.toString(),
          onRetry: () => ref.read(postsViewModelProvider.notifier).refresh(),
        ),
        data: (data) {
          final posts = data.posts;
          final remotePosts = posts.where((post) => !_isLocal(post)).toList();
          final localPosts = posts.where(_isLocal).toList();

          return TabBarView(
            controller: _tabs,
            children: [
              RefreshIndicator(
                onRefresh: () => ref.read(postsViewModelProvider.notifier).refresh(),
                child: ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: remotePosts.length + 1,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == remotePosts.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Center(
                          child: data.isLoadingMore
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: CircularProgressIndicator(),
                                )
                              : OutlinedButton.icon(
                                  onPressed: data.hasMore
                                      ? () => ref.read(postsViewModelProvider.notifier).loadMore()
                                      : null,
                                  icon: const Icon(Icons.expand_more),
                                  label: Text(
                                    data.hasMore ? 'Carregar mais' : 'Sem mais posts',
                                  ),
                                ),
                        ),
                      );
                    }

                    final post = remotePosts[index];
                    return _PostCard(
                      post: post,
                      isLocal: false,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
                        );
                      },
                    );
                  },
                ),
              ),
              localPosts.isEmpty
                  ? RefreshIndicator(
                      onRefresh: () => ref.read(postsViewModelProvider.notifier).refresh(),
                      child: ListView(
                        children: [
                          const SizedBox(height: 220),
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.inbox_outlined, size: 56),
                                  const SizedBox(height: 12),
                                  const Text('Nenhum post local ainda.'),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Crie um post pelo botao + para ele aparecer aqui.',
                                    textAlign: TextAlign.center,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: 16),
                                  ElevatedButton.icon(
                                    onPressed: _openCreate,
                                    icon: const Icon(Icons.add),
                                    label: const Text('Criar post'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(12),
                      itemCount: localPosts.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final post = localPosts[index];

                        final tile = _PostCard(
                          post: post,
                          isLocal: true,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => PostDetailPage(post: post)),
                            );
                          },
                        );

                        if (post.id == null) {
                          return tile;
                        }

                        return Dismissible(
                          key: ValueKey('local_${post.id}'),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.delete_outline, color: Colors.red),
                          ),
                          confirmDismiss: (_) async {
                            return await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: const Text('Excluir post?'),
                                    content: const Text(
                                      'Isso remove apenas o post criado localmente.',
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text('Cancelar'),
                                      ),
                                      ElevatedButton(
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text('Excluir'),
                                      ),
                                    ],
                                  ),
                                ) ??
                                false;
                          },
                          onDismissed: (_) async {
                            final removed = post;
                            await ref
                                .read(postsViewModelProvider.notifier)
                                .deleteLocal(removed.id!);

                            if (!context.mounted) return;

                            AppSnackBar.show(
                              context,
                              'Post local removido',
                              icon: Icons.delete_outline,
                              duration: const Duration(seconds: 4),
                              action: SnackBarAction(
                                label: 'DESFAZER',
                                onPressed: () => ref
                                    .read(postsViewModelProvider.notifier)
                                    .restoreLocal(removed),
                              ),
                            );
                          },
                          child: tile,
                        );
                      },
                    ),
            ],
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({
    required this.post,
    required this.onTap,
    required this.isLocal,
  });

  final Post post;
  final VoidCallback onTap;
  final bool isLocal;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.4),
          ),
          color: isLocal
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.06)
              : Theme.of(context).cardColor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    post.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (isLocal) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                    ),
                    child: Text(
                      'LOCAL',
                      style: textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              post.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodyMedium?.copyWith(
                color: textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
                height: 1.25,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.4),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_off_outlined,
                    size: 52,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'Ops, nao foi possivel carregar os posts.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Verifique sua conexao e tente novamente.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tentar novamente'),
                  ),
                  const SizedBox(height: 12),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.all(12),
                    title: const Text('Detalhes'),
                    children: [
                      SelectableText(
                        message,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
