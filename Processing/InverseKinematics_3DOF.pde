import processing.serial.*;
Serial arduino;

import controlP5.*;
ControlP5 cp5;
Knob knobServoAlpha;
Knob knobServoTheta1;
Knob knobServoTheta2;
Slider sliderServoAlpha;

float originX = 0;
float originY = 0.25;
float originZ = 0;

float originAxisSize = 350;
float originPlaneSize = 250;

float x;
float y;
float z;

float upperArmLength = 135;
float lowerArmLength = 105;

 float alpha;
 float A; 
 float B;
 float q1a;
 float q1;
 float q2;
 float theta1;
 float theta2;
 float alphaServo;
 float theta1Servo;
 float theta2Servo;
 int alphauSec;
 int theta1uSec;
 int theta2uSec;

 int servoCenter = 1500;  // uSec
 float servoRangeRad = 160 * (PI/180);  // degrees
 int servoRangeuSec = 1200;  // uSec 

 int sketchTime1 = 4000;
 int sketchTime2 = 2000;
 int sketchTime3 = 2000;
 int sketchTime4 = 2000;
 int sketchStart;
 float faceDiam = 60.0;
 float eyeDiam = 12.0;
 float mouthDiam = 35.0;
 boolean sketching;

 float fromX;
 float fromY;
 float fromZ;
 float toX;
 float toY;
 float toZ;
 int moveStart;
 int moveDuration;
 boolean moving;

 boolean manual = false;

 ArrayList<PVector> sketchPoints;

//=========================================================================================================================== 
 void setup() {
    size(800, 800, P3D); 
    lights();   
    smooth(4);
    arduino = new Serial(this, "COM3", 57600);
    sketchPoints = new ArrayList<PVector>();
    
    cp5 = new ControlP5(this);
    // X slider
    cp5.addSlider("x")
     .setPosition(20,20)
     .setSize(200, 10)
     .setRange(-(upperArmLength+lowerArmLength),upperArmLength+lowerArmLength)
     .setValue(0.0);
     ;
    
    // Y slider
    cp5.addSlider("y")
     .setPosition(20,40)
     .setSize(200, 10)
     .setRange(-(upperArmLength+lowerArmLength),upperArmLength+lowerArmLength)
     .setValue(0.0)
     ;

    // Z slider     
     cp5.addSlider("z")
     .setPosition(20,60)
     .setSize(200, 10)
     .setRange(-(upperArmLength+lowerArmLength),upperArmLength+lowerArmLength)
     .setValue(-200.0)
     ; 
  
    // origin X slider
    cp5.addSlider("originX")
     .setPosition(width-240,20)
     .setSize(200, 10)
     .setRange(-PI/2,PI/2)
     .setValue(-0.56)
     ;
  
    // origin Y slider
    cp5.addSlider("originY")
     .setPosition(width-240,40)
     .setSize(200, 10)
     .setRange(-PI/2,PI/2)
     .setValue(-0.78)
     ; 
  
    // origin Z slider
    cp5.addSlider("originZ")
     .setPosition(width-240,60)
     .setSize(200, 10)
     .setRange(-PI/2,PI/2)
     ;

    float servoRangeMin = servoCenter - (servoRangeuSec / 2);
    float servoRangeMax = servoCenter + (servoRangeuSec / 2);
    float knobAngleRange = servoRangeRad;
    float knobStartAngle = PI/2 + ((TWO_PI - servoRangeRad)/2);
    
//    // servo 'alpha' slider
//    sliderServoAlpha = cp5.addSlider("alphausec")
//     .setPosition(20,height-40)
//     .setSize(width-40, 10)
//     .setRange(servoRangeMin,servoRangeMax)
//     .setValue(servoCenter)
//     ;
     
    // create a toggle
    cp5.addToggle("manual")
       .setPosition(20,250)
       .setSize(50,20)
       ;
     
    // servo 'alpha' knob
    knobServoAlpha = cp5.addKnob("alphausec")
               .setRange(servoRangeMin,servoRangeMax)
               .setValue(servoCenter)
               .setPosition(20,300)
               .setRadius(25)
               .setDragDirection(Knob.HORIZONTAL)
               .setViewStyle(1)
               .setAngleRange(knobAngleRange)
               .setStartAngle(knobStartAngle)
               ;
     
     // servo 'theta1' knob
     knobServoTheta1 = cp5.addKnob("theta1usec")
               .setRange(servoRangeMin,servoRangeMax)
               .setValue(servoCenter)
               .setPosition(20,370)
               .setRadius(25)
               .setDragDirection(Knob.HORIZONTAL)
               .setViewStyle(1)
               .setAngleRange(knobAngleRange)
               .setStartAngle(knobStartAngle)
               ;
               
     // servo 'theta2' knob
     knobServoTheta2 = cp5.addKnob("theta2usec")
               .setRange(servoRangeMin,servoRangeMax)
               .setValue(servoCenter)
               .setPosition(20,440)
               .setRadius(25)
               .setDragDirection(Knob.HORIZONTAL)
               .setViewStyle(1)
               .setAngleRange(knobAngleRange)
               .setStartAngle(knobStartAngle)
               ;

 }

