using UnityEngine;
using System.Collections;
using System.Collections.Generic;

public class DrawGL : MonoBehaviour {

	public Material mat;
	protected List<Vector3> points = new List<Vector3>();

	void Start() {

	}

	void Update() {
	}

	void OnPostRender() {
		if (!mat) {
			Debug.LogError("Please Assign a material on the inspector");
			return;
		}

		GL.PushMatrix();
		Matrix4x4 rotationMatrix = Matrix4x4.TRS(Vector3.zero, Quaternion.identity, Vector3.one);
		GL.MultMatrix(rotationMatrix); 
		mat.SetPass(0);
		GL.Begin(GL.LINES);
		GL.Color(Color.red);

		foreach( Vector3 point in points){
			GL.Vertex(point);
		}

		GL.End();
		GL.PopMatrix();
	}

	public void AddPoint(Vector3 point){
		points.Add(point);
	}

	public void Clear(){
		points.Clear();
	}
}