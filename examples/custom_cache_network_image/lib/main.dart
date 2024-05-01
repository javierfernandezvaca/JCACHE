import 'dart:io';

import 'package:flutter/material.dart';
import 'package:jcache/jcache.dart';

// ...
// RESOURCE
// ...
String domain = 'https://sampletestfiles.com/';
String imageResource = 'wp-content/uploads/2024/04/SamplePNGImage_5mbmb.png';
String url = domain + imageResource;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  void cacheJsonDataManagement() async {
    String key = 'user-profile-data';
    await JCacheManager.cacheData(
      key: key,
      value: {
        'Name': 'Jhon',
        'LastName': 'Doe',
        'Age': 35,
      },
      expiryInDays: 3,
    );
    final data = await JCacheManager.getCachedData(key);
    debugPrint(data.toString());
  }

  @override
  Widget build(BuildContext context) {
    // ...
    // JSON DATA
    // ...
    cacheJsonDataManagement();
    // ...
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('JCACHE'),
        ),
        body: Center(
          child: Builder(builder: (context) {
            // ...
            // FILE DATA
            // ...
            return const CustomNetworkCacheImageWidget();
            // ...
          }),
        ),
      ),
    );
  }
}

class CustomNetworkCacheImageWidget extends StatelessWidget {
  const CustomNetworkCacheImageWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // ...
    // CUSTOM CACHE NETWORK IMAGE
    // ...
    return JCacheWidget(
      url: url,
      expiryInDays: 5,
      onDownloading: (event, controller) {
        return OnDownloadingWidget(
          event: event,
          controller: controller,
        );
      },
      onCompleted: (event, controller) {
        return OnCompletedWidget(
          event: event,
          controller: controller,
        );
      },
      onError: (event, controller) {
        return OnErrorWidget(
          event: event,
          controller: controller,
        );
      },
      onInitialized: (event, controller) {
        return OnInitializedWidget(
          event: event,
          controller: controller,
        );
      },
      onCancelled: (event, controller) {
        return OnCancelledWidget(
          event: event,
          controller: controller,
        );
      },
    );
  }
}

class OnCancelledWidget extends StatelessWidget {
  const OnCancelledWidget({
    Key? key,
    required this.event,
    required this.controller,
  }) : super(key: key);

  final JFileDownloadEvent event;
  final JDownloadController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green[100],
      height: 250,
      width: 250,
      child: Center(
        child: IconButton(
          onPressed: () {
            controller.startDownload(event.url);
          },
          icon: const Icon(
            Icons.replay,
          ),
          splashRadius: 20,
        ),
      ),
    );
  }
}

class OnInitializedWidget extends StatelessWidget {
  const OnInitializedWidget({
    Key? key,
    required this.event,
    required this.controller,
  }) : super(key: key);

  final JFileDownloadEvent event;
  final JDownloadController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green[100],
      height: 250,
      width: 250,
      child: Center(
        child: IconButton(
          icon: const Icon(Icons.image),
          onPressed: () {},
        ),
      ),
    );
  }
}

class OnErrorWidget extends StatelessWidget {
  const OnErrorWidget({
    Key? key,
    required this.event,
    required this.controller,
  }) : super(key: key);

  final JFileDownloadEvent event;
  final JDownloadController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.green[100],
      height: 250,
      width: 250,
      child: Center(
        child: IconButton(
          icon: const Icon(Icons.broken_image_outlined),
          onPressed: () {},
        ),
      ),
    );
  }
}

class OnCompletedWidget extends StatelessWidget {
  const OnCompletedWidget({
    Key? key,
    required this.event,
    required this.controller,
  }) : super(key: key);

  final JFileDownloadEvent event;
  final JDownloadController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          color: Colors.green[100],
          height: 250,
          width: 250,
          child: Image.file(
            File(event.path!),
            fit: BoxFit.cover,
          ),
        ),
        // ...
        Padding(
          padding: const EdgeInsets.all(5),
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
  }
}

class OnDownloadingWidget extends StatelessWidget {
  const OnDownloadingWidget({
    Key? key,
    required this.event,
    required this.controller,
  }) : super(key: key);

  final JFileDownloadEvent event;
  final JDownloadController controller;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.bottomRight,
      children: [
        Container(
          color: Colors.green[100],
          height: 250,
          width: 250,
          child: Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(value: event.progress),
                IconButton(
                  onPressed: () {
                    controller.cancelDownload();
                  },
                  icon: const Icon(
                    Icons.close,
                  ),
                  splashRadius: 20,
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
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
                    '${(event.progress * 100).toStringAsFixed(0)} %',
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // ...
              const SizedBox(width: 5),
              // ...
              Container(
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
            ],
          ),
        ),
      ],
    );
  }
}
