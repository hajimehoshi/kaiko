module kaiko.game.affinematrix;

struct AffineMatrixBase(Float) {
  Float a, b, c, d, tx, ty;
}

alias AffineMatrixBase!double AffineMatrix;
