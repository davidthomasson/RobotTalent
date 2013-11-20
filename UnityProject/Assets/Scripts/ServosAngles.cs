using UnityEngine;
using System.Collections;
using System.IO;
using System.Collections.Generic;
using System;
using UnityEditor;

public class ServosAngles : MonoBehaviour {
	
	// TODO:
	//Serial code to send data to Arduino on the Update function
	//Replace "drawing button" by automatic process
	//Get 3D model from Arthur and make everything pretty
	//Fix angles representation issue or cheat by using the calculated stylus value
	
	
	public Vector3 debug;
	
	public float scale = 1/50;
	public float speed = 10000f; // 10cm/second

	public Transform screen;
	
	public Transform alphaTransform;
	public Transform theta1Transform;
	public Transform theta2Transform;
	public Transform stylusTransform;

	public Vector3 	screenSize = new Vector3(149, 198, 50);
	public Vector3 	screenCentre = new Vector3(0, 0, -211);
	private float 	screenTiltDeg;
	private float 	screenTiltRad = 0.18F;
	
	public float upperArmLength = 114;
	public float lowerArmLength = 132;
	
	public Vector3 screenXYZ;
	public Vector3 armXYZ;
	public Vector3 jointAngles;
	public Vector3 servosAngles;

	Servo servo1 = new Servo(Mathf.PI/2, 1200, 1500, -45 * Mathf.Deg2Rad, 45 * Mathf.Deg2Rad);
	Servo servo2 = new Servo(Mathf.PI/2, 1200, 1460, -45 * Mathf.Deg2Rad, 45 * Mathf.Deg2Rad);
	Servo servo3 = new Servo(Mathf.PI/2, 1200, 1500, -45 * Mathf.Deg2Rad, 45 * Mathf.Deg2Rad);

	//string filePath = "/Data/image_data.txt";
	string filePath = "/Data/lineCoords.txt";

	//===========================
	
	// Line structure used to guide the robot
	// Each line parsed from a TXT file is composed of a start point and an end point
	public class Line{
		public Vector3 start;
		public Vector3 end;
		public bool isDrawn;
	}
	
	//===========================
	
	void Start () {
		theta1Transform.parent = alphaTransform;
		theta2Transform.parent = theta1Transform;
		stylusTransform.parent = theta2Transform;

		alphaTransform.localScale = new Vector3 (1, 1, 1);
		theta1Transform.localScale = new Vector3 (1, 1, 1);
		theta2Transform.localScale = new Vector3 (1, 1, 1);
		stylusTransform.localScale = new Vector3 (1, 1, 1);
	}
	
	//===========================
	
	void Update () {
		UpdateRobot(screenXYZ);
	}
	
	void UpdateRobot(Vector3 pScreenXYZ){
		//screenTiltRad = screenTiltDeg * Mathf.Deg2Rad;
		screenTiltDeg = screenTiltRad * Mathf.Rad2Deg;
		
		InitializeScreen();
		armXYZ 		 = ConvertScreenToArmXYZ(pScreenXYZ);
		jointAngles  = CalculateJointAngles(armXYZ);
		servosAngles = CalculateServoAngles(jointAngles);
		
		SetJointsTransforms(jointAngles);
		SendData();
	}
	
	//===========================
	
	Vector3 ConvertScreenToArmXYZ(Vector3 pScreen){
		Vector3 arm;
		
		arm.x = pScreen.x + screenCentre.x;
		arm.y = (pScreen.y - pScreen.z / Mathf.Tan(screenTiltRad)) * Mathf.Cos(screenTiltRad) + pScreen.z / Mathf.Tan(screenTiltRad) + screenCentre.y;
		arm.z = screenCentre.z - (pScreen.y - pScreen.z / Mathf.Tan(screenTiltRad)) * Mathf.Sin(screenTiltRad);
		
		return arm;
	}
	
	//===========================
	
	Vector3 CalculateJointAngles(Vector3 pArm){
		float alpha, theta1, theta2;
		float A, B, q1, q2;
		
		A  = Mathf.Sqrt ( Mathf.Pow(pArm.y,2) + Mathf.Pow(pArm.z,2) ); 
		B  = Mathf.Clamp( Mathf.Sqrt(Mathf.Pow(A,2) + Mathf.Pow(pArm.x,2)), 0, upperArmLength + lowerArmLength ) ;
		q1 = Mathf.Atan2( -pArm.x, -A );
		q2 = Mathf.Acos ( (Mathf.Pow(upperArmLength,2) - Mathf.Pow(lowerArmLength,2) + Mathf.Pow(B,2))/(2*upperArmLength*B) );
		
		alpha  =  Mathf.Atan2(-pArm.y, -pArm.z);
		theta1 = -Mathf.PI + q1 + q2;
		theta2 = -Mathf.PI + Mathf.Acos((Mathf.Pow(upperArmLength,2) + Mathf.Pow(lowerArmLength,2) - Mathf.Pow(B,2))/(2*upperArmLength*lowerArmLength));
		
		//debug = new Vector3(alpha, theta1, theta2);
		return new Vector3(alpha, theta1, theta2);
	}
	
