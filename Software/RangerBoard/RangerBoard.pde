#include <Wire.h>

#define I2C_ADDR 0x11
#define MAX_ADC 3 // I2C takes up ADC4,5

uint16_t adcValue[8];
float filt = 0.2; // exponential filter parameter; multiplied against current signal
enum modes { STANDARD, VALUES, MONITOR };
int mode = STANDARD;

void setup() {
  Serial.begin(9600);
  Wire.begin(I2C_ADDR);
  Wire.onRequest(handleI2CRequest); // register event
  Wire.onReceive(handleI2CReceive); // register Receive event
  delay(1000);
  Serial.println("ADC to I2C Ranger Interface");
  Serial.println("? for help");
}


void loop() {
  int b;
  for (int j=0; j < 128; j++) {
    for (int i=0; i < MAX_ADC; i++) {
      adcValue[i] = filt*analogRead(i) + (1-filt)*adcValue[i]; 
    }
  }

  if (Serial.available()) {
    char c = Serial.read();
    switch (c) {
      case 'm' :
        mode = MONITOR;
        break;
      case 'q' :
        printValues();
        break;
      case 's' :
      case '?' :
        mode = STANDARD;
        Serial.println("---------------\nm - monitor\nq - query\ns - standard\nv - values\n? - help (this menu)\n---------------\n");
        break;
      case 'v' :
        mode = VALUES;
        break;
      default :
        break;
    }
  }

  if (mode == VALUES) {
    printValues();
  }
  delay(10);
}


void printValues() {
  for (int i=0; i < MAX_ADC; i++) {
    Serial.print(adcValue[i]);
    if (i < (MAX_ADC-1)) Serial.print(",");
  }
  Serial.println();
}


// returns distance in m for Sharp GP2YOA710K0F
// to get m and b, I wrote down volt vs. dist by eyeballing the
// datasheet chart plot. Then used Excel to do linear regression
//
float irDistance(unsigned int adc)
{
    float b = 1.0934; // Intercept from Excel
    float m = 1.4088; // Slope from Excel

    return m / (((float) adc) * 4.95/1024 - b);
}


// returns distance in m for LV-EZ1 sonar
//
float sonarDistance(unsigned int adc)
{
    float distance = 9999.9;
    
    // EZ1 uses 9.8mV/inch @ 5V or scaling factor of Vcc / 512
    // so we can eliminate Vcc changes by simply converting the 0-512 inch range
    // to the ADC's 0-4096 range
    distance = ((float) adc) * (512 * 0.0254) / 4096;   // distance converted to inch then meter

    return distance;
}    

void handleI2CReceive(int numBytes)
{
  char command = Wire.receive(); // pretty much just ignore the command

  return;
}

/** Function that executes whenever data is requested by master
 *  this function is registered as an event, see setup()
 *
 * Protocol
 * 1) Master requests 4 bytes from us (slave), the bounding box
 * 2) Slave sends sets of 2 bytes for each uint16_t ADC value
 */
void handleI2CRequest()
{
  byte data[6];
  byte *v = (byte *) adcValue;
  
  for (int i=0; i < 6; i++)
    data[i] = *v++;

  Wire.send(data,6);
  
  if (mode == MONITOR) Serial.print("Request received\n");
  
  return;
}
