#include <Wire.h>
//#include <NewSoftSerial.h>
#include <Parse.h>

#define MAX_COLORS 16        // Max number of AVRcam colormap colors
#define COLSIZ 48

#define statLED 13

// Buffer size
#define MAXDATA 32

#define MAX_ADC 3 // I2C takes up ADC4,5
uint16_t adcValue[MAX_ADC];

//////////////////////////////////////////////////////////////////////////////
// initialization
//////////////////////////////////////////////////////////////////////////////
void setup() {
  initI2C();
  initCam();
  
  pinMode(statLED, OUTPUT);
  
  timerSetup();
  
  //  cam.println("Hello, Camera");
  //pc.println("Hello, PC");

  initBoxes();

  Wire.onRequest(handleI2CRequest); // register Request event
  Wire.onReceive(handleI2CReceive); // register Receive event
  initColorTrack();
}

//////////////////////////////////////////////////////////////////////////////
// Not much to do here except receive/parse camera serial... even this could
// be moved to an interrupt handler
//////////////////////////////////////////////////////////////////////////////
void loop() {
  recvCam();
}


 


