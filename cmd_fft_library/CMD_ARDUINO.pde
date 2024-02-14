/*
  This ArduinoControls class is used at the Institute of Arts Maastricht exposition, semester Generative Art
 Students build their own Arduino remote controller with 3 potentiometers and 3 pushbuttons.
 This library simplifies the use for these controls. It adds functionality like:
 - executing single commands when longpressing getPushButtonOnce(0);
 - multiple pushbuttons being pressed if (getPushButton(0) && getPushButton(1))
 - smooth analog potmeter values getPotmeter(0,0.02);
 - fallback to keyboard and mouse when not using arduino. 1 to 9 for pushbuttons. q,w,e,r,t,y together with mouseX for potmeters
 */
import java.util.Collections;

public class ArduinoControls {



  // this.parent is a reference to the parent sketch
  PApplet parent;

  Arduino arduino;
  boolean enableArduino;
  boolean enableKeypress = false;

  PGraphics overlay;
  int[] digitalPortsUsed;
  int[] analogPortsUsed;
  ArrayList <Boolean> inputButtons = new ArrayList<Boolean>();
  ArrayList <Boolean> inputButtonsOnce = new ArrayList<Boolean>();
  ArrayList <Boolean> inputButtonsActionTaken = new ArrayList<Boolean>();
  ArrayList <Integer> inputPotmeters = new ArrayList<Integer>();
  ArrayList <Float> inputPotmetersSmooth = new ArrayList<Float>();

  // some buttons return a LOW value when pressed
  // if you're using these buttons set this variable to false
  boolean pushButtonHighWhenPressed = true;


  int lastFrameCount = -1;
  Integer[] infoPanelLocation = {0, 0, 0, 0}; //x, y, w, h
  boolean showInfoPanel = false;
  char infoPanelKey = 'i';

  ArduinoControls(PApplet parent, Arduino a, int[] digitalPorts, int[] analogPorts, boolean enableArduino) {
    this.arduino = a;
    this.enableArduino = enableArduino;
    this.digitalPortsUsed = digitalPorts;
    for (int i=0; i<digitalPorts.length; i++) {
      this.inputButtons.add(false);
      this.inputButtonsOnce.add(false);
      this.inputButtonsActionTaken.add(false);
    }
    this.analogPortsUsed = analogPorts;
    for (int i=0; i<analogPorts.length; i++) {
      this.inputPotmeters.add(0);
      this.inputPotmetersSmooth.add(0.0);
    }
    this.parent = parent;

    parent.registerMethod("draw", this);
    parent.registerMethod("post", this);
    this.parent.registerMethod("keyEvent", this);

    infoPanelLocation[2] = this.parent.width;
    infoPanelLocation[3] = 100;
    this.overlay = this.parent.createGraphics(infoPanelLocation[2], infoPanelLocation[3]);
  }

  public float getPotmeter(int index) {
    return this.getPotmeter(index, 1.0);
  }

  public float getPotmeter(int index, float smoothness) {
    //the default returnvalue is based on the inputPotmeters array, which is also controlled with mouseX and "qwerty" keys
    float returnValue = this.inputPotmeters.get(index);
    if (this.enableArduino) {

      this.inputPotmeters.set(index, this.arduino.analogRead(this.analogPortsUsed[index]));
      returnValue = this.inputPotmeters.get(index);

      //if we don't handle the raw input seperately (when calling getPotmeter(index, 1.0)), every additional call to getPotmeter removes the previous smoothness
      if (smoothness < 1.0) {
        this.inputPotmetersSmooth.set(index, lerp(this.inputPotmetersSmooth.get(index), this.inputPotmeters.get(index), smoothness));
        returnValue = this.inputPotmetersSmooth.get(index);
      }
    }
    return constrain(map(returnValue, 0, 1023, 0, 1), 0, 1);
  }

  public boolean getPushButtonOnce(int index) {
    return this.getPushButton(index, true);
  }

  public boolean getPushButton(int index) {
    return this.getPushButton(index, false);
  }

  private boolean getPushButton(int index, boolean once) {
    if (this.enableArduino) {
      if (this.arduino.digitalRead(this.digitalPortsUsed[index]) == (this.pushButtonHighWhenPressed ? Arduino.HIGH : Arduino.LOW) && this.inputButtonsActionTaken.get(index) == false) {
        this.inputButtonsActionTaken.set(index, true);
        this.inputButtons.set(index, true);
        this.inputButtonsOnce.set(index, true);
        this.lastFrameCount = this.parent.frameCount;
      }
      if (this.arduino.digitalRead(this.digitalPortsUsed[index]) == (this.pushButtonHighWhenPressed ? Arduino.LOW : Arduino.HIGH)) {
        this.inputButtonsActionTaken.set(index, false);
        this.inputButtons.set(index, false);
      }
    }
    if (once) return this.inputButtonsOnce.get(index);
    else return this.inputButtons.get(index);
  }


