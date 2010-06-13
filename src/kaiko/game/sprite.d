module kaiko.game.sprite;

import kaiko.game.affinematrix;
import kaiko.game.colormatrix;;

final class Sprite(Texture) {

  private Texture texture_;
  private AffineMatrix affineMatrix_;
  private int z_;
  private ColorMatrix colorMatrix_;
  private ubyte alpha_ = 255;

  invariant() {
    assert(this.texture_);
    assert(this.affineMatrix_);
    assert(this.colorMatrix_);
  }

  public this(Texture texture) {
    this.texture_ = texture;
    this.affineMatrix_ = new AffineMatrix(1, 0, 0, 1, 0, 0);
    this.colorMatrix_ = new ColorMatrix();

    this.colorMatrix_[0, 0] = 1;
    this.colorMatrix_[0, 1] = 0;
    this.colorMatrix_[0, 2] = 0;
    this.colorMatrix_[0, 3] = 0;

    this.colorMatrix_[1, 0] = 0;
    this.colorMatrix_[1, 1] = 0;
    this.colorMatrix_[1, 2] = 1;
    this.colorMatrix_[1, 3] = 0;

    this.colorMatrix_[2, 0] = 0;
    this.colorMatrix_[2, 1] = 0;
    this.colorMatrix_[2, 2] = 1;
    this.colorMatrix_[2, 3] = 0;
    
    this.colorMatrix_[3, 0] = 0;
    this.colorMatrix_[3, 1] = 0;
    this.colorMatrix_[3, 2] = 0;
    this.colorMatrix_[3, 3] = 1;
  }

  public void draw(GraphicsContext)(GraphicsContext gc) {
    gc.drawTexture(this.texture_, this.affineMatrix_, this.z_, this.colorMatrix_, this.alpha_);
  }

  @property
  public AffineMatrix affineMatrix() {
    return this.affineMatrix_;
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
  public ColorMatrix colorMatrix() {
    return this.colorMatrix_;
  }

  @property
  public const(ColorMatrix) colorMatrix() const {
    return this.colorMatrix_;
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
