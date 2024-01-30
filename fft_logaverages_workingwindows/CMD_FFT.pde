//enum Input {
//  MIC,
//  LINEIN,
//  FILE
//}

class FrequencyAnalyzer {
  int bands = 30;
  Minim minim;
  AudioPlayer inputFile;
  AudioInput inputMono;
  AudioInput inputStereo;
  AudioBuffer selectedInput;
  String selectedInputString;

  FFT fft;

  float maxVal = 0.000001; //avoid NaN when using maxVal in map() in the first frame.
  boolean showInfo = false;
PApplet main;

  FrequencyAnalyzer(PApplet p) {
    this(p, 3);
  }

  FrequencyAnalyzer(PApplet p, int bandsPerOctave) {
main = p;
    bands = bandsPerOctave * 10;
    minim = new Minim(p);
    //minim.debugOn();
    //in MacOS getLineIn always refers to the selected AUDIO IN device in the sound panel


    fft = new FFT(1024, 44100.0); //always 1024 and 44100.0??
    //fft = new FFT(inputStereo.bufferSize(), inputStereo.sampleRate());
    //fft = new FFT(inputMono.bufferSize(), inputMono.sampleRate());

    fft.logAverages(22, bandsPerOctave); // 3 results in 30 bands. 1 results in 10 etc.



    //default input is built-in microphone
    //selectedInput = inputMono.mix;
    //selectedInput = inputStereo.mix;
  }

  void setFile(String file) {
    inputFile = minim.loadFile(file);
  }

  void setInput(String input) {
    if (input == "MIC") {
      if (inputMono != null) inputMono.close();
      //minim.stop();
      inputMono = minim.getLineIn(Minim.MONO);
      //inputMono.enableMonitoring();
      selectedInput = inputMono.mix;
    }
    if (input == "LINEIN") {
      if (inputMono != null) inputMono.close();
      //minim.stop();
      inputMono = minim.getLineIn(Minim.STEREO);
      //inputStereo.enableMonitoring();
      selectedInput = inputMono.mix;
    }
    if (input == "FILE") {
      selectedInput = inputFile.mix;
    selectedInputString = input;

    }
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

    fft.forward(selectedInput);

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
      fill(255);
      textSize(25);
      textAlign(LEFT);
      text(round(frameRate), 20, 30);
      textAlign(CENTER);
      text("maxVal: " + round(maxVal), width/2, 30);
      textAlign(LEFT);
      String s = "selected input: " + selectedInputString;
      text(s, width-textWidth(s)-10, 30);
      String mon = "off";
      //if ( inputMono.isMonitoring() || inputStereo.isMonitoring() ) mon = "on";
      text("monitoring: " + mon, width-textWidth(s)-10, 60);
      popStyle();
    }
  }
}

void exit() {
  //might not be necessary
  println("called exit()");
  if (fAnalyzer.inputFile != null) fAnalyzer.inputFile.close();
  fAnalyzer.minim.stop();
  super.exit();//let processing carry with it's regular exit routine
}
