module kaiko.game.drawablecollection;

final class DrawableCollection(Drawable) {

  private Drawable[] drawables_;

  public this(Drawable[] drawables) {
    this.drawables_ = drawables;
  }

  public void draw(GraphicsContext)(GraphicsContext gc) {
    static if (is(Drawable == kaiko.game.sprite.Sprite)) {
      gc.drawSprites(this.drawables_);
    } else {
      foreach (drawable; this.drawables_) {
        drawable.draw(gc);
      }
    }
  }

}
