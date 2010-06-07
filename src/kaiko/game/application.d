module kaiko.game.application;

import std.windows.syserror;
import win32.windows;
import kaiko.game.sprite;
import kaiko.game.texture;

final class Application {

  public static immutable width = 256;
  public static immutable height = 224;

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

  public static int run(Device)(HWND hWnd, Device device) in {
    assert(hWnd);
  } body {
    ShowWindow(hWnd, typeof(this).cmdShow);
    if (!UpdateWindow(hWnd)) {
      throw new Exception(sysErrorString(GetLastError()));
    }
    MSG msg;
    auto texture = new Texture!Device(device, "d.png");
    auto sprites = [new Sprite!(Texture!Device)(texture)];
    sprites[0].x = 10;
    sprites[0].y = 10;
    while (msg.message != WM_QUIT) {
      if (PeekMessage(&msg, null, 0, 0, PM_REMOVE)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
      } else {
        Sleep(1);
        device.update(sprites);
      }
    }
    return cast(int)msg.wParam;
  }

}
