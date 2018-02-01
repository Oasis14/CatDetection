/**
 * WhichFace
 * Daniel Shiffman
 * http://shiffman.net/2011/04/26/opencv-matching-faces-over-time/
 *
 * Modified by Jordi Tost (@jorditost) to work with the OpenCV library by Greg Borenstein:
 * https://github.com/atduskgreg/opencv-processing
 *
 * Modified again by Rebecca Fiebrink to send 3 OSC values to Wekinator:
 * www.wekinator.org
 *
 * Modified again by Ryan Craig and Rachel Platt to detect cat faces. 
 *
 * @url: https://github.com/jorditost/BlobPersistence/
 *
 * University of Applied Sciences Potsdam, 2014
 */

import gab.opencv.*;
import processing.video.*;
import java.awt.*;
import oscP5.*;
import netP5.*;


import org.opencv.core.Core;
import org.opencv.core.Mat;
import org.opencv.core.CvType;
import org.opencv.core.Scalar;

OscP5 oscP5;
NetAddress dest;

Capture video;
OpenCV opencv;
OpenCV eyeDetection;

PFont f;

// List of my Face objects (persistent)
ArrayList<Face> faceList;

// List of detected faces (every frame)
Rectangle[] faces;
Rectangle[] eyes;

// Number of faces detected over all time. Used to set IDs.
int faceCount = 0;

// Scaling down the video
int scl = 2;

//Some memory
int countWithout = 0;
int countWithoutMax = 10;

int x = 0; 
int y = 0; 
int w = 0;
float r = 0;

//training 
boolean train = false;
String[] catImgFileName;
PImage[] catPImage = new PImage[9];
int display, displaySize;

void setup() {
  size(640, 480);
  video = new Capture(this, width/scl, height/scl);
  opencv = new OpenCV(this, width/scl, height/scl);
  //opencv.loadCascade(OpenCV.CASCADE_FRONTALFACE);
  opencv.loadCascade("haarcascade_frontalcatface_extended.xml");  
  
  //eyeDetection = new OpenCV(this, width/scl, height/scl);
  //eyeDetection.loadCascade(OpenCV.CASCADE_EYE); 
  
  
  
  
  faceList = new ArrayList<Face>();
  
  f = createFont("Courier", 12);
  textFont(f);
  
  video.start();
  
  /* start oscP5, listening for incoming messages at port 12000 */
  oscP5 = new OscP5(this,9000);
  dest = new NetAddress("10.201.27.233",8000);
  frameRate(90);
  

  File folder = new File(sketchPath() + "/pictures");
  catImgFileName = folder.list();
  displaySize = catImgFileName.length;
  catPImage = new PImage[displaySize];
  //load cat Pimages to array
  for (int i = 0; i < catImgFileName.length; i ++){
   println(sketchPath() + "/pictures/" + catImgFileName[i]);
   catPImage[i] = loadImage( sketchPath() + "/pictures/" + catImgFileName[i]); 
   catPImage[i].resize(width/scl, height/scl);
  }
}





void draw() {
  
  //check if training key is pressed
  if (keyPressed) {
    if (key == 't' || key == 'T') {
      train = !train;
      println(train);
    }
    
    if(key == 'd' || key == 'D'){
      
      display ++;
    }
    
    if(key == 'a' || key == 'A'){
     display --; 
    }
  }


  if(display > displaySize - 1){
   display = 0; 
  }
  if(display < 0){
    display = displaySize - 1;
  }
  
  scale(scl);
  
  if(train){
   //be able to get all pictures for training data set 
   image(catPImage[display],0,0);
   opencv.loadImage(catPImage[display]);
  } else {
    //Use live data 
    image(video, 0, 0 );
    opencv.loadImage(video);
  }
  
  //Done regardless of training or running
  detectFaces();
  detectEyes ();

  //Rectangles:
  if (faceList.size() >= 1) {
    countWithout = 0;
    
    noFill();
    strokeWeight(5);
    stroke(255,0,0);
    Face f = faceList.get(0);
    rect(f.face.x, f.face.y, f.face.width, f.face.height); //if you want the rectangle
    for(int e = 0; e < f.eyes.length; e ++){
      if(f.eyes[e] != null){
        rect(f.face.x + f.eyes[e].x, f.face.y + f.eyes[e].y, f.eyes[e].width, f.eyes[e].height);
      }
    }
    //draw eyes
    x = f.face.x;
    y = f.face.y;
    w = f.face.width;
    for(int i = 0; i < f.eyes.length; i++){
      if(f.eyes[i] != null){
        r = f.face.width / f.eyes[i].width ;
      }
    }
    //drawFace();
      
  } else if (countWithout > countWithoutMax) {
    x = 0;
    y = 0;
    w = 0;
    r = 0;
    drawFace();
  } else {
    countWithout++;
  }
  
  
  
  //Send the OSC message with face current position
  sendOsc();
  
  fill(255);
  text("Continuously sends 3 inputs to Wekinator\nUsing message /wek/inputs, to port 6448", 10, 10);
  text("Face x=" + x + ", y=" + y + ", width=" + w +", ratio= " + r, 10, 40);
  fill(255,0,0);
  text("Hint: remove glasses, don't tilt your head", 10, 55);
}

