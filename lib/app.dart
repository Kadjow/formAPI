import 'package:flutter/material.dart';
import 'package:formapi/features/posts/ui/posts_list_page.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Form API',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true),
      home: const PostsListPage(),
    );
  }
}
