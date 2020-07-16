import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:hackernews/model/article.dart';
import 'package:hackernews/src/hn_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

void main() async {
  final hnBloc = HackerNewsBloc();
  runApp(MyApp(bloc: hnBloc));
}

class MyApp extends StatelessWidget {
  final HackerNewsBloc bloc;

  const MyApp({Key key, this.bloc}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Hacker News',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MyHomePage(
        title: 'Flutter Hacker News',
        bloc: bloc,
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final HackerNewsBloc bloc;
  MyHomePage({Key key, this.title, this.bloc}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Article> articles = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: StreamBuilder<UnmodifiableListView<Article>>(
        stream: widget.bloc.articles,
        initialData: UnmodifiableListView<Article>([]),
        builder: (context, snapshot) => ListView(
          children: snapshot.data.map(_buildItem).toList(),
        ),
      ),
    );
  }

  Widget _buildItem(Article article) => Padding(
        key: Key(article.text),
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
        child: ExpansionTile(
          children: <Widget>[
            Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    "By: ${article.by}",
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                  IconButton(
                    icon: Icon(Icons.launch),
                    onPressed: () {
                      _onTapped(article.url);
                    },
                  )
                ],
              ),
            ),
          ],
          title: Text(
            article.title ?? "No Title Found",
            style: TextStyle(fontSize: 18),
          ),
        ),
      );

  _onTapped(String url) async {
    String fUrl = url;
    if (await canLaunch((fUrl))) {
      await launch(fUrl);
    } else {
      debugPrint("Can not launch the url $fUrl");
    }
  }
}
