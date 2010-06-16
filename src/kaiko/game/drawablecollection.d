module kaiko.game.drawablecollection;

import std.algorithm;

final class DrawableCollection(Drawable) {

  private Drawable[] drawables_;

  public this(Drawable[] drawables) {
    this.drawables_ = drawables;
  }

  public void draw(GraphicsContext)(GraphicsContext gc) {
    static if (is(typeof({ Drawable d; int z = d.z; }()))) {
      sort!(q{a.z < b.z})(this.drawables_);
    }
    foreach (drawable; this.drawables_) {
      drawable.draw(gc);
    }
  }

  @property
  public Drawable[] values() {
    return this.drawables_;
  }

  @property
  public const(Drawable)[] values() const {
    return this.drawables_;
  }

}
