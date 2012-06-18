#define cam Serial

#define CAM_UNKNOWN 0x00
#define CAM_ACK     0x01
#define CAM_NOACK   0x02
#define CAM_TIMEOUT 0x04
#define CAM_NOEOL   0x08

char status = 0x0;

int boxCount;
typedef struct {
  char c;  // tracking color
  char x1; // bounding box coordinates
  char y1;
  char x2;
  char y2;
} boxes;

#define MAX_BOX 8
boxes box[MAX_BOX]; // TODO: not sure how many we need to be able to track

char trackColor[COLSIZ];       // RGB color to track

//////////////////////////////////////////////////////////////////////////////
// recvAck
//
// Receive camera response status: either ACK or NCK. If it's anything
// else, mark it unknown status. Check for timeout
//
//////////////////////////////////////////////////////////////////////////////
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

//////////////////////////////////////////////////////////////////////////////
// recvCam
//
// Receive camera serial data for bounding boxes of tracked blobs
//
//////////////////////////////////////////////////////////////////////////////
void recvCam() 
{

  //' re-initialize box count
  // Get Tracking Data
  // Byte 0: 0x0A Indicating the start of a tracking packet
  // AVRcam sends no data until boxCount are detected, so we timeout
  // and reset the number of boxCount to 0 at some point

  char c;
  int timeout=80;  
  int myBoxes;
  int time=millis();

  do {  

    while (!cam.available()) {
      // The AVRcam doesn't send anything if it doesn't see anything so the way to
      // tell if there are no boxes is that nothing gets sent. We need a timeout...
      if (timeout == 0) {
        cli(); // prevent I2C from reading boxCount until we're done
        boxCount = 0;
        sei();
        timeout = -1; // no need to keep zeroing the box count
      } else if (timeout > 0) {
        timeout--;
        delay(1);
      }
    }
    c = (char) cam.read();

    // Reset the camera if we've waited 5 seconds
    /*
    if ((millis() - time) > 5000) {
      initColorTrack();
      time = millis();
    }
    */

  } while ( c != 0x0A );

  // Byte 1: Number of tracked objects (0x00...0x08 are valid)
  myBoxes = cam.read();

  if (myBoxes > 8) myBoxes = 8; // just to be safe...

  for (int i=0; i < myBoxes; i++) {  
    box[i].c = cam.read();  // Color of object tracked in bounding box 1
    box[i].x1 = cam.read(); // X upper left corner of bounding box 1
    box[i].y1 = cam.read(); // Y upper left corner of bouding box 1
    box[i].x2 = cam.read(); // X lower right corner of boudning box 1
    box[i].y2 = cam.read(); // Y lower right corner of boudning box 1
    if (cam.read() != 0xff)
      status |= CAM_NOEOL;
    
    cli();
    boxCount = myBoxes; // reset the new counter
    sei();
    
  }

  return;
}

void initCam()
{
  cam.begin(115200);
}

//////////////////////////////////////////////////////////////////////////////
// initBoxes
//
// Initialize box data
//
//////////////////////////////////////////////////////////////////////////////
void initBoxes() {
  cli();
  boxCount = 0;
  sei();
  for (int i=0; i < MAX_BOX; i++) {
    box[i].c = 0;
    box[i].x1 = box[i].x2 = box[i].y1 = box[i].y2 = 0;
  }
}
  
//////////////////////////////////////////////////////////////////////////////
// initColorTrack
//
// Initialize the camera and color tracking map
//
//////////////////////////////////////////////////////////////////////////////
void initColorTrack() 
{
  int stat=0;

  /*
   * Initialize Color Map: RED
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
    
  digitalWrite(statLED, HIGH);
  cam.print("PG\r");  // ping the camera
  // wait for ACK
  stat |= recvAck();

  digitalWrite(statLED, LOW);
  delay(200);
  digitalWrite(statLED, HIGH);

  cam.print("DT\r");  // disable tracking before setting color map
  stat |= recvAck();

  digitalWrite(statLED, LOW);
  delay(200);
  digitalWrite(statLED, HIGH);

  cam.print("SM"); // set color map
  for (int i=0; i < COLSIZ; i++)
    cam.print(trackColor[i]);
  cam.print("\r");
  stat |= recvAck();

  digitalWrite(statLED, LOW);
  delay(200);
  digitalWrite(statLED, HIGH);
  
  cam.print("ET\r");  // enable tracking
  stat |= recvAck();

  digitalWrite(statLED, LOW);
  delay(200);
  digitalWrite(statLED, HIGH);
  
  if (stat == 0) {
    digitalWrite(statLED, HIGH);
  } else {
    digitalWrite(statLED, LOW);
  }
  
  return;
}




