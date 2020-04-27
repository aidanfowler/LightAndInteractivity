/*
  Aidan Fowler Light & Interactivity
  Philips Hue Control from Processing Using Times Square Webcam
  HTTP request code from Tom Igoe
  Uses Rune Madsen's HTTP library, so you need to install it from the library manager. 
  created 26 April 2020
  Reads webcam data (movie), translates video colors to hue colors using playhead to look at different sections 
  of image at sunset (6pm) the lights will turn on and a sunset movie will briefly play mapped to the hue bulbs
  After the sunset, until sunrise, a 12 hour webcam timelapse of times square will map to the hue bulbs scanning
  accross the image As if you were in times square looking around at the screens
  When the sun rises (6am) the lights will turn off
*/

import http.requests.*;
import processing.video.*;
// variable to hold the video
Movie ourMovie;   
Movie sunriseMovie;
Movie sunsetMovie;
Movie timesSquareMovie;
// you must have these global varables to use the PxPGetPixel()
PImage drawImage;
int R, G, B, A;      
int totalCountedPixels=1;
int totalR = 0;
int totalB = 0;
int totalG = 0;
// Hue hub IP address. Fill in the right one for your hue hub:
String server = "http://192.168.1.136";
// Hue hub user name. Fill in yours here:
String username = "3hDIo9lwwF9TZCgo6lmlQB51pI3HXD2knPKuebu3";
boolean sendRequest = true;
boolean drawImageOnScreen = true;
//scanner locations for each light
int scanStart;
int scanStart2;
int scanStart3;
int scanSpeed = 3;
int scanWidth = 0;
//timer to send hue requests every few seconds
int savedTime;
int timerLength = 250;
int switchLight = 1;
int brightnessAdjust = -60;
boolean sunrise = false;
boolean sunset = false;
boolean timesSquare = false;
boolean lampOff = true;
int sunRiseTime = 6; //6am
int sunSetTime = 23; //6pm
//found these with mouseX and mouseY until I got a pleasing color range and flashiness 
int brightnessThreshold = 440;
int saturationMultiplier = 521;
int margin = 120;
public void setup() {
  size(1380, 720);
  sunsetMovie = new Movie(this,"sunset.mp4");
  timesSquareMovie = new Movie(this,"TimesSquareDuskToDawn.mp4"); 
  //need this so we have the movie width when initializing the scanner width
  smooth();
  stroke(255);
  noFill();
  strokeWeight(2);
  drawImage = new PImage(1280,720);
  turnOffLights();
  delay(2000);
  savedTime = millis();
  background(255);
}

void draw() {
  selectMovieUsingCurrentTime();
  if(!lampOff){
    drawImage.loadPixels();
    ourMovie.loadPixels(); // load the pixels array of the window  
    //process top third of screen to get a color
    if(ourMovie.pixels.length >0){
      processImageGetLight(scanStart,scanStart +scanWidth,0,ourMovie.height/3);
      if(switchLight == 1){
        //draw light and send update to corresponding hue light
        updateLight(margin/2,100,100,1);
      }
      //process middle third of screen to get a color
      processImageGetLight(scanStart2,scanStart2 + scanWidth,ourMovie.height/3,2*ourMovie.height/3);
      if(switchLight == 2){      
        //draw light and send update to corresponding hue light
        updateLight(margin/2,height/3+100,100,2);
      }
      //process bottom third of screen to get a color
      processImageGetLight(scanStart3,scanStart3 + scanWidth,2*ourMovie.height/3,ourMovie.height);
      if(switchLight == 3){
        //draw light and send update to corresponding hue light
        updateLight(margin/2,2*height/3+100,100,3);
      }
      if(drawImageOnScreen){
        //refresh image on screen with pixels that were used to set lights
        drawImage.updatePixels();
        image(drawImage,margin,0,drawImage.width,drawImage.height); 
        //draw line divisions
        stroke(255);
        noFill();
        //draw rectangles
        rect(scanStart+margin,0,scanWidth,ourMovie.height/3);
        rect(scanStart2+margin,height/3,scanWidth,ourMovie.height/3);
        rect(scanStart3+margin,2*height/3,scanWidth,ourMovie.height/3);
        line(margin,height/3,width,height/3);
        line(margin,2*height/3,width,2*height/3);
      }
      //update scanner areas
      updateScanner();
    }
  }
  else{
    background(255);
    textSize(50);
    fill(0);
    text("LAMP IS OFF",100,200);
  }
}

