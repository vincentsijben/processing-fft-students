ArrayList <Serotonin> serotonins = new ArrayList<Serotonin>();

class Serotonin {

  float x;
  float y;
  float d;
  float diaBPM;
  float horDirection;
  float verDirection;
  float speed;
  color c = color(255,0,0);

  Serotonin(color tempC) {
    x = width/2;
    y = height/2;
    d = random(15, 30);
    horDirection = random(2) > 1 ? 1 : -1;
    verDirection = random(2) > 1 ? 1 : -1;
    speed = random(1, 5);
    c = tempC;
  }
  void spawnSerotonin() {

    fill(c);
    noStroke();
    diaBPM = map(0.5, 0, 1, 10, 25);
    ellipse(x, y, d + diaBPM, d + diaBPM);

    x += horDirection * speed;
    y += verDirection;
  }
}
