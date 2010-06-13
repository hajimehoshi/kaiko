module kaiko.game.application;

import std.random;
import std.windows.syserror;
import win32.windows;
import kaiko.game.drawablecollection;
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
    auto texture = new Texture(device, "d.png");
    auto sprites = new Sprite!(typeof(texture))[2];
    for (int i = 0; i < sprites.length; i++) {
      sprites[i] = new Sprite!(typeof(texture))(texture);
    }
    auto drawableCollection = new DrawableCollection!(typeof(sprites[0]))(sprites);

    while (msg.message != WM_QUIT) {
      if (PeekMessage(&msg, null, 0, 0, PM_REMOVE)) {
        TranslateMessage(&msg);
        DispatchMessage(&msg);
      } else {
        Sleep(1);
        foreach (i, sprite; sprites) {
          sprite.affineMatrix.tx = i * 50;
          sprite.affineMatrix.ty = i * 50;
          sprite.z = i;
          auto colorMatrix = sprite.colorMatrix;
          if (i == 1) {
            foreach (j; 0..3) {
              colorMatrix[j, 0] = 0.2989;
              colorMatrix[j, 1] = 0.5866;
              colorMatrix[j, 2] = 0.1145;
              colorMatrix[j, 3] = 0;
            }
            colorMatrix[3, 0] = 0;
            colorMatrix[3, 1] = 0;
            colorMatrix[3, 2] = 0;
            colorMatrix[3, 3] = 0.5;
          } else {
            colorMatrix[0, 4] = 0.5;
            colorMatrix[3, 3] = 1;
          }
        }
        device.update(drawableCollection);
      }
    }
    return cast(int)msg.wParam;
  }

}
