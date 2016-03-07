class TestPattern extends EarthquakePattern {

	int diameter = 55;

	BasicParameter period = new BasicParameter("period", 1000, 500, 10000);
	SawLFO xValue = new SawLFO(0, CANVAS_WIDTH, period);
	SinLFO yValue = new SinLFO(diameter, CANVAS_HEIGHT - diameter, 300);

	TestPattern(LX lx) {
		super(lx);
		addParameter(period);
		addModulator(xValue).start();
		addModulator(yValue).start();
	}

	public void run(double deltaMs) {
		PGraphics pg = getGraphics();

		//draw on Processing canvas...
		pg.background(100, 0, 0);
		pg.stroke(255);
		pg.strokeWeight(10);
		pg.ellipse(xValue.getValuef(), yValue.getValuef(), diameter, diameter);

		drawGraphics(pg);
	}
}
