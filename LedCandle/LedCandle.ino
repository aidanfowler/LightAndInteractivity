/*
   Aidan Fowler
   Feb 7th 2020
   LED Candle mimicking the turning on of an flickering of a candle
   Flickering code and hsv color setting adapted from Tom Igoe
   https://github.com/tigoe/LightProjects/blob/master/Candles/WS281xCandle/WS281xCandle.ino
*/
#include <Adafruit_NeoPixel.h>

const int neoPixelPin = 6; // control pin
const int pixelCount = 7; // number of pixels
int count = 1; //count loops for flickering
int sat[pixelCount]; //saturation
int intensity[pixelCount]; //intensity
int flickerInterval = 683; //flicker interval (big prime for modulo division)
int constrainRange = 1500; //constrain LEDs close to initial colors

// set up strip:
Adafruit_NeoPixel candle = Adafruit_NeoPixel(pixelCount, neoPixelPin, NEO_GRBW + NEO_KHZ800);

//starting with range between pink and yellow, will never fluctuate much from here
unsigned int hue[pixelCount] = {2000, 3000, 4000, 5000, 6000, 7000, 8000};
//save state right after candle flickers before normal operations
unsigned int constrainToInitialState[pixelCount] = {1500, 2500, 3500, 4500, 5500, 6500, 7500};
//hold values so we can have a bit of an initial flicker
unsigned int savePreviousIntensity[pixelCount] = {0, 0, 0, 0, 0, 0, 0};

void setup() {
  Serial.begin(9600);
  randomSeed(analogRead(A6));
  candleStartup();
}

//use Tom's candle flickering with adjusted colros and intensity
//for more level variation but more limited color range to complement dichroic
//additional flickering every 683 / 1366 / 2049 cycles
void loop() {
  if (count % flickerInterval == 0) {
    int flickerTime = random(7, 15);
    for (int i = 0; i < flickerTime; i++) {
      flicker(10);
    }
    flickerInterval += 683;
    count = 1;
    if (flickerInterval >= 2732) {
      flickerInterval = 683;
    }
  }
  else {
    mimickCandle();
  }
  count++;
}

void setPixel(int p) {
  // get RGB from HSV:
  unsigned long color = candle.ColorHSV(hue[p], sat[p], intensity[p]);
  // do a gamma correction:
  unsigned long correctedColor = candle.gamma32(color);
  candle.setPixelColor(p, correctedColor);
}

void candleStartup() {
  candle.begin(); // initialize pixel strip
  candle.clear(); // turn all LEDs off
  for (int p = 0; p < pixelCount; p++) {
    sat[p] = random(192, 255); // high end of saturation
    intensity[p] = random(10, 40); // start off dark and ignite
    setPixel(p);
  }
  for (int i = 0; i < 200; i++) {
    intensify();
  }
  for (int i = 0; i < 45; i++) {
    flicker(15);
  }
}

void intensify() {
  for (int p = 0; p < pixelCount; p++) {
    if (savePreviousIntensity[p] != 0) {
      intensity[p] = savePreviousIntensity[p];
    }
    //flicker 3% of the pixel adjustments but save prior value to save overall light
    if (random(100) > 97) {
      savePreviousIntensity[p] = intensity[p];
      intensity[p] = 30;
    }
    else {
      savePreviousIntensity[p] = 0;
      intensity[p] += random(1, 2);
    }
    intensity[p] = constrain(intensity[p], 30, 255);
    setPixel(p);
  }
  candle.show();
  delay(5);
}

void flicker(int delayTime) {
  for (int p = 0; p < pixelCount; p++) {
    sat[p] = random(192, 255);
    intensity[p] = random(150, 255);
    hue[p] = random(3500, 7500);
    hue[p] = constrain(hue[p], constrainToInitialState[p]-constrainRange, constrainToInitialState[p]+constrainRange);
    setPixel(p);
  }
  candle.show();
  delay(delayTime);
}

void mimickCandle() {
  for (int p = 0; p < pixelCount; p++) {
    int hueChange = random(-1, 1);
    hue[p] += hueChange;
    hue[p] = constrain(hue[p], constrainToInitialState[p]+constrainRange, constrainToInitialState[p]-constrainRange);
    int satChange = random(-1, 1);
    sat[p] += satChange;
    sat[p] = constrain(sat[p], 192, 255);
    int intensityChange = random(-1, 2);
    intensity[p] += intensityChange;
    intensity[p] = constrain(intensity[p], 100, 220);
    setPixel(p);
  }
  candle.show();
  delay(5);
}
