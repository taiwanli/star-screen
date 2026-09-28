# Win32 窗口截图工具（PrintWindow PW_RENDERFULLCONTENT）
import ctypes
import ctypes.wintypes as wt
import sys
from PIL import Image

user32 = ctypes.windll.user32
gdi32 = ctypes.windll.gdi32

BI_RGB = 0

# 显式声明原型，避免 ctypes 默认整型返回把指针截断
user32.GetDC.argtypes = [wt.HWND]
user32.GetDC.restype = wt.HANDLE
user32.ReleaseDC.argtypes = [wt.HWND, wt.HANDLE]
gdi32.CreateCompatibleDC.argtypes = [wt.HANDLE]
gdi32.CreateCompatibleDC.restype = wt.HANDLE
gdi32.CreateCompatibleBitmap.argtypes = [wt.HANDLE, ctypes.c_int, ctypes.c_int]
gdi32.CreateCompatibleBitmap.restype = wt.HANDLE
gdi32.SelectObject.argtypes = [wt.HANDLE, wt.HANDLE]gdi32.SelectObject.restype = wt.HANDLEgdi32.DeleteObject.argtypes = [wt.HANDLE]gdi32.DeleteDC.argtypes = [wt.HANDLE]user32.PrintWindow.argtypes = [wt.HWND, wt.HANDLE, ctypes.c_uint]user32.PrintWindow.restype = ctypes.c_int
gdi32.GetDIBits.argtypes = [wt.HANDLE, wt.HANDLE, wt.DWORD, wt.DWORD, ctypes.c_void_p, ctypes.c_int, ctypes.c_int]
gdi32.GetDIBits.restype = wt.DWORD


def shot(hwnd: int, out: str):
    r = wt.RECT()
    user32.GetWindowRect(wt.HWND(hwnd), ctypes.byref(r))
    w, h = r.right - r.left, r.bottom - r.top
    if w <= 0 or h <= 0:
        print("bad rect")
        return
    hwnd = wt.HWND(hwnd)
    hdc = user32.GetDC(hwnd)
    dc = gdi32.CreateCompatibleDC(hdc)
    bmp = gdi32.CreateCompatibleBitmap(hdc, w, h)
    gdi32.SelectObject(dc, bmp)
    ok = user32.PrintWindow(hwnd, dc, 2)

    buf_size = 40 + w * h * 4
    buf = ctypes.create_string_buffer(buf_size)
    bi_ptr = ctypes.addressof(buf)

    def put32(off, v):
        ctypes.memmove(bi_ptr + off, v.to_bytes(4, "little", signed=True), 4)

    put32(0, 40)
    put32(4, w)
    put32(8, -h)  # 负值 = top-down
    put32(12, 1)
    put32(14, 32)
    put32(16, BI_RGB)
    got = gdi32.GetDIBits(dc, bmp, 0, h, buf, buf_size, 0)
    gdi32.DeleteObject(bmp)
    gdi32.DeleteDC(dc)
    user32.ReleaseDC(hwnd, hdc)
    print(f"ok={ok} bits={got} {w}x{h}")
    if got:
        data = buf.raw[40:]
        img = Image.frombuffer("RGBA", (w, h), data, "raw", "BGRA", 0, 1).convert("RGB")
        img.save(out)
        print("saved", out)


if __name__ == "__main__":
    shot(int(sys.argv[1]), sys.argv[2])
