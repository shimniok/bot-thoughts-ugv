#include "mbed.h"
#include "Sirf3.h"

// TODO: parameterize LED

Sirf3::Sirf3(PinName tx, PinName rx):
    serial(tx, rx)
{
    setBaud(4800);
    enable();
}

void Sirf3::init(void)
{
    disableVerbose();
}

void Sirf3::setBaud(int baud)
{
    serial.baud(baud);
}

Serial *Sirf3::getSerial(void)
{
    return &serial;
}

void Sirf3::enable(void)
{
    reset_available();
    serial.attach(this, &Sirf3::recv_handler, Serial::RxIrq);
}

void Sirf3::disable(void)
{
    serial.attach(NULL, Serial::RxIrq);
}

/**
 * Enable verbose messages for debugging
 */
void Sirf3::enableVerbose(void)
{
    gsaMessage(true);
    gsvMessage(true);
}

/**
 * Disable verbose messages for debugging
 */
void Sirf3::disableVerbose(void)
{
    gsaMessage(false);
    gsvMessage(false);
}

double Sirf3::latitude(void)
{
    double latitude, longitude;
    unsigned long age;
    nmea.f_get_position(&latitude, &longitude, &age);
    return latitude;
}

double Sirf3::longitude(void)
{
    double latitude, longitude;
    unsigned long age;
    nmea.f_get_position(&latitude, &longitude, &age);
    return longitude;
}

float Sirf3::hdop(void)
{
    return nmea.f_hdop();
}

int Sirf3::sat_count(void)
{
    return nmea.sat_count();
}

float Sirf3::speed_mps(void)
{
    return nmea.f_speed_mps();
}

float Sirf3::heading_deg(void)
{
    return nmea.f_course();
}

bool Sirf3::available(void)
{
    return nmea.ready();
}

void Sirf3::reset_available(void)
{
    nmea.reset_ready();
}

void Sirf3::recv_handler(void)
{
    while (serial.readable()) {
        nmea.encode(serial.getc());
    }
}

void Sirf3::gsaMessage(bool enable)
{
    if (enable) {
        serial.printf("$PSRF103,02,00,01,01*27\r\n");     // Enable GSA
    } else {
        serial.printf("$PSRF103,02,00,00,01*26\r\n");     // Disable GSA
    }

    return;
}

void Sirf3::gsvMessage(bool enable)
{
    if (enable) {
        serial.printf("$PSRF103,03,00,01,01*26\r\n");     // Enable GSV
    } else {
        serial.printf("$PSRF103,03,00,00,01*27\r\n");     // Disable GSV
    }

    return;
}

