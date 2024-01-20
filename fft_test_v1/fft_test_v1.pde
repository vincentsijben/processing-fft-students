/*  music: https://pixabay.com/music/beats-hot-coffee-179282/ */

import ddf.minim.*;
import ddf.minim.analysis.*;
Minim minim;
AudioPlayer song;
FFT fft;
FrequencyAnalyzer fAnalyzer;

void setup() {

  fullScreen();
  minim = new Minim(this);
  song = minim.loadFile("assets/hot-coffee.mp3");
  song.play();

  
  /* 
  this custom fAnalyzer class is just an early version I've tested.
  I want my students to be able to setup several frequency bands, for example 0 - 150Hz, 150 - 250Hz etc and return the normalized amplitude for those ranges.
  I say normalized because then they could easily use these numbers in a lerp function.
  They then can use the returned value for 0-150 to animate a specific shape and 150-250 to change another specific shape.
  The visuals then would have a more realtime feel to it, because without input from their Arduino buttons, the work would animate autonomously...
  
  - I've read about linAverages, logAverages, calcAvg etc. But I'm a n00b in this area. I just want some numbers returned that makes their work feel more realtime.
  */
  fft = new FFT(song.bufferSize(), song.sampleRate());
  fAnalyzer = new FrequencyAnalyzer(fft);
  fAnalyzer.showInfo = true;
  fAnalyzer.addFrequencyBand(new FrequencyBand(0, 150));
  fAnalyzer.addFrequencyBand(new FrequencyBand(150, 250));
  fAnalyzer.addFrequencyBand(new FrequencyBand(250, 300));
  fAnalyzer.addFrequencyBand(new FrequencyBand(300, fft.specSize()));
  
}

void draw() {
  background(200);

  fft.forward(song.mix);
  
  fAnalyzer.run();
  //optional: reset the max values (used for correct scaling) after ... milliseconds
  fAnalyzer.resetMax(2000);

  // example to use the analyzed data
  // what should be the best way to do this...
  // setting a threshold maybe results in a less 'realtime' feel?
  if (fAnalyzer.size[0] > .9) {
    serotonins.add(new Serotonin(color(random(100,255),0,0,127)));
  }
  if (fAnalyzer.size[1] > .5) {
    serotonins.add(new Serotonin(color(0, random(100,255),0,127)));
  }
  if (fAnalyzer.size[2] > .5) {
    serotonins.add(new Serotonin(color(200,200,0,127)));
  }
  if (fAnalyzer.size[3] > .5) {
    serotonins.add(new Serotonin(color(0, 0, random(100,255),127)));
  }
  
  //show particles
  for (int i = 0; i < serotonins.size(); i++) {
    Serotonin sero = serotonins.get(i);
    sero.spawnSerotonin();
  }

}

void stop() {
  song.close();
  minim.stop();
  super.stop();
}
