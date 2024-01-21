class FrequencyBand {
  float freqStart;
  float freqEnd;
  FrequencyBand(float frequencyStart, float frequencyEnd) {
    freqStart = frequencyStart;
    freqEnd = frequencyEnd;
  }
}

class FrequencyAnalyzer {
  int linNum = 30;
  Minim minim;
  AudioPlayer song;
  AudioInput input;
  //AudioIn in;
  FFT fft;


  float maxVal = 0.0;

  boolean enableMic = false;
  boolean enableSong = false;
  boolean enableMixer = false;

  boolean showInfo = false;
  float startTime = 0;
  float[] avg = new float[0];
  float[] max = new float[0];
  float[] count = new float[0];
  float[] size = new float[0];
  FrequencyBand[] frequencyBands = new FrequencyBand[0];

  FrequencyAnalyzer(PApplet p) {
    this(p, 3);
  }

  FrequencyAnalyzer(PApplet p, int bandsPerOctave) {

    linNum = bandsPerOctave * 10;
    minim = new Minim(p);

    fft = new FFT(1024, 44100.0); //always 1024 and 44100.0??
    //fft = new FFT(input.bufferSize(), input.sampleRate());

    //fft.linAverages(linNum);
    fft.logAverages(22, bandsPerOctave); //results in 30 bands. 1 results in 10 etc.
  }

  void enableMicrophone() {
    input = minim.getLineIn(Minim.MONO);
    //input.enableMonitoring();
    enableMic = true;
  }
  void enableSong(String file) {
    song = minim.loadFile(file);
    song.play();
    enableSong = true;
  }

  //void addFrequencyBand(FrequencyBand b) {
  //  frequencyBands = (FrequencyBand[]) append (frequencyBands, b);
  //  avg = append(avg, 0.1);
  //  max = append(max, 0.1);
  //  count = append(count, 0);
  //  size = append(size, 0);
  //}

  //void resetMax(float duration) {
  //  if (millis() - startTime > duration) {
  //    for (int j=0; j<frequencyBands.length; j++) max[j] = avg[j];
  //    startTime = millis();
  //  }
  //}

  float getAvg(int i) {
    println("maxValue: " + maxVal);
    return map(fft.getAvg(i), 0, maxVal, 0, 1);
  }

  void run() {

    if (enableSong) fft.forward(song.mix);
    if (enableMic) fft.forward(input.mix);
    //if (enableMixer) fft.forward(in.mix);

    //determine max value to normalize all average values
    for (int i = 0; i < fft.avgSize(); i++) if (fft.getAvg(i) > maxVal) maxVal = fft.getAvg(i);
    
    
    
    //for (int j=0; j<frequencyBands.length; j++) {
    //  avg[j] = 0;
    //  count[j] = 0;
    //}



    //for (int j=0; j<frequencyBands.length; j++) {
    //  if (count[j]>0) avg[j] /= count[j];
    //  max[j] = max(max[j], avg[j]);
    //  avg[j] = constrain(avg[j], 0, max[j]);
    //  size[j] = map(avg[j], 0, max[j], 0, 400);

    //  if (showInfo) {
    //    pushStyle();
    //    rectMode(CENTER);
    //    textAlign(CENTER, CENTER);
    //    noStroke();
    //    fill(240);
    //    rect(width/(frequencyBands.length+1)*(j+1), height/2, 50, size[j]);

    //    fill(0);
    //    text(round(size[j]), width/(frequencyBands.length+1)*(j+1), height/2-size[j]/2-5);
    //    stroke(0);
    //    strokeWeight(1);
    //    fill(0);
    //    line(width/(frequencyBands.length+1)*(j+1)-50, height/2-200, width/(frequencyBands.length+1)*(j+1)-10, height/2-200);
    //    text("max: " + nf(max[j], 0, 2), width/(frequencyBands.length+1)*(j+1)-50, height/2-200-7);
    //    text("frequencies: " + round(frequencyBands[j].freqStart) + "-" + round(frequencyBands[j].freqEnd), width/(frequencyBands.length+1)*(j+1)-50, height/2-200-27);
    //    popStyle();
    //  }
    //}
  }
}

void exit() {
  //might not be necessary
  println("called exit()");
  fAnalyzer.song.close();
  fAnalyzer.minim.stop();
  super.exit();//let processing carry with it's regular exit routine
}
