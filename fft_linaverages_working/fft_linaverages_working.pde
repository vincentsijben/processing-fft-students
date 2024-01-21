import ddf.minim.*;
import ddf.minim.analysis.*;
Minim minim;
AudioPlayer song;
AudioInput input;
FFT fft;
int linNum = 10;

PGraphics pg;
float r = 0;
FloatList x = new FloatList();
FloatList y = new FloatList();
float max = 2;

void setup() {

  //fullScreen();
  size(700, 700);
  pg = createGraphics(width, height);
  minim = new Minim(this);
  song = minim.loadFile("assets/hot-coffee.mp3");
  song.play();
  input = minim.getLineIn(minim.MONO);
  //fft = new FFT(song.bufferSize(), song.sampleRate());
  fft = new FFT(input.bufferSize(), input.sampleRate()); //always 1024 and 44100.0??
  fft.linAverages(linNum);

  for (int i = 0; i < linNum; i++) {
    x.append(random(-pg.width / 4, pg.width / 4));
    y.append(random(-pg.width / 4, pg.width / 4));
  }
}


void draw() {
  background(50);

  fft.forward(song.mix);
  fft.forward(input.mix);

  drawCircles();
  drawRects();
}

void drawCircles() {
  pg.beginDraw();
  pg.fill(0, 0, 0, 30);
  pg.rect(0, 0, width, height);
  pg.translate(pg.width / 2, pg.height / 2);
  pg.rotate(radians(r));

  for (int i = 0; i < linNum; i++) {
    pg.strokeWeight(2);
    if (i % 2 == 1) pg.stroke(91, 244, 233);
    else pg.stroke(255, 199, 100);
    pg.noFill();

    float test = map(fft.getAvg(i), 0, max, 0, 1);
    test = lerp(0, 100, test);

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
  for (int i = 0; i < linNum; i++) {
    float xR = (i * width) / linNum;
    float yR = 100;
    fill(255);
    rect(xR, yR, width / linNum, map(fft.getAvg(i), 0, max, 0, -100));
    fill(255, 0, 0);
    textAlign(CENTER, CENTER);
    textSize(14);
    text(round(fft.getAvg(i)), xR + (width / linNum / 2), yR - 20);
    textSize(8);
    text(i, xR + (width / linNum / 2), yR-6);
  }
  textSize(25);
  text(round(frameRate), 20, 20);
}
void stop() {
  song.close();
  minim.stop();
  super.stop();
}
