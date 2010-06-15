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

  private this(int width, int height) {
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
    auto textureFactory = device.textureFactory;
    auto yielder = new Yielder();
    auto fiber = new Fiber({ scene.run(yielder); });
    MSG msg;
    while (msg.message != WM_QUIT) {
      if (PeekMessage(&msg, null, 0, 0, PM_REMOVE)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
      } else {
        Sleep(1);
        // 1/600 秒?
        fiber.call();
        if (scene.drawable !is null) {
          device.update(scene.drawable);
        }
      }
    }
    return cast(int)msg.wParam;
  }

  @property
  public int width() const {
    return this.width_;
  }

  private final class Yielder {

    public void yield() {
      Fiber.yield();
    }

  }

}
