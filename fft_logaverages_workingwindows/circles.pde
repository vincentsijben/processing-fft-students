class Circle {
  float x = random(-pg.width / 4, pg.width / 4);
  float y = random(-pg.height / 4, pg.height / 4);
  float r = 0;
  float rSpeed = random(0.1, 0.6);
  int counter = circles.size()+1;   
  color col = color(255, 199, 100);
  int index;

  Circle(int i) {
    if (counter % 2 == 1) col = color(91, 244, 233);
    index = i;
  }
}
