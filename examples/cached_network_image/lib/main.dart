import 'package:flutter/material.dart';
import 'package:jcache/jcache.dart';

import 'component/cached_network_image.dart';
import 'resources.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JCacheManager.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: MyAppPage(),
    );
  }
}

class MyAppPage extends StatelessWidget {
  const MyAppPage({super.key});

  void _onKeys() async {
    final keys = await JCacheManager.getKeys();
    for (var key in keys) {
      debugPrint(key);
    }
  }

  @override
  Widget build(BuildContext context) {
    // ...
    _onKeys();
    // ...
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cached Network Image'),
        elevation: 0,
      ),
      body: Column(
        children: images
            .map((String url) => Expanded(
                  flex: 1,
                  child: CachedNetworkImage(
                    imageUrl: url,
                  ),
                ))
            .toList(),
      ),
    );
  }
}
