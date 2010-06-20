module kaiko.game.textrenderer;

import kaiko.game.color;

final class TextRenderer {

  private string text_;
  private int x_, y_;
  private Color color_;

  public this(string text, int x, int y, ref const(Color) color) {
    this.text_ = text;
    this.x_ = x;
    this.y_ = y;
    this.color_ = color;
  }

  public void draw(GraphicsContext)(GraphicsContext gc) {
    gc.drawText(this.text_, this.x_, this.y_, this.color_);
  }

  @property
  public ref Color color() {
    return this.color_;
  }

  @property
  public ref const(Color) color() const {
    return this.color_;
  }

  @property
  public void color(ref const(Color) color) {
    this.color_ = color;
  }

  @property
  public string text() const {
    return this.text_;
  }

  @property
  public void text(string text) {
    this.text_ = text;
  }

  @property
  public int x() const {
    return this.x_;
  }

  @property
  public void x(int x) {
    this.x_ = x;
  }

  @property
  public int y() const {
    return this.y_;
  }

  @property
  public void y(int y) {
    this.y_ = y;
  }

}
