module kaiko.scenes.mainscene;

import kaiko.game.application;
import kaiko.game.drawablecollection;
import kaiko.game.sprite;

final class MainScene {

  public void run(TextureFactory, GameUpdater)(TextureFactory textureFactory, GameUpdater gameUpdater) {
    auto texture = textureFactory.load("d.png");
    auto sprites = new Sprite!(typeof(texture))[2];
    for (int i = 0; i < sprites.length; i++) {
      sprites[i] = new Sprite!(typeof(texture))(texture);
    }

    foreach (i, sprite; sprites) {
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
    auto drawableCollection = new DrawableCollection!(typeof(sprites[0]))(sprites);
    for (;;) {
      gameUpdater.update(drawableCollection);
    }
  }

}
