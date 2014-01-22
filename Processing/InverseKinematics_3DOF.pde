boolean connected = false;    // set to false when Arduino isn't connected

import processing.serial.*;
Serial arduino;

import de.voidplus.leapmotion.*;
LeapMotion leap;
Hand hand;
boolean leapInput = false;

import controlP5.*;
ControlP5 cp5;
Knob knobServo1;
Knob knobServo2;
Knob knobServo3;
Slider sliderArmX;
Slider sliderArmY;
Slider sliderArmZ;
Slider sliderScreenX;
Slider sliderScreenY;
Slider sliderScreenZ;

boolean servoMode = false;
boolean screenXYZ = true;

int screenXpixels = 768;
int screenYpixels = 1024;
float screenXsize = 149;
float screenYsize = 198;

//v7 arm
PVector screenCentre = new PVector(68, -27, -188);   // mm from shoulder joint to middle of screen
float screenTilt = 0.04f;  // radians from vertical

// at home
//PVector screenCentre = new PVector(37, -45, -190.8);   // mm from shoulder joint to middle of screen
//float screenTilt = 0.11f;  // radians from vertical

/* for milestone 3 demo
PVector screenCentre = new PVector(27, 0, -190.8);   // mm from shoulder joint to middle of screen
float screenTilt = 0.03f;  // radians from vertical
*/

float originX;
float originY;
float originZ;

float originAxisSize = 200;
float originPlaneSize = 250;

PVector arm = new PVector(0, 0, 0);
PVector screen = new PVector(0, 0, 0);

float upperArmLength = 108.5;
float lowerArmLength = 137.5;  // 141 for Adonit, 134 for other stylus

 float alpha;
 float A; 
 float B;
 float q1a;
 float q1;
 float q2;
 float theta1;
 float theta2;

 // arm v6
// Servo servo1 = new Servo(PI/2, 1962, 1038, 1500, radians(-35), radians(45));  // these limits should be set in Arduino too
// Servo servo2 = new Servo(PI/2, 1004, 1975, 1481, radians(-45), radians(45));
// Servo servo3 = new Servo(PI/2, 1061, 2023, 1534, radians(-45), radians(45));
 
 // arm v5
 Servo servo1 = new Servo(PI/2, 900, 2100, 1500, radians(-35), radians(45));  // these limits should be set in Arduino too
 Servo servo2 = new Servo(PI/2, 2050, 850, 1450, radians(-45), radians(45));
 Servo servo3 = new Servo(PI/2, 2100, 900, 1500, radians(-45), radians(45));
 
 int sketchTime1 = 4000;
 int sketchTime2 = 2000;
 int sketchTime3 = 2000;
 int sketchTime4 = 2000;
 int sketchStart;
 float faceDiam = 60.0;
 float eyeDiam = 12.0;
 float mouthDiam = 35.0;
 boolean sketching;

 ArrayList<PVector> sketchPoints;
 //Path squarePath = new Path("square");
 Goto move = new Goto();
 Path square = new Path("square");
 Path face = new Path("face");
 Path grid = new Path("grid");
 Path save = new Path("save");
 Path file = new Path("file");
 Path ink = new Path("ink");
 
 float deltaX = 2.0;
 float deltaY = 2.0;
 float deltaZ = 1.0;
 int deltaXdirection;
 int deltaYdirection;
 int deltaZdirection;
 boolean arrowsMove = false;
 boolean mouseMove = false;
 
//=========================================================================================================================== 
 void setup() {
    size(800, 800, P3D); 
    lights();   
    smooth(4);
    if (connected) {
      arduino = new Serial(this, "COM3", 57600);
    }
    sketchPoints = new ArrayList<PVector>();
    
    addUI();
    
    leap = new LeapMotion(this);
    
    //String[] lines = loadStrings("woman2.txt");
 }

//===========================================================================================================================  
 void draw() {
  background(0);
  
  if (!servoMode) {           // get x, y, z coordinates
    
    if(move.running) {
      move.update();
    } else if(square.running) {
      square.update();
    } else if(face.running) {
      face.update();
    } else if(grid.running) {
      grid.update();
    } else if (save.running) {
      save.update();
    } else if (file.running) {
      file.update();
    } else if (leapInput) {
      readLeap();
    }else if (arrowsMove) {
      arrowsInput();
    } else if (mouseMove) {
      mouseInput();
    }
    
    if (screenXYZ) {           // if inputting screen coords, 
      calculateXYZ();            // calculate arm coords
    }
    calculateJointAngles();
    
  } else {                    // if manually adjusting servos
    readJointAngles();           // from UI controls
  }
  
  calculateServoAngles();
  if (connected) sendData();

  drawModel();
  printDebug();

 }

