/*
see comment on https://stackoverflow.com/questions/40050731/how-to-make-two-fft-objects-for-the-left-and-right-channel-with-the-minim-librar
 todo: check https://stackoverflow.com/questions/20408388/how-to-filter-fft-data-for-audio-visualisation
 todo: check https://www.ee.columbia.edu/~dpwe/e4896/index.html
 
 problems with minim and audio input: https://code.compartmental.net/minim/audioinput_class_audioinput.html
 //input.setPan(1); //https://code.compartmental.net/minim/audioinput_method_shiftpan.html
 question: om de x seconden maxVal resetten levert enorme spikes op (want opeens is de max 1, of 0.00001. Misschien de gebruiker zelf laten bepalen wanneer de resetMaxValue functie wordt aangeroepen? of enkel fAnalyzer.maxValue = 1;
 todo: moet er 1 maxVal zijn voor totale frequencies, of per frequency band?
 todo: lerp smoothing inzetten voor sensor values
 todo: arduino potmeter values gebruiken voor aantal objecten, maar pas doorgeven als gestopt met draaien.
 todo: knop een aan switch maken, 1x drukken is aan, led aan, nog keer drukken is uit, led uit: mechanisme kunnen studenten zelf maken. er is nu een inputButtonsOnce die 1 frame true is als wordt gedrukt
 - Arduino: smooth out potmeter values (reduce jumping values)
 - Tom, idee hoe we dat kunnen doen? Of valt dat samen met volgende punt, dat de code alleen iets moet doen als er tenminste een change is van 5 units oid.
 - Arduino: change of value between time period. E.g. add 10 particles when at least value has changed 10 units.
 - Tom, kan me herinneren dat we dat ooit eens nodig hadden. Heb je usecases/voorbeelden?
 - BPM: bug: make bpm.bpm public
 - BPM: bug: showinfo bpm class should have nostroke in pushstyle
 */
import ddf.minim.*;
import ddf.minim.analysis.*;

FrequencyAnalyzer fAnalyzer;
PGraphics pg;
ArrayList<Circle> circles = new ArrayList<Circle>();

import processing.serial.*;
import cc.arduino.*;
Arduino arduino;
boolean enableArduino = false;
color col = 50;

ArduinoControls ac;

void setup() {



  //fullScreen();
  size(900, 700);

  fAnalyzer = new FrequencyAnalyzer(this);

  //fAnalyzer = new FrequencyAnalyzer(this, 10);
  //fAnalyzer.setFile("assets/hot-coffee.mp3");
  //fAnalyzer.setInput("FILE"); //"MONO", "STEREO" or "FILE"
  fAnalyzer.setInput("MONO"); //"MONO", "STEREO" or "FILE"
  fAnalyzer.showInfo = true;
  fAnalyzer.enableKeyPresses();
  fAnalyzer.debug();

  pg = createGraphics(width, height);
  for (int i = 0; i < fAnalyzer.bands; i++) {
    circles.add(new Circle(i));
  }
  int[] digitalPortsUsed = { 6, 7, 8 };
  int[] analogPortsUsed = { 2, 5 };
  ac = new ArduinoControls(this, digitalPortsUsed, analogPortsUsed);
  ac.showInfo = true;

  if (enableArduino) {
    println(Arduino.list());
    arduino = new Arduino(this, Arduino.list()[2], 57600);
    arduino.pinMode(8, Arduino.INPUT_PULLUP);
    arduino.pinMode(7, Arduino.INPUT_PULLUP);
    arduino.pinMode(6, Arduino.INPUT_PULLUP);
    // delay the start of the draw loop so the Arduino is in the ready state
    // (the first few frames, digitalRead returned incorrect values)
    //delay(2000);
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

  fill(255, 0, 0);
  noStroke();

  if (ac.getPushButton(0) && ac.getPushButton(1)) {
    fill(0, 0, 255);
  }

  ellipse(lerp(0, width, ac.getPotmeterSmooth(0)), height-100, 50, 50);
  ellipse(map(ac.getPotmeterSmooth(1, 0.01), 0, 1, 0, width), height-50, 50, 50);

  if (ac.getPushButtonOnce(1)) {
    background(255, 0, 0);
  }
  if (ac.getPushButtonOnce(0)) {
    col = color(255);
  }
    if (ac.getPushButtonOnce(2)) {
    col = color(50);
  }

}

void drawCircles() {
  pg.beginDraw();
  pg.fill(col, 30);
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