//if the hour is sunset time plan the sunset video then switch to times square
//if the hour is sunrise, turn off the lights
void selectMovieUsingCurrentTime(){
  int h = hour();
  if(h == sunSetTime && !sunset && !timesSquare){
    println("start sunset");
    lampOff = false;
    ourMovie = sunsetMovie;
    timesSquare = false;
    sunset = true;
    ourMovie.play();
    lampOff = false;
    scanWidth = 1280;
    scanStart = 0;
    scanStart2 = 0;
    scanStart3 = 0;
  }
  else if(h == sunRiseTime && timesSquare){
    println("sunrise, turn off lamp");
    lampOff = true;
    sunrise = true;
    ourMovie = null;
    turnOffLights();
  }
  //once the sunset video is over, switch to the times square movie this also runs if program is started between sunset and sunrise
  //for some reason movie time never reaches end, so checking if it is 95% done
  else if ((ourMovie != null && ourMovie.time() >= ourMovie.duration()*.95 && sunset) || (!sunset && !timesSquare && !sunrise)) {
      println("sunset over, switch to times ");
      sunset = false;
      timesSquare = true;
      ourMovie = timesSquareMovie;
      ourMovie.loop();
      lampOff = false;
      scanWidth = 320;
      scanStart = 0;
      scanStart2 = scanStart + scanWidth;
      scanStart3 = scanStart2 + scanWidth;
  }
}

//move section of image we are looking at to map to lights
void updateScanner(){
  if(timesSquare){
    scanStart = scanStart + scanSpeed;
    scanStart2 = scanStart2 + scanSpeed;
    scanStart3 = scanStart3 + scanSpeed;
    if(scanStart >= ourMovie.width-scanWidth){
      scanStart = 0;
    }
    if(scanStart2 >= ourMovie.width-scanWidth){
      scanStart2 = 0;
    }
    if(scanStart3 >= ourMovie.width-scanWidth){
      scanStart3 = 0;
    }
    scanWidth = ourMovie.width/4;
  }
}

//update light circle, send request to hue
void updateLight(int x, int y, int d, int l){
  totalR /= totalCountedPixels;
  totalG /= totalCountedPixels;
  totalB /= totalCountedPixels;
  if(totalR+totalG+totalB > brightnessThreshold || sunset){
    color newColor = color(totalR,totalG,totalB);
    fill(newColor);
    circle(x,y,d);
    sendColorUpdateOnTimer(newColor, l); 
  }
}

//if interval has passed, update light, switch to next light
void sendColorUpdateOnTimer(color c, int light){
  int passedTime = millis() - savedTime;
  // Has interval passed?
  if (passedTime > timerLength) {
    sendColorUpdate(c, light, true);
    savedTime = millis(); // Save the current time to restart the timer
    switchLight++;
    if(switchLight == 4){
      switchLight = 1;
    }    
  }
}

void movieEvent(Movie m){
  m.read();
}

//draw black on pixels outside of scanner window, for pixels inside scanner window, threshold and saturate so lights look pretty
void processImageGetLight(int startX, int stopX, int startY, int stopY){
  //println(startX,",",stopX,",",startY,",",stopY,",",ourMovie.width);
  resetCounters(); 
  //draw black outside of scanner
  for(int x= 0;x<startX;x++){
    for(int y = startY;y<stopY-1;y++){
      PxPSetPixel(x,y,0,0,0,255,drawImage.pixels,ourMovie.width);
    }
  }
  //threshold and saturate scanner area, copy to display image pixels
  for (int x = startX; x<stopX-1; x++) {
    for (int y = startY; y<stopY-1; y++) {
      PxPGetPixel(x, y, ourMovie.pixels, ourMovie.width);     // get the RGB of our pixel and place in RGB globals
      
      if ((R+G+B)  <brightnessThreshold && timesSquare) {                // threshold on mouseX 
        R=0;
        G=0;
        B=0;                                         
      }        
      else{
        totalCountedPixels++;
        saturate(saturationMultiplier);
      }
      PxPSetPixel(x, y, R, G, B, 255, drawImage.pixels, ourMovie.width);    // sets the R,G,B values to the window
      totalR += R;
      totalG += G;
      totalB += B;
    }
  }
  //draw black outside the scanner
  for(int x= stopX-1;x<ourMovie.width;x++){
    for(int y = startY;y<stopY-1;y++){
      PxPSetPixel(x,y,0,0,0,255,drawImage.pixels,ourMovie.width);
    }
  }
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
  //println("sending command");
   // form the request string: http://hue.hub.ip.address/apu/username/lights/lightNumber/state/ :
  String requestString = server + "/api/" + username + "/lights/" + lightNumber + "/state";
  // make a new request:
  PutRequest put = new PutRequest(requestString);
  // add the content-type header:
  put.addHeader("Content-Type", "application/json");
  // add the body of the request:
  put.addData("{\"on\":" + status + ",\"hue\":"+hue+",\"sat\":"+sat+",\"bri\":"+bri+"}");
  // send the request:
  //println(requestString);
  if(sendRequest){
    put.send();
  }
  //println("Reponse Content: " + put.getContent());
}

void turnOffLights(){
  sendColorUpdate(0,1,false);
  sendColorUpdate(0,2,false);
  sendColorUpdate(0,3,false);
}

void keyPressed(){
  if (key == 'd'){
    drawImageOnScreen = !drawImageOnScreen;
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
