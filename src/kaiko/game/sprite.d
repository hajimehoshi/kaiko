module kaiko.game.sprite;

import kaiko.game.affinematrix;

final class Sprite(Texture) {

  private Texture texture_;
  private AffineMatrix affineMatrix_;
  private int z_;
  private ubyte alpha_;

  invariant() {
    assert(this.texture_);
    assert(this.affineMatrix_);
  }

  public this(Texture texture) {
    this.texture_ = texture;
    this.affineMatrix_ = new AffineMatrix(1, 0, 0, 1, 0, 0);
  }

  public void draw(GraphicsContext)(GraphicsContext gc) {
    gc.drawTexture(this.texture_, affineMatrix, this.z_, this.alpha_);
  }

  @property
  public const(AffineMatrix) affineMatrix() const {
    return this.affineMatrix_;
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
    return cast(int)this.affineMatrix_.tx;
  }

  @property
  public void x(int x) {
    this.affineMatrix_.tx = x;
  }

  @property
  public int y() const {
    return cast(int)this.affineMatrix_.ty;
  }

  @property
  public void y(int y) {
    this.affineMatrix_.ty = y;
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
