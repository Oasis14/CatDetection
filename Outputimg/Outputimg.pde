
import oscP5.*;
import netP5.*;
OscP5 oscP5;
NetAddress dest;

PFont myFont;

PImage img; 
int imgName;
void setup() {
  oscP5 = new OscP5(this,12000);
  size(640, 600); 
}

void draw() {
  String filext= ".png";
  img = loadImage(imgName+filext);
  img.resize(640,0);
  image(img, 0, 0);
}

void oscEvent(OscMessage theOscMessage) {
 if (theOscMessage.checkAddrPattern("/wek/outputs")==true) {
     if(theOscMessage.checkTypetag("f")) { 
      float imgNameRec = theOscMessage.get(0).floatValue();
      imgName= int(imgNameRec);
     } else {
        println("Error: unexpected OSC message received by Processing: ");
        theOscMessage.print();
      }
 }
}


void sendOscNames() {
  OscMessage msg = new OscMessage("/wekinator/control/setOutputNames");
  msg.add("imagename"); //Now send all 5 names
  oscP5.send(msg, dest);
}

//Write instructions to screen.
void drawtext() {
    stroke(0);
    textFont(myFont);
    textAlign(LEFT, TOP); 
    fill(0, 0, 255);
    text("Receiving 1 parameter: image name ex. catface.png", 10, 10);
    text("Listening for /wek/outputs on port 12000", 10, 40);
}