Add-Type -AssemblyName System.Windows.Forms
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class PW3 {
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr hWnd, IntPtr hDC, uint flags);
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT r);
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
}
'@
$rect = New-Object PW3+RECT
[PW3]::GetWindowRect([IntPtr]5179468, [ref]$rect) | Out-Null
$w = $rect.Right - $rect.Left
$ht = $rect.Bottom - $rect.Top
Write-Host "win: ${w}x$ht"
$bmp = New-Object System.Drawing.Bitmap($w, $ht)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$hdc = $g.GetHdc()
[PW3]::PrintWindow([IntPtr]5179468, $hdc, 3) | Out-Null
$g.ReleaseHdc($hdc)
$g.Dispose()
$bmp.Save("C:\Users\Administrator\Desktop\星映 - 副本\tools\shot1_home.png")
$bmp.Dispose()
Write-Host "ok"
