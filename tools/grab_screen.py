# 全屏截图（Windows）
from PIL import ImageGrab
import sys

img = ImageGrab.grab()
img.save(sys.argv[1])
print("saved", sys.argv[1], img.size)
