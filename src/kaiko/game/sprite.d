module kaiko.game.sprite;

private import kaiko.game.affinematrix;
private import kaiko.game.colormatrix;

final class Sprite(Texture) {

  private Texture texture_;
  private AffineMatrix affineMatrix_;
  private int z_;
  private ColorMatrix colorMatrix_;

  invariant() {
    assert(this.texture_ !is null);
    assert(this.affineMatrix_ !is null);
    assert(this.colorMatrix_ !is null);
  }

  public this(Texture texture) {
    this.texture_ = texture;
    this.affineMatrix_ = new AffineMatrix(1, 0, 0, 1, 0, 0);
    this.colorMatrix_ = new ColorMatrix();

    this.colorMatrix_[0, 0] = 1;
    this.colorMatrix_[0, 1] = 0;
    this.colorMatrix_[0, 2] = 0;
    this.colorMatrix_[0, 3] = 0;
    this.colorMatrix_[0, 4] = 0;

    this.colorMatrix_[1, 0] = 0;
    this.colorMatrix_[1, 1] = 0;
    this.colorMatrix_[1, 2] = 1;
    this.colorMatrix_[1, 3] = 0;
    this.colorMatrix_[1, 4] = 0;

    this.colorMatrix_[2, 0] = 0;
    this.colorMatrix_[2, 1] = 0;
    this.colorMatrix_[2, 2] = 1;
    this.colorMatrix_[2, 3] = 0;
    this.colorMatrix_[2, 4] = 0;
    
    this.colorMatrix_[3, 0] = 0;
    this.colorMatrix_[3, 1] = 0;
    this.colorMatrix_[3, 2] = 0;
    this.colorMatrix_[3, 3] = 1;
    this.colorMatrix_[3, 4] = 0;
  }

  public void draw(GraphicsContext)(GraphicsContext gc) {
    gc.drawTexture(this.texture, this.affineMatrix, this.z, this.colorMatrix);
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
  public ColorMatrix colorMatrix() {
    return this.colorMatrix_;
  }

  @property
  public const(ColorMatrix) colorMatrix() const {
    return this.colorMatrix_;
  }

  @property
  public Texture texture() {
    return this.texture_;
  }

  @property
  public const(Texture) texture() const {
    return this.texture_;
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
