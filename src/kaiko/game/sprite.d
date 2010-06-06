module kaiko.game.sprite;

import std.conv;
import std.utf;
import std.windows.syserror;
import win32.directx.d3d9;
import win32.directx.d3dx9;
import win32.windows;

// render target の指定
// 

align(4) struct D3DXIMAGE_INFO {
  UINT Width;
  UINT Height;
  UINT Depth;
  UINT MipLevels;
  D3DFORMAT Format;
  D3DRESOURCETYPE ResourceType;
  D3DXIMAGE_FILEFORMAT ImageFileFormat;
}

extern (Windows) {
  HRESULT D3DXGetImageInfoFromFileW(LPCWSTR pSrcFile, D3DXIMAGE_INFO* pSrcInfo);
}

final class Sprite {

  private IDirect3DTexture9 d3dTexture_;
  private int textureWidth_, textureHeight_;
  private int width_, height_;
  private int x_;
  private int y_;

  public this(IDirect3DDevice9 device, string path) {
    {
      D3DXIMAGE_INFO imageInfo;
      D3DXGetImageInfoFromFileW(toUTF16z(path), &imageInfo);
      this.width_  = imageInfo.Width;
      this.height_ = imageInfo.Height;
    }
    {
      assert(std.file.exists(path)); // TODO: throw error
      immutable result = D3DXCreateTextureFromFileExW(device,
                                                      toUTF16z(path),
                                                      this.width_,
                                                      this.height_,
                                                      1,
                                                      0,
                                                      D3DFMT_A8R8G8B8,
                                                      D3DPOOL_DEFAULT,
                                                      D3DX_FILTER_NONE,
                                                      D3DX_DEFAULT,
                                                      0xff,
                                                      null,
                                                      null,
                                                      &this.d3dTexture_);
      if (FAILED(result)) {
        throw new Exception(to!string(result));
      }
    }
    assert(this.d3dTexture_);
    {
      D3DSURFACE_DESC surfaceDesc;
      this.d3dTexture_.GetLevelDesc(0, &surfaceDesc);
      this.textureWidth_ = surfaceDesc.Width;
      this.textureHeight_ = surfaceDesc.Height;
    }
  }

  ~this() {
    if (this.d3dTexture_) {
      this.d3dTexture_.Release();
      this.d3dTexture_ = null;
    }
  }

  @property
  public IDirect3DTexture9 d3dTexture() {
    return this.d3dTexture_;
  }

  @property
  public int height() const {
    return this.height_;
  }

  @property
  public int textureHeight() const {
    return this.textureHeight_;
  }

  @property
  public int textureWidth() const {
    return this.textureWidth_;
  }

  @property
  public int width() const {
    return this.width_;
  }

  @property
  public int x() const {
    return this.x_;
  }

  @property
  public void x(int x) {
    this.x_ = x;
  }

  @property
  public int y() const {
    return this.y_;
  }

  @property
  public void y(int y) {
    this.y_ = y;
  }
  
}
