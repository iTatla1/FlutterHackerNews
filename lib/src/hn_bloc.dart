import 'dart:async';
import 'dart:collection';

import 'package:hackernews/model/article.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';

class HackerNewsBloc {
  Stream<List<Article>> get articles => _articlesSubject.stream;
  final _articlesSubject = BehaviorSubject<UnmodifiableListView<Article>>();

  var _articles = <Article>[];

  List<int> articleIds = [
    23828253,
    23826176,
    23828475,
    23828920,
    23825979,
    23828499,
    23823963
  ];

  HackerNewsBloc() {
    _updateArticles().then((_) {
      _articlesSubject.add(UnmodifiableListView(_articles));
    });
  }

  Future<Null> _updateArticles() async {
    final futureArticles = articleIds.map((id) => getArticle(id));
    final articles = await Future.wait(futureArticles);
    _articles = articles;
  }

  Future<Article> getArticle(int id) async {
    final storyURL = 'https://hacker-news.firebaseio.com/v0/item/$id.json';
    final storyRes = await http.get(storyURL);
    if (storyRes.statusCode == 200) {
      return parseArticle(storyRes.body);
    }
  }
}
