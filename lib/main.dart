import 'dart:collection';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hackernews/model/article.dart';
import 'package:hackernews/src/hn_bloc.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

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
  static const primaryColor = Colors.white;
  @override
  Widget build(BuildContext context) {
    return Provider(
      create: (context) => widget.bloc,
      child: MaterialApp(
        title: 'Flutter Hacker News',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
//          textTheme: TextTheme(
//
//          ),
          primaryColor: primaryColor,
          scaffoldBackgroundColor: primaryColor,
          textTheme: Theme.of(context).textTheme.copyWith(
                headline1: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
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
        elevation: 0,
        actions: <Widget>[
          Builder(
            builder: (context) => IconButton(
              icon: Icon(Icons.search),
              onPressed: () {
                showSearch<Article>(
                  context: context,
                  delegate: ArticleSearch(bloc.articles),
                ).then((article) {
                  _onTapped(article.url);
                });
              },
            ),
          )
        ],
        title: Text(widget.title),
//        leading: LoadingInfo(
//          loadingStream: bloc.isLoading,
//        ),
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
        backgroundColor: Colors.black,
        unselectedItemColor: Colors.grey[500],
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
      ExpansionTile(
        key: Key(article.title),
        title: Text(
          article.title ?? 'No Title Found',
          style: Theme.of(context).textTheme.headline1,
        ),
        subtitle: Text('By: ${article.by}'),
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 24,
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      "Comments: ${article.kids.length}",
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
                Container(
                  height: 200,
                  child: WebView(
                    initialUrl: article.url,
                    javascriptMode: JavascriptMode.unrestricted,
                    gestureRecognizers: Set()
                      ..add(Factory<VerticalDragGestureRecognizer>(
                          () => VerticalDragGestureRecognizer())),
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  _onTapped(String url) async {
    String fUrl = url;
    if (await canLaunch((fUrl))) {
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => HNWebPage(
                url: url,
              )));
      // await launch(fUrl);
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

class ArticleSearch extends SearchDelegate<Article> {
  final Stream<UnmodifiableListView<Article>> articles;

  ArticleSearch(this.articles);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return StreamBuilder<UnmodifiableListView<Article>>(
      stream: articles,
      builder:
          (context, AsyncSnapshot<UnmodifiableListView<Article>> snapshot) {
        if (!snapshot.hasData || snapshot.hasError) {
          return Center(
            child: Text('No Data'),
          );
        }

        final results = snapshot.data.where((element) =>
            element.title.toLowerCase().contains(query.toLowerCase()));
        return ListView.builder(
          itemBuilder: (context, index) {
            var result = results.toList()[index];
            return ListTile(
              onTap: () {
                close(context, result);
              },
              title: Text(
                result.title ?? 'No Title Here',
              ),
              leading: Icon(Icons.bookmark),
              subtitle: Text(result.url),
            );
          },
          itemCount: results.length,
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
//    return Container();
    return StreamBuilder<UnmodifiableListView<Article>>(
      stream: articles,
      builder:
          (context, AsyncSnapshot<UnmodifiableListView<Article>> snapshot) {
        if (!snapshot.hasData || snapshot.hasError) {
          return Center(
            child: Text('No Data'),
          );
        }

        final results = snapshot.data.where((element) =>
            element.title.toLowerCase().contains(query.toLowerCase()));
        return ListView.builder(
          itemBuilder: (context, index) {
            var result = results.toList()[index];
            return ListTile(
              onTap: () {
                close(context, result);
              },
              title: Text(
                result.title ?? 'No Title Here',
                style: TextStyle(color: Colors.blue),
              ),
              leading: Icon(Icons.bookmark),
              subtitle: Text(result.url),
            );
          },
          itemCount: results.length,
        );
      },
    );
  }
}

class HNWebPage extends StatelessWidget {
  final String url;

  const HNWebPage({Key key, this.url}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Web Page'),
      ),
      body: WebView(
        initialUrl: url,
        javascriptMode: JavascriptMode.unrestricted,
      ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: Colors.black,
      //   child: IconButton(
      //     icon: Icon(
      //       Icons.favorite,
      //       color: Colors.white,
      //     ),
      //   ),
      // ),
    );
  }
}
