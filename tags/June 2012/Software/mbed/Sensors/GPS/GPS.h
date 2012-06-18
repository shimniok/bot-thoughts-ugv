// For SiRF III

#ifndef __GPS_H
#define __GPS_H

#include "mbed.h"
#include "TinyGPS.h"
#include "GeoPosition.h"

#define SIRF 1
#define MTK 2
#define VENUS 3

class GPS {
public:
    GPS(PinName tx, PinName rx, int type);
    void setType(int type);
    void setBaud(int baud);
    void setUpdateRate(int rate);
    void setNmeaMessages(bool gga, bool gsa, bool gsv, bool gll, bool rmc, bool vtg);
    void gsvMessage(bool enable);
    void gsaMessage(bool enable);
    void process(GeoPosition &here, char *date, char *time);
    void init(void);
    void gpsStartCapture(void);
    void gpsStopCapture(void);
    void recv(void);
    int year;           // gps date variables
    byte month;
    byte day;
    byte hour;
    byte minute;
    byte second;
    byte hundredths;
    float hdop;         // gps horizontal dilution of precision
    Serial serial;
    TinyGPS nmea;
private:
    PinName _rx;
    int _type;       // type of GPS device
};

#endif