module kaiko.game.colormatrix;

private import std.traits;

struct ColorMatrixBase(Float) if (isFloatingPoint!(Float)) {

  public this(in Float[5][4] elements) {
    this.elements_ = elements.dup;
  }

  private Float[5][4] elements_;

  public Float opIndex(int i, int j) const in {
    assert(0 <= i);
    assert(i < this.elements_.length);
    assert(0 <= j);
    assert(j < this.elements_[i].length);
  } body {
    return this.elements_[i][j];
  }

  public void opIndexAssign(Float value, int i, int j) in {
    assert(0 <= i);
    assert(i < this.elements_.length);
    assert(0 <= j);
    assert(j < this.elements_[i].length);
  } body {
    this.elements_[i][j] = value;
  }

}

alias ColorMatrixBase!double ColorMatrix;
