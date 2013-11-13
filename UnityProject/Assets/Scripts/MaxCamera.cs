using UnityEngine;
using System.Collections;

public class MaxCamera : MonoBehaviour
{
    //Orbit
    public Transform target;
	
    //MaxCamera
    public Transform temp;
    public Vector3 tempOffset;
    public float distance = 20.0f;
    public float maxDistance = 200.0f;
    public float minDistance = 0.6f;
    public float xSpeed = 200.0f;
    public float ySpeed = 200.0f;
    public int yMinLimit = -80;
    public int yMaxLimit = 80;
    public int zoomRate = 100;
    public float panSpeed = 1.0f;
    public float zoomDampening = 40.0f;
 
    public float xDeg = 0.0f;
    public float yDeg = 0.0f;
    public float currentDistance;
    public float desiredDistance;
    private Quaternion currentRotation;
    private Quaternion desiredRotation;
    private Quaternion rotation;
    private Vector3 position;
 
    void Start() { Init(); }
    void OnEnable() { Init(); }
 
    public void Init()
    {
        //If there is no temp, create a temporary temp at 'distance' from the cameras current viewpoint
        if (!temp)
        {
            GameObject go = new GameObject("Cam temp");
            go.transform.position = transform.position + (transform.forward * distance);
            temp = go.transform;
        }
 
        distance = Vector3.Distance(transform.position, temp.position);
        currentDistance = distance;
        desiredDistance = distance;
               
        //be sure to grab the current rotations as starting points.
        position = transform.position;
        rotation = transform.rotation;
        currentRotation = transform.rotation;
        desiredRotation = transform.rotation;
       
        xDeg = Vector3.Angle(Vector3.right, transform.right );
        yDeg = Vector3.Angle(Vector3.up, transform.up );
    }
 
	
    //Camera logic on LateUpdate to only update after all character movement logic has been handled.
    void LateUpdate()
    {
        // If left mouse button > ORBIT
        if (Input.GetMouseButton(1) )
        {
            xDeg += Input.GetAxis("Mouse X") * xSpeed * 0.02f;
            yDeg -= Input.GetAxis("Mouse Y") * ySpeed * 0.02f;
 
            ////////OrbitAngle
 
            //Clamp the vertical axis for the orbit
            yDeg = ClampAngle(yDeg, yMinLimit, yMaxLimit);
            // set camera rotation
            desiredRotation = Quaternion.Euler(yDeg, xDeg, 0);
            currentRotation = transform.rotation;
           
            rotation = Quaternion.Lerp(currentRotation, desiredRotation, Time.deltaTime * zoomDampening);
            transform.rotation = rotation;
        }
        // otherwise if middle mouse is selected, we pan by way of transforming the temp in screenspace
        else if (Input.GetMouseButton(2))
        {
            //grab the rotation of the camera so we can move in a psuedo local XY space
            temp.rotation = transform.rotation;
            temp.Translate(Vector3.right * -Input.GetAxis("Mouse X") * panSpeed); // these move temp
            temp.Translate(transform.up * -Input.GetAxis("Mouse Y") * panSpeed, Space.World);
        }
 
        ////////Orbit Position
 
        // affect the desired Zoom distance if we roll the scrollwheel
        desiredDistance -= Input.GetAxis("Mouse ScrollWheel") * Time.deltaTime * zoomRate * Mathf.Abs(desiredDistance);
        //clamp the zoom min/max
        desiredDistance = Mathf.Clamp(desiredDistance, minDistance, maxDistance);
        // For smoothing of the zoom, lerp distance
        currentDistance = Mathf.Lerp(currentDistance, desiredDistance, Time.deltaTime * zoomDampening);
 
        // calculate position based on the new currentDistance
        position = temp.position - (rotation * Vector3.forward * currentDistance + tempOffset);
        transform.position = position;
}
 
    private static float ClampAngle(float angle, float min, float max)
    {
        if (angle < -360)
            angle += 360;
        if (angle > 360)
            angle -= 360;
        return Mathf.Clamp(angle, min, max);
    }
}