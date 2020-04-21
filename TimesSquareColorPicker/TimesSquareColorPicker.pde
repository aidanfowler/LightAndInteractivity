/*
  Aidan Fowler Light & Interactivity
  Philips Hue Control from Processing
  HTTP request code from Tom Igoe
  Uses Rune Madsen's HTTP library, so you need to install it from the library manager. 
  created 18 April 2020
  Usage:
    -Click to turn on first light (or press 1). 
    -2 and 3 keys toggle 2nd and 3rd lights, will use mouse 
     position when key is pressed to determine color
    -drag circles to change light color/brightness
    -can change just brightness with up and down keys 
    -dont hold down up and down keys because server calls 
    -will stack up and you will overshoot
*/

import http.requests.*;
import processing.video.*;
// variable to hold the video
Movie ourMovie;   
// you must have these global varables to use the PxPGetPixel()
PImage drawImage;int R, G, B, A;          
int totalCountedPixels=1;
int totalR = 0;
int totalB = 0;
int totalG = 0;
// Hue hub IP address. Fill in the right one for your hue hub:
String server = "http://192.168.1.136";
// Hue hub user name. Fill in yours here:
String username = "3hDIo9lwwF9TZCgo6lmlQB51pI3HXD2knPKuebu3";
// light that you want to control:
int lightNumber = 1;
boolean sendRequest = false;
PImage colorPicker;
int currentLight=0;
int light1X = 0;
int light1Y = 0;
int light2X = 0;
int light2Y = 0;
int light3X = 0;
int light3Y = 0;
boolean light1On = false;
boolean light2On = false;
boolean light3On = false;
int brightnessAdjust = 0;

public void setup() {
  size(1920, 720);
  ourMovie = new Movie(this, "test.mp4"); 
  ourMovie.loop();  
  colorPicker = loadImage("ColorWheel.png");
  smooth();
  stroke(0);
  noFill();
  strokeWeight(2);
  drawImage = new PImage(1280,720);
  //turn off all lights to start
  sendColorUpdate(0,1,false);
  sendColorUpdate(0,2,false);
  sendColorUpdate(0,3,false); 
}

void draw() {
  background(255);
  image(colorPicker,0,0,width/3,height);
  //circle to display current light colors
  if(light1X>0 && light1On){
    circle(light1X, light1Y, 25);
  }
  if(light2X>0 && light2On){
    circle(light2X, light2Y, 25);
    circle(light2X,light2Y,15);
  }
  if(light3X>0 && light3On){
    circle(light3X,light3Y, 35);
    circle(light3X,light3Y,15);
    circle(light3X, light3Y, 25);
  }
  drawImage.loadPixels();
  ourMovie.loadPixels(); // load the pixels array of the window   
  //process top third of screen to get a color
  processImageGetLight(0,ourMovie.height/3);
  //draw a circle with that color for light 1
  drawLight(width/3-100,100,100);
  //process middle third of screen to get a color
  processImageGetLight(ourMovie.height/3,2*ourMovie.height/3);
  //draw a circle with that color for light 2
  drawLight(width/3-100,height/3+100,100);
  //process top third of screen to get a color
  processImageGetLight(2*ourMovie.height/3,ourMovie.height);
  //draw a circle with that color for light 3
  drawLight(width/3-100,2*height/3+100,100);    
  //refresh image on screen with pixels that were used to set lights
  drawImage.updatePixels();
  image(drawImage,width/3,0,width,height); 
  //draw line divisions
  stroke(255);
  line(width/3,height/3,width,height/3);
  line(width/3,2*height/3,width,2*height/3);
}

void movieEvent(Movie m){
  m.read();
}

void processImageGetLight(int start, int stop){
  resetCounters(); 
  for (int x = 0; x<ourMovie.width; x++) {
    for (int y = start; y<stop; y++) {
      PxPGetPixel(x, y, ourMovie.pixels, ourMovie.width);     // get the RGB of our pixel and place in RGB globals
      if ((R+G+B)  <mouseX) {                // threshold on mouseX 
        R=0;
        G=0;
        B=0;                                         
      }        
      else{
        totalCountedPixels++;
        saturate(mouseY);
      }
      PxPSetPixel(x, y, R, G, B, 255, drawImage.pixels, ourMovie.width);    // sets the R,G,B values to the window
      totalR += R;
      totalG += G;
      totalB += B;
    }
  }
}

void drawLight(int x, int y, int d){
    totalR /= totalCountedPixels;
    totalG /= totalCountedPixels;
    totalB /= totalCountedPixels;
    fill(color(totalR,totalG,totalB));
    circle(x,y,d);
}

void resetCounters(){
  totalCountedPixels=1;
  totalR = 0;
  totalB = 0;
  totalG = 0;
}

// this is from the litle C refrence book
void saturate(int saturation){
  int R1 = R;
  int G1=G;
  int B1 = B;                                 
  int RY1 = (70*R1-59*G1-11*B1)/100;
  int BY1 = (-30*R1-59*G1+89*B1)/100;
  int GY1 = (-30*R1+41*G1-11*B1)/100;
  int Y = (30 *R1 +59 *G1+11*B1)/100;
  int RY = (RY1 *saturation)/100;                   
  int GY = (GY1 *saturation)/100;
  int BY = (BY1 *saturation)/100;
  int tempR =  RY+Y;
  int tempG =  GY+Y;
  int tempB =  BY+Y;

  R= constrain(tempR, 0, 255);                                   
  G= constrain(tempG, 0, 255);                                  
  B= constrain(tempB, 0, 255); 
}


