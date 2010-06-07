module kaiko.game.sprite;

import std.utf;
import std.windows.syserror;
import win32.directx.d3d9;
import win32.directx.d3dx9;
import win32.windows;

final class Sprite(Texture) {

  private Texture texture_;
  private int x_, y_;

  public this(Texture texture) {
    this.texture_ = texture;
  }

  public void draw() {
    // TODO: move to GC
    auto lowerDevice = this.texture_.device.lowerDevice;
    lowerDevice.Clear(0, null, D3DCLEAR_TARGET | D3DCLEAR_ZBUFFER, D3DCOLOR_XRGB(0, 0, 0), 1.0f, 0);
    immutable x      = this.x;
    immutable y      = this.y;
    immutable width  = this.texture_.width;
    immutable height = this.texture_.height;
    immutable tu     = cast(float)this.texture_.width  / this.texture_.textureWidth;
    immutable tv     = cast(float)this.texture_.height / this.texture_.textureHeight;
    Texture.Device.Vertex[4] vertices = [{ x,         y,          0, 1, 0,  0,  },
                                         { x + width, y,          0, 1, tu, 0,  },
                                         { x,         y + height, 0, 1, 0,  tv, },
                                         { x + width, y + height, 0, 1, tu, tv, }];
    lowerDevice.SetTexture(0, this.texture_.lowerTexture);
    lowerDevice.DrawPrimitiveUP(D3DPT_TRIANGLESTRIP, 2, vertices.ptr, typeof(vertices[0]).sizeof);
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
