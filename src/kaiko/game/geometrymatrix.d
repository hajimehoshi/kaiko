module kaiko.game.geometrymatrix;

private import std.traits;
private import kaiko.game.affinematrix;

final class GeometryMatrixBase(Float) if (isFloatingPoint!(Float)) {

  mixin AffineMatrix!(Float, 3);

  @property
  public Float a() const {
    return this.elements_[0][0];
  }

  @property
  public Float a(Float a) {
    return this.elements_[0][0] = a;
  }

  @property
  public Float b() const {
    return this.elements_[0][1];
  }

  @property
  public Float b(Float b) {
    return this.elements_[0][1] = b;
  }

  @property
  public Float c() const {
    return this.elements_[1][0];
  }

  @property
  public Float c(Float c) {
    return this.elements_[1][0] = c;
  }

  @property
  public Float d() const {
    return this.elements_[1][1];
  }

  @property
  public Float d(Float d) {
    return this.elements_[1][1] = d;
  }

  @property
  public Float tx() const {
    return this.elements_[0][2];
  }

  @property
  public Float tx(Float tx) {
    return this.elements_[0][2] = tx;
  }

  @property
  public Float ty() const {
    return this.elements_[1][2];
  }

  @property
  public Float ty(Float ty) {
    return this.elements_[1][2] = ty;
  }

}

alias GeometryMatrixBase!double GeometryMatrix;