//update hue, saturation, brightne
void sendColorUpdate(color currentColor, int lightNumber, boolean status){
  int hue = int(map(hue(currentColor),0,255,0,65535));
  int bri = int(brightness(currentColor));
  int sat = int(saturation(currentColor));
  bri = bri+brightnessAdjust-180; //take an extra 80 off so that it doesnt start super bright
  bri = constrain(bri,0,255);
  println("sending command");
   // form the request string: http://hue.hub.ip.address/apu/username/lights/lightNumber/state/ :
  String requestString = server + "/api/" + username + "/lights/" + lightNumber + "/state";
  // make a new request:
  PutRequest put = new PutRequest(requestString);
  // add the content-type header:
  put.addHeader("Content-Type", "application/json");
  // add the body of the request:
  put.addData("{\"on\":" + status + ",\"hue\":"+hue+",\"sat\":"+sat+",\"bri\":"+bri+"}");
  // send the request:
  println(requestString);
  //println("stringEntity:",+put.stringEntity);
  if(sendRequest){
    put.send();
  }
  // print the response
  println("Reponse Content: " + put.getContent());
 // change the state for next time through the draw loop:
}

void keyPressed(){
  if(key=='1'){
    currentLight = 1;
    light1On = !light1On;
    println("light1 toggle:",light1On);
    refreshCircles();
    sendColorUpdate(get(light1X,light1Y),1, light1On);
  }
  else if (key =='2'){
    currentLight = 2;
    light2On = !light2On;
    println("light2 toggle:",light2On);
    if(light2On && light2X >= 1){
      light2X = mouseX;
      light2Y = mouseY;
    }
    refreshCircles();
    sendColorUpdate(get(light2X,light2Y),2, light2On);
  }
  else if(key == '3'){
    currentLight = 3;
    light3On = !light3On;
    println("light3 toggle:",light1On);
    if(light3On && light3X >= 1){
      light3X = mouseX;
      light3Y = mouseY;
    }
    refreshCircles();
    sendColorUpdate(get(light3X,light3Y),3, light3On);
  }
  if (key == CODED) {
    if (keyCode == UP) {
      println("Brightness +");
      brightnessAdjust += 15;
      updateAllLights();
    }
    if(keyCode == DOWN){
      println("Brightness -");
      brightnessAdjust -= 15;
      updateAllLights();
    }
  }
}



void updateAllLights(){
  if(light1On){
    sendColorUpdate(get(light1X,light1Y),1,true);
  }
  if(light2On){
    sendColorUpdate(get(light2X,light2Y),2,true);
  }
  if(light3On){
    sendColorUpdate(get(light3X,light3Y),3,true);
  }
}

void refreshCircles(){
  if(currentLight == 1){
    light1X = mouseX;
    light1Y = mouseY;   
  }
  else if(currentLight == 2){
    light2X = mouseX;
    light2Y = mouseY;
  }
  else if(currentLight == 3){
    light3X = mouseX;
    light3Y = mouseY;
  }
}

void mousePressed(){
  if(dist(mouseX,mouseY,light1X,light1Y) <= 25 && light1On){
    currentLight = 1;
  }
  else if(dist(mouseX,mouseY,light2X,light2Y) <= 25 && light2On){
    currentLight = 2;
  }
  else if(dist(mouseX,mouseY,light3X,light3Y) <= 25 && light3On){
    currentLight = 3;
  }
}

void mouseClicked(){
  //initialize program on first click
  if(currentLight == 0){
    currentLight = 1;
    light1On = true;
    refreshCircles();
    sendColorUpdate(get(mouseX,mouseY),currentLight,true);
  }
  refreshCircles();
}

void mouseDragged(){
  refreshCircles(); 
}

void mouseReleased(){
  if((currentLight == 1 && light1On) || (currentLight == 2 && light2On) || (currentLight == 3 && light3On)){
    sendColorUpdate(get(mouseX,mouseY),currentLight,true);
  } 
}


// our function for getting color components , it requires that you have global variables
// R,G,B   (not elegant but the simples way to go, see the example PxP methods in object for 
// a more elegant solution

void PxPGetPixel(int x, int y, int[] pixelArray, int pixelsWidth) {
  //println("x:",x," y:",y," width:",pixelsWidth;
  int thisPixel=pixelArray[x+y*pixelsWidth];     // getting the colors as an int from the pixels[]
  A = (thisPixel >> 24) & 0xFF;                  // we need to shift and mask to get each component alone
  R = (thisPixel >> 16) & 0xFF;                  // this is faster than calling red(), green() , blue()
  G = (thisPixel >> 8) & 0xFF;   
  B = thisPixel & 0xFF;
}


//our function for setting color components RGB into the pixels[] , we need to efine the XY of where
// to set the pixel, the RGB values we want and the pixels[] array we want to use and it's width

void PxPSetPixel(int x, int y, int r, int g, int b, int a, int[] pixelArray, int pixelsWidth) {
  a =(a << 24);                       
  r = r << 16;                                // We are packing all 4 composents into one int
  g = g << 8;                                 // so we need to shift them to their places
  color argb = a | r | g | b;                 // binary "or" operation adds them all into one int
  pixelArray[x+y*pixelsWidth]= argb;          // finaly we set the int with te colors into the pixels[]
}
