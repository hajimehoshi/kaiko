module kaiko.game.affinematrix;

private import std.traits;

struct AffineMatrixBase(Float) if (isFloatingPoint!(Float)) {

  public Float a, b, c, d, tx, ty;

  public this(Float a, Float b, Float c, Float d, Float tx, Float ty) {
    this.a = a;
    this.b = b;
    this.c = c;
    this.d = d;
    this.tx = tx;
    this.ty = ty;
  }
}

alias AffineMatrixBase!double AffineMatrix;
