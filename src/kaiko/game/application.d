module kaiko.game.application;

import std.windows.syserror;
import win32.windows;
import kaiko.game.sprite;

final class Application {

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

  public static int run(Renderer)(HWND hWnd, Renderer renderer) in {
    assert(hWnd);
  } body {
    ShowWindow(hWnd, typeof(this).cmdShow);
    if (!UpdateWindow(hWnd)) {
      throw new Exception(sysErrorString(GetLastError()));
    }
    MSG msg;
    Sprite[] sprites = [new Sprite(renderer.d3dDevice, "d.png")];
    while (msg.message != WM_QUIT) {
      if (PeekMessage(&msg, null, 0, 0, PM_REMOVE)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
      } else {
        Sleep(1);
        renderer.render(sprites);
      }
    }
    return cast(int)msg.wParam;
  }

}
