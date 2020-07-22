import 'dart:async';
import 'dart:collection';

import 'package:hackernews/model/article.dart';
import 'package:http/http.dart' as http;
import 'package:rxdart/rxdart.dart';

enum StoriesType { topStories, newStories }

class HackerNewsBloc {
  Stream<List<Article>> get articles => _articlesSubject.stream;
  final _articlesSubject = BehaviorSubject<UnmodifiableListView<Article>>();

  Stream<bool> get isLoading => _isLoadingSubject.stream;
  final _isLoadingSubject = BehaviorSubject.seeded(false);

  var _articles = <Article>[];

  Sink<StoriesType> get storiesType => _storiesTypeController.sink;
  final _storiesTypeController = StreamController<StoriesType>();

  void dispose() {
    closeStreams();
  }

  void closeStreams() {
    _storiesTypeController.close();
    _articlesSubject.close();
    _isLoadingSubject.close();
  }

  static List<int> _newIds = [
    23825979,
    23828499,
    23823963,
  ];

  static List<int> _topIds = [
    23828253,
    23826176,
    23828475,
    23828920,
  ];

  HackerNewsBloc() {
    _initializeArticle();

    _storiesTypeController.stream.listen((storiesType) async {
      _getArticlesAndUpdate(await _getIds(storiesType));
    });
  }

//  List<int> _ids

  Future<void> _initializeArticle() async {
    _getArticlesAndUpdate(await _getIds(StoriesType.topStories));
  }

  Future<List<int>> _getIds(StoriesType type) async {
    final partURL = type == StoriesType.topStories ? 'top' : 'new';
    final url = '$_baseURL${partURL}stories.json';
    final idRes = await http.get(url);
    if (idRes.statusCode == 200) {
      return parseTopStories(idRes.body).take(4).toList();
    } else {
      throw HackerNewApiError('Server Error');
    }
  }

  static const _baseURL = 'https://hacker-news.firebaseio.com/v0/';

  _getArticlesAndUpdate(List<int> ids) async {
    _isLoadingSubject.add(true);
    await _updateArticles(ids);
    _articlesSubject.add(UnmodifiableListView(_articles));
    _isLoadingSubject.add(false);
  }

  Future<Null> _updateArticles(List<int> articleIds) async {
    final futureArticles = articleIds.map((id) => getArticle(id));
    final articles = await Future.wait(futureArticles);
    _articles = articles;
  }

  Future<Article> getArticle(int id) async {
    final storyURL = '${_baseURL}item/$id.json';
    final storyRes = await http.get(storyURL);
    if (storyRes.statusCode == 200) {
      return parseArticle(storyRes.body);
    }

    throw HackerNewApiError("Article $id couldn't be fetched");
  }
}

class HackerNewApiError extends Error {
  final String message;

  HackerNewApiError(this.message);
}
