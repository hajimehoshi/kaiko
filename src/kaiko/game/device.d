module kaiko.game.device;

import std.conv;
import std.utf;
import std.windows.syserror;
import win32.directx.d3d9;
import win32.directx.d3dx9;

private pure nothrow roundUp(int x) {
  immutable x2 = x - 1;
  immutable x3 = x2 | (x2 >> 1);
  immutable x4 = x3 | (x3 >> 2);
  immutable x5 = x4 | (x4 >> 4);
  immutable x6 = x5 | (x5 >> 8);
  immutable x7 = x6 | (x6 >> 16);
  return x6 + 1;
}

unittest {
  static assert(256 == roundUp(255));
  static assert(256 == roundUp(256));
  static assert(512 == roundUp(257));
}

final class Device {

  struct Vertex {
    float x, y, z, rhw;
    float tu, tv;
  }

  private IDirect3D9 direct3D_;
  private IDirect3DDevice9 d3dDevice_;
  private IDirect3DTexture9 d3dOffscreenTexture_;
  private IDirect3DSurface9 d3dOffscreenSurface_;
  private IDirect3DSurface9 d3dBackBufferSurface_;
  private immutable int width_, height_;

  invariant() {
    assert(this.direct3D_);
    assert(this.d3dDevice_);
    assert(this.d3dOffscreenTexture_);
    assert(this.d3dOffscreenSurface_);
    assert(this.d3dBackBufferSurface_);
  }

  public this(HWND hWnd, int width, int height) {
    this.width_ = width;
    this.height_ = height;
    this.direct3D_ = Direct3DCreate9(D3D_SDK_VERSION);
    D3DPRESENT_PARAMETERS presentParameters;
    with (presentParameters) {
      Windowed               = true;
      SwapEffect             = D3DSWAPEFFECT_DISCARD;
      BackBufferCount        = 0;
      AutoDepthStencilFormat = D3DFMT_UNKNOWN;
      MultiSampleType        = D3DMULTISAMPLE_NONE;
      MultiSampleQuality     = 0;
      Flags                  = 0;
    }
    {
      immutable result = this.direct3D_.CreateDevice(D3DADAPTER_DEFAULT,
                                                     D3DDEVTYPE_HAL,
                                                     hWnd,
                                                     D3DCREATE_MIXED_VERTEXPROCESSING,
                                                     &presentParameters,
                                                     &this.d3dDevice_);
      if (FAILED(result)) {
        throw new Exception(to!string(result));
      }
    }
    assert(this.d3dDevice_);
    this.d3dDevice_.SetRenderState(D3DRS_CULLMODE, D3DCULL_NONE);
    this.d3dDevice_.SetRenderState(D3DRS_LIGHTING, false);
    this.d3dDevice_.SetRenderState(D3DRS_LOCALVIEWER, false);
    {
      immutable result = this.d3dDevice_.CreateTexture(roundUp(width_),
                                                       roundUp(height_),
                                                       1,
                                                       D3DUSAGE_RENDERTARGET,
                                                       D3DFMT_A8R8G8B8,
                                                       D3DPOOL_DEFAULT,
                                                       &this.d3dOffscreenTexture_,
                                                       null);
      if (FAILED(result)) {
        throw new Exception(to!string(result));
      }
    }
    assert(this.d3dOffscreenTexture_);
    {
      immutable result = this.d3dOffscreenTexture_.GetSurfaceLevel(0,
                                                                   &this.d3dOffscreenSurface_);
      if (FAILED(result)) {
        throw new Exception(to!string(result));
      }
    }
    assert(this.d3dOffscreenSurface_);
    {
      immutable result = this.d3dDevice_.GetBackBuffer(0,
                                                       0,
                                                       D3DBACKBUFFER_TYPE_MONO,
                                                       &this.d3dBackBufferSurface_);
      if (FAILED(result)) {
        throw new Exception(to!string(result));
      }
    }
    assert(this.d3dBackBufferSurface_);
  }

  ~this() {
    if (this.d3dDevice_) {
      this.d3dDevice_.Release();
      this.d3dDevice_ = null;
    }
    if (this.direct3D_) {
      this.direct3D_.Release();
      this.direct3D_ = null;
    }
  }

  @property
  public IDirect3DDevice9 lowerDevice() {
    return this.d3dDevice_;
  }

  public void update(Drawable)(Drawable[] drawables) in {
    assert(this.d3dDevice_);
  } body {
    this.d3dDevice_.Clear(0, null, D3DCLEAR_TARGET, D3DCOLOR_XRGB(0, 0, 0), 1.0f, 0);
    this.d3dDevice_.SetFVF(D3DFVF_XYZRHW | D3DFVF_TEX1);
    scope (exit) { this.d3dDevice_.Present(null, null, null, null); }
    {
      this.d3dDevice_.BeginScene();
      scope (exit) { this.d3dDevice_.EndScene(); }
      {
        this.d3dDevice_.SetRenderTarget(0, this.d3dOffscreenSurface_);
        scope (exit) { this.d3dDevice_.SetRenderTarget(0, this.d3dBackBufferSurface_); }
        foreach (drawable; drawables) {
          drawable.draw();
        }
      }
      {
        RECT sourceRect = { 0, 0, this.width_, this.height_ };
        RECT destRect   = { 0, 0, this.width_ * 2, this.height_ * 2 };
        this.d3dDevice_.StretchRect(this.d3dOffscreenSurface_,
                                    &sourceRect,
                                    this.d3dBackBufferSurface_,
                                    &destRect,
                                    D3DTEXF_POINT);
      }
    }
  }

}
