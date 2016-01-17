import heronarts.lx.*;
import heronarts.lx.audio.*;
import heronarts.lx.effect.*;
import heronarts.lx.midi.*;
import heronarts.lx.model.*;
import heronarts.lx.parameter.*;
import heronarts.lx.pattern.*;
import heronarts.lx.transform.*;
import heronarts.lx.transition.*;
import heronarts.lx.midi.*;
import heronarts.lx.modulator.*;

import heronarts.p3lx.*;
import heronarts.p3lx.ui.*;
import heronarts.p3lx.ui.component.*;
import heronarts.p3lx.ui.control.*;

import ddf.minim.*;
import processing.opengl.*;

import java.io.BufferedReader;
import java.io.BufferedWriter;
import java.io.FileReader;
import java.io.FileWriter;
import java.io.PrintWriter;
import java.io.Reader;
import java.io.Writer;
import java.util.Arrays;
import java.util.ArrayList;
import java.util.Collections;
import java.util.Comparator;
import java.util.Iterator;
import java.util.List;
import java.util.Map;

final static int SECONDS = 1000;
final static int MINUTES = 60*SECONDS;

final static float CHAIN = -12*Geometry.INCHES;
final static float BOLT = 22*Geometry.INCHES;

Model model;
P3LX lx;
ProcessingEngine engine;
BasicParameter outputBrightness;
UIChannelFaders uiFaders;
UIMultiDeck uiDeck;
BPMTool bpmTool;
LXAutomationRecorder[] automation;
BooleanParameter[] automationStop;
DiscreteParameter automationSlot;
LXListenableNormalizedParameter[] effectKnobParameters;
BooleanParameter[] previewChannels;
// EarthquakeMap earthquakeMap;

void settings() {
  size(1148, 720, OPENGL);
}

void setup() {
  frameRate(90); // this will get processing 2 to actually hit around 60
  
  engine = new ProcessingEngine(dataPath(""));
  engine.start();
}

class ProcessingEngine extends Engine {

  ProcessingEngine(String projectPath) {
    super(projectPath);
  }

  LX createLX() {
    return new P3LX(Tabula.this, model);
  }

  P3LX getLX() {
    return (P3LX)lx;
  }

  void configureLX(LX lx) {
    // earthquakeMap = new EarthquakeMap(lx);
  }

  void postCreateLX() {
    super.postCreateLX();

    Tabula.this.model = model;
    Tabula.this.lx = getLX();
    Tabula.this.outputBrightness = outputBrightness;
    Tabula.this.bpmTool = bpmTool;
    Tabula.this.automation = automation;
    Tabula.this.automationStop = automationStop; 
    Tabula.this.automationSlot = automationSlot;
    Tabula.this.effectKnobParameters = effectKnobParameters;
    Tabula.this.previewChannels = previewChannels;

    uiDeck = Tabula.this.uiDeck = new UIMultiDeck(Tabula.this.lx.ui);

    configureUI();
  }

  void addPatterns(ArrayList<LXPattern> patterns) {
    // patterns.add(new EarthquakePattern(lx, earthquakeMap));
    patterns.add(new WorldMapPattern(lx));
    patterns.add(new EarthquakeVisualizerPattern(lx));
    super.addPatterns(patterns);
    // try { patterns.add(new SyphonPattern(lx, Tabula.this)); } catch (Throwable e) {}
  }
}

void draw() {
  background(#222222);
}

/* configureUI */

void configureUI() {

  // // UI initialization
  // lx.ui.addLayer(new UI3dContext(lx.ui) {
  //     protected void beforeDraw(UI ui, PGraphics pg) {
  //       hint(ENABLE_DEPTH_TEST);
  //       pushMatrix();
  //       translate(0, 12*Geometry.FEET, 0);
  //     }
  //     protected void afterDraw(UI ui, PGraphics pg) {
  //       popMatrix();
  //       hint(DISABLE_DEPTH_TEST);
  //     }  
  //   }
  //   .setRadius(90*Geometry.FEET)
  //   .setCenter(model.cx, model.cy, model.cz)
  //   .setTheta(30*Utils.PI/180)
  //   .setPhi(10*Utils.PI/180)
  //   .addComponent(new UITrees())
  // );

  lx.ui.addLayer(new SimulatorCamera(lx, lx.ui));
  // lx.ui.addLayer(new MapWindow(lx.ui, earthquakeMap));
  // lx.ui.addLayer(new MapWindowRatio(lx.ui, earthquakeMap));

  lx.ui.addLayer(uiFaders = new UIChannelFaders(lx.ui));
  lx.ui.addLayer(new UIEffects(lx.ui, effectKnobParameters));
  lx.ui.addLayer(uiDeck);
  lx.ui.addLayer(new UILoopRecorder(lx.ui));
  lx.ui.addLayer(new UIMasterBpm(lx.ui, Tabula.this.width-144, 4, bpmTool));
}

TreesTransition getFaderTransition(LXChannel channel) {
  return (TreesTransition) channel.getFaderTransition();
}

