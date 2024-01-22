class FrequencyAnalyzer {
  int bands = 30;
  Minim minim;
  AudioPlayer song;
  AudioInput input;
  FFT fft;

  float maxVal = 0.000001; //avoid NaN when using maxVal in map() in the first frame.

  boolean enableMic = false;
  boolean enableSong = false;
  boolean showInfo = false;
  

  FrequencyAnalyzer(PApplet p) {
    this(p, 3);
  }

  FrequencyAnalyzer(PApplet p, int bandsPerOctave) {

    bands = bandsPerOctave * 10;
    minim = new Minim(p);

    fft = new FFT(1024, 44100.0); //always 1024 and 44100.0??
    //fft = new FFT(input.bufferSize(), input.sampleRate());

    fft.logAverages(22, bandsPerOctave); // 3 results in 30 bands. 1 results in 10 etc.
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

  //normalize the average for the given index
  float getAvg(int index) {
    return map(fft.getAvg(index), 0, maxVal, 0, 1);
  }

  //set a new max value for the given index and constrain the result between 0 and 1
  float getAvg(int index, float max) {
    return constrain(map(fft.getAvg(index), 0, max, 0, 1), 0, 1);
  }

  void run() {

    if (enableSong) fft.forward(song.mix);
    if (enableMic) fft.forward(input.mix);

    //determine max value to normalize all average values
    for (int i = 0; i < fft.avgSize(); i++) if (fft.getAvg(i) > maxVal) maxVal = fft.getAvg(i);

    if (showInfo) {
      pushStyle();
      fill(200, 127);
      rect(0, 0, width, 100);
      for (int i = 0; i < fAnalyzer.bands; i++) {
        float xR = (i * width) / bands;
        float yR = 100;

        fill(255);
        rect(xR, yR, width / bands, lerp(0, -100, fAnalyzer.getAvg(i)));
        fill(255, 0, 0);
        textAlign(CENTER, CENTER);
        textSize(14);
        text(round(lerp(0, maxVal, fAnalyzer.getAvg(i))), xR + (width / bands / 2), yR - 20);
        textSize(8);
        text(i, xR + (width / bands / 2), yR-6);
      }
      textSize(25);
      text(round(frameRate), 20, 20);
      popStyle();
    }

  }
}

void exit() {
  //might not be necessary
  println("called exit()");
  if (fAnalyzer.song != null) fAnalyzer.song.close();
  fAnalyzer.minim.stop();
  super.exit();//let processing carry with it's regular exit routine
}
