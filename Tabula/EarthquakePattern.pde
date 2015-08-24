public abstract class WorldMap {

  static final int IMAGE_WIDTH = 600;
  static final int IMAGE_HEIGHT = 300;

  protected final LX lx;

  protected PImage originalImage;
  protected PImage mapImage;

  WorldMap(LX lx) {
    this.lx = lx;
  }

  int getColorAtPixel(float rectTheta, float y) {
    int pixelColor = LXColor.BLACK;

    if (mapImage != null) {
      int mapX = (int)map(rectTheta, 0, Model.RECT_THETA_MAX, 0, mapImage.width) % mapImage.width;
      int mapY = (int)(mapImage.height - y - 1);
      pixelColor = mapImage.get(mapX, mapY);
    }

    return pixelColor;
  }

  void setImage(PImage image) {
    originalImage = image;
    mapImage = originalImage.get();
  }

  void setBlur(int amount) {
    mapImage = originalImage.get();
    mapImage.filter(BLUR, amount);
  }
}

public class BlueMarbleWorldMap extends WorldMap {
  BlueMarbleWorldMap(LX lx) {
    super(lx);
    WMSConnection wmsConnection = new WMSConnection();
    setImage(wmsConnection.getBlueMarbleImage(IMAGE_WIDTH, IMAGE_HEIGHT));
  }
}

public class ImageWorldMap extends WorldMap {
  ImageWorldMap(LX lx, int index) {
    super(lx);
    setImage(loadImage("map" + index + ".png"));
  }
}

static final int NUM_MAPS = 16;
static final WorldMap[] worldMaps = new WorldMap[NUM_MAPS];

public class WorldMapPattern extends TSPattern {

  private final DiscreteParameter mapIndex = new DiscreteParameter("#", 0, 0, NUM_MAPS);
  private final DiscreteParameter blur = new DiscreteParameter("BLUR", 0, 0, 10);

  WorldMapPattern(LX lx) {
    super(lx);

    addParameter(mapIndex);
    addParameter(blur);

    if (worldMaps[0] == null) {
      worldMaps[0] = new BlueMarbleWorldMap(lx);

      for (int i = 1; i < NUM_MAPS; i++) {
        worldMaps[i] = new ImageWorldMap(lx, i);
      }
    }

    blur.addListener(new LXParameterListener() {
      void onParameterChanged(LXParameter parameter) {
        worldMaps[mapIndex.getValuei()].setBlur(blur.getValuei());
      }
    });
    mapIndex.addListener(new LXParameterListener() {
      void onParameterChanged(LXParameter parameter) {
        worldMaps[mapIndex.getValuei()].setBlur(blur.getValuei());
      }
    });
  }

  void run(double deltaMs) {
    WorldMap worldMap = worldMaps[mapIndex.getValuei()];
    if (worldMap != null) {
      for (LED led : model.leds) {
        setColor(led.index, worldMap.getColorAtPixel(led.transformedRectTheta, led.rawY));
      }
    }
  }
}

static List<Earthquake> earthquakes;

public class EarthquakeVisualizerPattern extends TSPattern {

  private final int NUM_VISUALIZERS = 3;
  private final EarthquakeVisualizerPattern.EarthquakeVisualizer[] earthquakeVisualizers = new EarthquakeVisualizerPattern.EarthquakeVisualizer[NUM_VISUALIZERS];

  private final DiscreteParameter visualizerIndex = new DiscreteParameter("#", 1, 0, NUM_VISUALIZERS);

  private final BasicParameter visualizerPeriod = new BasicParameter("TIME", 2000, 100, 5000);
  private final BasicParameter hue = new BasicParameter("HUE", 135, 0, 360);
  private final DiscreteParameter blur = new DiscreteParameter("BLUR", 0, 0, 10);

  EarthquakeVisualizerPattern(LX lx) {
    super(lx);

    addParameter(visualizerIndex);
    addParameter(hue);
    addParameter(visualizerPeriod);
    addParameter(blur);

    if (earthquakes == null) {
      WMSConnection wmsConnection = new WMSConnection();
      earthquakes = wmsConnection.getEarthquakes();
    }
    if (earthquakeVisualizers[0] == null) {
      earthquakeVisualizers[0] = new PulseEarthquakeVisualizer(lx, earthquakes);

      for (int i = 1; i < NUM_VISUALIZERS; i++) {
        earthquakeVisualizers[i] = new ImageEarthquakeVisualizer(lx, earthquakes, i);
      }
    }

    blur.addListener(new LXParameterListener() {
      void onParameterChanged(LXParameter parameter) {
        earthquakeVisualizers[visualizerIndex.getValuei()].setBlur(blur.getValuei());
      }
    });
    visualizerIndex.addListener(new LXParameterListener() {
      void onParameterChanged(LXParameter parameter) {
        earthquakeVisualizers[visualizerIndex.getValuei()].setBlur(blur.getValuei());
      }
    });
  }

