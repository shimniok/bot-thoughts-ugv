#include <Wire.h>
//#include <NewSoftSerial.h>
#include <Parse.h>

// I2C
#define I2C_SEND_BOXES 0x01  // command to send boxes
#define I2C_SET_COLOR  0x04  // command to set tracking color
#define I2C_MAX_BYTES 5      // I2C Max data transmission

#define MAX_COLORS 16        // Max number of AVRcam colormap colors
#define COLSIZ 48

#define statLED 13

// Buffer size
#define MAXDATA 32

// Objects
//NewSoftSerial pc(9, 10);
#define cam Serial
Parse p;

enum states { SYNC_ON_EOL, WAIT_FOR_C, GET_DATA };
char received[I2C_MAX_BYTES];  // Data recieved from I2C
char trackColor[COLSIZ];      // RGB color to track
char data[MAXDATA];            // Bounding box data to send
int d = 0;
int state = SYNC_ON_EOL;

#define WD_TICK 1000          // clock ticks in ms
#define WD_TIMEOUT 3          // start with 3 x WD_TICK ms of timeout
int watchdog = WD_TIMEOUT;    // used to determine if we're still getting data

enum modes { STANDARD, BRIDGE, MONITOR };
int mode = STANDARD;

typedef struct {
  char x1;
  char y1;
  char x2;
  char y2;
} boxes;

#define MAX_BOX 8
boxes box[MAX_BOX]; // TODO: not sure how many we need to be able to track



void setup() {
  Wire.begin(0x80);
  //pc.begin(1200);
  cam.begin(115200);
  
  pinMode(statLED, OUTPUT);
  
//  cam.println("Hello, Camera");
  //pc.println("Hello, PC");
  
  for (int i=0; i < MAX_BOX; i++) {
     box[i].x1 = box[i].x2 = box[i].y1 = box[i].y2 = 0;
  }

  Wire.onRequest(handleI2CRequest); // register Request event
  Wire.onReceive(handleI2CReceive); // register Receive event
  //showHelp();
  initColorTrack();
}



// TODO: convert the rest to interrupt driven
// make the main loop handle commands and stuff
void loop() {
  recvCam();
  //recvSerial();
}




void handleI2CRequest(void) 
{
  //if (received[0] == I2C_SEND_BOXES) {
  
    // TODO: send entire list of boxes
    Wire.send(1);
    // send box count
    Wire.send(0x0);
    Wire.send(0xd);
    Wire.send(0xe);
    Wire.send(0xa);
    Wire.send(0xd);
    
    //if (mode == MONITOR) pc.print("Request received\n");
    
  //}
  return;
}

/** Function that executes whenever data is requested by master
 *  this function is registered as an event, see setup()
 *
 * Protocol
 * 1) Master requests 4 bytes from us (slave), the bounding box
 * 2) Slave sends 4 bytes, x1, y1, x2, y2 that are the bounding box, or all 0s if no obj
 *
 * TODO:
 *
 * .write tracking color register
 * .reset(?)
 * .request list of bounding boxes
 *
 */
void handleI2CReceive(int bytesReceived)
{
  for (int a = 0; a < bytesReceived; a++) {
    // flag I2C receive event
    if ( a < I2C_MAX_BYTES) {
      received[a] = Wire.receive();
    } else {
      Wire.receive();  // if we receive more data then allowed just throw it away
    }
  }
  if (received[0] == I2C_SET_COLOR) {
    trackColor[0*MAX_COLORS] = received[0];  // red0
    trackColor[1*MAX_COLORS] = received[1]; // green0
    trackColor[2*MAX_COLORS] = received[2]; // blue0
    initColorTrack();
  }
  return;
}
 

/* 
void recvSerial() 
{
  static int count = 0;

  while (pc.available()) {
    char c = (char) pc.read();

    if (mode == BRIDGE) {

      cam.print(c);
      // check for +++
      if (c == '+') {
          if (++count >= 3) {
            mode = STANDARD;
            //pc.println("Exited bridge mode, restarting color tracking");
            showHelp();
            initColorTrack();
          }
      } else {
          count = 0;
      }

    } else {
      
      switch (c) {
        case 'b' :
        case 'B' :
          mode = BRIDGE;
          break;
        case 'm' :
        case 'M' :
          mode = MONITOR;
          //pc.println("I2C Monitor mode. E to exit");
          break;
        case 'e' :
        case 'E' :
          if (mode == MONITOR)
            mode = STANDARD;
          break;
        case 'q' :
        case 'Q' :        
          if (c == 'Q')
          printBox();
          break;
        case '?' :
          showHelp();
          break;
        default :
          break;
      } // switch-case

    } // if mode == BRIDGE else
  } // while

  return;
} //recvSerial()
*/

#define CAM_UNKNOWN 0x00
#define CAM_ACK     0x01
#define CAM_NOACK   0x02
#define CAM_TIMEOUT 0x04

/** determine camera response status: either ACK or NCK. If it's anything
 * else, mark it unknown status. Check for timeout
 */ 
