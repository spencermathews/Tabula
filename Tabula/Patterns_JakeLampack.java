import heronarts.lx.LX;
import heronarts.lx.modulator.SawLFO;

class AcidTrip extends TSPattern {
  
  final SawLFO trails = new SawLFO(360, 0, 7000);
  
  AcidTrip(LX lx) {
    super(lx);

    addModulator(trails).start();
  }
    
  public void run(double deltaMs) {
    if (getChannel().getFader().getNormalized() == 0) return;
   
    for (LED led : model.leds) {
      colors[led.index] = lx.hsb(
        Utils.abs(model.cy - led.transformedY) + Utils.abs(model.cy - led.transformedTheta) + trails.getValuef() % 360,
        100,
        100
      );
    }
  }
}

