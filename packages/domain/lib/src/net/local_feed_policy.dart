import 'dart:io';

import '../config/config_cleaner.dart';
import '../starrule/star_rule_deep_link.dart';
import '../starrule/star_rule_parser.dart';

/// 本地订阅文件解析策略（docs/05 §5 / 源管理本地导入）。
///
/// 统一处理用户粘贴的「路径 / file:// / 相对路径 / JSON 原文 / 目录」，
/// 输出可直接进入解析管线的正文，并标明格式与来源，错误可读。
class LocalFeedPolicy {
  const LocalFeedPolicy._();

  /// 单文件正文上限（防御异常大文件；配置通常 < 2MB）。
  static const int maxFileBytes = 8 * 1024 * 1024;

  /// 目录扫描时最多导入的文件数。
  static const int maxDirFiles = 50;

  /// 认出的本地引用形态。
  static bool isLocalRef(String ref) {
    final t = _unquote(ref.trim());
    if (t.isEmpty) return false;
    if (t.startsWith('{') || t.startsWith('[')) return false; // 粘贴原文
    if (t.startsWith('http://') || t.startsWith('https://')) return false;
    if (StarRuleDeepLink.isImportLink(t)) return false;
    return true;
  }

  /// 粘贴的 JSON 原文。
  static bool isPastedJson(String ref) {
    final t = ref.trim();
    return t.startsWith('{') || t.startsWith('[');
  }

  /// 去掉误粘贴的首尾引号。
  static String _unquote(String s) {
    if (s.length >= 2 &&
        ((s.startsWith('"') && s.endsWith('"')) ||
            (s.startsWith("'") && s.endsWith("'")))) {
      return s.substring(1, s.length - 1).trim();
    }
    return s;
  }

  /// 把用户输入规范成文件系统路径；非法返回 null。
  static String? resolvePath(String ref) {
    var t = _unquote(ref.trim());
    if (t.isEmpty) return null;

    // file:// URI（含 file:///C:/ 与 file://localhost/C:/）
    if (t.startsWith('file:')) {
      try {
        final uri = Uri.parse(t);
        t = uri.toFilePath();
      } on Object {
        return null;
      }
    }

    // Windows 盘符反斜杠 / 正斜杠均接受；去掉可能的 file: 残留
    t = t.replaceAll('\\', Platform.isWindows ? '\\' : '/');
    return t;
  }

  /// 读取本地订阅文件（策略见类注释）。
  ///
  /// [baseDir]：相对路径基准（缺省为当前工作目录）。
  static LocalFeedRead readFile(String ref, {Directory? baseDir}) {
    final path = resolvePath(ref);
    if (path == null) {
      throw LocalFeedException('无法解析本地路径：$ref');
    }

    var file = File(path);
    if (!file.isAbsolute) {
      final root = baseDir ?? Directory.current;
      file = File('${root.path}${Platform.pathSeparator}$path');
    }

    if (!file.existsSync()) {
      // 兼容用户多写/少写扩展名
      final alt = _withAltExtensions(file);
      if (alt != null && alt.existsSync()) {
        file = alt;
      } else {
        throw LocalFeedException('本地文件不存在：${file.path}');
      }
    }

    final stat = file.statSync();
    if (stat.type == FileSystemEntityType.directory) {
      throw LocalFeedException(
        '这是目录而不是文件：${file.path}（批量导入请用 importDirectory）',
      );
    }
    if (stat.size > maxFileBytes) {
      throw LocalFeedException(
        '文件过大（${(stat.size / 1e6).toStringAsFixed(1)}MB > '
        '${(maxFileBytes / 1e6).toStringAsFixed(0)}MB）：${file.path}',
      );
    }
    if (stat.size == 0) {
      throw LocalFeedException('文件为空：${file.path}');
    }

    final bytes = file.readAsBytesSync();
    final body = ConfigCleaner.decodeBytes(bytes);
    final kind = detectKind(body, fileName: file.path);
    return LocalFeedRead(
      path: file.absolute.path,
      uri: Uri.file(file.absolute.path),
      body: body,
      kind: kind,
      sizeBytes: stat.size,
    );
  }

