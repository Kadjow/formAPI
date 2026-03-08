import '../model/post.dart';

abstract class PostsRepository {
  List<Post> getCachedPosts();

  Future<List<Post>> fetchPosts();

  Future<Post> createPost({required String title, required String body});
}