//===========================================================================================================================
void calculateXYZ() {
  // calculate the robot arm x,y,z coords from the iPad x,y,z coords (allowing for tilt)
  // refer to arm-screen_coords_transform.jpg 
  
  arm.x = screen.x + screenCentre.x;
  arm.y = ((screen.y - (screen.z / tan(screenTilt))) * cos(screenTilt)) + (screen.z / tan(screenTilt)) + screenCentre.y;
  arm.z = screenCentre.z - ((screen.y - (screen.z / tan(screenTilt))) * sin(screenTilt));
  
  // lift the stylus a little in the centre of the screen to take into account the roundness of the tip
  float hotspotX = 0;
  float hotspotY = 10;
  float distFromScreenCentre = sqrt(sq(screen.x - hotspotX) + sq(screen.y - hotspotY));
  float adjustZ = max(map(distFromScreenCentre, 0, screenXsize/2, 0.5, 0), 0);
  //arm.z += adjustZ;
  
  sliderArmX.setValue(arm.x);
  sliderArmY.setValue(arm.y);
  sliderArmZ.setValue(arm.z);

}

//===========================================================================================================================
void calculateJointAngles() {
  /*  refer to angles.jpg
  
    x - positive to the right of the iPad screen
    y - positive up the iPad screen
    z - away from the iPad screen
    
    Shoulder Joint Rotation (alpha)
    when looking at the shoulder from the right
    - positive clockwise
    - zero degrees is horizontal
      
    Shoulder Joint Extension (theta1)
    when looking at the shoulder from the top
    - negative clockwise
    - zero degrees is pointing directly at the screen
    
    Elbow Joint Extension (theta2)
    when looking at the elbow from the top
    - negative couter-clockwise
    - 0 degrees is lower arm in line with upper arm
    
  */
  A = sqrt(sq(arm.y) + sq(arm.z)); 
  B = constrain(sqrt(sq(A) + sq(arm.x)), 0, upperArmLength + lowerArmLength) ;
  q1 = atan2(-arm.x, -A);
  q2 = acos((sq(upperArmLength) - sq(lowerArmLength) + sq(B))/(2*upperArmLength*B));

  alpha = atan2(-arm.y, -arm.z);
 
  theta1 = PI/2 + (q1 + q2);
  if (theta1 > PI) {
    theta1 = theta1 - TWO_PI;  // this is negative when servo is moving with the arm
  } 
  
  theta2 = -PI + acos((sq(upperArmLength) + sq(lowerArmLength) - sq(B))/(2*upperArmLength*lowerArmLength));

  //theta1 = PI - (q1 + q2);
  //theta1 = -PI + (q1 + q2);  // when servo was on arm
//  if (theta1 < -PI) {
//    theta1 = -(TWO_PI + theta1);  // this is negative when servo is moving with the arm
//  } else {
//    theta1 = -theta1;
//  }    
}

//===========================================================================================================================
void calculateServoAngles() {
  // the angle the servo needs to go to, to make the joint angle required
  
  // alpha ----
  servo1.setAngle(alpha);
  knobServo1.setValue(alpha);
  
  // theta1 ----
  servo2.setAngle(theta1 + PI/4);      // adding 45 degrees so the servo central point is pointing at 45deg out of the joint
  knobServo2.setValue(theta1 + PI/4);
  
  // theta2 ----
  servo3.setAngle(theta2 + PI/4);      // adding 45 degrees so the servo central point is pointing at 45deg out of the joint
  knobServo3.setValue(theta2 + PI/4);  
}

//===========================================================================================================================
void readJointAngles() {
  alpha = knobServo1.getValue();
  //theta1 = -knobServo2.getValue() + PI/4;  // servo is positioned so that servo centre points upper arm at 45deg;
  theta1 = knobServo2.getValue() - PI/4;  // servo is positioned so that servo centre points upper arm at 45deg;
  theta2 = knobServo3.getValue() - PI/4;  // servo is positioned so that servo centre points lower arm at 45deg

}

