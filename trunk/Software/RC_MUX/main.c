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

#define	TRUE		1
#define FALSE		0

#define MCUenable	PB3
#define RCenable	PB4
#define AUTO		1
#define MANUAL		0

#define VALIDCNT	3				// number of valid signals required to go manual
#define DT			100				// delta time for ticks, usec
#define TIMEOUT		60000L			// timeout in microseconds

/************* GLOBAL VARIABLES **************/

volatile uint8_t mode=AUTO;			// Mode of operation, auto or manual

volatile uint8_t inactive1=VALIDCNT;// RX signal active pulse counter
volatile long ontime1;  			// measure length of signal on time
volatile long offtime1; 			// measure length of signal off time

volatile uint8_t inactive3=VALIDCNT;// RX signal valid counter
volatile long ontime3;  			// measure length of signal on time
volatile long offtime3; 			// measure length of signal off time

/****************** CODE *********************/

int main() {
	/* setup pins for output */
	DDRB = (1<<MCUenable)|(1<<RCenable);

	/* Setup timer to keep track of timing of signal */
	TCCR0A = (1<<WGM01);					// CTC mode
	TCCR0B = (0<<CS02)|(1<<CS01)|(0<<CS00); // clk/8, 9.6MHz -> 1.2MHz
	OCR0A = 111; 							// 1.2MHz / 120 -> 10kHz, 100usec
	TIMSK0 = (1<<OCIE0A);					// Enable output compare A interrupt

	/* Setup pin interrupts for input signals */
	PCMSK |= (1<<CH1INT)|(1<<CH3INT);	// Enable interrupt for PB1/PCINT1
	GIMSK |= (1<<PCIE);					// Enable pin change interrupts

	/* Ready to receive interrupts, now */
	sei();

	while (1);
}


/**
 * Interupt handler for pin change, detects and tracks RC signal
 */
ISR(PCINT0_vect) {
	long p;
	// Check ontime, period on rising edge
	if ((PINB & (1<<CH1RX)) != 0) {
		// If signal period is around 20ms and on-period is ~1-2ms, we have a valid signal
		p = ontime1+offtime1;
		if (inactive1 && p > MINPERIOD && p < MAXPERIOD && ontime1 > MINONTIME && ontime1 < MAXONTIME) {
			--inactive1;
		}
		ontime1 = offtime1 = 0;
	}

	if ((PINB & (1<<CH3RX)) != 0) {
		p = ontime3+offtime3;
		if (inactive3 && p > MINPERIOD && p < MAXPERIOD && ontime3 > MINONTIME && ontime3 < MAXONTIME) {
			--inactive3;
		}
		ontime3 = offtime3 = 0;
	}

	if (!inactive3) {
		if (ontime3 > 1500) {
			PORTB = (1<<RCenable);
		} else {
			PORTB = (1<<MCUenable);
		}
	} else if (!inactive1) {
		PORTB = (1<<RCenable);
	}

}


/**
 * Timer interrupt handler, fires every ~10us and subtracts from timeout value
 */
ISR(TIM0_COMPA_vect) {
	if ((PINB & (1<<CH1RX)) == 0) {
		offtime1 += DT;  // track off time
		if (offtime1 > TIMEOUT) {
			inactive1 = VALIDCNT;
			ontime1 = offtime1 = 0;
		}
	} else {
		ontime1 += DT;   // track on time
	}

	if ((PINB & (1<<CH3RX)) == 0) {
		offtime3 += DT;  // track off time
		if (offtime3 > TIMEOUT) {
			inactive3 = VALIDCNT;
			ontime3 = offtime1 = 0;
		}
	} else {
		ontime3 += DT;   // track on time
	}

	if (inactive1 && inactive3) {
		PORTB = (1<<MCUenable);
	}
}

