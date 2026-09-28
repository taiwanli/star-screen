// 架构守护（docs/03 §2 依赖规则）：扫描 packages/domain 的 Dart 源，
// 禁止依赖 flutter/material 等 UI 库。CI 中失败即阻断合并。
import 'dart:io';

const _bannedPrefixes = [
  'package:flutter/',
  'package:flutter_test/',
  'dart:ui',
];

void main() {
  final root = Directory('packages/domain');
  if (!root.existsSync()) {
    stderr.writeln('请在仓库根目录运行：dart run tools/check_architecture.dart');
    exit(2);
  }

  final violations = <String>[];
  for (final entity in root.listSync(recursive: true)) {
    if (entity is! File || !entity.path.endsWith('.dart')) continue;
    for (final line in entity.readAsLinesSync()) {
      final trimmed = line.trim();
      if (!trimmed.startsWith('import ') && !trimmed.startsWith('export ')) {
        continue;
      }
      for (final banned in _bannedPrefixes) {
        if (trimmed.contains("'$banned") || trimmed.contains('"$banned')) {
          violations.add('${entity.path}: $trimmed');
        }
      }
    }
  }

  if (violations.isNotEmpty) {
    stderr.writeln('领域层出现 UI 依赖，违反架构红线：');
    for (final v in violations) {
      stderr.writeln('  $v');
    }
    exit(1);
  }
  stdout.writeln('架构守护通过：packages/domain 无 UI 依赖。');
}
