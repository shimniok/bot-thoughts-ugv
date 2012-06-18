// I2C
#define I2C_ADDR 0x11
#define I2C_SEND_BOXES 0x01  // command to send boxes
#define I2C_SEND_RANGER 0x02 // command to send ranger data
#define I2C_SET_COLOR  0x04  // command to set tracking color
#define I2C_MAX_BYTES    64  // I2C Max data transmission

char received[I2C_MAX_BYTES];  // Data recieved from I2C

//////////////////////////////////////////////////////////////////////////////
// Initialize I2C peripheral
//////////////////////////////////////////////////////////////////////////////
void initI2C()
{
  Wire.begin(I2C_ADDR);
}

//////////////////////////////////////////////////////////////////////////////
// If we get a data request, send data
//////////////////////////////////////////////////////////////////////////////
void handleI2CRequest(void) 
{
 // if (received[0] == I2C_SEND_BOXES) {
  
    // TODO: send entire list of boxes
    Wire.send(1);
    // send box count
    Wire.send(0x0);
    Wire.send(0xd);
    Wire.send(0xe);
    Wire.send(0xa);
    Wire.send(0xd);
    
    //if (mode == MONITOR) pc.print("Request received\n");
  /* 
  } else if (received[0] == I2C_SEND_RANGER) {

    byte data[6];
    byte *v = (byte *) adcValue;
  
    for (int i=0; i < 6; i++)
      data[i] = *v++;
  
    Wire.send(data,6);
  }
  */
  return;
}

//////////////////////////////////////////////////////////////////////////////
// Function that executes whenever data is requested by master
//  this function is registered as an event, see setup()
//
// Protocol
// 1) Master requests 4 bytes from us (slave), the bounding box
// 2) Slave sends 4 bytes, x1, y1, x2, y2 that are the bounding box, or
//    all 0s if no obj
//
// TODO:
//
// .write tracking color register
// .reset(?)
// .request list of bounding boxes
//
//////////////////////////////////////////////////////////////////////////////
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
  /*
  if (received[0] == I2C_SET_COLOR) {
    trackColor[0*MAX_COLORS] = received[0];  // red0
    trackColor[1*MAX_COLORS] = received[1]; // green0
    trackColor[2*MAX_COLORS] = received[2]; // blue0
    initColorTrack();
  }
  */
  return;
}
