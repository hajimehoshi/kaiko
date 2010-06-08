module kaiko.game.sprite;

import std.utf;
import std.windows.syserror;
import win32.directx.d3d9;
import win32.directx.d3dx9;
import win32.windows;

final class Sprite(Texture) {

  private Texture texture_;
  private int x_, y_, z_;

  public this(Texture texture) {
    this.texture_ = texture;
  }

  public void draw(GraphicsContext)(GraphicsContext gc) {
    gc.drawTexture(this.texture_, this.x_, this.y_, this.z_);
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

  @property
  public int z() const {
    return this.z_;
  }

  @property
  public void z(int z) {
    this.z_ = z;
  }
  
}
