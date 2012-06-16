// Timer
unsigned int tcnt2;

// ADC variables
#define FILT_A 0.2 // exponential filter; gain for current reading
#define FILT_B 0.8 // gain for previous reading


//////////////////////////////////////////////////////////////////////////////
// Setup timer to call interrupt handler periodically
//
// http://popdevelop.com/2010/04/mastering-timer-interrupts-on-the-arduino/
// author: Sebastian Wallin 
//////////////////////////////////////////////////////////////////////////////
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

//////////////////////////////////////////////////////////////////////////////
// Install the Interrupt Service Routine (ISR) for Timer2 overflow. 
// This is normally done by writing the address of the ISR in the 
// interrupt vector table but conveniently done by using ISR()
//////////////////////////////////////////////////////////////////////////////
ISR(TIMER2_OVF_vect) {  
  /* Reload the timer */  
  TCNT2 = tcnt2;  
  /* toggle pin so that we can confirm our timer */  
  //PINB |= _BV(5); // toggle PB5 (Arduino Pin 13)

  for (int i=0; i < MAX_ADC; i++) {
    adcValue[i] = FILT_A*analogRead(i) + FILT_B*adcValue[i]; 
  }
}  
