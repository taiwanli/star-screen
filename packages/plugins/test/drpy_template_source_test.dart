import 'dart:async';

import 'package:star_domain/star_domain.dart';
import 'package:star_plugins/star_plugins.dart';
import 'package:test/test.dart';

class FakeHttpFetch implements HttpFetch {
  final FetchResult Function(Uri url) handler;

  FakeHttpFetch(this.handler);

  @override
  Future<FetchResult> get(
    Uri url, {
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  }) async =>
      handler(url);

  @override
  Future<FetchResult> post(
    Uri url, {
    String body = '',
    Map<String, String> headers = const {},
    Duration timeout = const Duration(seconds: 12),
  }) async =>
      handler(url);
}

SourceDef _def() => const SourceDef(
      key: 'tpl',
      name: '模板源',
      kind: SourceKind.drpyJs,
      sourceUrl: 'https://rt.example.com/lib/tpl.js',
    );

const _ruleJs = '''
var rule = {
    title:'模板源',
    host:'https://site.example.com',
    url:'/list/fyclass/fypage.html',
    searchUrl:'/search/**/fypage.html',
    searchable:1,
    class_name:'电影&剧集',
    class_url:'1&2',
    一级:'.module-item;.module-title&&Text;img&&data-src;.module-note&&Text;a&&href',
    二级:'*',
    搜索:'.module-item;.module-title&&Text;img&&data-src;.module-note&&Text;a&&href',
}
''';

const _listHtml = '''
<html><body>
<div class="module-item"><h3 class="module-title">夜航西行</h3><img data-src="https://img.example.com/a.jpg"><span class="module-note">更新至12集</span><a href="/detail/101.html"></a></div>
<div class="module-item"><h3 class="module-title">潮汐图书馆</h3><a href="https://site.example.com/detail/102.html"></a></div>
</body></html>
''';

void main() {
  group('DrpyTemplateSource —— 纯模板源原生执行（docs/09 M3-4）', () {
    late FakeHttpFetch http;
    late DrpyTemplateSource source;

    setUp(() {
      http = FakeHttpFetch((url) {
        if (url.path.contains('tpl.js')) {
          return FetchResult(url: url, statusCode: 200, body: _ruleJs);
        }
        return FetchResult(url: url, statusCode: 200, body: _listHtml);
      });
      source = DrpyTemplateSource(def: _def(), http: http);
    });

    test('home：host+url 拼 URL，一级选择器归一卡片', () async {
      final feed = await source.home();
      expect(feed.recommend, hasLength(2));
      expect(feed.recommend.first.title, '夜航西行');
      expect(feed.recommend.first.posterUrl, 'https://img.example.com/a.jpg');
      expect(feed.recommend.first.remarks, '更新至12集');
      expect(feed.recommend.first.workKey, 'tpl::/detail/101.html');
    });

    test('category：fyclass/fypage 占位替换', () async {
      final page = await source.category(const CategoryQuery(typeId: '2', page: 3));
      expect(page.items, hasLength(2));
    });

    test('search：** 关键词替换', () async {
      Uri? searched;
      final probing = FakeHttpFetch((url) {
        if (url.path.contains('tpl.js')) {
          return FetchResult(url: url, statusCode: 200, body: _ruleJs);
        }
        searched = url;
        return FetchResult(url: url, statusCode: 200, body: _listHtml);
      });
      final src = DrpyTemplateSource(def: _def(), http: probing);
      final page = await src.search('夜航');
      expect(searched!.path, contains(Uri.encodeComponent('夜航')));
      expect(page.items, hasLength(2));
    });

    test('detail/resolve：直链过滤 + 选集归一（使用闭环）', () async {
      const detailHtml = '''
<html><body><h1>夜航西行</h1><img src="https://img.example.com/a.jpg">
<a href="/play/1.m3u8">第01集</a><a href="/play/2.mp4">第02集</a>
<a href="/other/page">网页地址（过滤）</a></body></html>
''';
      final probing = FakeHttpFetch((url) {
        if (url.path.contains('tpl.js')) {
          return FetchResult(url: url, statusCode: 200, body: _ruleJs);
        }
        return FetchResult(url: url, statusCode: 200, body: detailHtml);
      });
      final src = DrpyTemplateSource(def: _def(), http: probing);

      final workDetail = await src.detail('/detail/101.html');
      expect(workDetail.lines, hasLength(1));
      expect(workDetail.lines.single.episodes, hasLength(2));
      expect(workDetail.lines.single.episodes.first.name, '第01集');
      expect(workDetail.lines.single.episodes.first.url,
          'https://site.example.com/play/1.m3u8');

      final candidate =
          await src.resolve(const PlayRequest(workId: '/detail/101.html', episodeIndex: 1));
      expect(candidate.url, 'https://site.example.com/play/2.mp4');
      expect(candidate.needsParse, isFalse);
    });
  });
}
