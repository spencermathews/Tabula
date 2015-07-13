public class SimulatorCamera extends UI3dContext {
  public SimulatorCamera(P2LX lx, UI ui) {
    super(ui);

    setRadius(100*Model.FEET);
    setCenter(0, 0, 0);
    setTheta(45*PI/180);
    setPhi(-5*PI/180);

    // addComponent(new LightsSimulator(lx));
    addComponent(new UIGLPointCloud(lx));
  }

  protected void beforeDraw(UI ui, PGraphics pg) {
    hint(ENABLE_DEPTH_TEST);
    pushMatrix();
    translate(0, -10*Model.FEET, 0);
  }

  protected void afterDraw(UI ui, PGraphics pg) {
    popMatrix();
    hint(DISABLE_DEPTH_TEST);
  }
}

public class LightsSimulator extends UI3dComponent {
  
  color[] previewBuffer;
  color[] black;

  P2LX lx;
  Model model;

  PShape building;
  PShape fins;
  
  LightsSimulator(P2LX lx) {
    this.lx = lx;
    this.model = (Model)lx.model;

    previewBuffer = new int[lx.total];
    black = new int[lx.total];
    for (int i = 0; i < black.length; ++i) {
      black[i] = #000000;
    }

    // building = loadShape("building.obj");
    // fins = loadShape("sherman_all_fins_only.obj");
  }
  
  protected void onDraw(UI ui, PGraphics pg) {
    lights();

    pointLight(0, 0, 80, 0, 100, -10*Model.FEET);

    // noStroke();
    // fill(#191919);
    // beginShape();
    // vertex(0, 0, 0);
    // vertex(30*FEET, 0, 0);
    // vertex(30*FEET, 0, 30*FEET);
    // vertex(0, 0, 30*FEET);
    // endShape(CLOSE);

    // drawBuilding(ui);
    drawLights(ui);

    noLights();
  }
     
  private void drawBuilding(UI ui) {
    pushMatrix();
    // Center model on screen
    translate(-width/4, height*4.8, -2000);
    rotateY(5.47);
    
    // Adjust for model
    translate(1500, 0, 600);
    scale(-1, 1);
    rotateX(PI/2);
    
    shape(building);
    shape(fins);
    popMatrix();
  }
     
  private void drawLights(UI ui) {
    color[] colors = lx.getColors();

    noStroke();
    noFill();
    
    for (LED led : model.leds) {
      drawLED(led, colors);
    }
  }
  
  private void drawLED(LED led, color[] colors) {
    pushMatrix();
    fill(colors[led.index]);
    translate(led.x, led.y, led.z);
    box(2, 2, 2);
    popMatrix();
  }
}
