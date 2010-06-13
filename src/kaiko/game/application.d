module kaiko.game.application;

import std.random;
import std.windows.syserror;
import win32.windows;
import kaiko.game.drawablecollection;
import kaiko.game.sprite;
import kaiko.game.texture;

final class ExitException : Exception {

  private immutable int status_;

  public this(int status) {
    super("Exit");
    this.status_ = status;
  }

  @property public int status() const {
    return this.status_;
  }

}

final class Application {

  public static immutable width = 256;
  public static immutable height = 224;

  private this() {
  }

  @property
  public static int cmdShow() {
    static cmdShow = -1;
    if (cmdShow == -1) {
      STARTUPINFO startupInfo;
      GetStartupInfo(&startupInfo);
      cmdShow = (startupInfo.dwFlags & STARTF_USESHOWWINDOW) ? startupInfo.wShowWindow : SW_SHOWDEFAULT;
      assert(cmdShow != -1);
    }
    return cmdShow;
  }

  @property
  public static HANDLE moduleHandle() {
    static HANDLE moduleHandle;
    if (!moduleHandle) {
      moduleHandle = GetModuleHandle(null);
      assert(moduleHandle);
    }
    return moduleHandle;
  }

  public static int run(Device, Scene)(HWND hWnd, Device device, Scene scene) in {
    assert(hWnd);
  } body {
    ShowWindow(hWnd, typeof(this).cmdShow);
    if (!UpdateWindow(hWnd)) {
      throw new Exception(sysErrorString(GetLastError()));
    }
    scene.run(device);
    return 0;
  }

  public static void update(Device, Drawable)(Device device, Drawable drawable) {
    MSG msg;
    if (PeekMessage(&msg, null, 0, 0, PM_REMOVE)) {
      TranslateMessage(&msg);
      DispatchMessage(&msg);
    } else {
      Sleep(1);
      device.update(drawable);
    }
    if (msg.message == WM_QUIT) {
      throw new ExitException(cast(int)msg.wParam);
    }
  }

}
