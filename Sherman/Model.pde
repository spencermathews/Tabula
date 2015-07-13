import heronarts.lx.model.LXModel;

public static class Model extends LXModel {

  public final static int INCHES = 1;
  public final static int FEET = 12 * INCHES;

  public final static int NUM_FINS = 68;

  public final static int NUM_FINS_LEFT_WALL = 45;
  public final static int NUM_FINS_RIGHT_WALL = 23;

  // public final static int NUM_STRIPS_PER_FIN = 2;
  public final static int NUM_LEDS_PER_STRIP = 300;
  public final static int NUM_LEDS_PER_FIN = NUM_LEDS_PER_STRIP;
  public final static int NUM_LEDS = NUM_FINS * NUM_LEDS_PER_FIN;

  public final static float DISTANCE_BETWEEN_FINS = 2 * FEET;
  public final static float DISTANCE_BETWEEN_LEDS = .66 * INCHES;

  public final static int NUM_LEDS_X = NUM_FINS_LEFT_WALL + NUM_FINS_RIGHT_WALL;
  public final static int NUM_LEDS_Y = NUM_LEDS_PER_STRIP;
  public final static float XY_DISTANCE_RATIO = DISTANCE_BETWEEN_FINS / DISTANCE_BETWEEN_LEDS;

  public final static float RECT_THETA_MAX = NUM_FINS_LEFT_WALL + NUM_FINS_RIGHT_WALL;


  public final List<LED> leds;

  public Model() {
    super(new Fixture());

    Fixture f = (Fixture)this.fixtures.get(0);
    this.leds = Collections.unmodifiableList(f.leds);
  }

  private static class Fixture extends LXAbstractFixture {

    final List<LED> leds = new ArrayList<LED>(NUM_LEDS);

    private Fixture() {
      for (int i = 0; i < NUM_FINS_LEFT_WALL; i++) {
        for (int j = 0; j < NUM_LEDS_PER_FIN; j++) {
          float x = (i - NUM_FINS_LEFT_WALL / 2) * DISTANCE_BETWEEN_FINS;
          float y = (NUM_LEDS_PER_FIN - j - 1) * DISTANCE_BETWEEN_LEDS;
          float z = (-1 - NUM_FINS_RIGHT_WALL / 2) * DISTANCE_BETWEEN_FINS;
          float rectTheta = i;

          LED led = new LED(x, y, z, rectTheta, NUM_LEDS_PER_FIN - j - 1);
          leds.add(led);
          for (LXPoint p : led.points) {
            points.add(p);
          }
        }
      }

      for (int i = 0; i < NUM_FINS_RIGHT_WALL; i++) {
        for (int j = 0; j < NUM_LEDS_PER_FIN; j++) {
          float x = (1 + NUM_FINS_LEFT_WALL / 2) * DISTANCE_BETWEEN_FINS;
          float y = (NUM_LEDS_PER_FIN - j - 1) * DISTANCE_BETWEEN_LEDS;
          float z = (i - NUM_FINS_RIGHT_WALL / 2) * DISTANCE_BETWEEN_FINS;
          float rectTheta = NUM_FINS_LEFT_WALL + i;

          LED led = new LED(x, y, z, rectTheta, NUM_LEDS_PER_FIN - j - 1);
          leds.add(led);
          for (LXPoint p : led.points) {
            points.add(p);
          }
        }
      }
    }
  }
}

public static class LED extends LXModel {

  public final int index;

  public final float x;
  public final float y;
  public final float z;

  public final float rectTheta;
  public final int rawY;

  public LED(float x, float y, float z, float rectTheta, int rawY) {
    super(Arrays.asList(new LXPoint[] { new LXPoint(x, y, z) }));

    this.index = this.points.get(0).index;

    this.x = x;
    this.y = y;
    this.z = z;
    this.rectTheta = rectTheta;
    this.rawY = rawY;
  }
}

public class Earthquake {

  public final double longitude;
  public final double latitude;
  public final float magnitude;

  public final float rectTheta;
  public final float rawY;

  Earthquake(double longitude, double latitude, float magnitude) {
    this.longitude = longitude;
    this.latitude = latitude;
    this.magnitude = magnitude;

    rectTheta = map((float)longitude, -180, 180, 0, Model.RECT_THETA_MAX);
    rawY = map((float)latitude, -90, 90, 0, Model.NUM_LEDS_PER_STRIP);
  }
}
