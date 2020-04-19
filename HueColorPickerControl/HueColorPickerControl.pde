/*
  Aidan Fowler Light & Interactivity
  Philips Hue Control from Processing
  HTTP request code from Tom Igoe
  Uses Rune Madsen's HTTP library, so you need to install it from the library manager. 
  created 18 April 2020
*/

import http.requests.*;

// Hue hub IP address. Fill in the right one for your hue hub:
String server = "http://192.168.1.136";
// Hue hub user name. Fill in yours here:
String username = "3hDIo9lwwF9TZCgo6lmlQB51pI3HXD2knPKuebu3";
// light that you want to control:
int lightNumber = 1;
boolean lightState = true;
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
  size(400, 400);
  colorPicker = loadImage("color_circle.png");
  smooth();
  stroke(0);
  noFill();
  strokeWeight(2);
  //turn off all lights to start
  sendColorUpdate(get(0,0),1,false);
  sendColorUpdate(get(0,0),2,false);
  sendColorUpdate(get(0,0),3,false); 
}

void draw() {
  background(255);
  image(colorPicker,0,0,width,height);
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
}

//update hue, saturation, brightne
void sendColorUpdate(color currentColor, int lightNumber, boolean status){
  int hue = int(map(hue(currentColor),0,255,0,65535));
  int bri = int(brightness(currentColor));
  int sat = int(saturation(currentColor));
  bri = bri+brightnessAdjust;
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
  put.send();
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
    sendColorUpdate(get(light1X,light2X),1,true);
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
}

void mouseDragged(){
  refreshCircles();
}

void mouseReleased(){
  if((currentLight == 1 && light1On) || (currentLight == 2 && light2On) || (currentLight == 3 && light3On)){
    sendColorUpdate(get(mouseX,mouseY),currentLight,true);
  } 
}
