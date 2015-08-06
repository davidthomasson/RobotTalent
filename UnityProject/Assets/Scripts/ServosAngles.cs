using UnityEngine;
using System.Collections;
using System.IO;
using System.Collections.Generic;
using System;
using UnityEditor;

public class ServosAngles : MonoBehaviour {
	
	public Vector3 debug;
	
	public float scale = 1/50;
	public float speed = 10000f; // 10cm/second

	public GameObject camera;
	public Transform screen;
	
	public Transform alphaTransform;
	public Transform theta1Transform;
	public Transform theta2Transform;
	public Transform stylusTransform;

	public Vector3 	screenSize = new Vector3(149, 198, 50);
	public Vector3 	screenSizePixel = new Vector3(768, 1024, 0);
	public Vector3 	screenCentre = new Vector3(0, 0, -211);
	private float 	screenTiltDeg;
	private float 	screenTiltRad = 0.18F;
	
	public float upperArmLength = 114;
	public float lowerArmLength = 132;
	
	public Vector3 screenPixelXYZ;
	public Vector3 screenMiliXYZ;
	public Vector3 armXYZ;
	public Vector3 jointAngles;
	public Vector3 servosAngles;

	Servo servo1 = new Servo(Mathf.PI/2, 900, 2100, 1500, -35 * Mathf.Deg2Rad, 45 * Mathf.Deg2Rad);
	Servo servo2 = new Servo(Mathf.PI/2, 2100, 900, 1460, -45 * Mathf.Deg2Rad, 45 * Mathf.Deg2Rad);
	Servo servo3 = new Servo(Mathf.PI/2, 2100, 900, 1500, -45 * Mathf.Deg2Rad, 45 * Mathf.Deg2Rad);

	private List<string> listFiles;
	private string filePath;
	private string COM_nb;
	private int nextDrawing = 0;
	private bool drawingDone = true;

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

		COM_nb = gameObject.GetComponent<SerialToArduino>().COMNumber.ToString();
		filePath = Application.dataPath + "/Data/boby.txt";