  public void keyEvent(KeyEvent event) {
    if (this.enableKeypress) {
    // Removed KeyEvent.TYPE because p2d or p3d don't register TYPE
    if (event.getAction() == KeyEvent.PRESS) this.onKeyPress(event);
    else if (event.getAction() == KeyEvent.RELEASE) this.onKeyRelease(event);
    }
  }


  private void onKeyPress(KeyEvent event) {

    //handle long press events, only works in default renderer, not in P2D or P3D
    //if in P2D or P3D mode, quick-tap the q,w or e button to get the correct mouseX value
    for (int i=0; i<this.inputPotmeters.size(); i++) {
      char mappedKey = "qwerty".toCharArray()[i];
      if (event.getKey() == mappedKey ) this.inputPotmeters.set(i, constrain(int(map(this.parent.mouseX, 0, width, 0, 1023)), 0, 1023));
    }

    for (int i=0; i<this.inputButtons.size(); i++) {
      //(char) ('0' + (i+1)) correctly converts keyboard 1,2,3 to chars '1','2' etc
      if (event.getKey()== (char) ('0' + (i+1)) && this.inputButtons.get(i) == false) {
        this.inputButtons.set(i, true);
      }
      if (event.getKey()== (char) ('0' + (i+1)) && this.inputButtonsActionTaken.get(i) == false) {
        this.inputButtonsActionTaken.set(i, true);
        this.inputButtonsOnce.set(i, true);
        this.lastFrameCount = this.parent.frameCount;
      }
    }
    
    if (event.getKey()==this.infoPanelKey) {
      this.showInfoPanel = !this.showInfoPanel;
    }
  }

  private void onKeyRelease(KeyEvent event) {
    // Reset the flag when the key is released, allowing for the action to be taken on the next key press
    char keyChar = event.getKey();
    if (Character.isDigit(keyChar)) {
      int keyValue = keyChar - '0';
      if (keyValue <= this.inputButtons.size() && keyValue > 0) {
        this.inputButtonsActionTaken.set((keyValue-1), false);
        this.inputButtons.set((keyValue-1), false);
      }
    }
  }

  public void setInfoPanel(int x, int y, int w, int h) {
    this.infoPanelLocation[0] = x;
    this.infoPanelLocation[1] = y;
    this.infoPanelLocation[2] = w;
    this.infoPanelLocation[3] = h;

    this.overlay = this.parent.createGraphics(w, h);
  }

  public void draw() {
    if (this.showInfoPanel) {
      boolean portrait = this.infoPanelLocation[2] < this.infoPanelLocation[3];

      this.overlay.beginDraw();
      this.overlay.background(0, 200);
      this.overlay.noStroke();
      this.overlay.fill(255);
      if (portrait) {
        for (int i=0; i<this.inputButtons.size(); i++) this.overlay.text("getButton("+i+ "): " + this.getPushButton(i), 5, 15+i*20);
        for (int i=0; i<this.inputPotmeters.size(); i++) this.overlay.text("getPotmeter("+i+ "): " + nf(this.getPotmeter(i), 0, 2), 5, 115+i*20);
      } else {
        for (int i=0; i<this.inputButtons.size(); i++) this.overlay.text("getButton("+i+ "): " + this.getPushButton(i), 5, 15+i*20);
        for (int i=0; i<this.inputPotmeters.size(); i++) this.overlay.text("getPotmeter("+i+ "): " + nf(this.getPotmeter(i), 0, 2), 185, 15+i*20);
      }

      this.overlay.endDraw();

      this.parent.image(this.overlay, this.infoPanelLocation[0], this.infoPanelLocation[1], this.infoPanelLocation[2], this.infoPanelLocation[3]); // Draw the overlay onto the main canvas
    }
  }

  public void post() {
    // https://github.com/benfry/processing4/wiki/Library-Basics
    // you cant draw in post() but its perfect for resetting the inputButtonsOnce array:
    if (this.parent.frameCount != this.lastFrameCount) Collections.fill(this.inputButtonsOnce, Boolean.FALSE);
  }
}
