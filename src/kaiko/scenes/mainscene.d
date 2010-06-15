module kaiko.scenes.mainscene;

import kaiko.game.application;
import kaiko.game.drawablecollection;
import kaiko.game.sprite;

final class MainScene(TextureFactory) {

  alias DrawableCollection!(Sprite!(TextureFactory.Texture)) Drawable;

  private Drawable drawable_;

  public this(TextureFactory textureFactory) {
    auto texture = textureFactory.load("d.png");
    auto sprites = new Sprite!(typeof(texture))[2];
    for (int i = 0; i < sprites.length; i++) {
      sprites[i] = new Sprite!(typeof(texture))(texture);
    }
    this.drawable_ = new Drawable(sprites);
  }

  @property
  public Drawable drawable() {
    return this.drawable_;
  }

  public void run() {
    foreach (i, sprite; this.drawable_.values) {
      sprite.affineMatrix.tx = i * 50;
      sprite.affineMatrix.ty = i * 50;
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
    }
    for (;;) {
      core.thread.Fiber.yield();
    }
  }

}
