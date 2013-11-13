using UnityEngine;
using System.Collections;
using System.IO.Ports;

public class MoveObject : MonoBehaviour {
	
	public float speed;
	private float moveAmount;
	
	SerialPort sp = new SerialPort("\\\\.\\COM11", 9600);
	
	void Start()
	{
		sp.Open();
		sp.ReadTimeout = 1;
	}
	
	void Update ()
	{
		moveAmount = speed * Time.deltaTime;
		
		if(sp.IsOpen){
			try{
				Move(sp.ReadByte());
				print(sp.ReadByte());
			}
			catch{
				
			}
		}
	}
	
	void Move( int direction )
	{
		if( direction == 1 )
		{
			transform.Translate(Vector3.left * moveAmount, Space.World);
		}
	}
}
