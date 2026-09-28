import 'package:star_player/star_player.dart';
import 'package:test/test.dart';

void main() {
  group('FallbackChain —— 失败回退链（docs/03 §1.2）', () {
    test('Windows：默认 libmpv（格式全覆盖），不可再回退时交还上层', () {
      const chain = FallbackChain(PlayerHost.windows);
      expect(chain.defaults(), [PlayerKernel.libmpv]);
      expect(chain.nextAfter(PlayerKernel.libmpv), isNull);
    });

    test('Android：默认 EXO → IJK → 系统，逐级降级', () {
      const chain = FallbackChain(PlayerHost.androidTv);
      expect(chain.defaults(),
          [PlayerKernel.exo, PlayerKernel.ijk, PlayerKernel.system]);
      expect(chain.nextAfter(PlayerKernel.exo), PlayerKernel.ijk);
      expect(chain.nextAfter(PlayerKernel.ijk), PlayerKernel.system);
      expect(chain.nextAfter(PlayerKernel.system), isNull);
    });

    test('Windows 下系统内核失败回退到 libmpv', () {
      const chain = FallbackChain(PlayerHost.windows);
      expect(chain.nextAfter(PlayerKernel.system), PlayerKernel.libmpv);
    });

    test('auto 起点展开为默认首档', () {
      const chain = FallbackChain(PlayerHost.androidPhone);
      expect(chain.nextAfter(PlayerKernel.auto), PlayerKernel.exo);
    });
  });
}
