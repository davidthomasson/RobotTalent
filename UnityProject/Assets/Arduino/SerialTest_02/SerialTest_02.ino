#include <Servo.h>
 
Servo servoAlpha;

int servoAlphaPos = 1500;
int servoTheta1Pos = 1500;
int servoTheta2Pos = 1500;

void setup()
{ 
	servoAlpha.attach(9);
	Serial.begin(9600);
}

void loop() {
  if(Serial.available() >= 7){
    int thisByte = Serial.read();
    
    if (thisByte == 65) {
      servoAlphaPos = Serial.read() + (Serial.read() << 8);
      servoTheta1Pos = Serial.read() + (Serial.read() << 8);
      servoTheta2Pos = Serial.read() + (Serial.read() << 8);      
    }
    servoAlpha.writeMicroseconds(constrain(servoAlphaPos, 900, 2100));
    //servoAlpha.writeMicroseconds(constrain(servoTheta1Pos, 900, 2100));
    //servoAlpha.writeMicroseconds(constrain(servoTheta2Pos, 900, 2100));
    Serial.flush();
    delay(15);
  }
}
