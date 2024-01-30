class FrequencyAnalyzer {

  // myParent is a reference to the parent sketch
  PApplet myParent;

  Minim minim;
  AudioPlayer inputFile;
  AudioInput inputLineIn;
  AudioBuffer selectedInput;
  FFT fft;
  int bands = 30;
  String selectedInputString;
  boolean enableKeyPresses = false;
  boolean showInfo = false;
  float maxVal = 0.000001; //avoid NaN when using maxVal in map() in the first frame.

  FrequencyAnalyzer(PApplet p) {
    this(p, 3);
  }

  FrequencyAnalyzer(PApplet p, int bandsPerOctave) {
    myParent = p;
    bands = bandsPerOctave * 10;
    minim = new Minim(p);

    //default input
    //in MacOS getLineIn always refers to the selected AUDIO IN device in the sound panel
    inputLineIn = minim.getLineIn(Minim.MONO);
    selectedInput = inputLineIn.mix;
    selectedInputString = "MONO";

    fft = new FFT(inputLineIn.bufferSize(), inputLineIn.sampleRate());
    //fft = new FFT(1024, 44100.0); //always 1024 and 44100.0??
    fft.logAverages(22, bandsPerOctave); // 3 results in 30 bands. 1 results in 10 etc.
  }

  public void enableKeyPresses() {
    enableKeyPresses = true;
  }

  void setFile(String file) {
    inputFile = minim.loadFile(file);
    inputFile.play();
    inputFile.mute();
  }

  void toggleMuteOrMonitoring() {
    if (selectedInputString=="FILE") {
      if (inputFile != null) {
        if (inputFile.isMuted()) inputFile.unmute();
        else inputFile.mute();
      }
    } else {
      if (inputLineIn.isMonitoring()) inputLineIn.disableMonitoring();
      else inputLineIn.enableMonitoring();
    }
  }


  void setInput(String i) {

    //always close the input. After testing in Windows, I couldn't get multiple input variables running at the same time
    //monitoring of inputLineIn is always disabled when calling setInput (because I assign a new getLineIn and the default is disabled monitoring)
    inputLineIn.close();
    //always mute the playing file, unmute it only when user chooses FILE input
    inputFile.mute();

    if (i == "MONO") {
      inputLineIn = minim.getLineIn(Minim.MONO);
      selectedInput = inputLineIn.mix;
    }
    if (i == "STEREO") {
      inputLineIn = minim.getLineIn(Minim.STEREO);
      selectedInput = inputLineIn.mix;
    }
    if (i == "FILE") {
      if (inputFile == null) {
        println("no call to setFile(), reverting back to MONO");
        setInput("MONO");
        return;
      } else {
        selectedInput = inputFile.mix;
        inputFile.unmute();
      }
    }
    //reset the maxVal after each input switch
    fAnalyzer.maxVal = 0.000001;
    selectedInputString = i;
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

    checkKeyPress();
    showInfo();
  }

  public void showInfo() {
    if (showInfo) {
      pushStyle();
      fill(200, 127);
      noStroke();
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
      if (selectedInputString == "FILE" && inputFile != null) {
        text("muted: " + inputFile.isMuted(), width-textWidth(s)-10, 60);
      } else {
        String mon = "off";
        if ( inputLineIn.isMonitoring()) mon = "on";
        text("monitoring: " + mon, width-textWidth(s)-10, 60);
      }

      popStyle();
    }
  }

  void checkKeyPress() {
    if (enableKeyPresses && myParent.keyPressed) {
      myParent.keyPressed = false; //don't allow the key to be 'longpressed' immediately
      if (myParent.key == '1') fAnalyzer.setInput("FILE");
      if (myParent.key == '2') fAnalyzer.setInput("MONO");
      if (myParent.key == '3') fAnalyzer.setInput("STEREO");
      if (myParent.key == '4') fAnalyzer.toggleMuteOrMonitoring();
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