  /// 目录批量：按扩展名收集可导入文件（排序稳定，限量 [maxDirFiles]）。
  static LocalDirScan scanDirectory(String ref, {Directory? baseDir}) {
    final path = resolvePath(ref);
    if (path == null) {
      throw LocalFeedException('无法解析本地目录：$ref');
    }
    var dir = Directory(path);
    if (!dir.isAbsolute) {
      final root = baseDir ?? Directory.current;
      dir = Directory('${root.path}${Platform.pathSeparator}$path');
    }
    if (!dir.existsSync()) {
      throw LocalFeedException('目录不存在：${dir.path}');
    }

    final files = <File>[];
    for (final e in dir.listSync(followLinks: false)) {
      if (e is! File) continue;
      final name = e.uri.pathSegments.isEmpty
          ? e.path
          : e.uri.pathSegments.last.toLowerCase();
      if (!_importableName(name)) continue;
      files.add(e);
    }
    files.sort((a, b) => a.path.compareTo(b.path));
    final capped = files.take(maxDirFiles).toList();
    return LocalDirScan(
      directory: dir.absolute.path,
      files: capped,
      truncated: files.length > capped.length,
      totalFound: files.length,
    );
  }

  /// 逐个读目录内文件，跳过损坏项并记录原因。
  static LocalDirReadResult readDirectory(String ref, {Directory? baseDir}) {
    final scan = scanDirectory(ref, baseDir: baseDir);
    final ok = <LocalFeedRead>[];
    final failed = <LocalFeedFailure>[];
    for (final f in scan.files) {
      try {
        ok.add(readFile(f.absolute.path));
      } on LocalFeedException catch (e) {
        failed.add(LocalFeedFailure(path: f.absolute.path, reason: e.message));
      } on Object catch (e) {
        failed.add(LocalFeedFailure(path: f.absolute.path, reason: '$e'));
      }
    }
    return LocalDirReadResult(
      directory: scan.directory,
      reads: ok,
      failed: failed,
      truncated: scan.truncated,
      totalFound: scan.totalFound,
    );
  }

  static bool _importableName(String lowerName) {
    return lowerName.endsWith('.json') ||
        lowerName.endsWith('.star.json') ||
        lowerName.endsWith('.txt') && lowerName.contains('config') ||
        lowerName.endsWith('.jsonc');
  }

  static File? _withAltExtensions(File f) {
    final p = f.path;
    final candidates = <String>[
      if (!p.endsWith('.json')) '$p.json',
      if (!p.endsWith('.star.json')) '$p.star.json',
      if (p.endsWith('.json')) p.substring(0, p.length - 5),
      if (p.endsWith('.star.json'))
        p.substring(0, p.length - '.star.json'.length),
    ];
    for (final c in candidates) {
      final alt = File(c);
      if (alt.existsSync() && alt.statSync().type == FileSystemEntityType.file) {
        return alt;
      }
    }
    return null;
  }

  /// 正文格式识别。
  static LocalFeedKind detectKind(String body, {String? fileName}) {
    final t = body.trimLeft().replaceFirst('\uFEFF', '');
    if (t.isEmpty) return LocalFeedKind.empty;
    if (t.startsWith('<') || t.toLowerCase().contains('<!doctype')) {
      return LocalFeedKind.html;
    }
    if (t.startsWith('{') || t.startsWith('[')) {
      if (StarRuleParser.looksLikeStarRule(t)) {
        return LocalFeedKind.starRule;
      }
      // TVBox：有 sites / storeHouse / urls / lives 任一
      if (t.contains('"sites"') ||
          t.contains('"storeHouse"') ||
          t.contains('"urls"') ||
          t.contains('"lives"') ||
          t.contains('"spider"')) {
        return LocalFeedKind.tvbox;
      }
      return LocalFeedKind.jsonUnknown;
    }
    return LocalFeedKind.textUnknown;
  }
}

/// 本地文件读取结果。
class LocalFeedRead {
  final String path;
  final Uri uri;
  final String body;
  final LocalFeedKind kind;
  final int sizeBytes;

  const LocalFeedRead({
    required this.path,
    required this.uri,
    required this.body,
    required this.kind,
    required this.sizeBytes,
  });
}

class LocalDirScan {
  final String directory;
  final List<File> files;
  final bool truncated;
  final int totalFound;

  const LocalDirScan({
    required this.directory,
    required this.files,
    required this.truncated,
    required this.totalFound,
  });
}

class LocalDirReadResult {
  final String directory;
  final List<LocalFeedRead> reads;
  final List<LocalFeedFailure> failed;
  final bool truncated;
  final int totalFound;

  const LocalDirReadResult({
    required this.directory,
    required this.reads,
    required this.failed,
    required this.truncated,
    required this.totalFound,
  });
}

class LocalFeedFailure {
  final String path;
  final String reason;
  const LocalFeedFailure({required this.path, required this.reason});
}

enum LocalFeedKind {
  starRule,
  tvbox,
  jsonUnknown,
  html,
  textUnknown,
  empty,
}

class LocalFeedException implements Exception {
  final String message;
  const LocalFeedException(this.message);
  @override
  String toString() => 'LocalFeedException: $message';
}
