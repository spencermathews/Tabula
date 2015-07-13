public abstract class Pattern extends LXPattern {

  protected final Model model;

  Pattern(LX lx) {
    super(lx);
    model = (Model)lx.model;
  }
}