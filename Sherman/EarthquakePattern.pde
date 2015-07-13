public class EarthquakeMap {

  static final int IMAGE_WIDTH = 600;
  static final int IMAGE_HEIGHT = 300;

  private final LX lx;

  private final SawLFO rotation = new SawLFO(Model.RECT_THETA_MAX, 0, 60000);

  private static final int PULSE_SPEED = 5000;
  private final QuadraticEnvelope pulseRadius = new QuadraticEnvelope(0, 20, PULSE_SPEED);
  private final QuadraticEnvelope pulseAlpha = new QuadraticEnvelope(1, 0, PULSE_SPEED);
  
  private static final int outerFade = 10;
  private static final int innerFade = 5;
  private static final int dotFade = 10;

  public PImage mapImage;
  public List<Earthquake> earthquakes = new ArrayList<Earthquake>();

  EarthquakeMap(LX lx) {
    this.lx = lx;

    pulseRadius.setEase(QuadraticEnvelope.Ease.OUT);
    pulseRadius.setLooping(true);

    pulseAlpha.setEase(QuadraticEnvelope.Ease.OUT);
    pulseAlpha.setLooping(true);

    lx.addModulator(rotation).start();
    lx.addModulator(pulseRadius).start();
    lx.addModulator(pulseAlpha).start();

    WMSConnection wmsConnection = new WMSConnection();
    mapImage = wmsConnection.getBlueMarbleImage(IMAGE_WIDTH, IMAGE_HEIGHT);
    earthquakes = wmsConnection.getEarthquakes();
  }

  int getColorAtPixel(float rectTheta, float y) {
    float ledRectTheta = rectTheta + rotation.getValuef();
    float ledRawY = y;

    int pixelColor = LXColor.BLACK;

    if (mapImage != null) {
      int mapX = (int)map(ledRectTheta, 0, Model.RECT_THETA_MAX, 0, mapImage.width) % mapImage.width;
      int mapY = (int)(mapImage.height - ledRawY - 1);
      pixelColor = mapImage.get(mapX, mapY);
    }

    float[] distances = new float[earthquakes.size()];

    for (int i = 0; i < earthquakes.size(); i++) {
      Earthquake earthquake = earthquakes.get(i);
      float earthquakeRectTheta = earthquake.rectTheta;
      if (2 * (earthquakeRectTheta - ledRectTheta) > Model.RECT_THETA_MAX) {
        earthquakeRectTheta -= Model.RECT_THETA_MAX;
      } else if (2 * (ledRectTheta - earthquakeRectTheta) > Model.RECT_THETA_MAX) {
        earthquakeRectTheta += Model.RECT_THETA_MAX;
      }
      float pulseRadiusOffset = max(earthquake.magnitude + dotFade, pulseRadius.getValuef() * earthquake.magnitude);
      if (abs(earthquakeRectTheta - ledRectTheta) * Model.XY_DISTANCE_RATIO > pulseRadiusOffset
        || abs(earthquake.rawY - ledRawY) > pulseRadiusOffset) {
        distances[i] = 10000;
        continue;
      }
      float distance = distances[i] = dist(earthquakeRectTheta * Model.XY_DISTANCE_RATIO, earthquake.rawY, ledRectTheta * Model.XY_DISTANCE_RATIO, ledRawY);

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

public class EarthquakePattern extends Pattern {

  private final EarthquakeMap earthquakeMap;

  EarthquakePattern(LX lx, EarthquakeMap earthquakeMap) {
    super(lx);
    this.earthquakeMap = earthquakeMap;
  }

  void run(double deltaMs) {
    for (LED led : model.leds) {
      setColor(led.index, earthquakeMap.getColorAtPixel(led.rectTheta, led.rawY));
    }
  }
}

public class MapWindow extends UIWindow {

  private final EarthquakeMap earthquakeMap;

  final static int HEIGHT = 150;
  final static int WIDTH = 2 * HEIGHT;

  MapWindow(UI ui, EarthquakeMap earthquakeMap) {
    super(ui, "", Sherman.this.width / 2 - WIDTH / 2, 50, WIDTH + 2, HEIGHT + 2);
    this.earthquakeMap = earthquakeMap;

    MapUIImage mapUIImage = new MapUIImage(1, 1, WIDTH, HEIGHT, earthquakeMap);
    mapUIImage.addToContainer(this);
  }
}

public class MapWindowRatio extends UIWindow {

  private final EarthquakeMap earthquakeMap;

  final static int HEIGHT = 100;
  final static int WIDTH = (int)(HEIGHT * Model.XY_DISTANCE_RATIO * Model.NUM_LEDS_X / Model.NUM_LEDS_Y);

  MapWindowRatio(UI ui, EarthquakeMap earthquakeMap) {
    super(ui, "", Sherman.this.width / 2 - WIDTH / 2, Sherman.this.height - HEIGHT - 50, WIDTH + 2, HEIGHT + 2);
    this.earthquakeMap = earthquakeMap;

    MapUIImage mapUIImage = new MapUIImage(1, 1, WIDTH, HEIGHT, earthquakeMap);
    mapUIImage.addToContainer(this);
  }
}

public class MapUIImage extends UI2dComponent {

  private final EarthquakeMap earthquakeMap;
  private PImage pImage;

  MapUIImage(int x, int y, int width, int height, EarthquakeMap earthquakeMap) {
    super(x, y, width, height);
    this.earthquakeMap = earthquakeMap;
  }

  @Override
  public void onDraw(UI ui, PGraphics pg) {
    pg.loadPixels();
    for (int i = (int)x; i < width + x; ++i) {
      for (int j = (int)y; j < height + y; ++j) {
        float rectTheta = map(i, 0, width, 0, Model.RECT_THETA_MAX);
        float rawY = map(height - j - 1, 0, height, 0, EarthquakeMap.IMAGE_HEIGHT);
        pg.pixels[i + j * (int)pg.width] = earthquakeMap.getColorAtPixel(rectTheta, rawY);
      }
    }
    pg.updatePixels();

    redraw();
  }
}

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
    request.setVendorSpecificParameter("map", "/Users/kyle/code/art/Sherman/EarthquakeMap.qgs");
    request.setFormat("image/png");
    request.setDimensions(width, height);
    request.setTransparent(true);
    request.setBBox("-180,-90,180,90");
    request.addLayer("EarthquakeMap", "default");

    return getImageFromMapRequest(wms, request);
  }
}