  void run(double deltaMs) {
    EarthquakeVisualizer visualizer = earthquakeVisualizers[visualizerIndex.getValuei()];
    if (visualizer != null) {
      for (LED led : model.leds) {
          setColor(led.index, visualizer.getColorAtPixel(led.transformedRectTheta, led.rawY));
      }
    }
  }

  public abstract class EarthquakeVisualizer {

    protected final LX lx;

    protected final List<Earthquake> earthquakes;

    EarthquakeVisualizer(LX lx, List<Earthquake> earthquakes) {
      this.lx = lx;
      this.earthquakes = earthquakes;
    }

    void setBlur(int amount) {}

    abstract int getColorAtPixel(float rectTheta, float y);
  }

  public class PulseEarthquakeVisualizer extends EarthquakeVisualizer {

    private static final int PULSE_SPEED = 5000;
    private final QuadraticEnvelope pulseRadius = new QuadraticEnvelope(0, 20, visualizerPeriod);
    private final QuadraticEnvelope pulseAlpha = new QuadraticEnvelope(2, 0, visualizerPeriod);
    
    private static final int outerFade = 10;
    private static final int innerFade = 5;
    private static final int dotFade = 10;

    PulseEarthquakeVisualizer(LX lx, List<Earthquake> earthquakes) {
      super(lx, earthquakes);

      pulseRadius.setEase(QuadraticEnvelope.Ease.OUT);
      pulseRadius.setLooping(true);
      lx.addModulator(pulseRadius).start();

      pulseAlpha.setEase(QuadraticEnvelope.Ease.OUT);
      pulseAlpha.setLooping(true);
      lx.addModulator(pulseAlpha).start();
    }

    int getColorAtPixel(float rectTheta, float y) {
      int pixelColor = LXColor.BLACK;

      float[] distances = new float[earthquakes.size()];

      for (int i = 0; i < earthquakes.size(); i++) {
        Earthquake earthquake = earthquakes.get(i);
        float earthquakeRectTheta = earthquake.rectTheta;
        if (2 * (earthquakeRectTheta - rectTheta) > Model.RECT_THETA_MAX) {
          earthquakeRectTheta -= Model.RECT_THETA_MAX;
        } else if (2 * (rectTheta - earthquakeRectTheta) > Model.RECT_THETA_MAX) {
          earthquakeRectTheta += Model.RECT_THETA_MAX;
        }
        float pulseRadiusOffset = max(earthquake.magnitude + dotFade, pulseRadius.getValuef() * earthquake.magnitude);
        if (abs(earthquakeRectTheta - rectTheta) * Model.XY_DISTANCE_RATIO > pulseRadiusOffset
          || abs(earthquake.rawY - y) > pulseRadiusOffset) {
          distances[i] = 10000;
          continue;
        }
        float distance = distances[i] = dist(earthquakeRectTheta * Model.XY_DISTANCE_RATIO, earthquake.rawY, rectTheta * Model.XY_DISTANCE_RATIO, y);

        float pulseDistance = distance - (pulseRadius.getValuef() * earthquake.magnitude - outerFade);
        float fadeValue;
        if (pulseDistance >= 0) {
          fadeValue = max(0, 1 - pulseDistance / outerFade);
        } else {
          fadeValue = max(0, 1 + pulseDistance / 100);
        }
        int adjustedFadeValue = (int)(100 * fadeValue * pulseAlpha.getValuef());
        if (adjustedFadeValue > 0) {
          pixelColor = LXColor.add(pixelColor, lx.hsb(100, 100, adjustedFadeValue));
        }
      }

      for (int i = 0; i < earthquakes.size(); i++) {
        Earthquake earthquake = earthquakes.get(i);
        float distance = distances[i];
        if (distance >= 10000) continue;

        float progress = max(0, 1 - max(0, distance - earthquake.magnitude) / dotFade);
        if (progress > 0) {
          pixelColor = LXColor.lerp(pixelColor, LXColor.RED, progress);
        }
      }

      return pixelColor;
    }
  }

  public class ImageEarthquakeVisualizer extends EarthquakeVisualizer {

    protected PImage originalImage;
    protected PImage indicatorImage;

    private final QuadraticEnvelope radius = new QuadraticEnvelope(0, 20, visualizerPeriod);

