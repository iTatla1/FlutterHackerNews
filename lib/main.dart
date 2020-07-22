import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:hackernews/model/article.dart';
import 'package:hackernews/src/hn_bloc.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'src/hn_bloc.dart';

void main() async {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  final HackerNewsBloc bloc = HackerNewsBloc();

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context) => widget.bloc,
      child: MaterialApp(
        title: 'Flutter Hacker News',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: MyHomePage(
          title: 'Flutter Hacker News',
        ),
      ),
    );
  }

  @override
  void dispose() {
    widget.bloc.dispose();
    super.dispose();
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  List<Article> articles = [];
  int selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    final bloc = Provider.of<HackerNewsBloc>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        leading: LoadingInfo(
          loadingStream: bloc.isLoading,
        ),
      ),
      body: StreamBuilder<UnmodifiableListView<Article>>(
          stream: bloc.articles,
          initialData: UnmodifiableListView<Article>([]),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              Text("Some server error happened");
            }
            if (!snapshot.hasData) {
              return Center(
                child: CircularProgressIndicator(),
              );
            }
            if (snapshot.hasData && snapshot.data.length > 0) {
              return ListView(
                children: snapshot.data.map(_buildItem).toList(),
              );
            }
            return Container();
          }),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedTab,
        onTap: (value) {
          setState(() {
            selectedTab = value;
          });
          bloc.storiesType.add(
              value == 0 ? StoriesType.topStories : StoriesType.newStories);
        },
        items: [
          BottomNavigationBarItem(
            title: Text("Top Stories"),
            icon: Icon(Icons.star),
          ),
          BottomNavigationBarItem(
            title: Text("New Stories"),
            icon: Icon(Icons.new_releases),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _buildItem(Article article) //=> Text('Debug');
      =>
      ListTile(
        onTap: () => _onTapped(article.url),
        title: Text(article.title ?? 'No Title Found'),
        subtitle: Text('By: ${article.by}'),
        trailing: Icon(Icons.launch),
      );
//      Padding(
//        key: Key(article.text),
//        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 8.0),
//        child: ExpansionTile(
//          children: <Widget>[
//            Padding(
//              padding:
//                  const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
//              child: Row(
//                mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                children: <Widget>[
//                  Text(
//                    "By: ${article.by}",
//                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
//                  ),
//                  IconButton(
//                    icon: Icon(Icons.launch),
//                    onPressed: () {
//                      _onTapped(article.url);
//                    },
//                  )
//                ],
//              ),
//            ),
//          ],
//          title: Text(
//            article.title ?? "No Title Found",
//            style: TextStyle(fontSize: 18),
//          ),
//        ),
//      );

  _onTapped(String url) async {
    String fUrl = url;
    if (await canLaunch((fUrl))) {
      await launch(fUrl);
    } else {
      debugPrint("Can not launch the url $fUrl");
    }
  }
}

class LoadingInfo extends StatefulWidget {
  final Stream<bool> loadingStream;

  const LoadingInfo({Key key, this.loadingStream}) : super(key: key);

  @override
  _LoadingInfoState createState() => _LoadingInfoState();
}

class _LoadingInfoState extends State<LoadingInfo>
    with SingleTickerProviderStateMixin {
  AnimationController _controller;
//  Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        seconds: 3,
      ),
    );

//    _opacity = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: widget.loadingStream,
      builder: (BuildContext context, AsyncSnapshot<bool> asyncShot) {
        if (asyncShot.hasData && asyncShot.data) {
          _controller.forward();
        } else {
          _controller.reverse();
        }
        return FadeTransition(
          opacity: _controller,
          child: Icon(
            FontAwesomeIcons.hackerNewsSquare,
            color: Colors.orange,
          ),
        );
      },
    );
  }
}
