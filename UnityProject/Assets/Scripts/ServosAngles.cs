using UnityEngine;
using System.Collections;
using System.IO;
using System.Collections.Generic;
using System;

public class ServosAngles : MonoBehaviour {
	
	// TODO:
	//Serial code to send data to Arduino on the Update function
	//Replace "drawing button" by automatic process
	//Get 3D model from Arthur and make everything pretty
	//Fix angles representation issue or cheat by using the calculated stylus value
	
	
	public Vector3 debug;
	
	public float scale = 1/50;
	public float timePerLine = 0.5f;
	
	public Transform screen;
	
	public Transform alphaTransform;
	public Transform theta1Transform;
	public Transform theta2Transform;
	public Transform stylusTransform;
	
	public Vector3 	screenSize = new Vector3(149, 198, 50);
	public Vector3 	screenCentre = new Vector3(30,-29.7F,-211);
	private float 	screenTiltDeg;
	private float 	screenTiltRad = 0.18F;
	
	public float upperArmLength = 114;
	public float lowerArmLength = 132;
	
	public Vector3 screenXYZ;
	public Vector3 armXYZ;
	public Vector3 jointAngles;
	public Vector3 servosAngles;
	
	private const float toDeg = 180/Mathf.PI;
	private const float toRad = Mathf.PI/180;
	
	//===========================
	
	// Line structure used to guide the robot
	// Each line parsed from a TXT file is composed of a start point and an end point
	public struct Line{
		public Vector3 start;
		public Vector3 end;
	}
	
	//===========================
	
	void Start () {
		
	}
	
	//===========================
	
	void Update () {
		UpdateRobot(screenXYZ);
	}
	
	void UpdateRobot(Vector3 pScreenXYZ){
		//screenTiltRad = screenTiltDeg * toRad;
		screenTiltDeg = screenTiltRad * toDeg;
		
		InitializeScreen();
		armXYZ 		 = ConvertScreenToArmXYZ(pScreenXYZ);
		jointAngles  = CalculateJointAngles(armXYZ);
		servosAngles = CalculateServoAngles(jointAngles);
		
		SetJointsTransforms(jointAngles);
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
		angles.x = alpha;
		
		//theta1
		if (theta1 < -Mathf.PI) {
			theta1 = -(Mathf.PI*2 + theta1);
		} else {
			theta1 = -theta1;
		}  
		angles.y = theta1 + Mathf.PI/4;
		
		//theta2
		angles.z = theta2 + Mathf.PI/4;
		
		return angles;
	}
	
	//===========================
	
	void SetJointsTransforms(Vector3 pJointAngles){
		//pJointAngles = debug;
		//pJointAngles = Vector3.zero;
		alphaTransform.localRotation  = Quaternion.AngleAxis(pJointAngles.x*toDeg, alphaTransform.right);
		theta1Transform.localRotation = alphaTransform.localRotation;
		theta2Transform.localRotation = alphaTransform.localRotation;
		theta1Transform.Rotate(Vector3.up, (pJointAngles.y - 0)*toDeg, Space.Self);
		theta2Transform.Rotate(Vector3.up, (pJointAngles.z + 45)*toDeg, Space.Self);
		
		theta2Transform.position = theta1Transform.position + theta1Transform.forward * upperArmLength * scale;
		stylusTransform.position = theta2Transform.position + theta2Transform.forward * lowerArmLength * scale;
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
			List<Line> image_lines = ReadTxtFile(Application.dataPath + "/Data/image_data.txt");
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
		screen.localEulerAngles = new Vector3(screenTiltDeg + 45, 180, 0);
	}
	
		
	//===========================
	
	List<Line> ReadTxtFile(string filePathAndName){
		StreamReader sr = new StreamReader(filePathAndName);
		string fileContents = sr.ReadToEnd();
		sr.Close();
		
		string[]   image_lines_str = fileContents.Split("\n"[0]);
		List<Line> image_lines = new List<Line>();
		
		foreach( string image_line_str in image_lines_str ) {
			string[] n = image_line_str.Split(" "[0]);
			Line image_line;
			
			image_line.start = new Vector3( Convert.ToSingle(n[0]),
											Convert.ToSingle(n[1]),
											Convert.ToSingle(n[2]));
			
			image_line.end   = new Vector3( Convert.ToSingle(n[3]),
											Convert.ToSingle(n[4]),
											Convert.ToSingle(n[5]));
			
			image_lines.Add(image_line);
		}
		
//		foreach( Line image_line in image_lines ){
//			Debug.Log(image_line.start);
//			Debug.Log(image_line.end);
//		}
		
		return image_lines;
	}
	
	//===========================
	
	IEnumerator Draw(List<Line> image_lines) {
		
		Vector3 previousPoint = image_lines[0].start;
		
		foreach( Line line in image_lines ){
			
			float disToNextLine = (line.start - previousPoint).magnitude;
			float disMax = 1.0f;
			float armUpHeight = 10.0f;
			
			//Debug.Log(disToNextLine);
			
			if( disToNextLine > disMax ){
				Vector3 armUp0 = new Vector3(previousPoint.x, previousPoint.y, previousPoint.z + armUpHeight);
				Vector3 armUp1 = new Vector3(line.start.x, line.start.y, line.start.z + armUpHeight);
				
				yield return StartCoroutine( MoveArmTo(previousPoint, armUp0, timePerLine) );
				yield return StartCoroutine( MoveArmTo(armUp0, armUp1, timePerLine) );
				yield return StartCoroutine( MoveArmTo(armUp1, line.start, timePerLine) );
			}
						
			yield return StartCoroutine( MoveArmTo(line.start, line.end, timePerLine) );
			previousPoint = line.end;			
		}
	}
	
	IEnumerator MoveArmTo(Vector3 start, Vector3 end, float time){
		float i = 0.0f;
		float rate = 1.0f/time;
		
		while( i < 1.0f ){
			i += Time.deltaTime * rate;
			//arm.position = Vector3.Lerp(start, end, i);
			UpdateRobot( Vector3.Lerp(start, end, i) );
			yield return null;
		}
	}
	
	//===========================
	
}








