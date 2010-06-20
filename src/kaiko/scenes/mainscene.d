module kaiko.scenes.mainscene;

private import std.algorithm;
private import kaiko.game.application;
private import kaiko.game.color;
private import kaiko.game.sprite;
private import kaiko.game.textrenderer;

final class MainScene(TextureFactory) {

  private class Renderer {

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
    public auto ref sprites() {
      return this.sprites_;
    }

    @property
    public auto ref textRenderers() {
      return this.textRenderers_;
    }

  }

  private Renderer renderer_;

  public this(TextureFactory textureFactory) in {
    assert(textureFactory !is null);
  } body {
    this.renderer_ = new Renderer();
    auto texture = textureFactory.load("d.png");
    this.renderer_.sprites.length = 2;
    for (int i = 0; i < this.renderer_.sprites.length; i++) {
      this.renderer_.sprites[i] = new Sprite!(typeof(texture))(texture);
    }
    this.renderer_.textRenderers.length = 1;
    this.renderer_.textRenderers[0] = new TextRenderer("hoge", 10, 10, Color(0xff, 0xff, 0x99, 0x99));
  }

  public void run(Yielder)(Yielder yield) in {
    assert(yield !is null);
  } body {
    foreach (i, sprite; this.renderer_.sprites) {
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
    }
    for (;;) {
      auto geometryMatrix = this.renderer_.sprites[0].geometryMatrix;
      geometryMatrix.tx = geometryMatrix.tx + 0.05;
      yield(this.renderer_);
    }
  }

}
