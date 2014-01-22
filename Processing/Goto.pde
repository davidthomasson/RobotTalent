class Goto {
  int startTime;
  PVector startLocation;        // mm from screen centre
  PVector endLocation;          // mm from screen centre
  float speed;                  // mm/sec
  float duration;               // mSec
  int transmitInterval = 100;   // mSec between instructions sent to arm
  boolean running;

  Goto() {
   startTime = 0;
   startLocation = new PVector(0, 0, 0);
   endLocation = new PVector(0, 0, 0);
   speed = 0;
   duration = 0;
   running = false;
  }
  
  //void to(float x, float y, float z, float speed_) {
  void to(PVector endLocation_, float speed_) {
   startTime = millis();
   //startLocation = new PVector(screen.z, screen.y, screen.z);
   startLocation = screen.get();
   //endLocation = new PVector(x, y, z);
   endLocation = endLocation_.get();
   speed = speed_;
   
   if(PVector.dist(startLocation, endLocation) > 0) {
     duration = PVector.dist(startLocation, endLocation) / speed * 1000;
   } else {
     duration = 200;
   }
   running = true;
  }

  void update() {
//    if(PVector.dist(startLocation, endLocation) > 0) {
      screen.x = lerp(startLocation.x, endLocation.x, min((millis() - startTime), duration)/duration);
      screen.y = lerp(startLocation.y, endLocation.y, min((millis() - startTime), duration)/duration);
      screen.z = lerp(startLocation.z, endLocation.z, min((millis() - startTime), duration)/duration);
//    } else {
//      PVector thisLocation = startLocation.get();
//      screen.x = thisLocation.x;
//      screen.y = thisLocation.y;
//      screen.z = thisLocation.z;
//      screen = startLocation.get();
//    }

    sliderScreenX.setValue(screen.x);
    sliderScreenY.setValue(screen.y);
    sliderScreenZ.setValue(screen.z);
    
//    if (screenZ == 0) {
//      drawPoint(); 
//    }
    
    if( millis() - startTime >= duration) {
      running = false; 
    }

  }

/*
  void drawPoint() {
    fill(255, 100);
    noStroke;
    pushMatrix();
      translate(width/2.5, height/2, 300);
      rotateX(originX);    
      rotateY(originY);
      rotateZ(originZ);
      translate(screenCentreX, -screenCentreY, screenCentreZ);
      rotateX(screenTilt);
      translate(0, 0, 1);
      

    for (int i = sketchPoints.size()-1; i >= 0; i--) {
    PVector thisPoint = sketchPoints.get(i);
    float thisX = thisPoint.x;
    float thisY = thisPoint.y;
    float thisZ = thisPoint.z;
    
    pushMatrix();
    translate(thisX, -thisY, thisZ);
    
    beginShape();
         fill(255);
         vertex(-2, -2, 0);
         vertex(2, -2, 0);
         vertex(2, 2, 0);
         vertex(-2, 2, 0);
    endShape();
    popMatrix();
  }


    pushMatrix();
      translate(screenCentreX, -screenCentreY, screenCentreZ);
      rotateX(screenTilt);
      
      beginShape(QUADS);
        // XY plane
        vertex(screenXsize/2, screenYsize/2, 0);
        vertex(-screenXsize/2, screenYsize/2, 0);
        vertex(-screenXsize/2, -screenYsize/2, 0);
        vertex(screenXsize/2, -screenYsize/2, 0);
      endShape(); 
      
      //drawPath();
      
    popMatrix();
  
  }
*/  
  
//  PVector convertCoord(PVector coord) {
//    PVector location = new PVector(0, 0);
//    location.x = map(coord.x, 0, screenXpixels, -screenXsize/2, screenXsize/2);
//    location.y = map(coord.y, 0, screenYpixels, -screenYsize/2, screenYsize/2);
//    return location;
//  }
}
