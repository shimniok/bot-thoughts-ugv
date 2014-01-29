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

#define CH1RX		PB2
#define CH1INT		PCINT2
#define CH3RX		PB0
#define CH3INT		PCINT0

#define MINPERIOD	5000L
#define MAXPERIOD	50000L
#define MINONTIME	300L
#define MAXONTIME	3000L

#define MCUenable	PB4
#define RCenable	PB3

#define VALIDCNT	3				// number of valid signals required to go manual
#define DT			100				// delta time for ticks, usec
#define TIMEOUT		60000L			// timeout in microseconds

/************* GLOBAL VARIABLES **************/

uint8_t inactive1=VALIDCNT;			// RX signal active pulse counter
long ontime1;  						// measure length of signal on time
long offtime1; 						// measure length of signal off time
uint8_t history1;					// history of pin states

uint8_t inactive3=VALIDCNT;			// RX signal active pulse counter
long ontime3;  						// measure length of signal on time
long offtime3; 						// measure length of signal off time
uint8_t history3;					// history of pin states

/****************** CODE *********************/

int main() {
	// setup pins for output
	// This is in the main routine instead of a function to save a few bytes of flash
	DDRB = (1<<MCUenable)|(1<<RCenable);

	// Setup timer to keep track of timing of signal
	// This is in the main routine instead of a function to save a few bytes of flash
	TCCR0A = (1<<WGM01);					// CTC mode
	TCCR0B = (0<<CS02)|(1<<CS01)|(0<<CS00); // clk/8, 9.6MHz -> 1.2MHz
	OCR0A = 111; 							// 1.2MHz / 120 -> 10kHz, 100usec
	TIMSK0 = (1<<OCIE0A);					// Enable output compare A interrupt

	/* Ready to receive interrupts, now */
	sei();

	while (1);
}


/**
 * Timer interrupt handler, fires periodically, counts on time, off time, and manages signal timeout
 */
ISR(TIM0_COMPA_vect) {
	// Count on time and off time for CH1
	history1 <<= 1;
	if ((PINB & (1<<CH1RX)) == 0) {
		offtime1 += DT;  // track off time
		// Does the signal off time exceeds the timeout?
		if (offtime1 > TIMEOUT) {
			inactive1 = VALIDCNT;
		}
	} else {
		ontime1 += DT;   // track on time
		history1 |= 1;
	}

	long p;
	// Positive edge
	if (history1 == 0b00000001) {
		p = ontime1+offtime1;
		if (inactive1 && p > MINPERIOD && p < MAXPERIOD && ontime1 > MINONTIME && ontime1 < MAXONTIME) {
			// Enable RC if CH1 active but CH3 inactive
			if ((--inactive1 == 0) && inactive3) {
				PORTB = (1<<RCenable);
			}
		}
		ontime1 = 0;
	}
	// Negative edge
	if (history1 == 0b11111110) {
		offtime1 = 0;
	}

	// Count on time and off time for CH3
	history3 <<= 1;
	if ((PINB & (1<<CH3RX)) == 0) {
		offtime3 += DT;  // track off time
		// Does the signal off time exceeds the timeout?
		if (offtime3 > TIMEOUT) {
			inactive3 = VALIDCNT;
		}
	} else {
		ontime3 += DT;   // track on time
		history3 |= 1;
	}

	// Positive edge
	if (history3 == 0b00000001) {
		p = ontime3+offtime3;
		if (inactive3 && p > MINPERIOD && p < MAXPERIOD && ontime3 > MINONTIME && ontime3 < MAXONTIME) {
			--inactive3; // using a single variable to conserve program memory
		}
		// Enable RC if CH3 active and CH3 on time > 1.5ms, else disable RC
		if (!inactive3) {
			if (ontime3 > 1500) {
				PORTB = (1<<RCenable);
			} else {
				PORTB = (1<<MCUenable);
			}
		}
		ontime3 = offtime3 = 0;
	}
	// Negative edge
	if (history3 == 0b11111110) {
		offtime3 = 0;
	}

	// If both CH1 and CH3 have timed out, disable RC
	if (inactive1 && inactive3) {
		PORTB = (1<<MCUenable);
	}
}