		listFiles = ListFiles( Application.dataPath + "/Data" );
	}
	
	//===========================
	
	void Update () {
		UpdateRobot(screenMiliXYZ);
	}
	
	void UpdateRobot(Vector3 pScreenMiliXYZ){
		//screenTiltRad = screenTiltDeg * Mathf.Deg2Rad;
		screenTiltDeg = screenTiltRad * Mathf.Rad2Deg;
		
		InitializeScreen();
		armXYZ 		 = ConvertScreenToArmXYZ(pScreenMiliXYZ);
		jointAngles  = CalculateJointAngles(armXYZ);
		servosAngles = CalculateServoAngles(jointAngles);
		
		SetJointsTransforms(jointAngles);
		SendData();
	}
	
	//===========================

	void InitializeScreen(){
		screen.localScale = new Vector3(screenSize.x, 1, screenSize.y) * scale / 10;
		screen.position = new Vector3(screenCentre.x, screenCentre.y, -screenCentre.z) * scale;
		screen.localEulerAngles = new Vector3(90 - screenTiltDeg, 180, 0);
	}

	float map(float val1, float r1_min, float r1_max, float r2_min, float r2_max){
		
		float r1 = r1_max - r1_min;
		float r2 = r2_max - r2_min;
		
		float val2 = (val1 - r1_min) * r2 / r1 + r2_min;
		return val2;
	}

	//===========================

	Vector3 ConvertPixelsToMili(Vector3 pixelXYZ ){
		Vector3 miliXYZ;
		miliXYZ.x = map(pixelXYZ.x, 0, screenSizePixel.x, -screenSize.x/2, screenSize.x/2);
		miliXYZ.y = map(pixelXYZ.y, 0, screenSizePixel.y, screenSize.y/2, -screenSize.y/2);
		miliXYZ.z = pixelXYZ.z;
		return miliXYZ;
	}


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
		//theta1 = -Mathf.PI + q1 + q2;
		theta1 = Mathf.PI / 2 + q1 + q2;
		if (theta1 > Mathf.PI) {
			theta1 = theta1 - (Mathf.PI * 2);
		}
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
		servo2.setAngle(theta1 + Mathf.PI/4);
		angles.y = theta1 + Mathf.PI/4;
		
		//theta2
		servo3.setAngle(theta2 + Mathf.PI/4);
		angles.z = theta2 + Mathf.PI/4;
		
		return angles;
	}
	
	//===========================
	
	void SetJointsTransforms(Vector3 pJointAngles){
		alphaTransform.localRotation  = Quaternion.AngleAxis(pJointAngles.x * Mathf.Rad2Deg, alphaTransform.forward);
		alphaTransform.Rotate(0,90,0);
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
		screenMiliXYZ = new Vector3(sliderScreenX, sliderScreenY, sliderScreenZ);
		filePath = GUILayout.TextField(filePath, 400);
		speed = Convert.ToSingle(GUILayout.TextField(speed.ToString(), 400));
		COM_nb = GUILayout.TextField(COM_nb.ToString(), 400);
		// UPDATE COM
		if(GUILayout.Button("Update COM")){
			gameObject.GetComponent<SerialToArduino>().Initialize(Convert.ToInt16(COM_nb));
		}
		// OPEN TXT FILE
		if(GUILayout.Button("Open")){
			filePath = EditorUtility.OpenFilePanel("Choose file", Application.dataPath, "txt");
		}
		// START DRAWING
		if (GUILayout.Button("Draw")){
			//List<Line> image_lines = ReadTxtFile(Application.dataPath + filePath);
			camera.GetComponent<DrawGL>().Clear();
			List<Line> image_lines = ReadTxtFile(filePath);
			StopAllCoroutines();
			StartCoroutine( Draw(image_lines) );
		}
		// AUTO DRAWING
		if (GUILayout.Button("Auto")){
			drawingDone = true;
			StopAllCoroutines();
			StartCoroutine( LoopDrawings() );
		}
		// STOP DRAWING
		if (GUILayout.Button("Stop")){
			StopAllCoroutines();
		}
		// VECTORS LOG
		GUILayout.Label(screenMiliXYZ.ToString() + " > screenMiliXYZ");
		GUILayout.Label(armXYZ.ToString() + " > armXYZ");
		//GUILayout.Label((stylusTransform.position/scale).ToString() + " > armXYZ in game");
		GUILayout.EndVertical();
	}
		
	//===========================

	List<Line> ReadTxtFile(string filePathAndName){
		string fileContents = "";
		try{
			StreamReader sr = new StreamReader(filePathAndName);
			fileContents = sr.ReadToEnd();
			sr.Close();
		}
		catch{
			filePathAndName = "file not found";
		}

		string[]   image_lines_str = fileContents.Split("\n"[0]);
		List<Line> image_lines = new List<Line>();
		Vector3 correction = new Vector3(1f, 1f, 0.5f) * 1f;
		
		int line_count = image_lines_str.Length;
		for( int i = 0; i < line_count-1; i++){
			Char[] split_char = new Char[] {',', ' '};
			string image_line_str0 = image_lines_str[i];
			string image_line_str1 = image_lines_str[i+1];
			string[] n0 = image_line_str0.Split(split_char);
			string[] n1 = image_line_str1.Split(split_char);
			
			if(image_line_str0 == "" || image_line_str1 == "")
				continue;
			
			Line image_line = new Line();
			
			image_line.start = new Vector3( Convert.ToSingle(n0[0]),
			                               Convert.ToSingle(n0[1]),
			                               Convert.ToSingle(n0[2]) );
			
			image_line.end   = new Vector3( Convert.ToSingle(n1[0]),
			                               Convert.ToSingle(n1[1]),
			                               Convert.ToSingle(n1[2]) );
			
			image_line.start = ConvertPixelsToMili(Vector3.Scale(image_line.start, correction)) ;
			image_line.end   = ConvertPixelsToMili(Vector3.Scale(image_line.end,   correction)) ;
			
			image_line.isDrawn = false;
			image_lines.Add(image_line);
		}
		
		return image_lines;
	}

	//===========================

	IEnumerator LoopDrawings(){
		while(true){
			if(drawingDone){
				camera.GetComponent<DrawGL>().Clear();
				List<Line> image_lines = ReadTxtFile(listFiles[nextDrawing]);
				//StopAllCoroutines();
				StartCoroutine( Draw(image_lines) );

				nextDrawing++;
				if( nextDrawing > listFiles.Count -1)
					nextDrawing = 0;

				drawingDone = false;
			}
			yield return null;
		}
	}

	IEnumerator Draw(List<Line> image_lines) {
		
		Vector3 previousPoint = image_lines[0].start;
		int lineCount = image_lines.Count;
		bool lineFound = true;
		int debugWhile = -1;

		yield return StartCoroutine( MoveArmTo(stylusTransform.position, previousPoint, speed) );

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
			
			yield return StartCoroutine( MoveArmTo(line.start, line.end, speed) );
			previousPoint = line.end;
			if(line.start.z > 0 || line.end.z > 0)
				continue;

			DebugDrawLines(line.start, line.end);
		}
		
		//Debug.Log("Done!");
		drawingDone = true;
	}

	//===========================

	void DebugDrawLines(Vector3 start, Vector2 end){

		Vector3 vStart = ConvertScreenToArmXYZ(start * scale) - screenCentre;
		Vector3 vEnd   = ConvertScreenToArmXYZ(end   * scale) - screenCentre;

		Vector3 offset = new Vector3(screenCentre.x, screenCentre.y, -screenCentre.z);

		vStart = new Vector3(vStart.x, vStart.y, -vStart.z) + offset * scale;
		vEnd   = new Vector3(vEnd.x,   vEnd.y,   -vEnd.z  ) + offset * scale;

		Debug.DrawLine( vStart, vEnd, Color.green, 200, false);

		camera.GetComponent<DrawGL>().AddPoint(vStart);
		camera.GetComponent<DrawGL>().AddPoint(vEnd);
	}

	//===========================

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

	//===========================

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

	List<string> ListFiles(string directoryPath){
		string [] fileEntries = Directory.GetFiles(directoryPath);
		List<string> files_names = new List<string>();

		foreach( string file in fileEntries ){
			string ext = file.Substring(file.Length - 4, 4);

			if(ext == ".txt")
				files_names.Add(file);
		}

		return files_names;
	}
	
}









