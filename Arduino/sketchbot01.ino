
#include <Servo.h> 
 
Servo servoAlpha;
Servo servoTheta1;
Servo servoTheta2;
 
int servoAlphaPos = 1500;
int servoTheta1Pos = 1500;
int servoTheta2Pos = 1500;

int periodAlpha = 2000;
int periodTheta1 = 3000;
int periodTheta2 = 1500;

boolean demo1 = false;
boolean demo2 = false;

long loops;

const boolean DOWN = false;
const boolean UP = true;
int servoAlphaMax = 1800;
int servoAlphaMin = 1200;
boolean alphaChange = UP;

//=========================================================================================================================== 
void setup() 
{ 
  servoAlpha.attach(9);
  servoTheta1.attach(10);
  servoTheta2.attach(11);
  
  Serial.begin(57600);
} 
 
//===========================================================================================================================  
void loop() { 
  loops++;
  
  Serial.print(loops);
  if (demo1) {
    float Alpha = (millis() % periodAlpha) / float(periodAlpha) * TWO_PI;
    float Theta1 = (millis() % periodTheta1) / float(periodTheta1) * TWO_PI;
    float Theta2 = (millis() % periodTheta2) / float(periodTheta2) * TWO_PI;
    
    servoAlphaPos = 1500 + int((160 * sin(Theta1)));
    servoTheta1Pos = 1800 + int((160 * cos(Alpha)));
    servoTheta2Pos = 1500 + int((500 * cos(Theta2)));
    Serial.println(servoTheta2Pos);
    
  } else if (demo2) {
    if (loops%10 == 0) {
      if (alphaChange == UP) {
        servoAlphaPos++;
      } else {
        servoAlphaPos--;
      }
      if (servoAlphaPos == servoAlphaMax) {
        alphaChange = DOWN;
      } else if (servoAlphaPos == servoAlphaMin) {
        alphaChange = UP;
      }
      //Serial.print(loops);
      Serial.print("  ");
      Serial.print(servoAlphaPos);
    }
    
  } else {
    checkSerial(); 
  }
  Serial.println("");
  
  servoAlpha.writeMicroseconds(constrain(servoAlphaPos, 1200, 1800));
  servoTheta1.writeMicroseconds(constrain(servoTheta1Pos, 1400, 2100));
  servoTheta2.writeMicroseconds(constrain(servoTheta2Pos, 1000, 1700));
  
//  Serial.print(servoAlphaPos);
//  Serial.print("  ");
//  Serial.println(servoTheta1Pos);
} 

//=========================================================================================================================== 
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
