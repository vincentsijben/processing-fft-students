/*
  This ArduinoControls class is used at the Institute of Arts Maastricht exposition, semester Generative Art
 Students build their own Arduino remote controller with 3 potentiometers and 3 pushbuttons.
 This library simplifies the use for these controls. It adds functionality like:
 - executing single commands when longpressing getPushButtonOnce(0);
 - multiple pushbuttons being pressed if (getPushButton(0) && getPushButton(1))
 - smooth analog potmeter values getPotmeter(0,0.02); reducing jumping values
 - fallback to keyboard and mouse when not using arduino. 1 to 9 for pushbuttons. q,w,e,r,t,y together with mouseX for potmeters
 - adjustable infopanel (set hotkey, size, location)
 */


public class PushButton {
  private int signalPressed; // when pressed, does the button return Arduino.HIGH or Arduino.LOW
  private int digitalPort;
  private boolean pressed;
  private boolean pressedOnce;
  private boolean actionTaken;

  public PushButton(int digitalPort, int signalPressed) {
    this.signalPressed = signalPressed;
    this.digitalPort = digitalPort;
    this.pressed = false;
    this.pressedOnce = false;
    this.actionTaken = false;
  }
}

public class Potentiometer {
  private float value;
  private float smoothValue;
  private int analogPort;
  private int minValue;
  private int maxValue;

  public Potentiometer(int analogPort) {
    this(analogPort, 0, 1023);
  }

  public Potentiometer(int analogPort, int minValue, int maxValue) {
    this.analogPort = analogPort;
    this.minValue = minValue;
    this.maxValue = maxValue;
  }
}

public class ArduinoControls {

  // this.parent is a reference to the parent sketch
  PApplet parent;

  Arduino arduino;
  boolean enableArduino = false;
  boolean enableKeypress = false;

  PGraphics overlay;
  ArrayList <PushButton> pushbuttons;
  ArrayList <Potentiometer> potmeters;


  // some buttons return a LOW value when pressed
  // if you're using these buttons set this variable to false
  //boolean pushButtonHighWhenPressed = false;


  int lastFrameCount = -1;
  boolean keyPressedActionTaken = false; // Flag to track if the action for a key press has been taken
  Integer[] infoPanelLocation = {0, 0, 0, 0}; //x, y, w, h
  boolean showInfoPanel = false;
  char infoPanelKey = 'o';

  ArduinoControls(PApplet parent, Arduino a, ArrayList <PushButton> pushbuttons, ArrayList <Potentiometer> potmeters, boolean enableArduino) {
    this.arduino = a;
    this.enableArduino = enableArduino;
    this.pushbuttons = pushbuttons;
    this.potmeters = potmeters;
    this.parent = parent;

    parent.registerMethod("draw", this);
    parent.registerMethod("post", this);
    parent.registerMethod("keyEvent", this);

    infoPanelLocation[2] = parent.width;
    infoPanelLocation[3] = 100;
    this.overlay = parent.createGraphics(infoPanelLocation[2], infoPanelLocation[3]);
  }

  public float getPotmeter(int index) {
    return this.getPotmeter(index, 1.0);
  }

  public float getPotmeter(int index, float smoothness) {
    //the default returnvalue is based on the inputPotmeters array, which is also controlled with mouseX and "qwerty" keys
    float returnValue = this.potmeters.get(index).value;
    if (this.enableArduino) {
      this.potmeters.get(index).value = this.arduino.analogRead(this.potmeters.get(index).analogPort);
      returnValue = this.potmeters.get(index).value;

      //if we don't handle the raw input seperately (when calling getPotmeter(index, 1.0)), every additional call to getPotmeter removes the previous smoothness
      if (smoothness < 1.0) {
        this.potmeters.get(index).smoothValue = lerp(this.potmeters.get(index).smoothValue, this.potmeters.get(index).value, smoothness);
        returnValue = this.potmeters.get(index).smoothValue;
      }
    }
    return constrain(map(returnValue, this.potmeters.get(index).minValue, this.potmeters.get(index).maxValue, 0, 1), 0, 1);
  }

  public boolean getPushButtonOnce(int index) {
    return this.getPushButton(index, true);
  }

  public boolean getPushButton(int index) {
    return this.getPushButton(index, false);
  }

