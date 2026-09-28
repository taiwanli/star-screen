import 'dart:convert';

import 'exceptions.dart';

/// 订阅原文清洗器（docs/05 §5 容错规则 1）。
///
/// 生态实测（docs/06、docs/11 压测）：配置存在 BOM、UTF-16 编码、`//` 注释行、
/// 尾随逗号、字符串内未转义控制字符等脏格式；本类把它们全部归一。
class ConfigCleaner {
  const ConfigCleaner._();

  /// 字节级智能解码：UTF-16LE/BE BOM → UTF-8 BOM → 宽松 UTF-8。
  /// （实测 c120487/00wh0.txt 为 UTF-16LE，直接 utf8 解码会得到乱码。）
  static String decodeBytes(List<int> bytes) {
    if (bytes.length >= 2 && bytes[0] == 0xFF && bytes[1] == 0xFE) {
      final units = <int>[
        for (var i = 2; i + 1 < bytes.length; i += 2)
          bytes[i] | (bytes[i + 1] << 8),
      ];
      return String.fromCharCodes(units);
    }
    if (bytes.length >= 2 && bytes[0] == 0xFE && bytes[1] == 0xFF) {
      final units = <int>[
        for (var i = 2; i + 1 < bytes.length; i += 2)
          (bytes[i] << 8) | bytes[i + 1],
      ];
      return String.fromCharCodes(units);
    }
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3), allowMalformed: true);
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  /// 清洗 BOM / 注释行 / 尾随逗号，返回可解析的 JSON 文本。
  static String clean(String raw) {
    var text = raw;
    if (text.startsWith('\uFEFF')) text = text.substring(1);

    final lines = text.split('\n');
    final kept = lines.where((line) {
      final t = line.trimLeft();
      return !t.startsWith('//');
    }).toList();

    return kept.join('\n').trim();
  }

  /// 清洗并解码为 JSON。三级容错：严格 → 尾随逗号 → 字符串内控制字符转义。
  ///
  /// [source] 用于失败提示上下文 —— 无效源必须能被用户识别（docs/11 压测反馈）。
  static dynamic decode(String raw, {Uri? source}) {
    final cleaned = clean(raw);
    final where = source == null ? '' : '（来源：$source）';
    final hint = '$where —— 源可能已失效，或该地址是网页入口而非配置直链';
    try {
      return jsonDecode(cleaned);
    } on FormatException {
      try {
        return jsonDecode(_stripTrailingCommas(cleaned));
      } on FormatException {
        try {
          return jsonDecode(_escapeControlChars(_stripTrailingCommas(cleaned)));
        } on FormatException catch (e) {
          throw ConfigParseException('订阅内容不是合法的配置 JSON$hint', e.message);
        }
      }
    }
  }

  static String _stripTrailingCommas(String text) => text.replaceAllMapped(
        RegExp(r',\s*([}\]])'),
        (m) => m.group(1)!,
      );

  /// 修复字符串内的未转义控制字符（实测：部分手写配置在字符串里直接换行）。
  static String _escapeControlChars(String text) {
    final out = StringBuffer();
    var inString = false;
    var escaped = false;
    for (final rune in text.runes) {
      final ch = String.fromCharCode(rune);
      if (!inString) {
        if (rune == 0x22) inString = true;
        out.write(ch);
        continue;
      }
      if (escaped) {
        escaped = false;
        out.write(ch);
        continue;
      }
      switch (rune) {
        case 0x5C: // backslash
          escaped = true;
          out.write(ch);
        case 0x22: // quote
          inString = false;
          out.write(ch);
        case 0x0A:
          out.write(r'\n');
        case 0x0D:
          out.write(r'\r');
        case 0x09:
          out.write(r'\t');
        default:
          if (rune < 0x20) {
            out.write(rune.toRadixString(16).padLeft(4, '0').padLeft(6, r'\u'));
          } else {
            out.write(ch);
          }
      }
    }
    return out.toString();
  }
}
