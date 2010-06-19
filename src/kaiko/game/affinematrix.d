module kaiko.game.affinematrix;

template AffineMatrix(Float, int dimension) {

  public Float[dimension][dimension - 1] elements;
  
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
