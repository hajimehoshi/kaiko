module kaiko.game.mainwindow;

import std.utf;
import std.windows.syserror;
import win32.windows;

final class MainWindow {

  private static string wndClassName_ = "KaikoMainWindowClass";
  private static HANDLE moduleHandle_;
  
  static this() {
    moduleHandle_ = GetModuleHandle(null);
    assert(moduleHandle_);
    {
      WNDCLASSEX wc;
      with (wc) {
        cbSize        = typeof(wc).sizeof;
        style         = CS_HREDRAW | CS_VREDRAW;
        lpfnWndProc   = &WndProc;
        hInstance     = moduleHandle_;
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
  }

  static ~this() {
    UnregisterClass(toUTF16z(wndClassName_), moduleHandle_);
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

  private HWND hWnd_;

  invariant() {
    assert(this.hWnd_);
  }

  public this(int width, int height) {
    RECT rect = { 0, 0, width * 2, height * 2 };
    immutable style = WS_OVERLAPPEDWINDOW & ~WS_THICKFRAME & ~WS_MAXIMIZEBOX;
    if (!AdjustWindowRect(&rect, style, false)) {
      throw new Exception(sysErrorString(GetLastError()));
    }
    this.hWnd_ = CreateWindow(toUTF16z(wndClassName_),
                              toUTF16z("Fooo"),
                              style,
                              CW_USEDEFAULT, CW_USEDEFAULT,
                              rect.right - rect.left, rect.bottom - rect.top,
                              null, null, moduleHandle_, null);
    if (!this.hWnd_) {
      throw new Exception(sysErrorString(GetLastError()));
    }
  }

  @property
  public HANDLE handle() {
    return this.hWnd_;
  }

  @property
  public const(HANDLE) handle() const {
    return this.hWnd_;
  }

}
