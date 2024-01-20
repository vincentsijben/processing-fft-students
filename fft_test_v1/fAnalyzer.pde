class FrequencyBand {
  float freqStart;
  float freqEnd;
  FrequencyBand(float frequencyStart, float frequencyEnd) {
    freqStart = frequencyStart;
    freqEnd = frequencyEnd;
  }
}

class FrequencyAnalyzer {
  boolean showInfo = false;
  float startTime = 0;
  float[] avg = new float[0];
  float[] max = new float[0];
  float[] count = new float[0];
  float[] size = new float[0];
  FrequencyBand[] frequencyBands = new FrequencyBand[0];

  FFT fftFrequency;

  FrequencyAnalyzer(FFT fftTemp) {
    fftFrequency = fftTemp;
  }

  void addFrequencyBand(FrequencyBand b) {
    frequencyBands = (FrequencyBand[]) append (frequencyBands, b);
    avg = append(avg, 0.1);
    max = append(max, 0.1);
    count = append(count, 0);
    size = append(size, 0);
  }

  void resetMax(float duration) {
    if (millis() - startTime > duration) {
      for (int j=0; j<frequencyBands.length; j++) max[j] = avg[j];
      startTime = millis();
    }
  }

  void run() {
    for (int j=0; j<frequencyBands.length; j++) {
      avg[j] = 0;
      count[j] = 0;
    }

    for (int i = 0; i < fftFrequency.specSize(); i++) {
      for (int j=0; j<frequencyBands.length; j++) {
        if (fftFrequency.getFreq(i) > frequencyBands[j].freqStart && fftFrequency.getFreq(i) < frequencyBands[j].freqEnd) {
          avg[j] += fftFrequency.getBand(i);
          count[j]++;
        }
      }
    }

    for (int j=0; j<frequencyBands.length; j++) {
      if (count[j]>0) avg[j] /= count[j];
      max[j] = max(max[j], avg[j]);
      avg[j] = constrain(avg[j], 0, max[j]);
      size[j] = map(avg[j], 0, max[j], 0, 1);

      if (showInfo) {
        pushStyle();
        rectMode(CENTER);
        textAlign(CENTER, CENTER);
        noStroke();
        fill(240);
        rect(width/(frequencyBands.length+1)*(j+1), height/2, 50, size[j]*400);

        fill(0);
        text(nf(avg[j],0,2), width/(frequencyBands.length+1)*(j+1), height/2-size[j]/2-5);
        stroke(0);
        strokeWeight(1);
        fill(0);
        line(width/(frequencyBands.length+1)*(j+1)-50, height/2-200, width/(frequencyBands.length+1)*(j+1)-10, height/2-200);
        text("max: " + nf(max[j], 0, 2), width/(frequencyBands.length+1)*(j+1)-50, height/2-200-7);
        text("frequencies: " + round(frequencyBands[j].freqStart) + "-" + round(frequencyBands[j].freqEnd), width/(frequencyBands.length+1)*(j+1)-50, height/2-200-27);  
        popStyle();
      }
    }
    
  }
}
