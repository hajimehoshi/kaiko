module kaiko.game.colormatrix;

private import std.traits;

struct ColorMatrixBase(Float) if (isFloatingPoint!(Float)) {

  // TODO: mixin AffineMatrix!(5, Float)

  public Float[5][4] elements;

  public Float opIndex(int i, int j) const in {
    assert(0 <= i);
    assert(i < this.elements.length);
    assert(0 <= j);
    assert(j < this.elements[i].length);
  } body {
    return this.elements[i][j];
  }

  public void opIndexAssign(Float value, int i, int j) in {
    assert(0 <= i);
    assert(i < this.elements.length);
    assert(0 <= j);
    assert(j < this.elements[i].length);
  } body {
    this.elements[i][j] = value;
  }

}

alias ColorMatrixBase!double ColorMatrix;
