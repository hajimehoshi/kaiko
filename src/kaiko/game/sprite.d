module kaiko.game.sprite;

import kaiko.game.affinematrix;

final class Sprite(Texture) {

  private Texture texture_;
  private ubyte alpha_;
  private int x_, y_, z_;

  public this(Texture texture) {
    this.texture_ = texture;
  }

  public void draw(GraphicsContext)(GraphicsContext gc) {
    AffineMatrix affineMatrix;
    with (affineMatrix) {
      a = 1;
      b = 0;
      c = 0;
      d = 1;
      tx = this.x_;
      ty = this.y_;
    };
    gc.drawTexture(this.texture_, affineMatrix, this.z_, this.alpha_);
  }

  @property
  public ubyte alpha() const {
    return this.alpha_;
  }

  @property
  public void alpha(ubyte alpha) {
    this.alpha_ = alpha;
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
