module kaiko.game.application;

import std.windows.syserror;
import win32.windows;
import kaiko.game.texture;

final class ExitException : Exception {

  private immutable int status_;

  public this(int status) {
    super("Exit");
    this.status_ = status;
  }

  @property public int status() {
    return this.status_;
  }

}

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

  public void run(Device, Scene)(HWND hWnd, Device device, Scene scene) in {
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
    auto gameUpdater = new GameUpdater!Device(device);
    scene.run(textureFactory, gameUpdater);
  }

  @property
  public int width() const {
    return this.width_;
  }

  private final class GameUpdater(Device) {

    private Device device_;

    invariant() {
      assert(this.device_ !is null);
    }

    private this(Device device) in {
      assert(device !is null);
    } body {
      this.device_ = device;
    }

    public void update(Drawable)(Drawable drawable) {
      MSG msg;
      if (PeekMessage(&msg, null, 0, 0, PM_REMOVE)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
      } else {
        Sleep(1);
        // 1/600 秒?
        if (drawable) {
          this.device_.update(drawable);
        }
      }
      if (msg.message == WM_QUIT) {
        throw new ExitException(cast(int)msg.wParam);
      }
    }

  }

}
