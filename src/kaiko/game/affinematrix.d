module kaiko.game.affinematrix;

template AffineMatrix(Float, int dimension) {

  private Float[dimension][dimension - 1] elements_;

  public this(in Float[dimension][dimension - 1] elements) {
    this.elements_ = elements;
  }
  
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
