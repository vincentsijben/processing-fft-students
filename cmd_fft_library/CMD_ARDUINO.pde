/*
  This ArduinoControls class is used at the Institute of Arts Maastricht exposition, semester Generative Art
 Students build their own Arduino remote controller with 3 potentiometers and 3 pushbuttons.
 Digital ports 6, 7 and 8 are used for the pushbuttons. Analog ports A0, A1 and A2 are used for the potentiometers.
 */
import java.util.Collections;

public class ArduinoControls {

 
  
  // this.parent is a reference to the parent sketch
  PApplet parent;

  Arduino arduino;
  

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
  boolean showInfo = false;
  boolean keyPressedActionTaken = false; // Flag to track if the action for a key press has been taken

  ArduinoControls(PApplet parent, Arduino a, int[] digitalPorts, int[] analogPorts) {
    this.arduino = a;
    this.digitalPortsUsed = digitalPorts;
    for (int i=0; i<digitalPorts.length; i++) {
      inputButtons.add(false);
      inputButtonsOnce.add(false);
      inputButtonsActionTaken.add(false);
    }
    this.analogPortsUsed = analogPorts;
    for (int i=0; i<analogPorts.length; i++) {
      inputPotmeters.add(0);
      inputPotmetersSmooth.add(0.0);
    }
    this.parent = parent;
    this.overlay = parent.createGraphics(parent.width, 100);
    parent.registerMethod("draw", this);
    parent.registerMethod("post", this);
    if (!enableArduino) this.parent.registerMethod("keyEvent", this);
  }

  float getPotmeter(int index) {
    return getPotmeter(index, 1.0);
  }

  float getPotmeter(int index, float smoothness) {
    //the default returnvalue is based on the inputPotmeters array, which is also controlled with mouseX and "qwerty" keys
    float returnValue = inputPotmeters.get(index);  
    if (enableArduino) {
      if (smoothness < 1) {
        inputPotmeters.set(index, this.arduino.analogRead(analogPortsUsed[index]));
        inputPotmetersSmooth.set(index, lerp(inputPotmetersSmooth.get(index), inputPotmeters.get(index), smoothness));
        returnValue = inputPotmetersSmooth.get(index);
      } else {
        //if we don't handle the raw input seperately (when calling getPotmeter(index, 1.0)), every additional call to getPotmeter removes the previous smoothness
        inputPotmeters.set(index, this.arduino.analogRead(analogPortsUsed[index]));
        returnValue = inputPotmeters.get(index);
      }
    } 
    return constrain(map(returnValue, 0, 1023, 0, 1), 0, 1);
  }
  
  boolean getPushButton(int index) {
    return getPushButton(index,false);
  }
  
  boolean getPushButton(int index, boolean once) {
    if (enableArduino) {
      if (this.arduino.digitalRead(digitalPortsUsed[index]) == (pushButtonHighWhenPressed ? Arduino.HIGH : Arduino.LOW) && inputButtonsActionTaken.get(index) == false) {
        inputButtonsActionTaken.set(index, true);
        inputButtons.set(index, true);
        inputButtonsOnce.set(index, true);
        this.lastFrameCount = parent.frameCount;
      }
      if (this.arduino.digitalRead(digitalPortsUsed[index]) == (pushButtonHighWhenPressed ? Arduino.LOW : Arduino.HIGH)) {
        inputButtonsActionTaken.set(index, false);
        inputButtons.set(index, false);
      }
    }
    if (once) return inputButtonsOnce.get(index);
    else return inputButtons.get(index);
  }


  public void keyEvent(KeyEvent event) {
    // Removed KeyEvent.TYPE because p2d or p3d don't register TYPE
    if (event.getAction() == KeyEvent.PRESS) this.onKeyPress(event);
    else if (event.getAction() == KeyEvent.RELEASE) this.onKeyRelease(event);
  }


  private void onKeyPress(KeyEvent event) {

    //handle long press events, only works in default renderer, not in P2D or P3D
    //if in P2D or P3D mode, quick-tap the q,w or e button to get the correct mouseX value
    for (int i=0; i<this.inputPotmeters.size(); i++) {
      char mappedKey = "qwerty".toCharArray()[i];
      if (event.getKey() == mappedKey ) inputPotmeters.set(i, constrain(int(map(mouseX, 0, width, 0, 1023)), 0, 1023));
    }

    for (int i=0; i<this.inputButtons.size(); i++) {
      //(char) ('0' + (i+1)) correctly converts keyboard 1,2,3 to chars '1','2' etc
      if (event.getKey()== (char) ('0' + (i+1)) && inputButtons.get(i) == false) {
        
        inputButtons.set(i, true);
      }
      if (event.getKey()== (char) ('0' + (i+1)) && inputButtonsActionTaken.get(i) == false) {
        inputButtonsActionTaken.set(i, true);
        inputButtonsOnce.set(i, true);
        this.lastFrameCount = parent.frameCount;
        
      }
    }
  }

  private void onKeyRelease(KeyEvent event) {
    // Reset the flag when the key is released, allowing for the action to be taken on the next key press
    char keyChar = event.getKey();
    if (Character.isDigit(keyChar)) {
      int keyValue = keyChar - '0';
      if (keyValue <= inputButtons.size() && keyValue > 0) {
        inputButtonsActionTaken.set((keyValue-1), false);
        inputButtons.set((keyValue-1), false);
      }
    }
  }

  public void draw() {
    if (this.showInfo) {
      this.overlay.beginDraw();
      this.overlay.background(0, 200);
      this.overlay.noStroke();
      this.overlay.fill(255);
      for (int i=0; i<this.inputButtons.size(); i++) this.overlay.text("getButton("+i+ "): " + this.getPushButton(i), 5, 15+i*20);
      for (int i=0; i<this.inputPotmeters.size(); i++) this.overlay.text("getPotmeter("+i+ "): " + nf(this.getPotmeter(i), 0, 2), 185, 15+i*20);
      this.overlay.endDraw();
      image(this.overlay, 0, this.parent.height-100); // Draw the overlay onto the main canvas
    }
  }

  public void post() {
    // https://github.com/benfry/processing4/wiki/Library-Basics
    // you cant draw in post() but its perfect for resetting the inputButtonsOnce array:
    if (parent.frameCount != this.lastFrameCount) Collections.fill(this.inputButtonsOnce, Boolean.FALSE);
  }
}
