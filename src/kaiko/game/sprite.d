module kaiko.game.sprite;

private import kaiko.game.colormatrix;
private import kaiko.game.geometrymatrix;

final class Sprite(Texture) {

  private Texture texture_;
  private GeometryMatrix geometryMatrix_;
  private int z_;
  private ColorMatrix colorMatrix_;

  invariant() {
    assert(this.texture_ !is null);
  }

  public this(Texture texture) {
    this.texture_ = texture;
    this.geometryMatrix_ = GeometryMatrix([[1, 0, 0],
                                       [0, 1, 0]]);
    this.colorMatrix_ = ColorMatrix([[1, 0, 0, 0, 0],
                                     [0, 1, 0, 0, 0],
                                     [0, 0, 1, 0, 0],
                                     [0, 0, 0, 1, 0]]);
  }

  public void draw(GraphicsContext)(GraphicsContext gc) {
    gc.drawTexture(this.texture_, this.geometryMatrix_, this.z_, this.colorMatrix_);
  }

  @property
  public GeometryMatrix geometryMatrix() const {
    return this.geometryMatrix_;
  }

  @property
  public GeometryMatrix geometryMatrix(ref const(GeometryMatrix) geometryMatrix) {
    return this.geometryMatrix_ = geometryMatrix;
  }

  @property
  public ColorMatrix colorMatrix() const {
    return this.colorMatrix_;
  }

  @property
  public ColorMatrix colorMatrix(ref const(ColorMatrix) colorMatrix) {
    return this.colorMatrix_ = colorMatrix;
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
