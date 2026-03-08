import 'package:flutter/material.dart';

import '../model/post.dart';

class PostDetailPage extends StatelessWidget {
  const PostDetailPage({super.key, required this.post});

  final Post post;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhes')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              Text(
                post.title,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              Text(
                post.body,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Divider(color: Theme.of(context).dividerColor),
              const SizedBox(height: 8),
              Text('ID: ${post.id ?? "-"}'),
              Text('UserID: ${post.userId ?? "-"}'),
            ],
          ),
        ),
      ),
    );
  }
}