    ImageEarthquakeVisualizer(LX lx, List<Earthquake> earthquakes, int index) {
      super(lx, earthquakes);
      setImage(loadImage("indicator" + index + ".png"));

      radius.setEase(QuadraticEnvelope.Ease.OUT);
      radius.setLooping(true);
      lx.addModulator(radius).start();
    }

    void setImage(PImage image) {
      originalImage = image;
      indicatorImage = originalImage.get();
    }

    void setBlur(int amount) {
      indicatorImage = originalImage.get();
      indicatorImage.filter(BLUR, amount);
    }

    int getColorAtPixel(float rectTheta, float y) {
      int pixelColor = LXColor.BLACK;

      if (indicatorImage == null) return pixelColor;

      for (int i = 0; i < earthquakes.size(); i++) {
        Earthquake earthquake = earthquakes.get(i);
        float earthquakeRectTheta = earthquake.rectTheta;
        float earthquakeRawY = earthquake.rawY;

        // adjust earthquakeRectTheta to be on the same plane as rectTheta
        if (2 * (earthquakeRectTheta - rectTheta) > Model.RECT_THETA_MAX) {
          earthquakeRectTheta -= Model.RECT_THETA_MAX;
        } else if (2 * (rectTheta - earthquakeRectTheta) > Model.RECT_THETA_MAX) {
          earthquakeRectTheta += Model.RECT_THETA_MAX;
        }

        float currentPulseRadius = radius.getValuef() * earthquake.magnitude;

        // bounding box
        if (abs(earthquakeRectTheta - rectTheta) * Model.XY_DISTANCE_RATIO > currentPulseRadius
          || abs(earthquakeRawY - y) > currentPulseRadius) {
          continue;
        }

        float startX = earthquakeRectTheta * Model.XY_DISTANCE_RATIO - currentPulseRadius;
        float startY = earthquakeRawY - currentPulseRadius;

        // System.out.println("startX: "+startX + ", startY: "+startY);

        int mapX = (int)map(rectTheta * Model.XY_DISTANCE_RATIO, startX, startX + 2 * currentPulseRadius, 0, indicatorImage.width) % indicatorImage.width;
        int mapY = (int)map(y, startY, startY + 2 * currentPulseRadius, 0, indicatorImage.height) % indicatorImage.height;
        int colr = indicatorImage.get(mapX, mapY);
        float brightness = 100 * (colr & 255) / 255;

        pixelColor = LXColor.add(pixelColor, lx.hsb(EarthquakeVisualizerPattern.this.hue.getValuef(), 100, brightness));
      }

      return pixelColor;
    }
  }
}

// public class MapWindow extends UIWindow {

//   private final EarthquakeMap earthquakeMap;

//   final static int HEIGHT = 150;
//   final static int WIDTH = 2 * HEIGHT;

//   MapWindow(UI ui, EarthquakeMap earthquakeMap) {
//     super(ui, "", Tabula.this.width / 2 - WIDTH / 2, 50, WIDTH + 2, HEIGHT + 2);
//     this.earthquakeMap = earthquakeMap;

//     MapUIImage mapUIImage = new MapUIImage(1, 1, WIDTH, HEIGHT, earthquakeMap);
//     mapUIImage.addToContainer(this);
//   }
// }

// public class MapWindowRatio extends UIWindow {

//   private final EarthquakeMap earthquakeMap;

//   final static int HEIGHT = 100;
//   final static int WIDTH = (int)(HEIGHT * Model.XY_DISTANCE_RATIO * Model.NUM_LEDS_X / Model.NUM_LEDS_Y);

//   MapWindowRatio(UI ui, EarthquakeMap earthquakeMap) {
//     super(ui, "", Tabula.this.width / 2 - WIDTH / 2, 10, WIDTH + 2, HEIGHT + 2);
//     this.earthquakeMap = earthquakeMap;

//     MapUIImage mapUIImage = new MapUIImage(1, 1, WIDTH, HEIGHT, earthquakeMap);
//     mapUIImage.addToContainer(this);
//   }
// }

// public class MapUIImage extends UI2dComponent {

//   private final EarthquakeMap earthquakeMap;
//   private PImage pImage;

//   MapUIImage(int x, int y, int width, int height, EarthquakeMap earthquakeMap) {
//     super(x, y, width, height);
//     this.earthquakeMap = earthquakeMap;
//   }

//   @Override
//   public void onDraw(UI ui, PGraphics pg) {
//     pg.loadPixels();
//     for (int i = (int)x; i < width + x; ++i) {
//       for (int j = (int)y; j < height + y; ++j) {
//         float rectTheta = map(i, 0, width, 0, Model.RECT_THETA_MAX);
//         float rawY = map(height - j - 1, 0, height, 0, EarthquakeMap.IMAGE_HEIGHT);
//         pg.pixels[i + j * (int)pg.width] = earthquakeMap.getColorAtPixel(rectTheta, rawY);
//       }
//     }
//     pg.updatePixels();