	//===========================
	
	Vector3 CalculateServoAngles(Vector3 pJointAngles) {
		//The angle the servo needs to go to, to make the joint angle required
		Vector3 angles;
		float alpha, theta1, theta2;
		
		alpha  = pJointAngles.x;
		theta1 = pJointAngles.y;
		theta2 = pJointAngles.z;
		
		//alpha
		servo1.setAngle(alpha);
		angles.x = alpha;
		
		//theta1
		if (theta1 < -Mathf.PI) {
			theta1 = -(Mathf.PI*2 + theta1);
		} else {
			theta1 = -theta1;
		}  
		servo2.setAngle(theta1 + Mathf.PI/4);
		angles.y = theta1 + Mathf.PI/4;
		
		//theta2
		servo3.setAngle(theta2 + Mathf.PI/4);
		angles.z = theta2 + Mathf.PI/4;
		
		return angles;
	}
	
	//===========================
	
	void SetJointsTransforms(Vector3 pJointAngles){
		//pJointAngles = debug;
		//pJointAngles = Vector3.zero;
		alphaTransform.localRotation  = Quaternion.AngleAxis(pJointAngles.x * Mathf.Rad2Deg, alphaTransform.right);
		theta1Transform.localEulerAngles = new Vector3(0, pJointAngles.y * Mathf.Rad2Deg, 0);
		theta2Transform.localPosition = new Vector3(0, 0, upperArmLength * scale);
		theta2Transform.localEulerAngles = new Vector3(0, pJointAngles.z * Mathf.Rad2Deg, 0);
		stylusTransform.localPosition = new Vector3(0, 0, lowerArmLength * scale);

	}
	
	//===========================

	float sliderScreenX = 0;
	float sliderScreenY = 0;
	float sliderScreenZ = 15;
	
	void OnGUI(){

		GUILayout.BeginVertical( "box", GUILayout.Width(400));
		sliderScreenX = GUILayout.HorizontalSlider (sliderScreenX, -screenSize.x/2, screenSize.x/2);
		sliderScreenY = GUILayout.HorizontalSlider (sliderScreenY, -screenSize.y/2, screenSize.y/2);
		sliderScreenZ = GUILayout.HorizontalSlider (sliderScreenZ, 0.0F, screenSize.z);
		screenXYZ = new Vector3(sliderScreenX, sliderScreenY, sliderScreenZ);
		if (GUILayout.Button("Get image data")){
			List<Line> image_lines = ReadTxtFile(Application.dataPath + filePath);
			StartCoroutine( Draw(image_lines) );
		}
		GUILayout.Label(screenXYZ.ToString() + " > screenXYZ");
		GUILayout.Label(armXYZ.ToString() + " > armXYZ");
		GUILayout.Label((stylusTransform.position/scale).ToString() + " > armXYZ in game");
		GUILayout.EndVertical();

	}
	
	//===========================
	
	void InitializeScreen(){
		screen.localScale = new Vector3(screenSize.x, 1, screenSize.y) * scale / 10;
		screen.position = new Vector3(screenCentre.x, screenCentre.y, -screenCentre.z) * scale;
		screen.localEulerAngles = new Vector3(90 - screenTiltDeg, 180, 0);
	}
	
		
	//===========================
	
	List<Line> ReadTxtFile(string filePathAndName){
		StreamReader sr = new StreamReader(filePathAndName);
		string fileContents = sr.ReadToEnd();
		sr.Close();

		string[]   image_lines_str = fileContents.Split("\n"[0]);
		List<Line> image_lines = new List<Line>();
		Vector3 correction = new Vector3(-1f/10f*screenSize.x/10, -1f/20*screenSize.y/10, 1f) * 10f;
		Vector3 offset = new Vector3( screenSize.x, screenSize.y, 0) /2;
		
		foreach( string image_line_str in image_lines_str ) {
			string[] n = image_line_str.Split(" "[0]);
			Line image_line = new Line();

			image_line.start = new Vector3( Convert.ToSingle(n[0]),
											Convert.ToSingle(n[1]),
			                                Convert.ToSingle(n[2]) );

			image_line.end   = new Vector3( Convert.ToSingle(n[3]),
											Convert.ToSingle(n[4]),
			                                Convert.ToSingle(n[5]) );

			image_line.start = Vector3.Scale(image_line.start, correction) + offset;
			image_line.end   = Vector3.Scale(image_line.end,   correction) + offset;

			image_line.isDrawn = false;

			image_lines.Add(image_line);
		}
		
		return image_lines;
	}
	
