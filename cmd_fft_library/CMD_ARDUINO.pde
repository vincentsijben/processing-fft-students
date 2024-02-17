/*
  This ArduinoControls class is used at the Institute of Arts Maastricht exposition, semester Generative Art
 Students build their own Arduino remote controller with 3 potentiometers and 3 pushbuttons.
 This library simplifies the use for these controls. It adds functionality like:
 - executing single commands when longpressing getPushButtonOnce(0);
 - multiple pushbuttons being pressed if (getPushButton(0) && getPushButton(1))
 - smooth analog potmeter values getPotmeter(0,0.02); reducing jumping values
 - fallback to keyboard and mouse when not using arduino. e.g. 1 to 9 for pushbuttons. q,w,e,r,t,y together with mouseX for potmeters
 - adjustable infopanel (set hotkey, size, location)
 */

public class LED {
  private int digitalPort;
  private boolean pwm;
  private int value;

  public LED(int digitalPort) {
    this.digitalPort = digitalPort;
    this.pwm = Boolean.FALSE;
    this.value = 0;
  }

  //the user can decide to use pwm (analogWrite) for pwm pins, or digitalWrite (1-0)
  public LED setToPWM() {
    this.pwm = Boolean.TRUE;
    return this;
  }
}

public class PushButton {
  private int signalPressed;
  private int digitalPort;
  private boolean pressed;
  private boolean pressedOnce;
  private boolean actionTaken;
  private char keyboardKey;

  public PushButton(int digitalPort, char keyboardKey) {
    this.digitalPort = digitalPort;
    this.keyboardKey = keyboardKey;
    this.signalPressed = Arduino.HIGH; // By default, pressing a button returns Arduino.HIGH
    this.pressed = Boolean.FALSE;
    this.pressedOnce = Boolean.FALSE;
    this.actionTaken = Boolean.FALSE;
  }

  public PushButton setToLow() {
    this.signalPressed = Arduino.LOW;
    return this;
  }
}

public class Potentiometer {
  private float value;
  private float smoothValue;
  private int analogPort;
  private int minValue;
  private int maxValue;
  private char keyboardKey;


  public Potentiometer(int analogPort, char keyboardKey) {
    this.analogPort = analogPort;
    this.keyboardKey = keyboardKey;
    this.value = 0;
    this.smoothValue = 0;
    this.minValue = 0;
    this.maxValue = 1023;
  }

  public Potentiometer setMinValue(int minValue) {
    this.minValue = minValue;
    return this;
  }
  public Potentiometer setMaxValue(int maxValue) {
    this.maxValue = maxValue;
    return this;
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
  ArrayList <LED> leds;

  int lastFrameCount = -1;
  boolean keyPressedActionTaken = false; // Flag to track if the action for a key press has been taken
  Integer[] infoPanelLocation = {0, 0, 0, 0}; //x, y, w, h
  boolean showInfoPanel = false;
  char infoPanelKey = 'o';

  ArduinoControls(PApplet parent, Arduino a, ArrayList <PushButton> pushbuttons, ArrayList <Potentiometer> potmeters, ArrayList <LED> leds, boolean enableArduino) {
    this.arduino = a;
    this.enableArduino = enableArduino;
    this.pushbuttons = pushbuttons;
    this.potmeters = potmeters;
    this.leds = leds;
    //this.arduino.pinMode(6, Arduino.OUTPUT);
    this.parent = parent;

    parent.registerMethod("draw", this);
    parent.registerMethod("post", this);
    parent.registerMethod("keyEvent", this);

    infoPanelLocation[2] = parent.width;
    infoPanelLocation[3] = 100;
    this.overlay = parent.createGraphics(infoPanelLocation[2], infoPanelLocation[3]);
  }

  public void setLEDToOn(int index) {
    if (index >= 0 && index < this.leds.size()) {
      LED led = this.leds.get(index);
      if (led.pwm) this.setLED(index, 255);
      else this.setLED(index, Arduino.HIGH);
    } else {
      println("warning: index " + index + " was used which is out of bounds for the ArrayList leds with size " + leds.size());
    }
  }

  public void setLEDToOff(int index) {
    this.setLED(index, Arduino.LOW);
  }

  public void setLED(int index, int value) {
    if (index >= 0 && index < this.leds.size()) {
      LED led = this.leds.get(index);
      if (value != led.value) { // no need to continuously write the same value, causes flickering on pwm
        led.value = value;
        if (led.pwm) this.arduino.analogWrite(led.digitalPort, value);
        else this.arduino.digitalWrite(led.digitalPort, value);
      }
    } else {
      println("warning: index " + index + " was used which is out of bounds for the ArrayList leds with size " + leds.size());
    }
  }

  public float getPotmeter(int index) {
    return this.getPotmeter(index, 1.0);
  }

  public float getPotmeter(int index, float smoothness) {
    if (index >= 0 && index < this.potmeters.size()) {
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
    } else {
      println("warning: index " + index + " was used which is out of bounds for the ArrayList potmeters with size " + potmeters.size() + ", returning 0.0");
      return 0.0;
    }
  }

  public boolean getPushButtonOnce(int index) {
    return this.getPushButton(index, true);
  }

  public boolean getPushButton(int index) {
    return this.getPushButton(index, false);
  }

  private boolean getPushButton(int index, boolean once) {
    if (index >= 0 && index < this.pushbuttons.size()) {
      PushButton pushbutton = this.pushbuttons.get(index);
      if (this.enableArduino) {
        if (this.arduino.digitalRead(pushbutton.digitalPort) == pushbutton.signalPressed && pushbutton.actionTaken == false) {
          pushbutton.actionTaken = true;
          pushbutton.pressed = true;
          pushbutton.pressedOnce = true;
          this.lastFrameCount = this.parent.frameCount;
        }
        if (this.arduino.digitalRead(pushbutton.digitalPort) != pushbutton.signalPressed) {
          pushbutton.actionTaken = false;
          pushbutton.pressed = false;
        }
      }
      return once ? pushbutton.pressedOnce : pushbutton.pressed;
    } else {
      println("warning: index " + index + " was used which is out of bounds for the ArrayList pushbuttons with size " + pushbuttons.size() + ", returning false");
      return false;
    }
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
      Potentiometer potmeter = this.potmeters.get(i);
      if (event.getKey() == potmeter.keyboardKey ) potmeter.value = constrain(int(map(this.parent.mouseX, 0, width, potmeter.minValue, potmeter.maxValue)), potmeter.minValue, potmeter.maxValue);
    }

    for (int i=0; i<this.pushbuttons.size(); i++) {
      PushButton pushbutton = this.pushbuttons.get(i);

      if (event.getKey()== pushbutton.keyboardKey && pushbutton.actionTaken == false) {
        pushbutton.actionTaken = true;
        pushbutton.pressed = true;
        pushbutton.pressedOnce = true;
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
    for (PushButton button : pushbuttons) {
      if (button.keyboardKey == event.getKey()) {
        button.actionTaken = false;
        button.pressed = false;
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
    if (this.parent.frameCount != this.lastFrameCount) for (PushButton button : pushbuttons) button.pressedOnce = false;
  }
}
