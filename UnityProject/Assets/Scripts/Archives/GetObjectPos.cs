using UnityEngine;
using System.Collections;
using System.IO.Ports;
using System;

public class GetObjectPos : MonoBehaviour {

	SerialPort sp = new SerialPort("\\\\.\\COM11", 9600);
	
	void Start()
	{
		if(sp.IsOpen)
		{
			sp.Close();
		}
		else
		{
			sp.Open();
			sp.ReadTimeout = 16;
		}
	}
	
	void Update ()
	{
		int objectPosX = (int)transform.position.x;
		byte[] objectPosXByte = BitConverter.GetBytes(objectPosX);
		
//		Debug.Log(BitConverter.IsLittleEndian);
//		IsLittleEndian is True here
		
		if(sp.IsOpen){
			try{
				sp.Write(objectPosXByte, 0, 1);
				
				Debug.Log("--");
				foreach(byte b in objectPosXByte)
					Debug.Log(b.ToString());
			}
			catch(Exception e){
				Debug.Log(e);
			}
		}
	}
	
    void OnApplicationQuit() 
    {
       sp.Close();
    }
}