module kaiko.game.mainwindow;

import std.utf;
import std.windows.syserror;
import win32.windows;

final class MainWindow(Application) {

  private static string wndClassName_ = "KaikoMainWindowClass";
  
  static this() {
    WNDCLASSEX wc;
    with (wc) {
      cbSize        = typeof(wc).sizeof;
      style         = CS_HREDRAW | CS_VREDRAW;
      lpfnWndProc   = &WndProc;
      hInstance     = Application.moduleHandle;
      hCursor       = LoadCursor(null, IDC_ARROW);
      hbrBackground = cast(HBRUSH)(COLOR_WINDOW + 1);
      lpszMenuName  = null;
      lpszClassName = wndClassName_.toUTF16z();
    }
    immutable result = RegisterClassEx(&wc);
    if (!result) {
      throw new Exception(sysErrorString(GetLastError()));
    }
  }

  static ~this() {
    UnregisterClass(toUTF16z(typeof(this).wndClassName_), Application.moduleHandle);
  }

  private HWND hWnd_;

  public this() {
    RECT rect = { 0, 0, Application.width * 2, Application.height * 2 };
    immutable style = WS_OVERLAPPEDWINDOW & ~WS_THICKFRAME & ~WS_MAXIMIZEBOX;
    if (!AdjustWindowRect(&rect, style, false)) {
      throw new Exception(sysErrorString(GetLastError()));
    }
    this.hWnd_ = CreateWindow(toUTF16z(typeof(this).wndClassName_),
                              toUTF16z("Fooo"),
                              style,
                              CW_USEDEFAULT, CW_USEDEFAULT,
                              rect.right - rect.left, rect.bottom - rect.top,
                              null, null, Application.moduleHandle, null);
    if (!this.hWnd_) {
      throw new Exception(sysErrorString(GetLastError()));
    }
  }

  @property
  public HANDLE handle() {
    return this.hWnd_;
  }

  extern (Windows) {
    private static LRESULT WndProc(HWND hWnd, UINT message, WPARAM wParam, LPARAM lParam) {
      switch (message) {
      case WM_DESTROY:
        PostQuitMessage(0);
        break;
      default:
        return DefWindowProc(hWnd, message, wParam, lParam);
      }
      return 0;
    }
  }

}