void detectFaces() {
  
  
  // Faces detected in this frame
  faces = opencv.detect();
  
  // Check if the detected faces already exist are new or some has disappeared. 
  
  // SCENARIO 1 
  // faceList is empty
  if (faceList.isEmpty()) {
    // Just make a Face object for every face Rectangle
    for (int i = 0; i < faces.length; i++) {
      println("+++ New face detected with ID: " + faceCount);
      Face foundFace = new Face(faceCount, faces[i].x,faces[i].y,faces[i].width,faces[i].height);
      faceList.add(foundFace);
      faceCount++;
    }
  
  // SCENARIO 2 
  // We have fewer Face objects than face Rectangles found from OPENCV
  } else if (faceList.size() <= faces.length) {
    boolean[] used = new boolean[faces.length];
    // Match existing Face objects with a Rectangle
    for (Face f : faceList) {
       // Find faces[index] that is closest to face f
       // set used[index] to true so that it can't be used twice
       float record = 50000;
       int index = -1;
       for (int i = 0; i < faces.length; i++) {
         float d = dist(faces[i].x,faces[i].y,f.face.x,f.face.y);
         if (d < record && !used[i]) {
           record = d;
           index = i;
         } 
       }
       // Update Face object location
       used[index] = true;
       f.update(faces[index]);
    }
    // Add any unused faces
    for (int i = 0; i < faces.length; i++) {
      if (!used[i]) {
        println("+++ New face detected with ID: " + faceCount);
        Face foundFace = new Face(faceCount, faces[i].x,faces[i].y,faces[i].width,faces[i].height);
        //find eyes
        
        faceList.add(foundFace);
        faceCount++;
      }
    }
  
  // SCENARIO 3 
  // We have more Face objects than face Rectangles found
  } else {
    // All Face objects start out as available
    for (Face f : faceList) {
      f.available = true;
    } 
    // Match Rectangle with a Face object
    for (int i = 0; i < faces.length; i++) {
      // Find face object closest to faces[i] Rectangle
      // set available to false
       float record = 50000;
       int index = -1;
       for (int j = 0; j < faceList.size(); j++) {
         Face f = faceList.get(j);
         float d = dist(faces[i].x,faces[i].y,f.face.x,f.face.y);
         if (d < record && f.available) {
           record = d;
           index = j;
         } 
       }
       // Update Face object location
       Face f = faceList.get(index);
       f.available = false;
       f.update(faces[i]);
    } 
    // Start to kill any left over Face objects
    for (Face f : faceList) {
      if (f.available) {
        f.countDown();
        if (f.dead()) {
          f.delete = true;
        } 
      }
    } 
  }
  
  // Delete any that should be deleted
  for (int i = faceList.size()-1; i >= 0; i--) {
    Face f = faceList.get(i);
    if (f.delete) {
      faceList.remove(i);
    } 
  }
}

void captureEvent(Capture c) {
  c.read();
}

//Send 3 inputs to Wekinator via oSC
void sendOsc() {
  OscMessage msg = new OscMessage("/wek/inputs");
  msg.add((float)x); 
  msg.add((float)y);
  msg.add((float)w);
  msg.add((float)r);
  oscP5.send(msg, dest);
}

void detectEyes(){
  for (int i = faceList.size()-1; i >= 0; i--) {
    
    Face f = faceList.get(i);
    PImage faceImage;
    if(train){
      faceImage = catPImage[display].get(f.face.x, f.face.y, f.face.width, f.face.height); 
    }else{
      faceImage = video.get(f.face.x, f.face.y, f.face.width, f.face.height);
    }
    eyeDetection = new OpenCV(this, f.face.width, f.face.height);
    eyeDetection.loadCascade(OpenCV.CASCADE_EYE);  
    eyeDetection.loadImage(faceImage);
    eyes = eyeDetection.detect();
    for(int e = 0; e < eyes.length; e++){
      f.addEyes(eyes[e]);
    }
  }
 
}

void drawFace() {
   //fill(255, 255, 0);
   //noStroke();
   //ellipse(x+(float)w/2, y+(float)w/2, w, w);
   //fill(0);
   //ellipse(x+(float)w/3, y+(float)w/3, 10, 10);
   //ellipse(x+(2. * w)/3, y+(float)w/3, 10, 10);
   //arc(x + (float)w/2, y + (float)w/2, (float)w/2, (float)w/4, 0, PI);
   
   PImage img = loadImage("smiley.jpg");
   image(img, x, y, w, w);
   
}