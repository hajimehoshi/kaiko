module kaiko.game.texture;

import std.conv;
import std.utf;
import std.windows.syserror;
import win32.directx.d3d9;
import win32.directx.d3dx9;
import win32.windows;

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

final class Texture(Device_) {

  alias Device_ Device;

  private Device device_;
  private IDirect3DTexture9 d3dTexture_;
  private immutable int textureWidth_, textureHeight_;
  private immutable int width_, height_;

  invariant() {
    assert(this.device_);
    assert(this.d3dTexture_);
    assert(0 < this.width_);
    assert(this.width_ <= this.textureWidth_);
    assert(0 < this.height_);
    assert(this.height_ <= this.textureHeight_);
  }

  public this(Device device, string path) {
    this.device_ = device;
    auto lowerDevice = device.lowerDevice;
    {
      D3DXIMAGE_INFO imageInfo;
      D3DXGetImageInfoFromFileW(toUTF16z(path), &imageInfo);
      this.width_  = imageInfo.Width;
      this.height_ = imageInfo.Height;
    }
    {
      assert(std.file.exists(path)); // TODO: throw error
      immutable result = D3DXCreateTextureFromFileExW(lowerDevice,
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
  public Device device() {
    return this.device_;
  }

  @property
  public int height() const {
    return this.height_;
  }

  @property
  public IDirect3DTexture9 lowerTexture() {
    return this.d3dTexture_;
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

}
