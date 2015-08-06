
#include <Servo.h> 
 
Servo servoAlpha;
Servo servoTheta1;
Servo servoTheta2;
 
int servoAlphaPos = 1500;
int servoTheta1Pos = 1500;
int servoTheta2Pos = 1500;

void setup() 
{ 
  servoAlpha.attach(9);
  servoTheta1.attach(10);
  servoTheta2.attach(11);
  
  Serial.begin(57600);
} 
  
void loop() { 
  checkSerial();
  
  servoAlpha.writeMicroseconds(constrain(servoAlphaPos, 900, 2100));
  servoTheta1.writeMicroseconds(constrain(servoTheta1Pos, 900, 2100));
  servoTheta2.writeMicroseconds(constrain(servoTheta2Pos, 900, 2100));
} 

void checkSerial() {
  if(Serial.available() >= 7){
    int thisByte = Serial.read();
    
    if (thisByte == 65) {
      servoAlphaPos = Serial.read() + (Serial.read() << 8);
      servoTheta1Pos = Serial.read() + (Serial.read() << 8);
      servoTheta2Pos = Serial.read() + (Serial.read() << 8);      
    }
  }
}
