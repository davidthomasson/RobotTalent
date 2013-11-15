#include <Servo.h>
 
Servo servoAlpha;

void setup()
{ 
	servoAlpha.attach(9);
	Serial.begin(9600);
}


void loop() 
{
	if (Serial.available() > 0) { 
		int val = Serial.read();

		if (val > 0 && val < 180)  {	
			servoAlpha.write(val);
			Serial.flush();
			delay(15);
		}
	}
}
