using UnityEngine;

public class Servo {
	public int microSeconds;   // microSeconds value to send to servo to get current angle
	float angle;               // current angle (radians) of the servo from it's centre point
	float angleRange;          // radians from max CCW to max CW
	int microSecondsMin;       // uSec for fully CCW
	int microSecondsMax;       // uSec for fully CW
	//int microSecondsRange;     // uSec from max CCW to max CW
	int microSecondsCentre;    // uSec to get servo horm pointing exactly center
	float angleLimitMin;       // angle (radians) of maximum allowable movement in the CCW direction
	float angleLimitMax;       // angle (radians) of maximum allowable movement in the CW direction
	
	public Servo(float angleRange_, int microSecondsMin_, int microSecondsMax_, int microSecondsCentre_, float angleLimitMin_, float angleLimitMax_) {
		this.angle = 0.0f;
		this.microSeconds = 1500;
		this.angleRange = angleRange_;
		this.microSecondsMin = microSecondsMin_;
		this.microSecondsMax = microSecondsMax_;
		//this.microSecondsRange = microSecondsRange_;
		this.microSecondsCentre = microSecondsCentre_;
		this.angleLimitMin = angleLimitMin_;
		this.angleLimitMax = angleLimitMax_;
	}
	
	public Servo() {
		this.angle = 0.0f;
		this.microSeconds = 1500;
		this.angleRange = 90 * Mathf.Deg2Rad;
		this.microSecondsMin = 2100;
		this.microSecondsMax = 900;
		//this.microSecondsRange = 1200;
		this.microSecondsCentre = 1500;
		this.angleLimitMin = -this.angleRange/2;
		this.angleLimitMax = this.angleRange/2;
	}
	
	public void setAngle(float angle_) {
		this.angle = angle_;
		float angleMin = -this.angleRange/2;
		float angleMax = this.angleRange/2;
		//int uSecMin = this.microSecondsCentre + (this.microSecondsRange/2);  // for a CCW servo
		//int uSecMax = this.microSecondsCentre - (this.microSecondsRange/2);  // for a CCW servo
		int uSecMin = this.microSecondsCentre - (this.microSecondsMax - microSecondsMin)/2;
		int uSecMax = this.microSecondsCentre + (this.microSecondsMax - microSecondsMin)/2;
		this.angle = Mathf.Clamp(this.angle, this.angleLimitMin, this.angleLimitMax);
		this.microSeconds = (int)(map(this.angle, angleMin, angleMax, uSecMin, uSecMax));
	}
	
	public float map(float val1, float r1_min, float r1_max, float r2_min, float r2_max){
		
		float r1 = r1_max - r1_min;
		float r2 = r2_max - r2_min;
		
		float val2 = (val1 - r1_min) * r2 / r1 + r2_min;
		return val2;
	}
}












