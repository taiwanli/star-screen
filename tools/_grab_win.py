import win32gui, win32ui
from PIL import Image
import ctypes
from ctypes import windll, c_long, c_uint32, c_uint16, c_long

class RECT(ctypes.Structure):
    _fields_ = [("left", c_long), ("top", c_long), ("right", c_long), ("bottom", c_long)]

hwnd = windll.user32.GetForegroundWindow()
rect = RECT()
windll.user32.GetWindowRect(hwnd, ctypes.byref(rect))
print("Window:", windll.user32.GetWindowTextW(hwnd, None, 0), (rect.left, rect.top, rect.right, rect.bottom))

w = rect.right - rect.left
h = rect.bottom - rect.top

hwndDC = windll.user32.GetWindowDC(hwnd)
memDC = windll.gdi32.CreateCompatibleDC(hwndDC)
hbm = windll.gdi32.CreateCompatibleBitmap(hwndDC, w, h)
old = windll.gdi32.SelectObject(memDC, hbm)
windll.gdi32.BitBlt(memDC, 0, 0, w, h, hwndDC, 0, 0, 0x00CC0020)  # SRCCOPY

class BITMAPINFOHEADER(ctypes.Structure):
    _fields_ = [("biSize", c_uint32), ("biWidth", c_long), ("biHeight", c_long),
                ("biPlanes", c_uint16), ("biBitCount", c_uint16),
                ("biCompression", c_uint32), ("biSizeImage", c_uint32),
                ("biXPelsPerMeter", c_long), ("biYPelsPerMeter", c_long),
                ("biClrUsed", c_uint32), ("biClrImportant", c_uint32)]

bmih = BITMAPINFOHEADER()
bmih.biSize = ctypes.sizeof(BITMAPINFOHEADER)
bmih.biWidth = w
bmih.biHeight = -h
bmih.biPlanes = 1
bmih.biBitCount = 32
bmih.biCompression = 0
bmih.biSizeImage = w * h * 4

buf = ctypes.create_string_buffer(w * h * 4)
windll.gdi32.GetDIBits(memDC, hbm, 0, h, buf, ctypes.byref(bmih), 0)

img = Image.frombuffer("RGBA", (w, h), buf, "raw", "BGRA", 0, 1)
out = "C:/Users/Administrator/Desktop/星映 - 副本/tools/shot_test_home.png"
img.save(out)
print("Saved:", out, img.size)

windll.gdi32.DeleteDC(memDC)
windll.gdi32.DeleteObject(hbm)
windll.user32.ReleaseDC(hwnd, hwndDC)
