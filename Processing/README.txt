Provides a graphical simulation of the 3DOF robot arm.
Also sends serial commands to Arduino to control the servos of the actual arm.

The arm can be controlled by setting the X,Y,Z coordinates of the tip of the arm, and letting this code work out the Inverse Kinematics to determine the required angles of each of the 3 servos.
It can also be controlled by setting the angle of each servo individually.
There is also a 'sketch' mode which draws a smiley face.