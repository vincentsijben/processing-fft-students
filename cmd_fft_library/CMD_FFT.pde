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
  //float startTime = 0;
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
    parent.registerMethod("post", this);
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

  //void resetMaxValue(float duration) {
  //  if (millis() - this.startTime > duration) {
  //    this.maxVal = 1;
  //    startTime = millis();
  //  }
  //}


  void setInput(String i) {

    // Always close the input when changing inputs. After testing in Windows, I couldn't get multiple input variables running at the same time.
    // Monitoring of inputLineIn is disabled by default when calling setInput again
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

  public void draw() {
    if (this.showInfo) {
      this.overlay.beginDraw();
      this.overlay.fill(200, 127);
      this.overlay.noStroke();
      this.overlay.rect(0, 0, this.overlay.width, this.overlay.height);
      for (int i = 0; i < this.bands; i++) {
        float xR = (i * this.overlay.width) / this.bands;
        float yR = 100;

        this.overlay.fill(255);
        this.overlay.rect(xR, yR, this.overlay.width / this.bands, PApplet.lerp(0, -100, this.getAvg(i)));
        this.overlay.fill(255, 0, 0);
        this.overlay.textAlign(CENTER, CENTER);
        this.overlay.textSize(14);
        this.overlay.text(round(lerp(0, maxVal, this.getAvg(i))), xR + (this.overlay.width / this.bands / 2), yR - 20);
        this.overlay.textSize(8);
        this.overlay.text(i, xR + (this.overlay.width / this.bands / 2), yR-6);
      }
      this.overlay.fill(255);
      this.overlay.textSize(25);
      this.overlay.textAlign(LEFT);
      this.overlay.text(round(this.parent.frameRate), 20, 30);
      this.overlay.textAlign(CENTER);
      this.overlay.text("maxVal: " + round(maxVal), this.parent.width/2, 30);
      this.overlay.textAlign(LEFT);
      String s = "selected input: " + selectedInputString;
      float posX = this.overlay.width-this.overlay.textWidth(s)-10;
      this.overlay.text(s, posX, 30);
      if (selectedInputString == "FILE" && inputFile != null) this.overlay.text("muted: " + inputFile.isMuted(), posX, 60);
      else this.overlay.text("monitoring: " + (inputLineIn.isMonitoring() ? "on": "off"), posX, 60);
      this.overlay.endDraw();
      image(this.overlay, 0, 0); // Draw the overlay onto the main canvas
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
  
  public void post(){
    // https://github.com/benfry/processing4/wiki/Library-Basics
    // you cant draw in post() but its perfect for the fft analysis:
    fft.forward(this.selectedInput);
    //determine max value to normalize all average values
    for (int i = 0; i < fft.avgSize(); i++) if (fft.getAvg(i) > this.maxVal) this.maxVal = fft.getAvg(i);

  }

  void debug() {
    System.out.println("Your OS name -> " + System.getProperty("os.name"));
    System.out.println("Your OS version -> " + System.getProperty("os.version"));
    System.out.println("Your OS Architecture -> " + System.getProperty("os.arch"));
    if (minim != null) {
      println("MONO -> " + minim.getLineIn(Minim.MONO));
      println("STEREO -> " + minim.getLineIn(Minim.STEREO));
    }
  }

  public void dispose() {
    //might not be necessary, but just in case
    if (this.inputFile != null) this.inputFile.close();
    this.minim.stop();
  }
}
