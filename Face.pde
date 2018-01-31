/**
 * Which Face Is Which
 * Daniel Shiffman
 * http://shiffman.net/2011/04/26/opencv-matching-faces-over-time/
 *
 * Modified by Jordi Tost (call the constructor specifying an ID)
 * @updated: 01/10/2014
 */

class Face {
  
  // A Rectangle
  Rectangle face;
  Rectangle eyes;
  
  // Am I available to be matched?
  boolean available;
  
  // Should I be deleted?
  boolean delete;
  
  // How long should I live if I have disappeared?
  int timer = 127;
  
  // Assign a number to each face
  int id;
  
  // Make me
  Face(int newID, int x, int y, int w, int h) {
    face = new Rectangle(x,y,w,h);
    available = true;
    delete = false;
    id = newID;
  }

  // Show me
  void display() {
    fill(0,0,255,timer); //Blue
    stroke(0,0,255);  //Blue
    rect(face.x,face.y,face.width, face.height);
    //rect(r.x*scl,r.y*scl,r.width*scl, r.height*scl);
    fill(255,timer*2);
    text(""+id,face.x+10,face.y+30);
    //text(""+id,r.x*scl+10,r.y*scl+30);
    //text(""+id,r.x*scl+10,r.y*scl+30);
  }

  // Give me a new location / size
  // Oooh, it would be nice to lerp here!
  void update(Rectangle newR) {
    face = (Rectangle) newR.clone();
  }

  // Count me down, I am gone
  void countDown() {
    timer--;
  }

  // I am deed, delete me
  boolean dead() {
    if (timer < 0) return true;
    return false;
  }
  
  void addEyes(){
    
  }
}