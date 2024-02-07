//https://github.com/benfry/processing4/wiki/Library-Basics
public class FrequencyAnalyzer {

  // this.parent is a reference to the parent sketch
  PApplet parent;

  Minim minim;
  AudioPlayer inputFile;
  AudioInput inputLineIn;
  AudioBuffer selectedInput;
  FFT fft;
  int bands = 30;
  String selectedInputString;
  boolean showInfo = false;
  float maxVal = 0.000001; //avoid NaN when using maxVal in map() in the first frame.
  boolean keyPressedActionTaken = false; // Flag to track if the action for a key press has been taken
  PGraphics overlay;

  FrequencyAnalyzer(PApplet parent) {
    this(parent, 3);
  }

  FrequencyAnalyzer(PApplet parent, int bandsPerOctave) {
    this.parent = parent;
    this.bands = bandsPerOctave * 10;
    this.minim = new Minim(parent);
    this.overlay = parent.createGraphics(parent.width, 100);
    parent.registerMethod("draw", this);
    parent.registerMethod("dispose", this);

    //default input
    //in MacOS getLineIn always refers to the selected AUDIO IN device in the sound panel
    //tested in Sonoma 14.2

    this.inputLineIn = minim.getLineIn(Minim.MONO);
    this.selectedInput = inputLineIn.mix;
    this.selectedInputString = "MONO";

    fft = new FFT(this.inputLineIn.bufferSize(), this.inputLineIn.sampleRate());
    //fft = new FFT(1024, 44100.0); //always 1024 and 44100.0??
    fft.logAverages(22, bandsPerOctave); // 3 results in 30 bands. 1 results in 10 etc.
   
  }



  void setFile(String file) {
    this.inputFile = minim.loadFile(file);
    this.inputFile.play();
    this.inputFile.mute();
  }

  void toggleMuteOrMonitoring() {
    if (this.selectedInputString=="FILE") {
      if (this.inputFile != null) {
        if (this.inputFile.isMuted()) this.inputFile.unmute();
        else this.inputFile.mute();
      }
    } else {
      if (this.inputLineIn.isMonitoring()) this.inputLineIn.disableMonitoring();
      else this.inputLineIn.enableMonitoring();
    }
  }


  void setInput(String i) {

    //always close the input. After testing in Windows, I couldn't get multiple input variables running at the same time
    //monitoring of inputLineIn is always disabled when calling setInput (because I assign a new getLineIn and the default is disabled monitoring)
    this.inputLineIn.close();
    //always mute the playing file, unmute it only when user chooses FILE input
    if (this.inputFile != null) this.inputFile.mute();

    if (i == "MONO") {
      this.inputLineIn = minim.getLineIn(Minim.MONO);
      this.selectedInput = this.inputLineIn.mix;
    }
    if (i == "STEREO") {
      this.inputLineIn = minim.getLineIn(Minim.STEREO);
      this.selectedInput = this.inputLineIn.mix;
    }
    if (i == "FILE") {
      if (this.inputFile == null) {
        println("no call to setFile(), reverting back to MONO");
        this.setInput("MONO");
        return;
      } else {
        this.selectedInput = this.inputFile.mix;
        this.inputFile.unmute();
      }
    }
    //reset the maxVal after each input switch
    this.maxVal = 0.000001;
    this.selectedInputString = i;
  }

  //normalize the average for the given index
  float getAvg(int index) {
    return map(fft.getAvg(index), 0, this.maxVal, 0, 1);
  }

  //set a new max value for the given index and constrain the result between 0 and 1
  float getAvg(int index, float max) {
    return constrain(map(fft.getAvg(index), 0, max, 0, 1), 0, 1);
  }

  void run() {

    fft.forward(this.selectedInput);
    //determine max value to normalize all average values
    for (int i = 0; i < fft.avgSize(); i++) if (fft.getAvg(i) > this.maxVal) this.maxVal = fft.getAvg(i);
  }

  public void draw() {
    if (showInfo) {
      overlay.beginDraw();
      overlay.fill(200, 127);
      overlay.noStroke();
      overlay.rect(0, 0, overlay.width, overlay.height);
      for (int i = 0; i < this.bands; i++) {
        float xR = (i * overlay.width) / bands;
        float yR = 100;

        overlay.fill(255);
        overlay.rect(xR, yR, overlay.width / bands, lerp(0, -100, this.getAvg(i)));
        overlay.fill(255, 0, 0);
        overlay.textAlign(CENTER, CENTER);
        overlay.textSize(14);
        overlay.text(round(lerp(0, maxVal, this.getAvg(i))), xR + (overlay.width / bands / 2), yR - 20);
        overlay.textSize(8);
        overlay.text(i, xR + (overlay.width / bands / 2), yR-6);
      }
      overlay.fill(255);
      overlay.textSize(25);
      overlay.textAlign(LEFT);
      overlay.text(round(this.parent.frameRate), 20, 30);
      overlay.textAlign(CENTER);
      overlay.text("maxVal: " + round(maxVal), this.parent.width/2, 30);
      overlay.textAlign(LEFT);
      String s = "selected input: " + selectedInputString;
      float posX = overlay.width-overlay.textWidth(s)-10;
      overlay.text(s, posX, 30);
      if (selectedInputString == "FILE" && inputFile != null) overlay.text("muted: " + inputFile.isMuted(), posX, 60);
      else overlay.text("monitoring: " + (inputLineIn.isMonitoring() ? "on": "off"), posX, 60);
      overlay.endDraw();
      image(overlay, 0, 0); // Draw the overlay onto the main canvas
    }
  }

  public void enableKeyPresses() {
    this.parent.registerMethod("keyEvent", this);
  }

  public void keyEvent(KeyEvent event) {
    // Removed KeyEvent.TYPE because p2d or p3d don't register TYPE
    if (event.getAction() == KeyEvent.PRESS) this.onKeyPress(event);
    else if (event.getAction() == KeyEvent.RELEASE) this.onKeyRelease(event);
  }

  private void onKeyPress(KeyEvent event) {

    if (event.isControlDown()) {

      //handle long press events, only works in default renderer, not in P2D or P3D
      if (event.getKey() == '0' ) println("CTRL+0 is longpressed");

      // handle single press events
      if (event.getKey() == '1' && !this.keyPressedActionTaken) {
        this.setInput("FILE");
        this.keyPressedActionTaken = true; // Set the flag to true to avoid repeating the action
      }
      if (event.getKey() == '2'  && !this.keyPressedActionTaken) {
        this.setInput("MONO");
        this.keyPressedActionTaken = true; // Set the flag to true to avoid repeating the action
      }
      if (event.getKey() == '3'  && !this.keyPressedActionTaken) {
        this.setInput("STEREO");
        this.keyPressedActionTaken = true; // Set the flag to true to avoid repeating the action
      }
      if (event.getKeyCode() == 'M' && !this.keyPressedActionTaken) {
        this.toggleMuteOrMonitoring();
        this.keyPressedActionTaken = true; // Set the flag to true to avoid repeating the action
      }
      if (event.getKeyCode() == 'I' && !this.keyPressedActionTaken) {
        this.showInfo = !this.showInfo;
        this.keyPressedActionTaken = true; // Set the flag to true to avoid repeating the action
      }
    }
  }

  private void onKeyRelease(KeyEvent event) {
    // Reset the flag when the key is released, allowing for the action to be taken on the next key press
    this.keyPressedActionTaken = false;
  }

  public void dispose() {
    //might not be necessary, but just in case
    if (this.inputFile != null) this.inputFile.close();
    this.minim.stop();
  }
}