int recvAck()
{
  int timeout;
  int stat = CAM_UNKNOWN;
  char resp[5];
  int i;
  
  for (i=0; i < 5; i++)
    resp[i] = 0;
  
  // Check for timeout
  timeout = 3;
  while (cam.available() == 0 && timeout > 0) {
    delay(1000);
    timeout--;
  }
  
  if (timeout <= 0) {
    stat = CAM_TIMEOUT;
  } else {

    i = 0;
    while (cam.available()) {
      if (i < 5) {
        resp[i] = cam.read();
      } else {
        cam.read();
      }
      //if (mode == BRIDGE) pc.print(resp[i]);
      i++;
    }
  
    // Parse response; defaults to CAM_UNKNOWN status  
    if (resp[1] == 'C' && resp[2] == 'K') {
      if (resp[0] == 'A')
        stat = CAM_ACK;
      else if (resp[0] == 'N')
        stat = CAM_NOACK;
    }
  
  }
  
  return stat;
}

void recvCam() 
{
  // every WD_TICK ms, decrement the watchdog ticker
  // it gets incremented every time a color track packet
  // is processed, up to a WD_TIMEOUT
  if ((millis() % WD_TICK) == 0) {
    watchdog--;
    // if the ticker runs out, try to reinitialize the color tracking
    if (watchdog <= 0)
      initColorTrack();
  }

  while (cam.available()) {
    char c = (char) cam.read();
    //if (mode == BRIDGE) pc.print(c);
    parse(c);
  }
  return;
}

void parse(char c) 
{
  switch (state) {
    case SYNC_ON_EOL:
      if (c == '\r') state = WAIT_FOR_C;
      break;
    case WAIT_FOR_C:
      if (c == 'C') {
        d = 0;
        state = GET_DATA;
      } else {
        state = SYNC_ON_EOL;
      }
      break;
    case GET_DATA:
      if (c == '\r') {
        data[d] = 0;
        process();
        state = WAIT_FOR_C;
      } else {
        data[d++] = c;
      }
      break;
    default :
      state = SYNC_ON_EOL;
      break;
  }
  return;
}

void process() {
  char tok[8];
  char *t;
  
  /*
  // suck up the first space
  t = p.split(tok, data, MAXDATA, ' ');
  
  t = p.split(tok, t, MAXDATA, ' ');
  box.x1 = atoi(tok);
  
  t = p.split(tok, t, MAXDATA, ' ');
  box.y1 = atoi(tok);

  t = p.split(tok, t, MAXDATA, ' ');
  box.x2 = atoi(tok);

  t = p.split(tok, t, MAXDATA, ' ');
  box.y2 = atoi(tok);
  */  
  
  if (watchdog < WD_TIMEOUT)
    watchdog++;
  
  return;
}

/*
void printAck(int stat) 
{
  if (stat == CAM_ACK) {
    pc.println("ACK received");
  } else if (stat == CAM_NOACK) {
    pc.println("NCK received");
  } else if (stat == CAM_TIMEOUT) {
    pc.println("Cam timeout");
  }
  return;
}

void printBox() {
  pc.print("X1: ");
  pc.print((int) box.x1);
  pc.print(" Y1: ");
  pc.print((int) box.y1);
  pc.print(" X2: ");
  pc.print((int) box.x2);
  pc.print(" Y2: ");
  pc.print((int) box.y2);
  pc.println();
  return;
}

void showHelp() {
  pc.println("AVRcam I2C Bridge is online");
  pc.println("   B to enter serial to serial bridge, +++ to stop");
  pc.println("   M to enter I2C debug monitor mode E to exit");
  pc.println("   Q to display current bounding box");
  pc.println("   ? displays this menu");
  return;
}
*/


void initCamera() {
  // disable AWB
  // Other configurations?
}

void initColorTrack() 
{
  int stat;

  /*
   * Initialize Color Map
   * r=144:176, b=32:64, g=16:48
   * r 0 0 0 0 0 0 0 0 0 128 128 128 0 0 0 0
   * g 0 0 128 128 128 0 0 0 0 0 0 0 0 0 0 0
   * b 0 128 128 128 0 0 0 0 0 0 0 0 0 0 0 0
   */
  for (int i=0; i < COLSIZ; i++)
    trackColor[i] = 0;
  trackColor[9]  = trackColor[10] = trackColor[11] = 128;
  trackColor[18] = trackColor[19] = trackColor[20] = 128;
  trackColor[33] = trackColor[34] = trackColor[35] = 128;
  
  
  //pc.println("Resetting camera and initializing color tracking");
  mode = BRIDGE;  // automatically display I/O to FTDI port

  digitalWrite(statLED, HIGH);
  cam.print("PG\r");  // ping the camera
  // wait for ACK
  //pc.println("PG");
  stat |= recvAck();
  //printAck(stat);

  digitalWrite(statLED, LOW);
  delay(200);
  digitalWrite(statLED, HIGH);

  cam.print("DT\r");  // disable tracking before setting color map
  //pc.println("DT");
  stat |= recvAck();
  //printAck(stat);

  digitalWrite(statLED, LOW);
  delay(200);
  digitalWrite(statLED, HIGH);

  cam.print("SM"); // set color map
  //pc.println("SM");
  for (int i=0; i < COLSIZ; i++)
    cam.print(trackColor[i]);
  cam.print("\r");
  stat |= recvAck();
  //printAck(stat);

  digitalWrite(statLED, LOW);
  delay(200);
  digitalWrite(statLED, HIGH);
  
  cam.print("ET\r");  // enable tracking
  //pc.println("ET");
  stat |= recvAck();
  //printAck(stat);

  digitalWrite(statLED, LOW);
  delay(200);
  digitalWrite(statLED, HIGH);
  
  if (stat == 0) {
    digitalWrite(statLED, HIGH);
  } else {
    digitalWrite(statLED, LOW);
  }
  
  //mode = STANDARD;
  
  watchdog = WD_TIMEOUT;
  
  return;
}
