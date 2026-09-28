import 'package:drift/drift.dart';
import 'package:star_domain/star_domain.dart';
import 'package:star_storage/star_storage.dart';

/// 直播频道落库（live_channel 表，docs/09 M3-5）。
///
/// v0.1 语义：导入订阅时全量替换（单一直播面），分组=TXT `#genre#` /
/// M3U `group-title`；tvgId 落 epg_id 供 EPG 客户端关联。
class DriftLiveChannelStore {
  final StarDatabase db;

  DriftLiveChannelStore(this.db);

  /// 全量替换频道表（先清空再批量写入）。
  Future<void> replaceAll(List<ParsedLiveChannel> channels) async {
    await db.delete(db.liveChannels).go();
    await db.batch((b) {
      for (var i = 0; i < channels.length; i++) {
        final c = channels[i];
        b.insert(db.liveChannels, LiveChannelsCompanion.insert(
          groupId: c.group,
          name: c.name,
          url: c.url,
          logo: c.logo == null ? const Value.absent() : Value(c.logo),
          epgId: c.tvgId == null ? const Value.absent() : Value(c.tvgId),
          tuneNo: Value(i + 1),
          sort: Value(i),
        ));
      }
    });
  }

  /// 清空全部直播频道。
  Future<void> clearAll() async {
    await db.delete(db.liveChannels).go();
  }

  Future<int> count() async {
    final countExp = db.liveChannels.id.count();
    final query = db.selectOnly(db.liveChannels)
      ..addColumns([countExp]);
    final row = await query.getSingle();
    return row.read(countExp) ?? 0;
  }

  /// 全部频道（按导入顺序），聚合为「分组 → 频道」结构供直播页渲染。
  Future<Map<String, List<ParsedLiveChannel>>> grouped() async {
    final query = db.select(db.liveChannels)
      ..orderBy([(u) => OrderingTerm(expression: u.sort)]);
    final rows = await query.get();
    final out = <String, List<ParsedLiveChannel>>{};
    for (final r in rows) {
      out
          .putIfAbsent(r.groupId, () => [])
          .add(ParsedLiveChannel(
            group: r.groupId,
            name: r.name,
            url: r.url,
            tvgId: r.epgId,
            logo: r.logo,
          ));
    }
    return out;
  }
}
