void setup() {
  size(1024, 768, OPENGL);
  // size(640, 360, P3D);

  P2LX lx = new P2LX(this, new Model());

  EarthquakeMap earthquakeMap = new EarthquakeMap(lx);

  lx.setPatterns(new LXPattern[] {
    new EarthquakePattern(lx, earthquakeMap),
  });

  lx.ui.addLayer(new SimulatorCamera(lx, lx.ui));
  // lx.ui.addLayer(new MapWindow(lx.ui, earthquakeMap));
  lx.ui.addLayer(new MapWindowRatio(lx.ui, earthquakeMap));

  lx.engine.setThreaded(true);
}

void draw() {
  background(#222222);
}
