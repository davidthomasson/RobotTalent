class Path {
  ArrayList<PVector> locations;
  ArrayList<PVector> coords;
  PVector origin;
  float maxSpeed = 100.0; // mm/sec
  int transmitInterval = 100;  // mSec between instructions sent to arm
  boolean running;
  int segment;
  Goto move;

  Path(String type) {
    locations = new ArrayList<PVector>();
    coords = new ArrayList<PVector>();
    running = false;
    segment = 0;
    move = new Goto();
    
    if (type == "square") {
      squarePoints();
    } else if (type == "face") {
      facePoints();
    }
    
  }

//  void load(String type) {
//    if (type == "square") {
//      coords = new ArrayList<PVector>();
//      coords.add(new PVector(50, 50));
//      coords.add(new PVector(50, 970));
//      coords.add(new PVector(720, 970));
//      coords.add(new PVector(720, 50)); 
//      coords.add(new PVector(50, 50));
//
//      convertCoords(coords);
//    }
//    
//  }
  
  void start() {
    segment = 0;
    running = true;
    move.to(screenX, screenY, 20, 100);
  }

  void update() {
    
    if (move.running) {
      move.update();
      
    } else {
      if (segment < locations.size()) {
        PVector nextLocation = locations.get(segment);
        move.to(nextLocation.x, nextLocation.y, nextLocation.z, 100);
        segment++;
      } else {
        running = false; 
      }
    }

  }
  
  void convertCoords(ArrayList<PVector> coords_) {
    for (int i = 0; i < coords_.size(); i++) {
      PVector thisCoord = coords_.get(i);
      PVector thisLocation = new PVector(0, 0, 0);
      thisLocation.x = map(thisCoord.x, 0, screenXpixels, -screenXsize/2, screenXsize/2);
      thisLocation.y = map(thisCoord.y, 0, screenYpixels, screenYsize/2, -screenYsize/2);
      thisLocation.z = thisCoord.z;
      locations.add(new PVector(thisLocation.x, thisLocation.y, thisLocation.z));
    }
  }
  
  void run() {
    
    
  }
  
  void squarePoints() {
    coords.add(new PVector(50, 50, 20));
    coords.add(new PVector(50, 50, 0));
    coords.add(new PVector(50, 970, 0));
    coords.add(new PVector(720, 970, 0));
    coords.add(new PVector(720, 50, 0)); 
    coords.add(new PVector(50, 50, 0));
    coords.add(new PVector(50, 50, 20));

    convertCoords(coords);  
  }
  
  void facePoints() {
    int faceCenterX = 384;
    int faceCenterY = 512;
    int faceDiam = 250;
  
    // draw outer circle
    circle(faceCenterX, faceCenterY, faceDiam, 16);
    
    // draw left eye
    int eyeCenterX = faceCenterX - (faceDiam/3);
    int eyeCenterY = faceCenterY - (faceDiam/3);
    int eyeDiam = faceDiam/4;
    circle(eyeCenterX, eyeCenterY, eyeDiam, 16);
    
    // draw right eye
    eyeCenterX = faceCenterX + (faceDiam/3);
    circle(eyeCenterX, eyeCenterY, eyeDiam, 16);
    
    // draw mouth
    circleSegment(faceCenterX, faceCenterY, 150, 16, 4, 12);
    
    convertCoords(coords);
  }
  
  void circle(int centerX, int centerY, int diam, int segments) {
    float deltaAngle = TWO_PI / segments;
    
    for (int i=0; i<=segments+1; i++) {
      float thisAngle = i * deltaAngle;
      float pointX = (diam * sin(thisAngle)) + centerX;
      float pointY = centerY - (diam * cos(thisAngle));
      
      if (i == 0) coords.add(new PVector(pointX, pointY, 20));
      coords.add(new PVector(pointX, pointY, 0));
      if (i == segments+1) coords.add(new PVector(pointX, pointY, 20));
    }
    
  }

  void circleSegment(int centerX, int centerY, int diam, int segments, int startSegment, int endSegment) {
    float deltaAngle = TWO_PI / segments;
    
    for (int i=startSegment; i<=endSegment+1; i++) {
      float thisAngle = i * deltaAngle;
      float pointX = (diam * sin(thisAngle)) + centerX;
      float pointY = centerY - (diam * cos(thisAngle));
      
      if (i == 0) coords.add(new PVector(pointX, pointY, 20));
      coords.add(new PVector(pointX, pointY, 0));
      if (i == endSegment+1) coords.add(new PVector(pointX, pointY, 20));
    }
    
  }  

}
