class Servo {
  float angle;               // current angle (radians) of the servo from it's centre point
  int microSeconds;          // microSeconds value to send to servo to get current angle
  float angleRange;          // radians from max CCW to max CW
  int microSecondsRange;     // uSec from max CCW to max CW
  int microSecondsCentre;    // uSec to get servo horm pointing exactly center
  float angleLimitMin;       // angle (radians) of maximum allowable movement in the CCW direction
  float angleLimitMax;       // angle (radians) of maximum allowable movement in the CW direction
  
  Servo(float angleRange_, int microSecondsRange_, int microSecondsCentre_, float angleLimitMin_, float angleLimitMax_) {
    angle = 0.0;
    microSeconds = 1500;
    angleRange = angleRange_;
    microSecondsRange = microSecondsRange_;
    microSecondsCentre = microSecondsCentre_;
    angleLimitMin = angleLimitMin_;
    angleLimitMax = angleLimitMax_;
  } 

  Servo() {
    angle = 0.0;
    microSeconds = 1500;
    angleRange = radians(90);
    microSecondsRange = 1200;
    microSecondsCentre = 1500;
    angleLimitMin = -angleRange/2;
    angleLimitMax = angleRange/2;
  } 
  
  void setAngle(float angle_) {
    angle = angle_;
    float angleMin = -angleRange/2;
    float angleMax = angleRange/2;
    int uSecMin = microSecondsCentre + (microSecondsRange/2);  // for a CCW servo
    int uSecMax = microSecondsCentre - (microSecondsRange/2);  // for a CCW servo
    angle = constrain(angle, angleLimitMin, angleLimitMax);
    microSeconds = int(map(angle, angleMin, angleMax, uSecMin, uSecMax));
  }
  
}
