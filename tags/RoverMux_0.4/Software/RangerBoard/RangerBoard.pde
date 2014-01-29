#include <Wire.h>

#define I2C_ADDR 0x11

// ADC variables
#define MAX_ADC 3 // I2C takes up ADC4,5
#define FILT_A 0.2 // exponential filter; gain for current reading
#define FILT_B 0.8 // gain for previous reading
uint16_t adcValue[MAX_ADC];

// UI modes
enum modes { STANDARD, VALUES, MONITOR };
int mode = STANDARD;
char command;
byte data[32];

// Timer
unsigned int tcnt2;

void setup() {
  Serial.begin(9600);
  Wire.begin(I2C_ADDR);
  Wire.onRequest(handleI2CRequest); // register event
  //Wire.onReceive(handleI2CReceive); // register Receive event
  timerSetup();
  delay(1000);
  Serial.println("ADC to I2C Ranger Interface");
  Serial.println("? for help");
  DDRB |= _BV(5); // setup PB5 (Digital 13) as output
}


void loop() {
  if (Serial.available()) {
    char c = Serial.read();
    switch (c) {
      case 'm' :
        mode = MONITOR;
        Serial.println("Monitor mode enabled");
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



void handleI2CReceive(int numBytes)
{
  char d;
  
  if (mode == MONITOR) 
    Serial.print("I2C Receive: ");

  for (int i=0; i < numBytes; i++) {
    d = Wire.receive(); // pretty much just ignore the command

    if (i == 0) 
      command = d;

    if (i < 32) {
      data[i] = d;
    }

    if (mode == MONITOR) {
      Serial.print(d, HEX);
      Serial.print(" ");
    }
  }
  Serial.println();

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
  byte *v = (byte *) adcValue;

  if (mode == MONITOR)
      Serial.print("I2C Request. Sending: ");
  
  for (int i=0; i < 6; i++) {
    data[i] = *v++;
    if (mode == MONITOR) {
      Serial.print(data[i], HEX);
      Serial.print(" ");
    }
  }
  Serial.println();

  Wire.send(data,6);
  
  return;
}

// http://popdevelop.com/2010/04/mastering-timer-interrupts-on-the-arduino/
// author: Sebastian Wallin 
void timerSetup()
{
   /* First disable the timer overflow interrupt while we're configuring */  
  TIMSK2 &= ~(1<<TOIE2);  
  
  /* Configure timer2 in normal mode (pure counting, no PWM etc.) */  
  TCCR2A &= ~((1<<WGM21) | (1<<WGM20));  
  TCCR2B &= ~(1<<WGM22);  
  
  /* Select clock source: internal I/O clock */  
  ASSR &= ~(1<<AS2);  
  
  /* Disable Compare Match A interrupt enable (only want overflow) */  
  TIMSK2 &= ~(1<<OCIE2A);  
  
  /* Now configure the prescaler to CPU clock divided by 128 */  
  TCCR2B |= (1<<CS22)  | (1<<CS20); // Set bits  
  TCCR2B &= ~(1<<CS21);             // Clear bit  
  
  /* We need to calculate a proper value to load the timer counter. 
   * The following loads the value 131 into the Timer 2 counter register 
   * The math behind this is: 
   * (CPU frequency) / (prescaler value) = 125000 Hz = 8us. 
   * (desired period) / 8us = 125.  1000 / 8 = 125
   * MAX(uint8) + 1 - 125 = 131; 
   */  
  /* Save value globally for later reload in ISR */  
  tcnt2 = 131;   
  
  /* Finally load end enable the timer */  
  TCNT2 = tcnt2;  
  TIMSK2 |= (1<<TOIE2);  
}


/* 
 * Install the Interrupt Service Routine (ISR) for Timer2 overflow. 
 * This is normally done by writing the address of the ISR in the 
 * interrupt vector table but conveniently done by using ISR()  */  
ISR(TIMER2_OVF_vect) {  
  /* Reload the timer */  
  TCNT2 = tcnt2;  
  /* toggle pin so that we can confirm our timer */  
  PINB |= _BV(5); // toggle PB5 (Arduino Pin 13)

  for (int i=0; i < MAX_ADC; i++) {
    adcValue[i] = FILT_A*analogRead(i) + FILT_B*adcValue[i]; 
  }
}  