  private boolean getPushButton(int index, boolean once) {
    if (this.enableArduino) {
      int port = this.pushbuttons.get(index).digitalPort;
      int highWhenPressed = this.pushbuttons.get(index).signalPressed;
      boolean actionTaken = this.pushbuttons.get(index).actionTaken;
      if (this.arduino.digitalRead(port) == highWhenPressed && actionTaken == false) {
        this.pushbuttons.get(index).actionTaken = true;
        this.pushbuttons.get(index).pressed = true;
        this.pushbuttons.get(index).pressedOnce = true;
        this.lastFrameCount = this.parent.frameCount;
      }
      if (this.arduino.digitalRead(port) != highWhenPressed) {
        this.pushbuttons.get(index).actionTaken = false;
        this.pushbuttons.get(index).pressed = false;
      }
    }
    return once ? this.pushbuttons.get(index).pressedOnce : this.pushbuttons.get(index).pressed;
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
    for (int i=0; i<this.potmeters.size(); i++) {
      char mappedKey = "qwerty".toCharArray()[i];
      if (event.getKey() == mappedKey ) this.potmeters.get(i).value = constrain(int(map(this.parent.mouseX, 0, width, this.potmeters.get(i).minValue, this.potmeters.get(i).maxValue)), this.potmeters.get(i).minValue, this.potmeters.get(i).maxValue);
    }

    for (int i=0; i<this.pushbuttons.size(); i++) {
      //(char) ('0' + (i+1)) correctly converts keyboard 1,2,3 to chars '1','2' etc
      /*
      CHECK IF THESE TO IFS CAN BE COMBINED
       */
      if (event.getKey()== (char) ('0' + (i+1)) && this.pushbuttons.get(i).pressed == false) {
        this.pushbuttons.get(i).pressed = true;
      }
      if (event.getKey()== (char) ('0' + (i+1)) && this.pushbuttons.get(i).actionTaken == false) {
        this.pushbuttons.get(i).actionTaken = true;
        this.pushbuttons.get(i).pressedOnce = true;
        this.lastFrameCount = this.parent.frameCount;
      }
    }

    if (event.getKey()==this.infoPanelKey && !this.keyPressedActionTaken) {
      this.showInfoPanel = !this.showInfoPanel;
      this.keyPressedActionTaken = true; // Set the flag to true to avoid repeating the action
    }
  }

  private void onKeyRelease(KeyEvent event) {
    // Reset the flag when the key is released, allowing for the action to be taken on the next key press
    char keyChar = event.getKey();
    if (Character.isDigit(keyChar)) {
      int keyValue = keyChar - '0';
      if (keyValue <= this.pushbuttons.size() && keyValue > 0) {
        //this.inputButtonsActionTaken.set((keyValue-1), false);
        this.pushbuttons.get((keyValue-1)).actionTaken = false;
        this.pushbuttons.get((keyValue-1)).pressed = false;
        //this.inputButtons.set((keyValue-1), false);
      }
    }
    // Reset the flag when the key is released, allowing for the action to be taken on the next key press
    this.keyPressedActionTaken = false;
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
        for (int i=0; i<this.pushbuttons.size(); i++) this.overlay.text("getButton("+i+ "): " + this.getPushButton(i), 5, 15+i*20);
        for (int i=0; i<this.potmeters.size(); i++) this.overlay.text("getPotmeter("+i+ "): " + nf(this.getPotmeter(i), 0, 2) + " raw: " + this.potmeters.get(i).value, 5, 115+i*20);
      } else {
        for (int i=0; i<this.pushbuttons.size(); i++) this.overlay.text("getButton("+i+ "): " + this.getPushButton(i), 5, 15+i*20);
        for (int i=0; i<this.potmeters.size(); i++) this.overlay.text("getPotmeter("+i+ "): " + nf(this.getPotmeter(i), 0, 2) + " raw: " + this.potmeters.get(i).value, 185, 15+i*20);
      }

      this.overlay.endDraw();

      this.parent.image(this.overlay, this.infoPanelLocation[0], this.infoPanelLocation[1], this.infoPanelLocation[2], this.infoPanelLocation[3]); // Draw the overlay onto the main canvas
    }
  }

  public void post() {
    // https://github.com/benfry/processing4/wiki/Library-Basics
    // you cant draw in post() but its perfect for resetting the inputButtonsOnce array:
    if (this.parent.frameCount != this.lastFrameCount) {

      for (PushButton button : pushbuttons) {
        button.pressedOnce = false;
      }
    }
  }
}
