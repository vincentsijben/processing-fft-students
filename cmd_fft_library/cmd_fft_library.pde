/*
see comment on https://stackoverflow.com/questions/40050731/how-to-make-two-fft-objects-for-the-left-and-right-channel-with-the-minim-librar
 todo: check https://stackoverflow.com/questions/20408388/how-to-filter-fft-data-for-audio-visualisation
 todo: check https://www.ee.columbia.edu/~dpwe/e4896/index.html
 
 problems with minim and audio input: https://code.compartmental.net/minim/audioinput_class_audioinput.html
 //input.setPan(1); //https://code.compartmental.net/minim/audioinput_method_shiftpan.html
 todo: om de x seconden maxVal resetten
 todo: lerp smoothing inzetten voor sensor values 
 todo: arduino potmeter values gebruiken voor aantal objecten, maar pas doorgeven als gestopt met draaien.
 */
import ddf.minim.*;
import ddf.minim.analysis.*;

FrequencyAnalyzer fAnalyzer;
PGraphics pg;
ArrayList<Circle> circles = new ArrayList<Circle>();


void setup() {
  
  System.out.println("Your OS name -> " + System.getProperty("os.name"));
  System.out.println("Your OS version -> " + System.getProperty("os.version"));
  System.out.println("Your OS Architecture -> " + System.getProperty("os.arch"));

  //fullScreen();
  size(900, 700);

  fAnalyzer = new FrequencyAnalyzer(this);
  
  //fAnalyzer = new FrequencyAnalyzer(this, 10);
  fAnalyzer.setFile("assets/hot-coffee.mp3");
  fAnalyzer.setInput("FILE"); //"MONO", "STEREO" or "FILE"
  //fAnalyzer.setInput("MONO"); //"MONO", "STEREO" or "FILE"
  fAnalyzer.showInfo = true;
  fAnalyzer.enableKeyPresses();
  
  pg = createGraphics(width, height);
  for (int i = 0; i < fAnalyzer.bands; i++) {
    circles.add(new Circle(i));
  }
  
}


void draw() {

  drawCircles();

  stroke(200);
  strokeWeight(5);
  noFill();
  // get the raw value for band 11:
  if (fAnalyzer.fft.getAvg(10)>40) {
    circle(width/4, height-100, 100);
  }

  // get the normalized value for band 11:
  if (fAnalyzer.getAvg(10)>0.5) {
    circle(width/2, height-100, 100);
  }

  // get the normalized value for band 5 using 20 as the max mapped value:
  if (fAnalyzer.getAvg(4, 20)>0.5) {
    circle(width/4*3, height-100, 100);
  }

  fAnalyzer.run();
}

void drawCircles() {
  pg.beginDraw();
  pg.fill(50, 30);
  pg.rect(0, 0, width, height);
  pg.translate(pg.width / 2, pg.height / 2);
  pg.strokeWeight(2);
  pg.noFill();

  for (int i = 0; i < circles.size(); i++) {
    Circle c = circles.get(i);

    pg.pushMatrix();
    pg.stroke(c.col);
    pg.rotate(radians(c.r));
    pg.circle(c.x, c.y, lerp(0, 100, fAnalyzer.getAvg(c.index)));
    pg.popMatrix();

    c.r+=c.rSpeed;
  }

  pg.endDraw();
  image(pg, 0, 0);
}