//=========================================================================================================================== 
void keyPressed() {
 if (key == CODED) {
   if (keyCode == LEFT) {
     arrowsMove = true;
     deltaXdirection = -1;
   } else if (keyCode == RIGHT) {
     arrowsMove = true;
     deltaXdirection = 1;
   } else if (keyCode == UP) {
     arrowsMove = true;
     deltaYdirection = 1;
   } else if (keyCode == DOWN) {
     arrowsMove = true;
     deltaYdirection = -1;
   }
   
 } else {
   if (key == ' ') {
     sketchStart = millis();
     sketching = !sketching; 
     //sketchPoints = new ArrayList<PVector>();
     sketchPoints.clear();
     
   } else if (key == 'x' || key == 'X') {
     sketchPoints.clear();
   } else if (key == 'h' || key == 'H') {
     move.to(new PVector(-60, 80, screen.z), 200);
   } else if (key == 'c' || key == 'C') {
     move.to(new PVector(0, 0, screen.z), 200);
   } else if (key == 'g' || key == 'G') {
     if (!grid.running) {
       grid.start();
     } else {
       grid.running = false;
     }
   } else if (key == 'p' || key == 'P') {
     square.start();
   } else if (key == 'f' || key == 'F') {
     if (!face.running) {
       face.start();
     } else {
       face.running = false;
     }
   } else if (key == '1') {
     move.to(new PVector(-70, 95, screen.z), 400);
   } else if (key == '2') {
     move.to(new PVector(70, 95, screen.z), 400);
   } else if (key == '3') {
     move.to(new PVector(70, -95, screen.z), 400);
   } else if (key == '4') {
     move.to(new PVector(-70, -95, screen.z), 400);
   } else if (key == 'l' || key == 'L') {
     leapInput = !leapInput;
   } else if (key == 'a' || key == 'A') {
     arrowsMove = true;
     deltaZdirection = -1;
   } else if (key == 'z' || key == 'Z') {
     arrowsMove = true;
     deltaZdirection = 1;
   } else if (key == 'm' || key == 'M') {
     mouseMove = !mouseMove;
   } else if (key == 's' || key == 'S') {   // Save button
     save.start();
   } else if (key == 'k' || key == 'K') {   // select black ink
     ink.start();
   } else if (key == 'i' || key == 'I') {
     if (!file.running) {
       file.start();
     } else {
       file.running = false;
     }
   }
 }
  
}

//===========================================================================================================================
void keyReleased() {
 if (key == CODED) {
   if (keyCode == LEFT || keyCode == RIGHT) {
     arrowsMove = false;
     deltaXdirection = 0;
   } else if (keyCode == UP || keyCode == DOWN) {
     arrowsMove = false;
     deltaYdirection = 0;
   }
 } else {
   if (key == 'a' || key == 'A') {
     arrowsMove = false;
     deltaZdirection = 0;
   } else if (key == 'z' || key == 'Z') {
     arrowsMove = false;
     deltaZdirection = 0;
   }
 }
}


//=========================================================================================================================== 
void drawSketch() {
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
}

//===========================================================================================================================
void sendData() {
  
  arduino.write(65);  // 'A'
  arduino.write(servo1.microSeconds);
  arduino.write(servo1.microSeconds >> 8);
  arduino.write(servo2.microSeconds);
  arduino.write(servo2.microSeconds >> 8); 
  arduino.write(servo3.microSeconds);
  arduino.write(servo3.microSeconds >> 8);  

}

//===========================================================================================================================
void drawModel() {
  stroke(255, 100);
  noFill();
  pushMatrix();
    translate(width/2.5, height/2, 300);
    
    rotateX(originX);    
    rotateY(originY);
    rotateZ(originZ);
    
    drawAxes();
    drawArm();
    drawScreen();
    drawSketch();
    
  popMatrix();
  
  // backgrounds to the servo knobs
  fill(23, 100, 205, 65);
  noStroke();
  rect(9, 440, 75, 113);
  rect(9, 560, 75, 113);
  rect(9, 680, 75, 113);
  
  // text under the servo knobs
  fill(150);
  text(int(degrees(servo1.angle)) + " deg", 17, 528);
  text(servo1.microSeconds + " uSec", 17, 543);
  text(int(degrees(servo2.angle)) + " deg", 17, 648);
  text(servo2.microSeconds + " uSec", 17, 663);
  text(int(degrees(servo3.angle)) + " deg", 17, 768);
  text(servo3.microSeconds + " uSec", 17, 783);
  
  // instructions in lower right corner
  fill(200);
  text("press <SPACE> to start sketch", width - 200, height - 30);
  text("press <X> to clear sketch", width - 200, height - 15);
  
}

