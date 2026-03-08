import '../model/post.dart';

abstract class PostsRepository {
  List<Post> getCachedPosts();

  Future<List<Post>> fetchPosts({int start = 0, int limit = 20});

  Future<Post> createPost({required String title, required String body});

  Future<void> deleteLocalPost(int id);
}