//     redraw();
//   }
// }

public class WMSConnection {

  WMSConnection() {
  }

  List<Earthquake> getEarthquakes() {
    BufferedReader in = null;
    FeatureCollection earthquakeFeatureCollection;
    try {
      // URL url = new URL("http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_month.geojson");
      // URL url = new URL("http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/4.5_week.geojson");
      // URL url = new URL("http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/2.5_day.geojson");
      URL url = new URL("http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/1.0_hour.geojson");
      in = new BufferedReader(new InputStreamReader(url.openStream()));
      FeatureJSON featureJSON = new FeatureJSON();
      earthquakeFeatureCollection = featureJSON.readFeatureCollection(in);
    } catch (Exception e) {
      println(e);
      return null;
    } finally {
      if (in != null) {
        try {
          in.close();
        } catch (Exception e) {
        }
      }
    }

    List<Earthquake> earthquakes = new ArrayList<Earthquake>();
    FeatureIterator iterator = earthquakeFeatureCollection.features();
    try {
      while (iterator.hasNext()) {
        Feature feature = iterator.next();
        GeometryAttribute geometry = feature.getDefaultGeometryProperty();
        com.vividsolutions.jts.geom.Point point = (com.vividsolutions.jts.geom.Point)geometry.getValue();
        Coordinate coordinate = point.getCoordinate();

        org.opengis.feature.Attribute magnitudeAttribute = (org.opengis.feature.Attribute)feature.getProperty("mag");
        Number magnitude = (Number)magnitudeAttribute.getValue();

        Earthquake earthquake = new Earthquake(coordinate.x, coordinate.y, magnitude.floatValue());
        earthquakes.add(earthquake);
      }
    } finally {
      iterator.close();
    }
    return earthquakes;
  }

  // http://earthquake.usgs.gov/earthquakes/feed/v1.0/geojson.php
  // http://earthquake.usgs.gov/earthquakes/feed/v1.0/summary/significant_month.geojson

  PImage getBlueMarbleImage(int width, int height) {
    //crs=CRS:84&dpiMode=7&featureCount=10&format=image/png&layers=BlueMarbleNG-TB&styles=&url=http://neowms.sci.gsfc.nasa.gov/wms/wms

    WebMapServer wms;
    try {
      URL serverURL = new URL("http://neowms.sci.gsfc.nasa.gov/wms/wms");
      wms = new WebMapServer(serverURL);
    } catch (Exception e) {
      println(e);
      return null;
    }

    GetMapRequest request = wms.createGetMapRequest();
    request.setFormat("image/png");
    request.setDimensions(width, height);
    // request.setTransparent(true);
    // request.setBBox(new CRSEnvelope("CRS:84", -180, -90, 180, 90));
    request.setBBox("-180,-90,180,90");
    request.addLayer("BlueMarbleNG-TB", "");
    request.setVendorSpecificParameter("CRS", "CRS:84");
    request.setSRS("CRS:84");
    // request.setVendorSpecificParameter("DPI", "72");
    // request.setVendorSpecificParameter("MAP_RESOLUTION", "72");
    // request.setVendorSpecificParameter("FORMAT_OPTIONS", "dpi:72");

    return getImageFromMapRequest(wms, request);
  }

  PImage getLocalhostImage(int width, int height) {
    // return loadImage("http://localhost/qgis-mapserv/qgis_mapserv.fcgi?map=/Users/kyle/code/art/Sherman/EarthquakeMap.qgs&SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&LAYER=EarthquakeMap&WIDTH=" + width + "&HEIGHT=" + height + "&FORMAT=image/png&STYLE=default&TRANSPARENT=TRUE&BBOX=-180,-90,180,90", "png");

    WebMapServer wms;
    try {
      URL serverURL = new URL("http://localhost/qgis-mapserv/qgis_mapserv.fcgi");
      wms = new WebMapServer(serverURL);
    } catch (Exception e) {
      println(e);
      return null;
    }

    GetMapRequest request = wms.createGetMapRequest();
    request.setVendorSpecificParameter("map", "data/EarthquakeMap.qgs");
    request.setFormat("image/png");
    request.setDimensions(width, height);
    request.setTransparent(true);
    request.setBBox("-180,-90,180,90");
    request.addLayer("EarthquakeMap", "default");

    return getImageFromMapRequest(wms, request);
  }
}
