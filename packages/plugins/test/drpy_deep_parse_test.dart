import 'package:star_domain/star_domain.dart';
import 'package:star_plugins/star_plugins.dart';
import 'package:test/test.dart';

import 'fakes.dart';

/// mxpro 风格二级：tabs（:eq(#id) 展开）× lists（;; 集标题;集链接）+ tab 处理。
const _ruleJs = '''
var rule = {
    title:'深解析源',
    host:'https://site.example.com',
    url:'/list/fyclass/fypage.html',
    searchUrl:'/search/**-fypage.html',
    class_name:'电影&剧集',
    class_url:'1&2',
    一级:'.module-item;.module-title&&Text;img&&data-src;.module-note&&Text;a&&href',
    二级:'*;h1&&Text;.poster&&img&&src;.info&&Text;.desc&&Text;.tabs&&.tab&&Text;.play-list:eq(#id)&&.play-list-content&&a;;a&&Text;a&&href',
    play_parse:1,
    lazy:'js:setResult({url:input,parse:0});',
    tab_remove:'猜你',
    tab_rename:'线路一&超清',
}
''';

const _listHtml = '''
<html><body>
<div class="module-item"><h3 class="module-title">夜航西行</h3><a href="/detail/101.html"></a></div>
</body></html>
''';

const _detailHtml = '''
<html><body>
<h1>夜航西行</h1>
<div class="poster"><img src="/img/a.jpg"></div>
<div class="info">2026|大陆</div>
<div class="desc">一段旅程。</div>
<div class="tabs"><div class="tab">线路一</div><div class="tab">线路二</div><div class="tab">猜你想看</div></div>
<div class="play-list"><div class="play-list-content"><a href="/play/1-1.m3u8">第01集</a><a href="/play/1-2.m3u8">第02集</a></div></div>
<div class="play-list"><div class="play-list-content"><a href="/play/2-1.mp4">第01集</a></div></div>
</body></html>
''';

void main() {
  SourceDef def() => const SourceDef(
        key: 'deep',
        name: '深解析源',
        kind: SourceKind.drpyJs,
        sourceUrl: 'https://rt.example.com/lib/deep.js',
      );

  FakeHttpFetch http() => FakeHttpFetch((url, method, body, headers) {
        final path = url.path;
        if (path.endsWith('deep.js')) {
          return FetchResult(url: url, statusCode: 200, body: _ruleJs);
        }
        if (path.contains('/list/')) {
          return FetchResult(url: url, statusCode: 200, body: _listHtml);
        }
        return FetchResult(url: url, statusCode: 200, body: _detailHtml);
      });

  group('drpy 二级模板深解析（docs/09 M3-4）', () {
    test('detail：tabs×lists 多线路 + tab_remove/rename + 相对地址补全', () async {
      final src = DrpyTemplateSource(def: def(), http: http());
      final d = await src.detail('/detail/101.html');

      expect(d.card.title, '夜航西行');
      expect(d.card.posterUrl, 'https://site.example.com/img/a.jpg');
      expect(d.card.remarks, '2026|大陆');
      expect(d.content, '一段旅程。');

      expect(d.lines, hasLength(2));
      expect(d.lines[0].name, '超清'); // 线路一 → rename；猜你想看 → remove
      expect(d.lines[0].episodes, hasLength(2));
      expect(d.lines[0].episodes.first.name, '第01集');
      expect(d.lines[0].episodes.first.url, 'https://site.example.com/play/1-1.m3u8');
      expect(d.lines[1].name, '线路二');
      expect(d.lines[1].episodes.single.url, 'https://site.example.com/play/2-1.mp4');
    });

    test('resolve：play_parse 源走 lazy js —— 直链直通并转发 header', () async {
      final src = DrpyTemplateSource(def: def(), http: http());
      final c = await src.resolve(
        const PlayRequest(workId: '/detail/101.html', episodeIndex: 0),
      );
      expect(c.url, 'https://site.example.com/play/1-1.m3u8');
      expect(c.needsParse, isFalse);
    });

    test('resolve：lazy 返回需解析地址 → needsParse 标记（不做网页嗅探）', () async {
      final rt = FakeJsRuntime();
      rt.onEvalAsync = (code) async => {
            'url': 'https://parse.example/go?u=abc',
            'parse': 1,
          };
      final src = DrpyTemplateSource(
        def: def(),
        http: http(),
        jsFactory: () => rt,
      );
      final c = await src.resolve(
        const PlayRequest(workId: '/detail/101.html', episodeIndex: 1),
      );
      expect(c.url, 'https://parse.example/go?u=abc');
      expect(c.needsParse, isTrue);
    });

    test('二级对象形态（{title,img,tabs,lists}）等价解析', () async {
      const objRule = '''
var rule = {
    title:'对象二级',
    host:'https://site.example.com',
    二级:{title:'h1&&Text',img:'.poster&&img&&src',desc:'.info&&Text',
         content:'.desc&&Text',tabs:'.tabs&&.tab&&Text',
         lists:'.play-list:eq(#id)&&.play-list-content&&a;;a&&Text;a&&href'},
}
''';
      final h = FakeHttpFetch((url, method, body, headers) {
        if (url.path.contains('obj.js')) {
          return FetchResult(url: url, statusCode: 200, body: objRule);
        }
        return FetchResult(url: url, statusCode: 200, body: _detailHtml);
      });
      final src = DrpyTemplateSource(
        def: const SourceDef(
          key: 'obj',
          name: '对象二级',
          kind: SourceKind.drpyJs,
          sourceUrl: 'https://rt.example.com/lib/obj.js',
        ),
        http: h,
      );
      final d = await src.detail('/detail/101.html');
      expect(d.card.title, '夜航西行');
      expect(d.lines, hasLength(2));
      expect(d.lines[0].episodes.first.url, 'https://site.example.com/play/1-1.m3u8');
    });

    test('class_parse：分类树写回，category 按 fyclass 占位请求', () async {
      const cpRule = '''
var rule = {
    title:'分类解析源',
    host:'https://site.example.com',
    url:'/list/fyclass/fypage.html',
    class_parse:'.nav&&a;a&&Text;a&&href',
    一级:'.module-item;.module-title&&Text;a&&href',
}
''';
      const homeHtml = '''
<html><body>
<ul class="nav"><a href="/list/1/1.html">电影</a><a href="/list/2/1.html">剧集</a></ul>
<div class="module-item"><h3 class="module-title">夜航西行</h3><a href="/detail/101.html"></a></div>
</body></html>
''';
      Uri? categoryUri;
      final h = FakeHttpFetch((url, method, body, headers) {
        if (url.path.endsWith('cp.js')) {
          return FetchResult(url: url, statusCode: 200, body: cpRule);
        }
        if (url.path.startsWith('/list/')) {
          categoryUri = url;
          return FetchResult(url: url, statusCode: 200, body: homeHtml);
        }
        return FetchResult(url: url, statusCode: 200, body: homeHtml);
      });
      final src = DrpyTemplateSource(
        def: const SourceDef(
          key: 'cp',
          name: '分类解析源',
          kind: SourceKind.drpyJs,
          sourceUrl: 'https://rt.example.com/lib/cp.js',
        ),
        http: h,
      );
      final feed = await src.home();
      expect(feed.recommend, hasLength(1));
      final page = await src.category(const CategoryQuery(typeId: '2', page: 1));
      expect(categoryUri.toString(), 'https://site.example.com/list/2/1.html');
      expect(page.items, hasLength(1));
    });
  });
}
