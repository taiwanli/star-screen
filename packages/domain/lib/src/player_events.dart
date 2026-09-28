/// 领域侧播放器契约与事件（依赖方向守护）：
///
/// packages/player 面向宿主，domain 不能反向依赖它。领域层只认这里的
/// [DomainPlayerController]；宿主在组装时把 `star_player.PlayerController`
/// 桥接为实现（几个方法的一次性适配）。
library;

sealed class DomainPlayerEvent {
  const DomainPlayerEvent();
}

class DomainPlayerBuffering extends DomainPlayerEvent {
  final double progress;
  const DomainPlayerBuffering(this.progress);
}

class DomainPlayerPosition extends DomainPlayerEvent {
  final int positionSec;
  final int durationSec;
  const DomainPlayerPosition(this.positionSec, this.durationSec);
}

class DomainPlayerCompleted extends DomainPlayerEvent {
  const DomainPlayerCompleted();
}

class DomainPlayerFailed extends DomainPlayerEvent {
  final String reason;
  const DomainPlayerFailed(this.reason);
}

/// 领域播放器契约（最小面）。
abstract interface class DomainPlayerController {
  Stream<DomainPlayerEvent> get events;

  Future<void> load(
    String url, {
    Map<String, String> headers = const {},
    int startAtSec = 0,
  });

  Future<void> play();
  Future<void> pause();
  Future<void> seek(int positionSec);
  Future<void> dispose();
}
