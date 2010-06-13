module kaiko.game.texture;

import std.utf;
import std.windows.syserror;
import win32.directx.d3d9;
import win32.directx.d3dx9;
import win32.windows;

final class Texture {

  private IDirect3DTexture9 d3dTexture_;
  private immutable int textureWidth_, textureHeight_;
  private immutable int width_, height_;

  invariant() {
    assert(this.d3dTexture_);
    assert(0 < this.width_);
    assert(this.width_ <= this.textureWidth_);
    assert(0 < this.height_);
    assert(this.height_ <= this.textureHeight_);
  }

  public this(IDirect3DTexture9 d3dTexture, int width, int height) in {
    assert(d3dTexture);
    assert(0 < width);
    assert(0 < height);
  } body {
    this.d3dTexture_ = d3dTexture;
    this.width_ = width;
    this.height_ = height;
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
  public int height() const {
    return this.height_;
  }

  @property
  public IDirect3DTexture9 lowerTexture() {
    return this.d3dTexture_;
  }

  @property
  public const(IDirect3DTexture9) lowerTexture() const {
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
