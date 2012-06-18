#include "logging.h"
#include "SDHCFileSystem.h"
#include "SerialGraphicLCD.h"

extern Serial pc;
extern SerialGraphicLCD lcd;

SDFileSystem sd(p5, p6, p7, p8, "log"); // mosi, miso, sclk, cs
static FILE *logp;


void clearState( SystemState *s ) {
    s->millis = 0;
    s->current = s->voltage = 0.0;
    s->g[0] = s->g[1] = s->g[2] = 0;
    s->gTemp = 0;
    s->a[0] = s->a[1] = s->a[2] = 0;
    s->m[0] = s->m[1] = s->m[2] = 0;
    s->gHeading = s->cHeading = 0.0;
    //s->roll = s->pitch = s->yaw =0.0;
    s->gpsLatitude = s->gpsLongitude = s->gpsCourse = s->gpsHDOP = 0.0;
    s->lrEncDistance = s->rrEncDistance = 0.0;
    s->lrEncSpeed = s->rrEncSpeed = s->encHeading = 0.0;
    s->estHeading = s->estLatitude = s->estLongitude = 0.0;
    //s->estNorthing = s->estEasting = 
    s->estX = s->estY = 0.0;
    s->nextWaypoint = 0;
    s->bearing = s->distance = 0.0;
}

//void logData( SystemState s, void (*logString)(char *s) ) {
void logData( SystemState s ) {
    char buf[256];

    sprintf(buf, "%d,%.1f,%.1f,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%.2f,,,,,%.6f,%.6f,%.1f,%.1f,%.1f,%d,%.7f,%.7f,%.2f,%.2f,%.1f,%.1f,%.6f,%.6f,,,%.4f,%.4f,%d,%.1f,%.3f,%.5f,%.5f,%.3f,%.3f,%.3f,%.3f\n",
        s.millis,
        s.current, s.voltage,
        s.g[0], s.g[1], s.g[2],
        s.gTemp,
        s.a[0], s.a[1], s.a[2],
        s.m[0], s.m[1], s.m[2],
        s.gHeading, //s.cHeading,
        //s.roll, s.pitch, s.yaw,
        s.gpsLatitude, s.gpsLongitude, s.gpsCourse, s.gpsSpeed*0.44704, s.gpsHDOP, s.gpsSats, // convert gps speed to m/s
        s.lrEncDistance, s.rrEncDistance, s.lrEncSpeed, s.rrEncSpeed, s.encHeading,
        s.estHeading, s.estLatitude, s.estLongitude,
        // s.estNorthing, s.estEasting, 
        s.estX, s.estY,
        s.nextWaypoint, s.bearing, s.distance, s.gbias, s.errAngle,
        s.leftRanger, s.rightRanger, s.centerRanger,
        s.crossTrackErr
    );

    if (logp)
        fprintf(logp, buf);

    return;    
}


FILE *openlog(char *prefix)
{
    FILE *fp = 0;
    char myname[64];
    
    pc.printf("Opening file...\n");

    while (fp == 0) {
        if ((fp = fopen("/log/test.txt", "w")) == 0) {
            pc.printf("Waiting for filesystem to come online...");
            wait(0.200);
            lcd.pos(0,1);
            lcd.printf("%-16s", "Waiting for fs");
        }
    }    
    fclose(fp);

    for (int i = 0; i < 1000; i++) {
        sprintf(myname, "/log/%s%03d.csv", prefix, i);
        if ((fp = fopen(myname, "r")) == 0) {
            break;
        } else {
            fclose(fp);
        }
    }
    fp = fopen(myname, "w");
    if (fp == 0) {
        pc.printf("file write failed: %s\n", myname);
    } else {
    
        // TODO -- set error message, get rid of writing to terminal
        
        //status = true;
        pc.printf("opened %s for writing\n", myname);
        lcd.pos(0,1);
        lcd.printf("%-16s", myname);
    }
    
    return fp;
}


// Find the next unused filename of the form logger##.csv where # is 0-9
//
bool initLogfile() 
{    
    bool status = false;
    
    logp = openlog("log");
    
    if (logp != 0) {
        status = true;
        fprintf(logp, "s.millis, s.current, s.voltage, s.gx, s.gy, s.gz, s.gTemp, s.ax, s.ay, s.az, s.mx, s.my, s.mz, s.gHeading, s.cHeading, s.roll, s.pitch, s.yaw, s.gpsLatitude, s.gpsLongitude, s.gpsCourse, s.gpsSpeed, s.gpsHDOP, s.lrEncDistance, s.rrEncDistance, s.lrEncSpeed, s.rrEncSpeed, s.encHeading, s.estHeading, s.estLatitude, s.estLongitude, s.estNorthing, s.estEasting, s.estX, s.estY, s.nextWaypoint, s.bearing, s.distance, s.gbias, s.errAngle, s.leftRanger, s.rightRanger, s.centerRanger, s.crossTrackErr\n");
    }
    
    return status;
}

void closeLogfile(void)
{
    if (logp) fclose(logp);
}