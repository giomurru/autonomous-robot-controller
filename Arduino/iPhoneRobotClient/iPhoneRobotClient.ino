#include "IRSensor.h"
#include "CarController.h"
#include "Wire.h"
#include <Adafruit_MotorShield.h>
#include "utility/Adafruit_PWMServoDriver.h"

IRSensor sensor_00(14); //starting from bottom
IRSensor sensor_01(11);
IRSensor sensor_02(15);
IRSensor sensor_03(12);

CarController carController(4, 1, 3, 2);
boolean carIsMoving;
unsigned long lastStreamReceived;

byte irData[5];
boolean readyForNewCommand;
unsigned long loopNumber = 0;

int decodeSpeedByte(byte speedByte)
{
  int realSpeed = 0;
  
  if (speedByte >= 128)
  {
    realSpeed = (speedByte - 128 + 1)*2;
  }
  else
  {
    realSpeed = -speedByte*2;
  }
  
  return realSpeed;
}
  
void setup() {
  // put your setup code here, to run once:
  Serial.begin(9600);
  Serial1.begin(57600);
  
  carController.Init();
  carIsMoving = false;
  readyForNewCommand = true;
  Serial.println("Setup");
  //randomSeed(analogRead(1));
}

void loop() 
{
  Serial.print("LN: ");
  Serial.println(loopNumber);
  loopNumber++;
  
  /*
  If a command is already started wait for it to complete
  */
  if (readyForNewCommand == false) 
  {
    Serial.println("Not ready for new command");
  }
  else
  {
    readyForNewCommand = false;
    Serial.println("Ready for new command");
    /*
    If I loose connection stop the robot
    */
    /*
    if ((millis() - lastStreamReceived) > 500 && carIsMoving)
    {
      lastStreamReceived = millis();
      carIsMoving = false;
      carController.Stop();
      readyForNewCommand = true;
      Serial.println("Exit 0");
      return;
    }
    */
      
    /*
      If the connection is stable read the commands coming from the bluetooth server (iPhone or Android device)
    */
    
    if (Serial1.available() > 0) 
    {    
      Serial.println("Start loop");
      unsigned long loopStartTime = millis();
      //Serial.println("New serial event occurred:");
      
      /*
      Wait for the byte the signal the start of a new velocity wheel command,
      while discarding other bytes
      */
      while (Serial1.available() > 0 && Serial1.read() != 0xff) 
      {
        Serial.println("There's junk on the buffer. Waiting for next velocity command");  
        delay(5);
        
        /*
        if it takes too long to receive the command, stop the car
        */
        if ((millis() - lastStreamReceived) > 500 && carIsMoving)
        {
          lastStreamReceived = millis();
          carController.Stop();
          carIsMoving = false;
          readyForNewCommand = true;
          Serial.println("Exit 1");
          return;
        }
      }
      
      //Serial.println("I found a velocity command.");
      while (Serial1.available() < 4) 
      {
        //Serial.println("Waiting all the command bytes to be available.");  
        delay(5);
        
        /*
        if it takes too long to complete the 4 bytes command, skip the command
        */
        if ((millis() - lastStreamReceived) > 500 && carIsMoving)
        {
          lastStreamReceived = millis();
          carController.Stop();
          carIsMoving = false;
          readyForNewCommand = true;
          Serial.println("Exit 2");
          return;
        }
      }
      /*
      If I make it here it means that I have the 4 bytes command in the Serial1 buffer
      */
      //Serial.println("All bytes are available.");  
      byte receivedBytes[4];
      Serial1.readBytes(receivedBytes, sizeof(byte)*4); 
    
      /*
      Empty all the extra bytes available
      */
      while (Serial1.available() > 0) 
      { 
        Serial.println("Still bytes inside buffer. Emptying."); 
        Serial1.read(); 
      }
      unsigned long timeOfTransmission = millis() - lastStreamReceived;
      lastStreamReceived = millis();
      carIsMoving = true;
      int frontRight = decodeSpeedByte(receivedBytes[0]);
      int frontLeft = decodeSpeedByte(receivedBytes[1]);
      int rearRight = decodeSpeedByte(receivedBytes[2]);
      int rearLeft = decodeSpeedByte(receivedBytes[3]);
      
      carController.SetFrontRightWheelSpeed(frontRight);
      carController.SetFrontLeftWheelSpeed(frontLeft);
      carController.SetRearRightWheelSpeed(rearRight);
      carController.SetRearLeftWheelSpeed(rearLeft);
      // add it to the inputString:
     
      
      Serial.print(" Robot speeds values are: FR: ");
      Serial.print(frontRight);
      Serial.print(", FL: ");
      Serial.print(frontLeft);
      Serial.print(", RR: ");
      Serial.print(rearRight);
      Serial.print(", RL: ");
      Serial.println(rearLeft);
      
      /*
      After I received the car velocities and I set them on the robot,
      it's time to send the sensor data to the server in order to decide
      which are the correct wheels velocities
      */
      
      //Serial.print("Sending ir sensor data: ");
      irData[0] = 0xff;
      irData[1] = sensor_00.byteValue();
      irData[2] = sensor_01.byteValue();
      irData[3] = sensor_02.byteValue();
      irData[4] = sensor_03.byteValue();
      
      /*
      Serial.print(irData[0], DEC);
      Serial.print(", ");
      Serial.print(irData[1], DEC);
      Serial.print(", ");
      Serial.print(irData[2], DEC);
      Serial.print(", ");
      Serial.println(irData[3], DEC);
      */
      
      Serial1.write(irData, sizeof(irData));
      unsigned long loopTime = millis() - loopStartTime;
      Serial.print(loopTime);
      Serial.print(" ");
      
      if (loopTime < 500)
      {
        delay(500 - loopTime);
      }
    }
    else
    {
       Serial.println("No yet serial");
    }
    
    readyForNewCommand = true;
  }
}
