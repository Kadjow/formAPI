import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/post.dart';
import 'posts_view_model.dart';
export 'posts_dependencies.dart';

class PostsHasMoreNotifier extends Notifier<bool> {
  @override
  bool build() => true;

  void set(bool value) {
    state = value;
  }
}

class PostsIsLoadingMoreNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) {
    state = value;
  }
}

final postsHasMoreProvider = NotifierProvider<PostsHasMoreNotifier, bool>(
  PostsHasMoreNotifier.new,
);
final postsIsLoadingMoreProvider =
    NotifierProvider<PostsIsLoadingMoreNotifier, bool>(
      PostsIsLoadingMoreNotifier.new,
    );

final postsViewModelProvider =
    AsyncNotifierProvider<PostsViewModel, List<Post>>(PostsViewModel.new);
