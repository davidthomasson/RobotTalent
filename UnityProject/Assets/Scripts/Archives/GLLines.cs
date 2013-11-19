using UnityEngine;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System;

public class GLLines : MonoBehaviour {
	public Material mat;
	protected List<Line> image_lines;

	// Line structure used to guide the robot
	// Each line parsed from a TXT file is composed of a start point and an end point
	public struct Line{
		public Vector3 start;
		public Vector3 end;
	}

	void Start(){
		string filePath = "/Data/lineCoords.txt";
		image_lines = ReadTxtFile(Application.dataPath + filePath);;
	}

	void Update() {
	}

	void OnPostRender() {
		if (!mat) {
			Debug.LogError("Please Assign a material on the inspector");
			return;
		}
		GL.PushMatrix();
		mat.SetPass(0);
		GL.LoadOrtho();
		GL.Begin(GL.LINES);
		//GL.Color(Color.red);

//		foreach( Line line in image_lines ){
//			GL.Vertex(line.start);
//			GL.Vertex(line.end);
//			//Debug.Log(line.start);
//		}

		GL.End();
		GL.PopMatrix();
	}

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
}