	//===========================
	
	IEnumerator Draw(List<Line> image_lines) {
		
		Vector3 previousPoint = image_lines[0].start;
		int lineCount = image_lines.Count;
		bool lineFound = true;
		int debugWhile = -1;

		//for( int i=0; i<lineCount; i++ ){
		while(debugWhile < 10000000 && lineFound){

			debugWhile++;
			Line line = new Line();

			if(debugWhile>0){
				lineFound = FindNextLine(ref image_lines, previousPoint, ref line);
			}else{
				line = image_lines[0];
				lineFound = true;
			}

//			if(!lineFound)
//				break;

			float disToNextLine = (line.start - previousPoint).magnitude;
			float disMax = 10.0f;
			float armUpHeight = 10.0f;
			
			Debug.Log(disToNextLine);
			
			if( disToNextLine > disMax ){
				Vector3 armUp0 = new Vector3(previousPoint.x, previousPoint.y, previousPoint.z + armUpHeight);
				Vector3 armUp1 = new Vector3(line.start.x, line.start.y, line.start.z + armUpHeight);
				
				Debug.Log("Stylus up!");
				yield return StartCoroutine( MoveArmTo(previousPoint, armUp0, speed) );
				yield return StartCoroutine( MoveArmTo(armUp0, armUp1, speed) );
				yield return StartCoroutine( MoveArmTo(armUp1, line.start, speed) );
			}else{
				yield return StartCoroutine( MoveArmTo(previousPoint, line.start, speed) );
				Debug.DrawLine(previousPoint * scale, line.start * scale, Color.red, 200, false);
			}
			
			yield return StartCoroutine( MoveArmTo(line.start, line.end, speed) );
			previousPoint = line.end;
			Debug.DrawLine(line.start * scale, line.end * scale, Color.red, 200, false);
		}

		Debug.Log("Done!");
	}

	bool FindNextLine(ref List<Line> image_lines, Vector3 previousPoint, ref Line nextLine){
		float disMini = 2828282828;
		bool lineFound = false;
		int lineFoundIndex = 0;
		int i = -1;
		//Debug.Log(image_lines.Count);

		foreach( Line line in image_lines ){
			i++;

			if(line.isDrawn)
				continue;

			if( disMini == 2828282828 ){
				nextLine = line;
				lineFoundIndex = i;
				disMini = Vector3.Distance( previousPoint, line.start );
				lineFound = true;
				continue;
			}

			float dis = Vector3.Distance( previousPoint, line.start );

			if( dis < disMini ){
				nextLine = line;
				lineFoundIndex = i;
				disMini = dis;
				lineFound = true;
			}
		}

		if(lineFound)
			image_lines[lineFoundIndex].isDrawn = true;

		return lineFound;
	}

	IEnumerator MoveArmTo(Vector3 start, Vector3 end, float pSpeed){
		float i = 0.0f;
		float dis = Vector3.Distance(start, end);

		float rate = Mathf.Clamp(pSpeed,1f,1000000f) / dis;
		
		while( i < 1.0f ){
			i += Time.deltaTime * rate;
			//arm.position = Vector3.Lerp(start, end, i);
			UpdateRobot( Vector3.Lerp(start, end, i) );
			yield return null;
		}
	}
	
	//===========================

	void SendData() {

		byte[] servoBytes = new byte[7];

		byte[] servo1Bytes = BitConverter.GetBytes(servo1.microSeconds);
		byte[] servo2Bytes = BitConverter.GetBytes(servo2.microSeconds);
		byte[] servo3Bytes = BitConverter.GetBytes(servo3.microSeconds);

		servoBytes[0] = BitConverter.GetBytes(65)[0];
		servoBytes[1] = servo1Bytes[0];
		servoBytes[2] = servo1Bytes[1];
		servoBytes[3] = servo2Bytes[0];
		servoBytes[4] = servo2Bytes[1];
		servoBytes[5] = servo3Bytes[0];
		servoBytes[6] = servo3Bytes[1];

		SerialToArduino.ServoBytes = servoBytes;
	}

	//===========================

}









