/*
see comment on https://stackoverflow.com/questions/40050731/how-to-make-two-fft-objects-for-the-left-and-right-channel-with-the-minim-librar
 todo: check https://stackoverflow.com/questions/20408388/how-to-filter-fft-data-for-audio-visualisation
 todo: check https://www.ee.columbia.edu/~dpwe/e4896/index.html
 
 problems with minim and audio input: https://code.compartmental.net/minim/audioinput_class_audioinput.html
 //input.setPan(1); //https://code.compartmental.net/minim/audioinput_method_shiftpan.html
 question: om de x seconden maxVal resetten levert enorme spikes op (want opeens is de max 1, of 0.00001. Misschien de gebruiker zelf laten bepalen wanneer de resetMaxValue functie wordt aangeroepen? of enkel fAnalyzer.maxValue = 1;
 todo: moet er 1 maxVal zijn voor totale frequencies, of per frequency band?
 todo: arduino potmeter values gebruiken voor aantal objecten, maar pas doorgeven als gestopt met draaien.
 todo: knop een aan switch maken, 1x drukken is aan, led aan, nog keer drukken is uit, led uit: mechanisme kunnen studenten zelf maken. er is nu een inputButtonsOnce die 1 frame true is als wordt gedrukt
 
 - Tom, idee hoe we dat kunnen doen? Of valt dat samen met volgende punt, dat de code alleen iets moet doen als er tenminste een change is van 5 units oid.
 - Arduino: change of value between time period. E.g. add 10 particles when at least value has changed 10 units.
 - Tom, kan me herinneren dat we dat ooit eens nodig hadden. Heb je usecases/voorbeelden?
 - BPM: bug: make bpm.bpm public
 - BPM: bug: showinfo bpm class should have nostroke in pushstyle
 todo: all info panel adjustable
 todo: adjustable keys for each input
 
 */
import ddf.minim.*;
import ddf.minim.analysis.*;

FrequencyAnalyzer fa;
PGraphics pg;
ArrayList<Circle> circles = new ArrayList<Circle>();

import processing.serial.*;
import cc.arduino.*;
Arduino arduinoo;
boolean enableArduino = true;
color col = 50;

ArduinoControls ac;

void setup() {



  //fullScreen();
  size(900, 700);
  fa = new FrequencyAnalyzer(this);

  //fAnalyzer = new FrequencyAnalyzer(this, 10);
  //fAnalyzer.setFile("assets/hot-coffee.mp3");
  //fAnalyzer.setInput("FILE"); //"MONO", "STEREO" or "FILE"
  fa.setInput("MONO"); //"MONO", "STEREO" or "FILE"
  fa.showInfoPanel = true;
  fa.enableKeypress = true;
  fa.debug();

  pg = createGraphics(width, height);
  for (int i = 0; i < fa.bands; i++) {
    circles.add(new Circle(i));
  }


  if (enableArduino) {
    print("Serialports: ");
    println(Arduino.list());
    arduinoo = new Arduino(this, Arduino.list()[2], 57600);

    //arduino.pinMode(7, Arduino.INPUT_PULLUP);
    //arduino.pinMode(6, Arduino.INPUT_PULLUP);

    arduinoo.pinMode(11, Arduino.OUTPUT);
    //arduinoo.pinMode(10, Arduino.INPUT_PULLUP);
    arduinoo.pinMode(9, Arduino.OUTPUT);
    arduinoo.pinMode(8, Arduino.INPUT_PULLUP);
    //arduinoo.pinMode(7, Arduino.OUTPUT);
    //arduinoo.pinMode(6, Arduino.OUTPUT);
    // delay the start of the draw loop so the Arduino is in the ready state
    // (the first few frames, digitalRead returned incorrect values)
    delay(2000);
  }

  ArrayList <PushButton> pushbuttons = new ArrayList<PushButton>();
  //pushbuttons.add(new PushButton(7, '1'));
  //pushbuttons.add(new PushButton(8, '2').setToLow());
  //pushbuttons.add(new PushButton(9, '3'));
  //pushbuttons.add(new PushButton(10, '4').setToLow());

  ArrayList <Potentiometer> potmeters = new ArrayList<Potentiometer>();
  //potmeters.add(new Potentiometer(0, 'q'));
  //potmeters.add(new Potentiometer(1, 'w'));
  //potmeters.add(new Potentiometer(2, 'e').setMinValue(2).setMaxValue(945));

  ArrayList <LED> leds = new ArrayList<LED>();
  leds.add(new LED(7));
  leds.add(new LED(9).setToPWM());
  leds.add(new LED(10).setToPWM());

  ac = new ArduinoControls(this, arduinoo, pushbuttons, potmeters, leds, enableArduino);
  ac.showInfoPanel = true;
  ac.setInfoPanel(0, 0, width, 200);
  ac.infoPanelKey = 'o';
  ac.enableKeypress = true;
}


void draw() {
  drawCircles();



  stroke(200);
  strokeWeight(5);
  noFill();
  // get the raw value for band 11:
  if (fa.fft.getAvg(10)>40) {
    circle(width/4, height-100, 100);
  }

  // get the normalized value for band 11:
  if (fa.getAvg(10)>0.5) {
    circle(width/2, height-100, 100);
  }

  // get the normalized value for band 5 using 20 as the max mapped value:
  if (fa.getAvg(4, 20)>0.5) {
    circle(width/4*3, height-100, 100);
  }

  fill(255, 0, 0);
  noStroke();

  //if (ac.getPushButton(0) && ac.getPushButton(1)) {
  //  fill(0, 0, 255);
  //}

  //ellipse(lerp(0, width, ac.getPotmeter(0)), height-100, 150, 150);
  //ellipse(map(ac.getPotmeter(1, 0.05), 0, 1, 0, width), height-50, 50, 50);
  //fill(0,255,0);
  //ellipse(map(ac.getPotmeter(2, 0.25), 0, 1, 0, width), height-50, 5, 5);

  //if (ac.getPushButtonOnce(1)) {
  //  background(255, 0, 0);
  //arduinoo.digitalWrite(2, Arduino.HIGH);
  //arduinoo.digitalWrite(9, Arduino.HIGH);
  //}
  //if (ac.getPushButton(0)) {
  //  col = color(255);
  //  arduinoo.analogWrite(11,int(map(mouseX,0,width,0,255)));
  //}
  ac.setLED(0, 1);
  ac.setLED(1, int(lerp(0, 255, fa.getAvg(7))));
  ac.setLED(2, int(lerp(0, 255, fa.getAvg(7))));
  //if (mouseX > width/2) {
  //  //ac.setLED(1, val);
  //  //ac.setLEDToOn(0);
  //  ac.setLED(0, Arduino.HIGH);
  //  //ac.setLED(1,int(map(mouseX,width/2,width,0,255)));
  //} else {
  //  //ac.setLED(1, 0);
  //  ac.setLED(0, Arduino.LOW);
  //  ac.setLEDToOff(1);
  //}

  //println(fa.getAvg(7));
  //if (fa.getAvg(7)>0.5) {
  //  ac.setLEDToOn(0);
  //} else ac.setLEDToOff(0);

  //if (frameCount%4==0) ac.setLEDToOn(0);
  //else ac.setLEDToOff(0);
}
