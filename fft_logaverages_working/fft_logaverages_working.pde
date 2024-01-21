/*
see comment on https://stackoverflow.com/questions/40050731/how-to-make-two-fft-objects-for-the-left-and-right-channel-with-the-minim-librar
  todo: check https://stackoverflow.com/questions/20408388/how-to-filter-fft-data-for-audio-visualisation
  todo: check https://www.ee.columbia.edu/~dpwe/e4896/index.html
  
  
  todo: how to properly calculate max values for each avg.
*/
import ddf.minim.*;
import ddf.minim.analysis.*;
//import processing.sound.*;



PGraphics pg;
float r = 0;
FloatList x = new FloatList();
FloatList y = new FloatList();
float max = 100;
FrequencyAnalyzer fAnalyzer;

void setup() {

  //fullScreen();
  size(700, 700);
  pg = createGraphics(width, height);
  
  fAnalyzer = new FrequencyAnalyzer(this);
  //fAnalyzer = new FrequencyAnalyzer(this, 10);
  
  
  fAnalyzer.enableMicrophone();
  //fAnalyzer.enableSong("assets/hot-coffee.mp3"); //if mic is enabled, it will overwrite the song.mix but will pick up the audio through the mic (less accurate)

  
  

  for (int i = 0; i < fAnalyzer.linNum; i++) {
    x.append(random(-pg.width / 4, pg.width / 4));
    y.append(random(-pg.width / 4, pg.width / 4));
  }
}


void draw() {
  background(50);

  fAnalyzer.run();

  drawCircles();
  drawRects();
}

void drawCircles() {
  pg.beginDraw();
  pg.fill(0, 0, 0, 30);
  pg.rect(0, 0, width, height);
  pg.translate(pg.width / 2, pg.height / 2);
  pg.rotate(radians(r));

  for (int i = 0; i < fAnalyzer.linNum; i++) {
    pg.strokeWeight(2);
    if (i % 2 == 1) pg.stroke(91, 244, 233);
    else pg.stroke(255, 199, 100);
    pg.noFill();

    
    float test = lerp(0, 100, fAnalyzer.getAvg(i));

    pg.ellipse(
      x.get(i),
      y.get(i),
      test,
      test
      //map(fft.getAvg(i), 0, max, 0, 100),
      //map(fft.getAvg(i), 0, max, 0, 100)
      );
  }
  pg.endDraw();
  image(pg, 0, 0);
  r += 0.6;
}

void drawRects() {
  for (int i = 0; i < fAnalyzer.linNum; i++) {
    float xR = (i * width) / fAnalyzer.linNum;
    float yR = 100;
    fill(255);
    rect(xR, yR, width / fAnalyzer.linNum, lerp(0,-100,fAnalyzer.getAvg(i)));
    fill(255, 0, 0);
    textAlign(CENTER, CENTER);
    textSize(14);
    text(round(lerp(0,100,fAnalyzer.getAvg(i))), xR + (width / fAnalyzer.linNum / 2), yR - 20);
    textSize(8);
    text(i, xR + (width / fAnalyzer.linNum / 2), yR-6);
  }
  textSize(25);
  text(round(frameRate), 20, 20);
}
