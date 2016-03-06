class TestPattern extends EarthquakePattern {

	TestPattern(LX lx) {
		super(lx);
	}

	public void run(double deltaMs) {
		PGraphics pg = getGraphics();

		//draw on Processing canvas...
		pg.background(100);
		pg.stroke(255);
		pg.strokeWeight(10);
		pg.ellipse(200, 200, 50, 50);

		drawGraphics(pg);
	}
}