//===========================================================================================================================  
void drawAxes() {
  
  // draw axes --------------------
  beginShape(LINES);
  strokeWeight(1);
  // X axis
  stroke(255, 0, 0);
  vertex(-originAxisSize, 0, 0);
  vertex(originAxisSize, 0, 0);
  // Y axis
  stroke(0, 255, 0);
  vertex(0, -originAxisSize, 0);
  vertex(0, originAxisSize, 0);
  // Z axis
  stroke(0, 0, 255);
  vertex(0, 0, -originAxisSize);
  vertex(0, 0, originAxisSize);
  endShape();

//  // draw origin planes --------------------
//  stroke(255, 40);
//  strokeWeight(1);
//  beginShape(QUADS);
//  // YZ plane
//  vertex(0, originPlaneSize, originPlaneSize);
//  vertex(0, -originPlaneSize, originPlaneSize);
//  vertex(0, -originPlaneSize, -originPlaneSize);
//  vertex(0, originPlaneSize, -originPlaneSize);
//  // XZ plane
//  vertex(originPlaneSize, 0, originPlaneSize);
//  vertex(-originPlaneSize, 0, originPlaneSize);
//  vertex(-originPlaneSize, 0, -originPlaneSize);
//  vertex(originPlaneSize, 0, -originPlaneSize);
//  endShape();
//  // XY plane
//  vertex(originPlaneSize, originPlaneSize, 0);
//  vertex(-originPlaneSize, originPlaneSize, 0);
//  vertex(-originPlaneSize, -originPlaneSize, 0);
//  vertex(originPlaneSize, -originPlaneSize, 0);
//  endShape();  
}
 
//=========================================================================================================================== 
 void drawArm() {
   // draw x,y,z target -----------
   fill(23, 100, 205);
   noStroke();
   pushMatrix();
     translate(arm.x, -arm.y, arm.z);
     sphere(4);
   popMatrix();
  
   // draw arm -----------
   pushMatrix();
     fill(0, 0, 255);
     noStroke();
     rotateY(PI/2);
     ellipse(0, 0, 30, 30);
   popMatrix();
       
   pushMatrix();
     if (alpha != 0) {
       rotateX(alpha);
     }
     pushMatrix();
       rotateY(PI/2);
       
       // 0 degree line
       beginShape(LINES);
       stroke(50, 70, 190);
       strokeWeight(1);
       vertex(0, 0, 0);
       vertex(25, 0, 0);
       endShape();
       
       //rotateY(PI - theta1);
       //rotateY(theta1);  // when servo was on arm
       rotateY(-theta1 - PI/2);
       beginShape(LINES);
       stroke(150);
       strokeWeight(5);
       vertex(0, 0, 0);
       vertex(upperArmLength, 0, 0);
       endShape(); 
       
       pushMatrix();
           fill(23, 100, 205);
           noStroke();
           rotateX(PI/2);
           ellipse(0, 0, 20, 20);
       popMatrix();
       
       pushMatrix();
         translate(upperArmLength, 0, 0);
         pushMatrix();
           
           // 0 degree line
           beginShape(LINES);
           stroke(50, 70, 190);
           strokeWeight(1);
           vertex(0, 0, 0);
           vertex(15, 0, 0);
           endShape();
           
           
           rotateY(-theta2);
           beginShape(LINES);
           stroke(150);
           strokeWeight(5);
           vertex(0, 0, 0);
           vertex(lowerArmLength, 0, 0);
           endShape(); 
         popMatrix();
         
         pushMatrix();
           fill(23, 100, 205);
           noStroke();
           rotateX(PI/2);
           ellipse(0, 0, 20, 20);
         popMatrix();
         
       popMatrix();
     popMatrix();
   popMatrix();
 }

