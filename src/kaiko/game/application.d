module kaiko.game.application;

import core.thread;
import std.windows.syserror;
import win32.windows;
import kaiko.game.texture;

final class Application {

  private static Application instance_;

  static this() {
    this.instance_ = new Application(256, 224);
  }

  @property
  public static Application instance() {
    return this.instance_;
  }

  private immutable int width_, height_;

  invariant() {
    assert(0 < this.width_);
    assert(0 < this.height_);
  }

  private this(int width, int height) in {
    assert(0 < width);
    assert(0 < height);
  } body {
    this.width_ = width;
    this.height_ = height;
  }

  @property
  public int height() const {
    return this.height_;
  }

  public int run(Device, Scene)(HWND hWnd, Device device, Scene scene) in {
    assert(hWnd);
    assert(device !is null);
    assert(scene !is null);
  } body {
    {
      STARTUPINFO startupInfo;
      GetStartupInfo(&startupInfo);
      immutable cmdShow = (startupInfo.dwFlags & STARTF_USESHOWWINDOW) ? startupInfo.wShowWindow : SW_SHOWDEFAULT;
      ShowWindow(hWnd, cmdShow);
    }
    if (!UpdateWindow(hWnd)) {
      throw new Exception(sysErrorString(GetLastError()));
    }
    scene.Drawable drawable;
    auto fiber = new Fiber({
        scene.run((scene.Drawable d) {
            drawable = d;
            Fiber.yield();
          });
      });
    MSG msg;
    while (msg.message != WM_QUIT) {
      if (PeekMessage(&msg, null, 0, 0, PM_REMOVE)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
      } else {
        Sleep(1);
        // 1/600 秒?
        if (fiber.state == Fiber.State.TERM) {
          return 0;
        }
        fiber.call();
        if (drawable !is null) {
          device.update(drawable);
        }
      }
    }
    return cast(int)msg.wParam;
  }

  @property
  public int width() const {
    return this.width_;
  }

}
