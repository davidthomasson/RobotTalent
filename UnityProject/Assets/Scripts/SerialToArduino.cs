using UnityEngine;
using System.Collections;
using System.IO.Ports;
using System;

public class SerialToArduino : MonoBehaviour {

	public int COMNumber = 11;
	protected SerialPort sp;
	public static byte[] ServoBytes = new byte[7];

	void Start()
	{
		sp = new SerialPort("\\\\.\\COM" + COMNumber, 9600);

		if(sp.IsOpen)
		{
			sp.Close();
		}
		else
		{
			sp.Open();
			sp.ReadTimeout = 16;
		}

		StartCoroutine( SendBytesToArduino() );
	}
	
	void Update ()
	{

	}

	void OnApplicationQuit() 
	{
		sp.Close();
	}

	IEnumerator SendBytesToArduino(){
		while( true ){			
			//		Debug.Log(BitConverter.IsLittleEndian);
			//		IsLittleEndian is True here
			
			if(sp.IsOpen){
				try{
					sp.Write(ServoBytes, 0, 7);

//					Debug.Log("--");
//					foreach(byte b in ServoBytes)
//						Debug.Log(b.ToString());
				}
				catch(Exception e){
					Debug.Log(e);
				}
			}
			yield return null;
		}
	}
}
