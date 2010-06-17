module kaiko.scenes.mainscene;

private import kaiko.game.application;
private import kaiko.game.drawablecollection;
private import kaiko.game.sprite;

final class MainScene(TextureFactory) {

  alias DrawableCollection!(Sprite!(TextureFactory.Texture)) Drawable;

  private Sprite!(TextureFactory.Texture)[] sprites_;

  public this(TextureFactory textureFactory) in {
    assert(textureFactory !is null);
  } body {
    auto texture = textureFactory.load("d.png");
    this.sprites_ = new Sprite!(typeof(texture))[2];
    for (int i = 0; i < this.sprites_.length; i++) {
      this.sprites_[i] = new Sprite!(typeof(texture))(texture);
    }
  }

  public void run(Yielder)(Yielder yield) in {
    assert(yield !is null);
  } body {
    foreach (i, sprite; this.sprites_) {
      //sprite.affineMatrix.tx = i * 0.1;
      //sprite.affineMatrix.ty = i * 0.1;
      sprite.z = i;
      auto colorMatrix = sprite.colorMatrix;
      if (i == 1) {
        foreach (j; 0..3) {
          colorMatrix[j, 0] = 0.2989;
          colorMatrix[j, 1] = 0.5866;
          colorMatrix[j, 2] = 0.1145;
          colorMatrix[j, 3] = 0;
        }
        colorMatrix[3, 0] = 0;
        colorMatrix[3, 1] = 0;
        colorMatrix[3, 2] = 0;
        colorMatrix[3, 3] = 0.5;
      } else {
        colorMatrix[0, 4] = 0.5;
        colorMatrix[3, 3] = 1;
      }
      sprite.colorMatrix = colorMatrix;
    }
    auto drawable = new Drawable(this.sprites_);
    for (;;) {
      auto a = this.sprites_[0].affineMatrix;
      a.tx += 0.05;
      this.sprites_[0].affineMatrix = a;
      yield(drawable);
    }
  }

}
