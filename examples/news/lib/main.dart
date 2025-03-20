import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jcache/jcache.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:news/configs.dart';
import 'package:news/models/article.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JCacheManager.init();
  runApp(const NewsApp());
}

class NewsApp extends StatelessWidget {
  const NewsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: NewsPage(),
    );
  }
}

class NewsPage extends StatefulWidget {
  const NewsPage({super.key});

  @override
  NewsPageState createState() => NewsPageState();
}

class NewsPageState extends State<NewsPage> {
  final Connectivity _connectivity = Connectivity();
  List<ConnectivityResult> _connectionStatus = [];
  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;

  final newsArticles = <Article>[];

  @override
  void initState() {
    super.initState();
    initConnectivity();
    _connectivitySubscription =
        _connectivity.onConnectivityChanged.listen(_updateConnectionStatus);
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  Future<void> initConnectivity() async {
    late List<ConnectivityResult> result;
    try {
      result = await _connectivity.checkConnectivity();
    } catch (e) {
      debugPrint('Couldn\'t check connectivity status: $e');
      return;
    }
    if (!mounted) {
      return Future.value(null);
    }
    return _updateConnectionStatus(result);
  }

  Future<void> _updateConnectionStatus(List<ConnectivityResult> result) async {
    debugPrint('Connectivity changed: $_connectionStatus');
    setState(() {
      _connectionStatus = result;
    });
    if (!_connectionStatus.contains(ConnectivityResult.none)) {
      // Online
      loadNews();
    }
  }

  getNews(Map<String, dynamic>? newsJson) {
    newsArticles.clear();
    if (newsJson != null) {
      final articles = newsJson['articles'] as List;
      for (var a in articles) {
        final article = Article.fromJson(a);
        if (article.title != '[Removed]' && (article.urlToImage != null)) {
          newsArticles.add(article);
        }
      }
    }
  }

  Future<void> loadNews() async {
    if (_connectionStatus.contains(ConnectivityResult.none)) {
      // Offline
      try {
        final cachedNewsJson = await JCacheManager.getData(newsUrl);
        getNews(cachedNewsJson);
      } catch (e) {
        debugPrint('Error al leer del caché: $e');
        // ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cargar noticias desde caché.')));
      }
    } else {
      // Online
      final response = await http.get(Uri.parse(newsUrl));
      if (response.statusCode == 200) {
        final apiNewsJson = jsonDecode(response.body);
        await JCacheManager.setData(
          key: newsUrl,
          value: apiNewsJson,
          expiryDuration: const Duration(days: 1),
        );
        getNews(apiNewsJson);
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue.shade900,
        title: const Text(
          'News',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Builder(builder: (context) {
            bool offline = _connectionStatus.contains(ConnectivityResult.none);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    color:
                        offline ? Colors.red.shade900 : Colors.green.shade700,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    child: InkWell(
                      onTap: () {},
                      child: Text(
                        offline ? 'OFFLINE' : 'ONLINE',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: offline ? Colors.white : Colors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          })
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          loadNews();
        },
        child: newsArticles.isNotEmpty
            ? ListView.builder(
                addAutomaticKeepAlives: true,
                itemCount: newsArticles.length,
                itemBuilder: (context, index) {
                  final newsArticle = newsArticles[index];
                  return NewsArticleWidget(
                    newsArticle: newsArticle,
                  );
                },
              )
            : Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text(
                      'No news available at the moment',
                      style: TextStyle(color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: () {
                        loadNews();
                      },
                      child: const Text(
                        'Try Again',
                        style: TextStyle(color: Colors.black),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}

class NewsArticleWidget extends StatelessWidget {
  const NewsArticleWidget({
    super.key,
    required this.newsArticle,
  });

  final Article newsArticle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  newsArticle.source.name,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                Text(
                  DateFormat('EEE, MMM d, yyyy, h:mm a', 'en_US')
                      .format(newsArticle.publishedAt.toLocal()),
                  style: const TextStyle(
                    // fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (newsArticle.urlToImage != null)
          JCacheWidget(
            url: newsArticle.urlToImage!,
            expiryDuration: const Duration(days: 1),
            onDownloading: (event, controller) {
              return Container(
                color: Colors.black,
                width: double.infinity,
                height: 220,
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            },
            onCompleted: (event, controller) {
              return Stack(
                alignment: Alignment.bottomRight,
                children: [
                  Image.file(File(event.resourcePath!)),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(5),
                        color: Colors.black,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        child: Text(
                          '${(event.contentLength / 1024 / 1024).toStringAsFixed(2)} MB',
                          style: const TextStyle(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
            onError: (event, controller) {
              return const Text('Error');
            },
            onCancelled: (event, controller) {
              return const Text('Cancelled');
            },
            onInitialized: (event, controller) {
              return Container(
                color: Colors.black,
                width: double.infinity,
                height: 220,
                child: const Icon(Icons.image_outlined),
              );
            },
          ),
        Container(
          color: Colors.white,
          child: ListTile(
            title: Text(newsArticle.title),
            subtitle: Text(newsArticle.description ?? 'Unknow'),
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
