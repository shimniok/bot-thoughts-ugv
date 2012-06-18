// For SiRF III

#include "GPS.h"

extern Serial pc;




GPS::GPS(PinName tx, PinName rx, int type):
    hdop(0.0),
    serial(tx, rx)
{
    setType(SIRF);
    setBaud(4800);
} 


void GPS::setType(int type)
{
    if (type == VENUS || type == MTK || type == SIRF) {
        _type = type;
    }
    
    return;
}

void GPS::setBaud(int baud)
{
    serial.baud(baud);
    
    return;
}

void GPS::setUpdateRate(int rate)
{
    char msg[10] = { 0xA0, 0xA1, 0x00, 0x03,
                    0x0E, rate&0xFF, 01,
                    0, 0x0D, 0x0A };
    for (int i=4; i < 7; i++) {
        msg[7] ^= msg[i];
    }
    switch (rate) {
    case 1 :
    case 2 :
    case 4 :
    case 5 :
    case 8 :
    case 10 :
    case 20 :
        for (int i=0; i < 10; i++)            
            serial.putc(msg[i]);
        break;
    default :
        break;
    }
}

void GPS::setNmeaMessages(bool gga, bool gsa, bool gsv, bool gll, bool rmc, bool vtg)
{
    if (_type == VENUS) {
        // VENUS Binary MsgID=0x08
        // GGA interval
        // GSA interval
        // GSV interval
        // GLL interval
        // RMC interval
        // VTG interval
        // ZDA interval -- hardcode off
        char msg[15] = { 0xA0, 0xA1, 0x00, 0x09, 
                         0x08, gga, gsa, gsv, gll, rmc, vtg, 0,
                         0, 0x0D, 0x0A };
        for (int i=4; i < 12; i++) {
            msg[12] ^= msg[i];
        }
        for (int i=0; i < 15; i++)
            serial.putc(msg[i]);
    }
}
    

void GPS::gsvMessage(bool enable)
{
    if (enable) {
        if (_type == MTK) {
            serial.printf("$PSRF103,03,00,01,01*26\r\n");     // Enable GSV
        } else if (_type == VENUS) {
        }
    } else {
        if (_type == MTK) {
            serial.printf("$PSRF103,03,00,00,01*27\r\n");     // Disable GSV
        } else if (_type == VENUS) {
            // ??
        }
    }

    return;
}

void GPS::gsaMessage(bool enable)
{
    if (enable) {
        if (_type == SIRF) {
            serial.printf("$PSRF103,02,00,01,01*27\r\n");     // Enable GSA
        } else if (_type == VENUS) {
            // ??
        }
    } else {
        if (_type == SIRF) {
            serial.printf("$PSRF103,02,00,00,01*26\r\n");     // Disable GSA
        } else if (_type == VENUS) {
            // ??
        }
    }
    
    return;
}


// Handle data from a GPS (there may be two GPS's so needed to put the code in one routine
//
void GPS::process(GeoPosition &here, char *date, char *time)
{
    double lat, lon;
    unsigned long age;
    
    nmea.reset_ready(); // reset the flags
    //pc.printf("%d GPS RMC are ready\n", millis);
    nmea.f_get_position(&lat, &lon, &age);
    nmea.crack_datetime(&year, &month, &day, &hour, &minute, &second, &hundredths, &age);

    sprintf(date, "%02d/%02d/%4d", month, day, year);
    sprintf(time, "%02d:%02d:%02d.%03d", hour, minute, second, hundredths);

    hdop = nmea.f_hdop();

    // Bearing and distance to waypoint
    here.set(lat, lon);

    //pc.printf("HDOP: %.1f gyro: %d\n", gps1_hdop, gyro);

    return;
}


void GPS::init()
{    
    // Initialize the GPS comm and handler
    //serial.baud(57600); // LOCOSYS LS20031
    //DigitalIn myRx(_rx);
    //Timer tm;


/*    
    //pc.printf("gps.init()\n\n");
    int rate = 99999999;
    for (int i=0; i < 10; i++) {    
        //pc.printf("rate: %d\n", rate);
        while( myRx ); // wait for low
        tm.reset();
        tm.start();
        while ( !myRx ); // wait for high
        if (tm.read_us() < rate) rate = tm.read_us();
    }
*/
    if (_type == MTK) {
        gsvMessage(false);      // Disable GSV
        gsaMessage(false);      // Disable GSA
    } else if (_type == VENUS) {
        setNmeaMessages(true, true, false, false, true, false);
        setUpdateRate(10);
    }
    
    // Synchronize with GPS
    nmea.reset_ready();
}