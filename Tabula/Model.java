import java.awt.geom.Point2D;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import com.google.gson.JsonObject;

import heronarts.lx.LX;
import heronarts.lx.LXLayer;
import heronarts.lx.LXLoopTask;
import heronarts.lx.model.LXAbstractFixture;
import heronarts.lx.model.LXModel;
import heronarts.lx.model.LXPoint;
import heronarts.lx.transform.LXTransform;

import toxi.geom.Vec2D;
import toxi.geom.Vec3D;

class Geometry {

  final static int INCHES = 1;
  final static int FEET = 12 * INCHES;

  /**
   * Height of the trees.
   */
  public final static float HEIGHT = 570;

}

class Model extends LXModel {

  public final static int INCHES = 1;
  public final static int FEET = 12 * INCHES;

  public final static int NUM_FINS = 68;

  public final static int NUM_FINS_LEFT_WALL = 45;
  public final static int NUM_FINS_RIGHT_WALL = 23;

  // public final static int NUM_STRIPS_PER_FIN = 2;
  public final static int NUM_LEDS_PER_STRIP = 300;
  public final static int NUM_LEDS_PER_FIN = NUM_LEDS_PER_STRIP;
  public final static int NUM_LEDS = NUM_FINS * NUM_LEDS_PER_FIN;

  public final static float LED_START_Y = 180; // Mimic the Trees
  public final static float DISTANCE_BETWEEN_FINS = 2 * FEET;
  public final static float DISTANCE_BETWEEN_LEDS = 2 * 0.66f * INCHES;

  public final static int NUM_LEDS_X = NUM_FINS_LEFT_WALL + NUM_FINS_RIGHT_WALL;
  public final static int NUM_LEDS_Y = NUM_LEDS_PER_STRIP;
  public final static float XY_DISTANCE_RATIO = DISTANCE_BETWEEN_FINS / DISTANCE_BETWEEN_LEDS;

  public final static float RECT_THETA_MAX = NUM_FINS_LEFT_WALL + NUM_FINS_RIGHT_WALL;


  public final List<LED> leds;

  private final ArrayList<ModelTransform> modelTransforms = new ArrayList<ModelTransform>();

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
          float y = (NUM_LEDS_PER_FIN - j - 1) * DISTANCE_BETWEEN_LEDS + LED_START_Y;
          float z = (-1 - NUM_FINS_RIGHT_WALL / 2) * DISTANCE_BETWEEN_FINS;
          float rectTheta = i;
          float rectThetaNormalized = rectTheta / (2 * (NUM_FINS_RIGHT_WALL + NUM_FINS_LEFT_WALL)) * 360;

          LED led = new LED(x, y, z, rectTheta, rectThetaNormalized, NUM_LEDS_PER_FIN - j - 1);
          leds.add(led);
          for (LXPoint p : led.points) {
            points.add(p);
          }
        }
      }

      for (int i = 0; i < NUM_FINS_RIGHT_WALL; i++) {
        for (int j = 0; j < NUM_LEDS_PER_FIN; j++) {
          float x = (1 + NUM_FINS_LEFT_WALL / 2) * DISTANCE_BETWEEN_FINS;
          float y = (NUM_LEDS_PER_FIN - j - 1) * DISTANCE_BETWEEN_LEDS + LED_START_Y;
          float z = (i - NUM_FINS_RIGHT_WALL / 2) * DISTANCE_BETWEEN_FINS;
          float rectTheta = NUM_FINS_LEFT_WALL + i;
          float rectThetaNormalized = rectTheta / (2 * (NUM_FINS_RIGHT_WALL + NUM_FINS_LEFT_WALL)) * 360;

          LED led = new LED(x, y, z, rectTheta, rectThetaNormalized, NUM_LEDS_PER_FIN - j - 1);
          leds.add(led);
          for (LXPoint p : led.points) {
            points.add(p);
          }
        }
      }
    }
  }

  public void addModelTransform(ModelTransform modelTransform) {
    modelTransforms.add(modelTransform);
  }

  public void runTransforms() {
    for (LED led : leds) {
      led.resetTransform();
    }
    for (ModelTransform modelTransform : modelTransforms) {
      if (modelTransform.isEnabled()) {
        modelTransform.transform(this);
      }
    }
    for (LED led : leds) {
      led.didTransform();
    }
  }
}

class LED extends LXModel {

  public final int index;

  public final float x;
  public final float y;
  public final float z;

  public final float rectTheta;
  public final float rectThetaNormalized;
  public final int rawY;

  public float transformedY;
  public float transformedRectTheta;
  public float transformedTheta;
  public Vec2D transformedCylinderPoint;

  public LED(float x, float y, float z, float rectTheta, float rectThetaNormalized, int rawY) {
    super(Arrays.asList(new LXPoint[] { new LXPoint(x, y, z) }));

    this.index = this.points.get(0).index;

    this.x = x;
    this.y = y;
    this.z = z;
    this.rectTheta = rectTheta;
    this.rectThetaNormalized = rectThetaNormalized;
    this.rawY = rawY;
  }

  void resetTransform() {
    transformedRectTheta = rectTheta;
    transformedTheta = rectThetaNormalized;
    transformedY = y;
  }

  void didTransform() {
    transformedCylinderPoint = new Vec2D(transformedTheta, transformedY);
  }
}

class Earthquake {

  public final double longitude;
  public final double latitude;
  public final float magnitude;

  public final float rectTheta;
  public final float rawY;

  Earthquake(double longitude, double latitude, float magnitude) {
    this.longitude = longitude;
    this.latitude = latitude;
    this.magnitude = magnitude;

    rectTheta = Utils.map((float)longitude, -180, 180, 0, Model.RECT_THETA_MAX);
    rawY = Utils.map((float)latitude, -90, 90, 0, Model.NUM_LEDS_PER_STRIP);
  }
}

abstract class Layer extends LXLayer {

  protected final Model model;

  Layer(LX lx) {
    super(lx);
    model = (Model)lx.model;
  }
}

abstract class ModelTransform extends Effect {
  ModelTransform(LX lx) {
    super(lx);

    model.addModelTransform(this);
  }

  public void run(double deltaMs) {}

  abstract void transform(Model model);
}

class ModelTransformTask implements LXLoopTask {

  protected final Model model;

  ModelTransformTask(Model model) {
    this.model = model;
  }

  public void loop(double deltaMs) {
    model.runTransforms();
  }
}
