/*
 * main.c
 *
 * This firmware runs an RC multiplexer that switches between autonomous and manual control of a robot.
 * A timeout value is subtracted every ~10us. If an RC signal is present, this timeout is reset and Manual
 * Mode is selected. When no RC signal is present for the duration of the timeout period, Autonomous Mode
 * is selected.
 *
 *  Created on: Jul 12, 2013
 *      Author: mes
 */

#include <avr/io.h>
#include <avr/interrupt.h>
#include <util/delay.h>

/*************** DEFINITIONS ****************/

#define CH1RX		PB1
#define CH1INT		PCINT1
#define CH2RX		PB2
#define CH2INT		PCINT2

#define LEDAUTO		PB0
#define LEDMANUAL	PB3
#define ON 			1
#define OFF 		0

#define B			PB4
#define AUTO		1
#define MANUAL		0

#define VALIDCNT	3			// number of valid signals required to go manual
#define DT			10			// delta time for ticks, usec
#define TIMEOUT		200000UL	// timeout in microseconds

/************* GLOBAL VARIABLES **************/

static char mode=AUTO;			// Mode of operation, auto or manual
static int valid;				// RX signal valid counter
static unsigned long ontime;  	// measure length of signal on time
static unsigned long offtime; 	// measure length of signal off time

/*********** FUNCTION PROTOTYPES *************/

void init_timer(void);
void init_detector(void);
void pin(int pin, int value);
void led(int pin, int value);

/****************** CODE *********************/

int main() {
	/* setup pins for output */
	DDRB = (1<<LEDAUTO)|(1<<LEDMANUAL)|(1<<B);

	/* enable pull-up on MUX inputs */
	//PORTB = (1<<CH1RX)|(1<<CH2RX);

	/* Setup timer to keep track of timing of signal */
	init_timer();

	/* Setup pin interrupts for input signals */
	init_detector();

	/* Ready to receive interrupts, now */
	sei();

	while (1) {
		switch (mode) {
		case AUTO:
			// set mux
			pin(B, OFF);
			// set indicators
			led(LEDMANUAL, OFF);
			led(LEDAUTO, ON);
			break;
		case MANUAL:
			// set mux
			pin(B, ON);
			// set indicators
			led(LEDAUTO, OFF);
			led(LEDMANUAL, ON);
			break;
		}
		_delay_us(100);
	}
}



/**
 * Initialize signal detector
 */
void init_detector() {
	PCMSK |= (1<<CH1INT);	// Enable interrupt for PB1/PCINT1
	GIMSK |= (1<<PCIE);		// Enable pin change interrupts
}


/**
 * Interupt handler for pin change, detects and tracks RC signal
 */
ISR(PCINT0_vect) {
	// Check ontime, period on rising edge
	if ((PINB & (1<<CH1RX)) != 0) {
		// If signal period is around 20ms and on-period is ~1-2ms, we have a valid signal
		int p = ontime+offtime;
		if (p > 10000 && p < 50000 && ontime > 500 && ontime < 2500) {
			if (++valid > VALIDCNT) {
				valid = VALIDCNT+1;
				mode = MANUAL;
			}
		}
		ontime = 0;
		offtime = 0;
	}
}


/**
 * Initialize timer for tracking signal timing, timeout, etc.
 */
void init_timer() {
	TCCR0A = (1<<WGM01);					// CTC mode
	TCCR0B = (0<<CS02)|(1<<CS01)|(0<<CS00); // clk/8, 9.6MHz -> 1.2MHz
	OCR0A = 12; 							// 1.2MHz / 12 -> 100kHz, 10usec
	TIMSK0 = (1<<OCIE0A);					// Enable output compare A interrupt
}


/**
 * Timer interrupt handler, fires every ~10us and subtracts from timeout value
 */
ISR(TIM0_COMPA_vect) {
	if ((PINB & (1<<CH1RX)) == 0) {
		offtime += DT;  // track off time
		if (offtime > TIMEOUT) {
			valid = 0;
			mode = AUTO;
		}
	} else {
		ontime += DT;   // track on time
	}
}


void led(int pin, int value) {
	if (value) {
		DDRB |= (1<<pin);
		PORTB |= (1<<pin);
	} else {
		DDRB &= ~(1<<pin);
		PORTB &= ~(1<<pin);
	}
}

void pin(int pin, int value) {
	if (value) {
		PORTB |= (1<<pin);
	} else {
		PORTB &= ~(1<<pin);
	}
}


