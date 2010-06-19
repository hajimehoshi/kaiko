module kaiko.game.geometrymatrix;

private import std.traits;

struct GeometryMatrixBase(Float) if (isFloatingPoint!(Float)) {

  public Float[3][2] elements;

  @property
  public Float a() const {
    return this.elements[0][0];
  }

  @property
  public void a(Float a) {
    this.elements[0][0] = a;
  }

  @property
  public Float b() const {
    return this.elements[0][1];
  }

  @property
  public void b(Float b) {
    this.elements[0][1] = b;
  }

  @property
  public Float c() const {
    return this.elements[1][0];
  }

  @property
  public void c(Float c) {
    this.elements[1][0] = c;
  }

  @property
  public Float d() const {
    return this.elements[1][1];
  }

  @property
  public void d(Float d) {
    this.elements[1][1] = d;
  }

  @property
  public Float tx() const {
    return this.elements[0][2];
  }

  @property
  public void tx(Float tx) {
    this.elements[0][2] = tx;
  }

  @property
  public Float ty() const {
    return this.elements[1][2];
  }

  @property
  public void ty(Float ty) {
    this.elements[1][2] = ty;
  }

}

alias GeometryMatrixBase!double GeometryMatrix;
