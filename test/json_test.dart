import 'package:flutter_test/flutter_test.dart';
import 'package:hackernews/model/article.dart';
import 'package:http/http.dart' as http;

void main() {
  test("parses top stories", () {
    const jsonString =
        "[23828253, 23828475, 23828920, 23828499, 23827486, 23824845, 23826070, 23821648, 23825649, 23827073, 23824689]";
    expect(parseTopStories(jsonString).first, 23828253);
  });

  test("parses item json", () {
    const jsonString =
        """{"by":"jmcgough","descendants":62,"id":23828253,"kids":[23828922,23828980,23828714,23829197,23828605,23828634,23828899,23828923,23828758,23828904,23828326,23828934,23828620,23828688,23828558,23828728,23829173,23828664,23828596,23828649,23828659,23828898,23828591,23828976,23828799,23828563,23828982,23828481,23828911,23828679,23828974,23828941,23828770,23828953,23828662,23828568,23828727,23828890,23828636,23828594,23828894,23828624,23828645,23828631,23828683,23828734,23828961,23828975],"score":181,"time":1594697896,"title":"Grant Imahara Has Died","type":"story","url":"https://www.hollywoodreporter.com/news/grant-imahara-dead-mythbusters-host-was-49-1303101"}""";

    expect(parseArticle(jsonString).by, "jmcgough");
  });

  test(
    "parses item json over a network",
    () async {
      final url = 'https://hacker-news.firebaseio.com/v0/topstories.json';
      final res = await http.get(url);
      if (res.statusCode == 200) {
        final idList = parseTopStories(res.body);
        final List<int> ids = List<int>.from(idList);
        if (ids.isNotEmpty) {
          final storyURL =
              'https://hacker-news.firebaseio.com/v0/item/${ids[0]}.json';
          final storyRes = await http.get(storyURL);
          if (storyRes.statusCode == 200) {
            expect(parseArticle((storyRes.body)), isNotNull);
          }
        }
      }
    },
    skip: true,
  );
}
