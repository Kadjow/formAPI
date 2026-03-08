import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../model/post.dart';
import 'posts_view_model.dart';
export 'posts_dependencies.dart';

final postsViewModelProvider =
    AsyncNotifierProvider<PostsViewModel, List<Post>>(PostsViewModel.new);