//===========================================================================================================================  
 void draw() {
  background(0);
  
  if (sketching) {
    sketch();
  }
  if (moving) {
    move(); 
  }
  
  stroke(255, 100);
  noFill();
  pushMatrix();
  translate(width/2, height/2, 0);
  
  rotateX(originX);    
  rotateY(originY);
  rotateZ(originZ);

  //box(400);
  drawAxes();
  drawOriginPlanes();
  drawTarget();
  drawArm();
  drawSketch();
    
  popMatrix();

  drawServos();
  drawNotes();
  printDebug();
  
  sendData();
 }

//=========================================================================================================================== 
 void drawArm() {
   if (!manual) {
     alpha = atan2(-y, -z);
     A = sqrt(sq(y) + sq(z)); 
     //if (z<0) A = -A;
     
     B = constrain(sqrt(sq(A) + sq(x)), 0, upperArmLength + lowerArmLength) ;
     //q1 = (PI/2)- atan2(A, x);
     q1 = atan2(-x, -A);
     
     q2 = acos((sq(upperArmLength) - sq(lowerArmLength) + sq(B))/(2*upperArmLength*B));
     theta1 = PI - (q1 + q2);
     theta2 = -PI + acos((sq(upperArmLength) + sq(lowerArmLength) - sq(B))/(2*upperArmLength*lowerArmLength));
   } else {
       alpha = -servoAngle(int(knobServoAlpha.getValue()));
       theta1 = -servoAngle(int(knobServoTheta1.getValue()));
       theta2 = -servoAngle(int(knobServoTheta2.getValue())) - PI/2;
//     alpha = -knobServoAlpha.getValue()-1475)/925.0*1.309;  // 1475 midpoint, 1850uS,150deg(2.618rad) range
//     theta1 = -(knobServoTheta1.getValue()-1475)/925.0*1.309;
//     theta2 = -(knobServoTheta2.getValue()-1475)/925.0*1.309 - PI/2;
   }
 
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
       vertex(30, 0, 0);
       endShape();
       
       //rotateY(PI - theta1);
       rotateY(theta1);
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
           vertex(25, 0, 0);
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
 void drawTarget() {
  fill(23, 100, 205);
  noStroke();
  pushMatrix();
    translate(x, -y, z);
    sphere(5);
  popMatrix();
 }

//===========================================================================================================================  
 void drawAxes() {
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
 }

//===========================================================================================================================  
 void drawOriginPlanes() {
  stroke(255, 40);
  strokeWeight(1);
  beginShape(QUADS);
  // YZ plane
  vertex(0, originPlaneSize, originPlaneSize);
  vertex(0, -originPlaneSize, originPlaneSize);
  vertex(0, -originPlaneSize, -originPlaneSize);
  vertex(0, originPlaneSize, -originPlaneSize);
  // XZ plane
  vertex(originPlaneSize, 0, originPlaneSize);
  vertex(-originPlaneSize, 0, originPlaneSize);
  vertex(-originPlaneSize, 0, -originPlaneSize);
  vertex(originPlaneSize, 0, -originPlaneSize);
  endShape();
  // XY plane
  vertex(originPlaneSize, originPlaneSize, 0);
  vertex(-originPlaneSize, originPlaneSize, 0);
  vertex(-originPlaneSize, -originPlaneSize, 0);
  vertex(originPlaneSize, -originPlaneSize, 0);
  endShape();  
 }

//===========================================================================================================================  
 void drawArmSimple() {
  beginShape(LINES);
  // X axis
  stroke(255);
  strokeWeight(5);
  vertex(0, 0, 0);
  vertex(x, y, z);
  endShape(); 
 }

//=========================================================================================================================== 
void drawServos() {
  
  // alpha ----
  alphaServo = alpha;
  fill(150);
  text("shoulder", 20, height - 140);
  text("rotation", 20, height - 130);
  drawServo(alphaServo, 95, height - 140);
  alphauSec = constrain(servouSec(-alpha), 1200, 1800);  // also constrained in Arduino
  knobServoAlpha.setValue(alphauSec);
  
  // theta1 ----
  if (theta1 > PI) {
    theta1Servo = TWO_PI-theta1;
  } else {
    theta1Servo = -theta1;
  }
  fill(150);
  text("shoulder", 20, height - 90);
  text("extension", 20, height - 80);
  drawServo(theta1Servo, 95, height - 90);
  theta1uSec = constrain(servouSec(theta1Servo), 1400, 2100);  // also constrained in Arduino
  knobServoTheta1.setValue(theta1uSec);
  
  // theta2 ----
  theta2Servo = theta2 + PI/2;
  fill(150);
  text("elbow", 20, height - 40);
  text("extension", 20, height - 30);
  drawServo(theta2Servo, 95, height - 40);
  theta2uSec = constrain(servouSec(-theta2Servo), 1000, 1700);  // also constrained in Arduino
  knobServoTheta2.setValue(theta2uSec);
}

//=========================================================================================================================== 
void drawServo(float angle, int posnX, int posnY) {
  pushMatrix();
  translate(posnX, posnY);
  fill(2, 52, 77);
  noStroke();
  ellipse(0, 0, 30, 30);
  
  pushMatrix();
  rotate(angle - PI/2);
  stroke(1, 108, 158);
  strokeWeight(3);
  line(0, 0, 17, 0);
  popMatrix();
  
  int degrees = int(180/PI*angle);
  fill(255);
  text(degrees, 23, 3);
  
  popMatrix();
  
}

//=========================================================================================================================== 
void printDebug() {
  fill(255);
  text("alpha:  " + nf(alpha, 0, 2), 20, 100);
  text("A:        " + nf(A, 0, 1), 20, 115);
  text("B:        " + nf(B, 0, 1), 20, 130);
  text("q1:      " + nf(q1, 0, 2), 20, 145);
  text("q2:      " + nf(q2, 0, 2), 20, 160);
  text("theta1: " + nf(theta1, 0, 2), 20, 175);
  text("theta2: " + nf(theta2, 0, 2), 20, 190);
  
  //println("alpha:" + alpha + "  " + "A:" + A + "  " + "B:" + B + "  " + "q1a:" + q1a + "  " + "q1:" + q1 + "  " + "q2:" + q2 + "  " + "theta1:" + theta1 + "  " + "theta2:" + theta2); 
}

//=========================================================================================================================== 
void keyPressed() {
 if (key == ' ') {
 
   sketchStart = millis();
   sketching = !sketching; 
   //sketchPoints = new ArrayList<PVector>();
   sketchPoints.clear();
   
 } else if (key == 'x' || key == 'X') {
   sketchPoints.clear();
 }
  
}

//=========================================================================================================================== 
void sketch() {
  z = -210.0;
  int faceCenterX = 30;
  int faceCenterY = 0;
  
  float sketchAngle;
  
  if (millis() < sketchStart + sketchTime1) {
    sketchAngle = (millis() - sketchStart) / float(sketchTime1) * TWO_PI;
    x = faceDiam * sin(sketchAngle) + faceCenterX;
    y = faceDiam * cos(sketchAngle) + faceCenterY;
    
    PVector thispoint = new PVector(x, y, z);
    sketchPoints.add(thispoint);

  } else if (millis() < sketchStart + sketchTime1 + sketchTime2) {
    sketchAngle = (millis() - (sketchStart + sketchTime1)) / float(sketchTime2) * TWO_PI;
    x = eyeDiam * sin(sketchAngle) - 20 + faceCenterX;
    y = eyeDiam * cos(sketchAngle) + 20 + faceCenterY;
    
    PVector thispoint = new PVector(x, y, z);
    sketchPoints.add(thispoint);    

  } else if (millis() < sketchStart + sketchTime1 + sketchTime2 + sketchTime3) {
    sketchAngle = (millis() - (sketchStart + sketchTime1 + sketchTime2)) / float(sketchTime3) * TWO_PI;
    x = eyeDiam * sin(sketchAngle) + 20 + faceCenterX;
    y = eyeDiam * cos(sketchAngle) + 20 + faceCenterY;
    
    PVector thispoint = new PVector(x, y, z);
    sketchPoints.add(thispoint);      

  } else if (millis() < sketchStart + sketchTime1 + sketchTime2 + sketchTime3 + sketchTime4) {
    sketchAngle = TWO_PI/3 + (millis() - (sketchStart + sketchTime1 + sketchTime2 + sketchTime3)) / float(sketchTime4) * TWO_PI/3;
    x = mouthDiam * sin(sketchAngle) + faceCenterX;
    y = mouthDiam * cos(sketchAngle) + faceCenterY;
    
    PVector thispoint = new PVector(x, y, z);
    sketchPoints.add(thispoint);      
    
  } else {
//    if (!moving) {
//      toX = 200;
//      toY = 100;
//      toZ = 100;
//      fromX = x;
//      fromY = y;
//      fromZ = z;
//      moveDuration = 1000;
//      moveStart = millis();
//      moving = true;
//    }
    
    //sketching = false;
    sketchStart = millis();
    sketchPoints.clear();
    
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
void move() {
  if (moving) {
    if (millis() > moveStart + moveDuration) {
      moving = false;
    } else {
      x = (millis() - moveStart) / moveDuration * (toX - fromX);
      y = (millis() - moveStart) / moveDuration * (toY - fromY);
      z = (millis() - moveStart) / moveDuration * (toZ - fromZ);
    }
  }
}

//=========================================================================================================================== 
void drawNotes() {
  fill(200);
  text("press <SPACE> to start sketch", width - 200, height - 30);
  text("press <X> to clear sketch", width - 200, height - 15);
}

//===========================================================================================================================
void sendData() {
//  int alphaMicroseconds = servouSec(-alpha);
//  int theta1Microseconds = servouSec(theta1Servo);
//  int theta2Microseconds = servouSec(-theta2Servo);
  
//  print(millis() + ",");
//  print(alphauSec + ",");
//  print(theta1uSec + ",");
//  println(theta2uSec);
  
  arduino.write(65);  // 'A'
  arduino.write(char(alphauSec));
  arduino.write(char(alphauSec) >> 8);
  arduino.write(char(theta1uSec));
  arduino.write(char(theta1uSec) >> 8); 
  arduino.write(char(theta2uSec));
  arduino.write(char(theta2uSec) >> 8);  

}

//===========================================================================================================================
int servouSec(float angle) {
  return servoCenter + int(servoRangeuSec/servoRangeRad * angle);  // uSec
}

//===========================================================================================================================
float servoAngle(int uSec) {
  return (uSec - servoCenter)*servoRangeRad/servoRangeuSec;  // radians
  
}

