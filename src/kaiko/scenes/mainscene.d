module kaiko.scenes.mainscene;

private import std.algorithm;
private import kaiko.game.application;
private import kaiko.game.color;
private import kaiko.game.sprite;
private import kaiko.game.textrenderer;

final class MainScene(TextureFactory) {

  private class Drawable {

    private Sprite!(TextureFactory.Texture)[] sprites_;
    private TextRenderer[] textRenderers_;

    public void draw(GraphicsContext)(GraphicsContext gc) {
      sort!(q{a.z < b.z})(this.sprites_);
      foreach (sprite; this.sprites_) {
        sprite.draw(gc);
      }
      foreach (textRenderer; this.textRenderers_) {
        textRenderer.draw(gc);
      }
    }

    @property
    public ref typeof(sprites_) sprites() {
      return this.sprites_;
    }

    @property
    public ref TextRenderer[] textRenderers() {
      return this.textRenderers_;
    }
    
  }

  private Drawable drawable_;

  public this(TextureFactory textureFactory) in {
    assert(textureFactory !is null);
  } body {
    this.drawable_ = new Drawable();
    auto texture = textureFactory.load("d.png");
    this.drawable_.sprites.length = 2;
    for (int i = 0; i < this.drawable_.sprites.length; i++) {
      this.drawable_.sprites[i] = new Sprite!(typeof(texture))(texture);
    }
    this.drawable_.textRenderers.length = 1;
    this.drawable_.textRenderers[0] = new TextRenderer("hoge", 10, 10, Color(0xff, 0xff, 0x99, 0x99));
  }

  public void run(Yielder)(Yielder yield) in {
    assert(yield !is null);
  } body {
    foreach (i, sprite; this.drawable_.sprites) {
      //sprite.geometryMatrix.tx = i * 0.1;
      //sprite.geometryMatrix.ty = i * 0.1;
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
    for (;;) {
      auto a = this.drawable_.sprites[0].geometryMatrix;
      a.tx = a.tx + 0.05;
      this.drawable_.sprites[0].geometryMatrix = a;
      yield(this.drawable_);
    }
  }

}