//=========================================================================================================================== 
void drawScreen() {
  stroke(255, 100);
  fill(255, 30);
  strokeWeight(1);
  pushMatrix();
    translate(screenCentre.x, -screenCentre.y, screenCentre.z);
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

//===========================================================================================================================
void readLeap() {
  if (leap.hasHands()) {
    hand = leap.getHands().get(0);
    
    float leapX = hand.getPosition().x;
    float leapY = hand.getPosition().y;
    float leapZ = hand.getPosition().z;  
    screen.x = constrain(map(leapX, 320, 475, -screenXsize/2, screenXsize/2), -screenXsize/2, screenXsize/2);
    screen.y = constrain(map(leapY, 600, 400, -screenYsize/2, screenYsize/2), -screenYsize/2, screenYsize/2);
    screen.z = constrain(map(leapZ, 40, 30, 0, 50), 0, 50);
    //println(leapX + "  " + leapY);
    sliderScreenX.setValue(screen.x);
    sliderScreenY.setValue(screen.y);
    sliderScreenZ.setValue(screen.z);
  }
}

//===========================================================================================================================
void arrowsInput() {
  screen.x = constrain(screen.x + (deltaX * deltaXdirection), -screenXsize/2, screenXsize/2);
  screen.y = constrain(screen.y + (deltaY * deltaYdirection), -screenYsize/2, screenYsize/2); 
  screen.z = constrain(screen.z + (deltaZ * deltaZdirection), 0, 50);
  sliderScreenX.setValue(screen.x);
  sliderScreenY.setValue(screen.y);
  sliderScreenZ.setValue(screen.z);
}

//===========================================================================================================================
void mouseInput() {
  screen.x = constrain(map(mouseX, 100, 700, -screenXsize/2, screenXsize/2), -screenXsize/2, screenXsize/2);
  screen.y = constrain(map(mouseY, 0, 800, screenYsize/2, -screenYsize/2), -screenYsize/2, screenYsize/2); 
  sliderScreenX.setValue(screen.x);
  sliderScreenY.setValue(screen.y);
}

//=========================================================================================================================== 
void printDebug() {
  fill(255);
  int textY = 695;
  text("A:        " + nf(A, 0, 1), 100, textY);
  text("B:        " + nf(B, 0, 1), 100, textY+15);
  text("q1:      " + nf(q1, 0, 2), 100, textY+30);
  text("q2:      " + nf(q2, 0, 2), 100, textY+45);
  text("alpha:  " + nf(alpha, 0, 2), 100, textY+60);
  text("theta1: " + nf(theta1, 0, 2), 100, textY+75);
  text("theta2: " + nf(theta2, 0, 2), 100, textY+90);
  
  //println("alpha:" + alpha + "  " + "A:" + A + "  " + "B:" + B + "  " + "q1a:" + q1a + "  " + "q1:" + q1 + "  " + "q2:" + q2 + "  " + "theta1:" + theta1 + "  " + "theta2:" + theta2); 
}

//===========================================================================================================================
void addUI() {
    // arm X,Y,Z sliders ------------------------------------------------------
    cp5 = new ControlP5(this);
    // arm.x slider
    sliderArmX = cp5.addSlider("armX")
     .setPosition(20,20)
     .setSize(200, 10)
     .setRange(-(upperArmLength+lowerArmLength),upperArmLength+lowerArmLength)
     .setValue(0.0);
     ;
    
    // arm.y slider
    sliderArmY = cp5.addSlider("armY")
     .setPosition(20,40)
     .setSize(200, 10)
     .setRange(-(upperArmLength+lowerArmLength),upperArmLength+lowerArmLength)
     .setValue(0.0)
     ;

    // arm.z slider     
    sliderArmZ = cp5.addSlider("armZ")
     .setPosition(20,60)
     .setSize(200, 10)
     .setRange(-(upperArmLength+lowerArmLength),upperArmLength+lowerArmLength)
     .setValue(-100.0)
     ; 

    // arm X,Y,Z sliders ------------------------------------------------------
    // screen.x slider
    sliderScreenX = cp5.addSlider("screenX")
     .setPosition(20,100)
     .setSize(200, 10)
     .setRange(-screenXsize/2,screenXsize/2)
     .setValue(-74.0);
     ;
    
    // screen.y slider
    sliderScreenY = cp5.addSlider("screenY")
     .setPosition(20,120)
     .setSize(200, 10)
     .setRange(-screenYsize/2,screenYsize/2)
     .setValue(-99.0)
     ;

    // screen.z slider     
    sliderScreenZ = cp5.addSlider("screenZ")
     .setPosition(20,140)
     .setSize(200, 10)
     .setRange(0.0, 50.0)
     .setValue(40.0)
     ;   
    
    // armXYZ vs screenXYZ toggle ---------------------------------------------
    cp5.addToggle("screenXYZ")
       .setPosition(20,160)
       .setSize(50,20)
       .setValue(true);
       ;
    
    // origin X,Y,Z sliders ------------------------------------------------------
    // origin X slider
    cp5.addSlider("originX")
     .setPosition(width-270,20)
     .setSize(200, 10)
     .setRange(-PI/2,PI/2)
     .setValue(-0.6)
     ;
  
    // origin Y slider
    cp5.addSlider("originY")
     .setPosition(width-270,40)
     .setSize(200, 10)
     .setRange(-PI/2,PI/2)
     .setValue(-1.0)
     ; 
  
    // origin Z slider
    cp5.addSlider("originZ")
     .setPosition(width-270,60)
     .setSize(200, 10)
     .setRange(-PI/2,PI/2)
     .setValue(0.0)
     ;

    // screen orientation sliders -----------------------------------------------
    float initialValue = screenCentre.x;  // strange behaviour where it doesn't work if I put 'screenCentre.x' in .setValue
    cp5.addSlider("screenCentreX")
     .setPosition(width-270,100)
     .setSize(200, 10)
     .setRange(-screenXsize/2, screenXsize/2)
     .setValue(initialValue)
     ;

    initialValue = screenCentre.y;  // strange behaviour where it doesn't work if I put 'screenCentre.y' in .setValue
    cp5.addSlider("screenCentreY")
     .setPosition(width-270,120)
     .setSize(200, 10)
     .setRange(-screenYsize/2, screenYsize/2)
     .setValue(initialValue)
     ;
     
    initialValue = screenCentre.z;  // strange behaviour where it doesn't work if I put 'screenCentre.z' in .setValue
    cp5.addSlider("screenCentreZ")
     .setPosition(width-270,140)
     .setSize(200, 10)
     .setRange(-upperArmLength, -upperArmLength - lowerArmLength)
     .setValue(initialValue)
     ;
     
    cp5.addSlider("screenTilt")
     .setPosition(width-270,160)
     .setSize(200, 10)
     .setRange(0,PI/4)
     .setValue(screenTilt)
     ;      
     
    // XYZ vs servo angle input toggle -----------------------------------------
    cp5.addToggle("servoMode")
       .setPosition(20,400)
       .setSize(50,20)
       ;

    // servo knobs -------------------------------------------------------------
    // servo1 'alpha' knob
    knobServo1 = cp5.addKnob("servo1.angle")
               .setRange(-servo1.angleRange/2,servo1.angleRange/2)
               .setValue(0)
               .setPosition(20,450)
               .setRadius(25)
               .setDragDirection(Knob.HORIZONTAL)
               .setViewStyle(1)
               .setAngleRange(servo1.angleRange)
               .setStartAngle(PI/2 + ((TWO_PI - servo1.angleRange)/2))
               ;
     
     // servo2 'theta1' knob
     knobServo2 = cp5.addKnob("servo2.angle")
               .setRange(-servo2.angleRange/2,servo2.angleRange/2)
               .setValue(0)
               .setPosition(20,570)
               .setRadius(25)
               .setDragDirection(Knob.HORIZONTAL)
               .setViewStyle(1)
               .setAngleRange(servo2.angleRange)
               .setStartAngle(PI/2 + ((TWO_PI - servo2.angleRange)/2))
               ;
               
     // servo3 'theta2' knob
     knobServo3 = cp5.addKnob("servo3.angle")
               .setRange(-servo3.angleRange/2,servo3.angleRange/2)
               .setValue(0)
               .setPosition(20,690)
               .setRadius(25)
               .setDragDirection(Knob.HORIZONTAL)
               .setViewStyle(1)
               .setAngleRange(servo3.angleRange)
               .setStartAngle(PI/2 + ((TWO_PI - servo3.angleRange)/2))
               ;
}

//===========================================================================================================================
// Event Handlers for sliders
void armX(float theValue) {
  arm.x = theValue;
}
void armY(float theValue) {
  arm.y = theValue;
}
void armZ(float theValue) {
  arm.z = theValue;
}
void screenX(float theValue) {
  screen.x = theValue;
}
void screenY(float theValue) {
  screen.y = theValue;
}
void screenZ(float theValue) {
  screen.z = theValue;
}
void screenCentreX(float theValue) {
  screenCentre.x = theValue;
}
void screenCentreY(float theValue) {
  screenCentre.y = theValue;
}
void screenCentreZ(float theValue) {
  screenCentre.z = theValue;
}
