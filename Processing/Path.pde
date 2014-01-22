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
    } else if (type == "grid") {
      gridPoints(); 
    } else if (type == "save") {
      savePoints(); 
    } else if (type == "file") {
      filePoints2(); 
    } else if (type == "ink") {
      inkPoints(); 
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
    //move.to(screenX, screenY, 20, 100);
  }

  void update() {
    
    if (move.running) {
      move.update();
      
    } else {
      if (segment < locations.size()) {
        PVector nextLocation = locations.get(segment);
        move.to(nextLocation, 100);
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

//===========================================================================================================================  
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
  
//===========================================================================================================================
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

//===========================================================================================================================
  void gridPoints() {
    int columns = 7;
    int rows = 7;
    int borderX = 40;
    int borderY = 100;
    int intervalX = (screenXpixels - (borderX * 2)) / columns;
    int intervalY = (screenYpixels - (borderY * 2)) / rows;
    int endX = borderX + (intervalX * columns);
    int endY = borderY + (intervalY * columns);
   
    int y = borderY;
    for (int x = borderX; x <= endX; x += intervalX) {
      coords.add(new PVector(x, y, 10));
      coords.add(new PVector(x, y, 0));
      if (y == borderY) { 
        y = endY;
      } else {
        y = borderY;
      }
      coords.add(new PVector(x, y, 0));
      coords.add(new PVector(x, y, 10));
    }

    int x = endX;
    for (y = borderY; y <= endY; y += intervalY) {
      coords.add(new PVector(x, y, 10));
      coords.add(new PVector(x, y, 0));
      if (x == borderX) { 
        x = endX;
      } else {
        x = borderX;
      }
      coords.add(new PVector(x, y, 0));
      coords.add(new PVector(x, y, 10));
    }
    
//    for (int i = 0; i < coords.size(); i++) {
//      println(coords.get(i).x + "  " + coords.get(i).y + "  " + coords.get(i).z);
//    }
    
    convertCoords(coords);  
  }  

//===========================================================================================================================
  void savePoints() {
    PVector galleryButton = new PVector(20, 50);
    PVector saveButton = new PVector(360, 530);
    PVector wasteTime = new PVector(450, 210);
    PVector galleryItem = new PVector(80, 210);
    PVector shareButton = new PVector(465, 985);
    PVector printButton = new PVector(465, 935);
    PVector orientationOption = new PVector(395, 665);
    PVector selectPrinter = new PVector(540, 775);
    PVector finalPrintButton = new PVector(465, 930);
    
    tap(galleryButton, 0, -25);                                // tap top-left button
    tap(saveButton, 0, 10);                                    // tap confirm button
    //coords.add(new PVector(wasteTime.x, wasteTime.y, 10));     // wait for gallery
    pause(saveButton, 600);
    tap(galleryItem, 0, 10);                                   // tap on image (top-left item)
    tap(shareButton, 0, 20);                                   // tap on Share button at bottom edge
    pause(shareButton, 200);
    tap(printButton, 0, 20);                                   // tap on Print
    tap(orientationOption, 0, 20);                             // choose image orientation (top-left)
    pause(orientationOption, 400);
//    tap(selectPrinter, 20, 0);                                 // select printer (if necessary)
    tap(finalPrintButton, 10, 0);                              // tap on Print button    
    
    convertCoords(coords);  
  }
  
  void tap(PVector spot, int dragX, int dragY) {
    coords.add(new PVector(spot.x, spot.y, 10));
    coords.add(new PVector(spot.x, spot.y, 0));
    //coords.add(new PVector(spot.x, spot.y, 0));
    coords.add(new PVector(spot.x + dragX, spot.y + dragY, 0));
    coords.add(new PVector(spot.x, spot.y, 10));
  }
  
  void pause(PVector spot, int time) {
    for (int i=0; i<=time; i+=200) {
      coords.add(new PVector(spot.x, spot.y, 10));
    } 
  }
  
//===========================================================================================================================
  void filePoints() {
    String[] lines;
    int index = 0;
    PVector point = new PVector(0, 0);
    PVector prevPoint = new PVector(0, 0);
    
    lines = loadStrings("file:///C:/Users/thomasd/Documents/Processing/InverseKinematics_3DOF/Boby.txt");
    
    while (index < lines.length) {
      String[] pieces = split(lines[index], " ");
      if (pieces.length == 2) {
        point.x = int(pieces[0])-1200;
        point.y = int(pieces[1])+100;
        
        // lift the pen if there's a gap
        if (PVector.dist(point, prevPoint) > 40) {
          println(pieces[0] + "  " + pieces[1]);
          coords.add(new PVector(prevPoint.x, prevPoint.y, 10));
          coords.add(new PVector(point.x, point.y, 10));
        }
        
        coords.add(new PVector(point.x, point.y, 0));
        prevPoint = point.get();
      }
      index = index + 1;
    }
    
    convertCoords(coords);
  }

//===========================================================================================================================
  void filePoints2() {
    String[] lines;
    PVector point = new PVector(0, 0, 0);
    
    lines = loadStrings("file:///C:/Users/thomasd/Documents/Processing/InverseKinematics_3DOF/points.txt");
    
    for (int i=0; i < lines.length; i++) {
      String[] pieces = split(lines[i], ",");
      if (pieces.length == 3) {
        coords.add(new PVector(int(pieces[0]), int(pieces[1]), int(pieces[2])));
      }
    }
    
    convertCoords(coords);
  }

//===========================================================================================================================
  void inkPoints() {
    PVector brushButton = new PVector(390, 50);
    PVector colorWheel = new PVector(360, 530);
    PVector wasteTime = new PVector(450, 210);
    PVector galleryItem = new PVector(80, 210);
    PVector shareButton = new PVector(465, 985);
    PVector printButton = new PVector(465, 935);
    PVector orientationOption = new PVector(395, 665);
    PVector selectPrinter = new PVector(540, 775);
    PVector finalPrintButton = new PVector(465, 930);
 println("yep");   
   tap(brushButton, 0, -25);                                // tap top-left button
//    tap(saveButton, 0, 10);                                    // tap confirm button
//    //coords.add(new PVector(wasteTime.x, wasteTime.y, 10));     // wait for gallery
//    pause(saveButton, 600);
//    tap(galleryItem, 0, 10);                                   // tap on image (top-left item)
//    tap(shareButton, 0, 20);                                   // tap on Share button at bottom edge
//    pause(shareButton, 200);
//    tap(printButton, 0, 20);                                   // tap on Print
//    tap(orientationOption, 0, 20);                             // choose image orientation (top-left)
//    pause(orientationOption, 400);
////    tap(selectPrinter, 20, 0);                                 // select printer (if necessary)
//    tap(finalPrintButton, 10, 0);                              // tap on Print button    
    
    convertCoords(coords);  
  }
  
}


