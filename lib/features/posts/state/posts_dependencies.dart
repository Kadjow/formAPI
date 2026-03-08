import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/dio_client.dart';
import '../../../core/storage/shared_preferences_provider.dart';
import '../data/posts_api_service.dart';
import '../data/posts_local_datasource.dart';
import '../data/posts_repository.dart';
import '../data/posts_repository_impl.dart';

final dioClientProvider = Provider<DioClient>((ref) => DioClient());

final postsApiServiceProvider = Provider<PostsApiService>((ref) {
  final client = ref.watch(dioClientProvider);
  return PostsApiService(client);
});

final postsLocalDataSourceProvider = Provider<PostsLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return PostsLocalDataSource(prefs);
});

final postsRepositoryProvider = Provider<PostsRepository>((ref) {
  final api = ref.watch(postsApiServiceProvider);
  final local = ref.watch(postsLocalDataSourceProvider);
  return PostsRepositoryImpl(api, local);
});
