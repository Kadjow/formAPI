import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/post.dart';
import '../state/posts_providers.dart';
import 'create_post_page.dart';
import 'post_detail_page.dart';

class PostsListPage extends ConsumerWidget {
  const PostsListPage({super.key});

  bool _isLocal(Post p) => (p.id ?? 0) > 100;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(postsViewModelProvider);

    return Scaffold(
      appBar: AppBar(
        title: state.maybeWhen(
          data: (posts) => Text('Posts (${posts.length})'),
          orElse: () => const Text('Posts'),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePostPage()),
          );
        },
        child: const Icon(Icons.add),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => _ErrorState(
          message: err.toString(),
          onRetry: () => ref.read(postsViewModelProvider.notifier).refresh(),
        ),
        data: (posts) {
          final hasMore = ref.watch(postsHasMoreProvider);
          final isLoadingMore = ref.watch(postsIsLoadingMoreProvider);

          if (posts.isEmpty) {
            return RefreshIndicator(
              onRefresh: () => ref.read(postsViewModelProvider.notifier).refresh(),
              child: ListView(
                children: const [
                  SizedBox(height: 220),
                  Center(child: Text('Nenhum post encontrado.')),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.read(postsViewModelProvider.notifier).refresh(),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: posts.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (index == posts.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Center(
                      child: isLoadingMore
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(),
                            )
                          : OutlinedButton.icon(
                              onPressed: hasMore
                                  ? () => ref
                                      .read(postsViewModelProvider.notifier)
                                      .loadMore()
                                  : null,
                              icon: const Icon(Icons.expand_more),
                              label: Text(
                                hasMore ? 'Carregar mais' : 'Sem mais posts',
                              ),
                            ),
                    ),
                  );
                }

                final post = posts[index];

                final tile = _PostCard(
                  post: post,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PostDetailPage(post: post),
                      ),
                    );
                  },
                );

                if (!_isLocal(post) || post.id == null) return tile;

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
                    child: const Icon(
                      Icons.delete_outline,
                      color: Colors.red,
                    ),
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
                    await ref
                        .read(postsViewModelProvider.notifier)
                        .deleteLocal(post.id!);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Post local removido')),
                      );
                    }
                  },
                  child: tile,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  const _PostCard({required this.post, required this.onTap});

  final Post post;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(post.body, maxLines: 2, overflow: TextOverflow.ellipsis),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            const Text('Ops, não foi possível carregar os posts.'),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
