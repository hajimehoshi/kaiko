module kaiko.game.application;

private import core.thread;
private import std.windows.syserror;
private import win32.mmsystem;
private import win32.windows;
private import kaiko.game.texture;

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
    LARGE_INTEGER freq, gamePreviousTime, secondPreviousTime, now;
    QueryPerformanceCounter(&now);
    gamePreviousTime = secondPreviousTime = now;
    long gameFramesPerSecond = 0;
    long graphicsFramesPerSecond = 0;
    if (!QueryPerformanceFrequency(&freq) || freq.QuadPart == 0) {
      throw new Exception("Can't use QueryPerformanceFrequency function");
    }
    while (msg.message != WM_QUIT) {
      if (PeekMessage(&msg, null, 0, 0, PM_REMOVE)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
      } else {
        QueryPerformanceCounter(&now);
        // TODO: あまりにも差がある場合の考慮
        // TODO: 600 の定数化
        while (1 <= (now.QuadPart - gamePreviousTime.QuadPart) * 600 / freq.QuadPart) {
          assert(fiber.state != Fiber.State.TERM);
          fiber.call();
          if (fiber.state == Fiber.State.TERM) {
            return 0;
          }
          // TODO: remove division
          gamePreviousTime.QuadPart += freq.QuadPart / 600;
          gameFramesPerSecond++;
        }
        {
          if (drawable !is null) {
            device.update(drawable);
          }
          graphicsFramesPerSecond++;
        }
        if (1 <= (now.QuadPart - secondPreviousTime.QuadPart) / freq.QuadPart) {
          std.stdio.writeln("Game Frames: ", gameFramesPerSecond);
          std.stdio.writeln("Graphics Frames: ", graphicsFramesPerSecond);
          secondPreviousTime = now;
          gameFramesPerSecond = 0;
          graphicsFramesPerSecond = 0;
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
