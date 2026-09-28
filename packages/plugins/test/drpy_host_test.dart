import 'package:star_domain/star_domain.dart';
import 'package:star_plugins/star_plugins.dart';
import 'package:test/test.dart';

import 'fakes.dart';

const _ruleJs = '''
var rule = {
    title:'宿主测试',
    host:'https://site.example.com',
    headers:{'X-Rule':'rh'},
}
''';

void main() {
  late FakeJsRuntime rt;
  late FakeHttpFetch http;
  late DrpyHost host;

  setUp(() {
    rt = FakeJsRuntime();
    http = FakeHttpFetch((url, method, body, headers) =>
        FetchResult(url: url, statusCode: 200, body: '<html>ok</html>'));
    host = DrpyHost(
      runtime: rt,
      http: http,
      baseHeaders: const {'User-Agent': 'StarScreen/0.1'},
      ruleHost: 'https://site.example.com',
    );
  });

  group('DrpyHost —— drpy 注入 API（docs/04 §4.3）', () {
    test('install：API 全量注册 + rule/HOST/oheaders 全局定义', () async {
      await host.install(parseRule(_ruleJs));
      for (final name in [
        'req', 'request', 'post', 'fetch', 'pdfa', 'pdfh', 'pd',
        'setResult', 'setResult2', 'log', 'print', 'buildUrl', 'getProxyUrl',
      ]) {
        expect(rt.functions.containsKey(name), isTrue, reason: '缺少 $name');
      }
      final globals = rt.syncCodes.join('\n');
      expect(globals, contains('var rule ='));
      expect(globals, contains('var HOST ='));
      expect(globals, contains('var oheaders ='));
      // rule.headers 合并进 oheaders
      expect(globals, contains('X-Rule'));
    });

    test('pdfa/pdfh：经 PdfhEngine 求值（pdfa 返回 outerHTML 列表）', () async {
      await host.install(parseRule(_ruleJs));
      const page =
          '<div class="m"><a href="/1">A</a></div><div class="m"><a href="/2">B</a></div>';
      final items = (await rt.functions['pdfa']!([page, '.m'])) as List<Object?>;
      expect(items, hasLength(2));
      expect((items.first! as String).contains('/1'), isTrue);

      final href = await rt.functions['pdfh']!([items.first, 'a&&href']);
      expect(href, '/1');
      final text = await rt.functions['pdfh']!([items.first, 'a&&Text']);
      expect(text, 'A');
    });

    test('req：GET 合并请求头，返回 content/headers/status', () async {
      await host.install(parseRule(_ruleJs));
      final res = await rt.functions['req']!([
        'https://site.example.com/page',
        {'headers': {'X-Js': '1'}},
      ]);
      expect(res, isA<Map<Object?, Object?>>());
      final resMap = res! as Map<Object?, Object?>;
      expect(resMap['content'], '<html>ok</html>');
      expect(resMap['status'], 200);
      final call = http.calls.single;
      expect(call.$1, 'GET');
      expect(call.$2.toString(), 'https://site.example.com/page');
      expect(call.$4['User-Agent'], 'StarScreen/0.1');
      expect(call.$4['X-Js'], '1');
      expect(call.$4['X-Rule'], 'rh');
    });

    test('req：POST —— data 对象表单化编码', () async {
      await host.install(parseRule(_ruleJs));
      await rt.functions['post']!([
        'https://site.example.com/search',
        {'method': 'POST', 'data': {'wd': '夜航', 'pg': '1'}},
      ]);
      final call = http.calls.single;
      expect(call.$1, 'POST');
      expect(call.$3, 'wd=${Uri.encodeComponent('夜航')}&pg=1');
    });

    test('fetch：直接返回正文文本', () async {
      await host.install(parseRule(_ruleJs));
      final body = await rt.functions['fetch']!(['https://site.example.com/x']);
      expect(body, '<html>ok</html>');
    });

    test('pd：相对地址按 currentUrl 补全', () async {
      await host.install(parseRule(_ruleJs));
      host.currentUrl = 'https://site.example.com/detail/1.html';
      final abs = await rt.functions['pd']!([
        '<a href="/p/1.jpg">x</a>',
        'a&&href',
      ]);
      expect(abs, 'https://site.example.com/p/1.jpg');
    });

    test('buildUrl：合并既有查询串', () async {
      await host.install(parseRule(_ruleJs));
      final url = await rt.functions['buildUrl']!([
        'https://x.example/a?b=1',
        {'c': '2'},
      ]);
      expect(url, 'https://x.example/a?b=1&c=2');
    });

    test('budget：请求次数超限 → 熔断（FetchException，不崩溃）', () async {
      final strict = DrpyHost(
        runtime: rt,
        http: http,
        budget: DrpyBudget(maxRequests: 1),
      );
      await strict.install(parseRule(_ruleJs));
      await rt.functions['req']!(['https://site.example.com/1']);
      await expectLater(
        rt.functions['req']!(['https://site.example.com/2']),
        throwsA(isA<FetchException>().having((e) => e.message, 'message', contains('熔断'))),
      );
    });

    test('budget：setResult 输出超限 → 熔断', () async {
      final strict = DrpyHost(
        runtime: rt,
        http: http,
        budget: DrpyBudget(maxOutputChars: 8),
      );
      await strict.install(parseRule(_ruleJs));
      await rt.functions['setResult']!(['12345678']);
      await expectLater(
        rt.functions['setResult']!(['9']),
        throwsA(isA<FetchException>()),
      );
    });

    test('runSnippet：globals 注入 + setResult 捕获优先于返回值', () async {
      await host.install(parseRule(_ruleJs));
      rt.onEvalAsync = (code) async {
        expect(code, contains('globalThis["input"] = "https://u.example"'));
        expect(code, contains('var x = input;'));
        await rt.functions['setResult']!([
          {'a': 1},
        ]);
        return 'ignored';
      };
      final result = await host.runSnippet(
        'var x = input;',
        globals: const {'input': 'https://u.example'},
      );
      expect(result, {
        'a': 1,
      });
    });

    test('resultAsList：list 包裹 / JSON 字符串 / data.list 归一', () async {
      await host.install(parseRule(_ruleJs));
      expect(host.resultAsList([
        {'a': 1},
      ]), hasLength(1));
      expect(host.resultAsList('[{"a":1}]'), hasLength(1));
      expect(host.resultAsList({
        'data': {
          'list': [
            {'a': 1},
          ]
        }
      }), hasLength(1));
      expect(host.resultAsList('不是 JSON'), isEmpty);
      expect(host.resultAsList(null), isEmpty);
    });

    test('resultAsMap：JSON 字符串 / 列表首元素归一', () async {
      await host.install(parseRule(_ruleJs));
      expect(host.resultAsMap('{"url":"u"}'), {'url': 'u'});
      expect(host.resultAsMap([
        {'b': 2},
      ]), {'b': 2});
      expect(host.resultAsMap(''), isNull);
    });
  });
}
