module kaiko.game.colormatrix;

private import std.traits;
private import kaiko.game.affinematrix;

final class ColorMatrixBase(Float) if (isFloatingPoint!(Float)) {

  mixin AffineMatrix!(Float, 5);

}

alias ColorMatrixBase!double ColorMatrix;
