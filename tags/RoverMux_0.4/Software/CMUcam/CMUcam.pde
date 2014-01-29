#include <Wire.h>
#include <NewSoftSerial.h>
#include <Parse.h>

#define MAXDATA 32

NewSoftSerial cam(14, 15);
Parse p;

enum states { SYNC_ON_EOL, WAIT_FOR_C, GET_DATA };
char data[MAXDATA];
int d = 0;
int state = SYNC_ON_EOL;

#define WD_TICK 1000          // clock ticks in ms
#define WD_TIMEOUT 3          // start with 3 x WD_TICK ms of timeout
int watchdog = WD_TIMEOUT;    // used to determine if we're still getting data

enum modes { STANDARD, BRIDGE, MONITOR };
int mode = STANDARD;

struct {
  char x1;
  char y1;
  char x2;
  char y2;
} box;

void setup() {
  Wire.begin(0x07);
  Serial.begin(115200);
  cam.begin(9600);

  box.x1 = box.x2 = box.y1 = box.y2 = 0;

  Wire.onRequest(recvI2C); // register event
  showHelp();
  initColorTrack();
}

void loop() {
  recvCam();
  recvSerial();
}

/** Function that executes whenever data is requested by master
 *  this function is registered as an event, see setup()
 *
 * Protocol
 * 1) Master requests 4 bytes from us (slave), the bounding box
 * 2) Slave sends 4 bytes, x1, y1, x2, y2 that are the bounding box, or all 0s if no obj
 */
void recvI2C()
{
  Wire.send(box.x1);
  Wire.send(box.y1);
  Wire.send(box.x2);
  Wire.send(box.y2);
  if (mode == MONITOR) Serial.print("Request received\n");
  return;
}
 
 
void recvSerial() {
  static int count = 0;

  while (Serial.available()) {
    char c = (char) Serial.read();

    if (mode == BRIDGE) {

      cam.print(c);
      // check for +++
      if (c == '+') {
          if (++count >= 3) {
            mode = STANDARD;
            Serial.println("Exited bridge mode, restarting color tracking");
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
          Serial.println("I2C Monitor mode. E to exit");
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

void recvCam() {
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
    if (mode == BRIDGE) Serial.print(c);
    parse(c);
  }
  return;
}

void parse(char c) {
  
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
  
  if (watchdog < WD_TIMEOUT)
    watchdog++;
  
  return;
}

void printBox() {
  Serial.print("X1: ");
  Serial.print((int) box.x1);
  Serial.print(" Y1: ");
  Serial.print((int) box.y1);
  Serial.print(" X2: ");
  Serial.print((int) box.x2);
  Serial.print(" Y2: ");
  Serial.print((int) box.y2);
  Serial.println();
  return;
}

void showHelp() {
  Serial.println("CMU Cam I2C Bridge is online");
  Serial.println("   B to enter serial to serial bridge, +++ to stop");
  Serial.println("   M to enter I2C debug monitor mode E to exit");
  Serial.println("   Q to display current bounding box");
  Serial.println("   ? displays this menu");
  return;
}


void initColorTrack() {
  Serial.println("Resetting camera and initializing color tracking");
  mode = BRIDGE;
  cam.print("\r");
  delay(500);
  recvCam();
  cam.print("RS\r");
  delay(500);
  recvCam();
  cam.print("PM 0\r");
  delay(500);
  recvCam();
  cam.print("MM 0\r");
  delay(500);
  recvCam();
  cam.print("TC 120 255 0 50 0 30\r");
  delay(500);
  recvCam();
  mode = STANDARD;
  
  watchdog = WD_TIMEOUT;
  
  return;
}
