import 'package:dio/dio.dart';

import '../../../core/network/dio_client.dart';
import '../model/post.dart';

class PostsApiService {
  PostsApiService(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  Future<List<Post>> fetchPosts() async {
    final res = await _dio.get('/posts');
    final list = (res.data as List).cast<Map<String, dynamic>>();
    return list.map(Post.fromJson).toList();
  }

  Future<Post> createPost({
    required String title,
    required String body,
  }) async {
    final res = await _dio.post(
      '/posts',
      data: <String, dynamic>{
        'title': title,
        'body': body,
        'userId': 1,
      },
    );

    final map = (res.data as Map).cast<String, dynamic>();
    return Post.fromJson(map);
  }
}
