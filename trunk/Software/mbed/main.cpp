/** Code for "Data Bus" UGV entry for Sparkfun AVC 2011
 *  http://bot-thoughts.com/
 */

///////////////////////////////////////////////////////////////////////////////////////////////////////
// INCLUDES
///////////////////////////////////////////////////////////////////////////////////////////////////////

#include "mbed.h"
#include "TinyGPS.h"
#include "SDFileSystem.h"
#include "ADC128S.h"
#include "PinDetect.h"
#include "LSM303DLH.h"
#include "Servo.h"
#include "IncrementalEncoder.h"
#include "Steering.h"
#include "Schedule.h"
#include "GeoPosition.h"
#include "TinyCHR6dm.h"
#include "SimpleFilter.h"

///////////////////////////////////////////////////////////////////////////////////////////////////////
// DEFINES
///////////////////////////////////////////////////////////////////////////////////////////////////////

#define WHERE(x) debug->printf("%d\n", __LINE__);

#define clamp360(x) \
                while ((x) >= 360.0) (x) -= 360.0; \
                while ((x) < 0) (x) += 360.0;
#define clamp180(x) ((x) - floor((x)/360.0) * 360.0 - 180.0);

#define absf(x) (x *= (x < 0.0) ? -1 : 1)

#define UPDATE_PERIOD 50                // update period in ms
#define GYRO_UPDATE   UPDATE_PERIOD/5   // gyro update period in ms

#define GPS_MIN_SPEED   2.0             // speed below which we won't trust GPS course
#define GPS_MAX_HDOP    2.0             // HDOP above which we won't trust GPS course/position

// Error correction gains
#define COMPASS_GAIN    0.25
#define YAW_GAIN        0.25

// Driver configuration parameters
#define SONARLEFT_CHAN   0
#define SONARRIGHT_CHAN  1
#define IRLEFT_CHAN      2
#define IRRIGHT_CHAN     3  
#define TEMP_CHAN        4
#define GYRO_CHAN        5

// Waypoint queue parameters
#define MAXWPT    10
#define ENDWPT    9999.0

// Chassis specific parameters
#define WHEEL_CIRC 0.321537 // m; calibrated with 4 12.236m runs. Measured 13.125" or 0.333375 wheel dia
#define WHEELBASE  0.290
#define TRACK      0.280

///////////////////////////////////////////////////////////////////////////////////////////////////////
// GLOBAL OBJECTS
///////////////////////////////////////////////////////////////////////////////////////////////////////

// OUTPUT
DigitalOut confStatus(LED1);            // Config file status LED
DigitalOut logStatus(LED2);             // Log file status LED
DigitalOut gps2Status(LED3);            // GPS fix status LED
DigitalOut ahrsStatus(LED4);            // GPS fix status LED
DigitalOut sonarStart(p18);             // Sends signal to start sonar array pings
DigitalOut flasher(p10);                // Autonomous mode warning flasher
DigitalOut steerServo(p21);             // After shutdown, pass pulses through to servo
//Serial lcd(p9, NC);                     // LCD module, TX only

// INPUT
InterruptIn receiver(p23);              // RC Receiver steering channel
DigitalOut buttonPower(p19);            // Power the button(s)
//PinDetect upButton(p17);
PinDetect selectButton(p20);            // Input selectButton
//PinDetect downButton(p18);

// VEHICLE
Servo steering(p21);                    // Steering Servo
Servo throttle(p22);                    // ESC
Schedule go;                            // Throttle profile, dead stop to full speed
Schedule stop;                          // Throttle profile, full speed to dead stop
Steering steerCalc(TRACK, WHEELBASE);   // steering calculator
int maxSpeed=520;                       // Servo setting for max speed

// SENSORS
//HMC6352 compass(p28, p27);              // Driver for compass
LSM303DLH compass3d(p28, p27);          // Driver for compass
//I2C cam(p28, p27);                      // CMUcam I2C bridge
//ADC128S adc(p5, p6, p7, p15);         // ADC128S102 8ch ADC driver; mosi, miso, sclk, cs
ADC128S adc(p11, p12, p13, p14);        // ADC128S102 8ch ADC driver; mosi, miso, sclk, cs
IncrementalEncoder left(p30);           // Left wheel encoder
IncrementalEncoder right(p29);          // Right wheel encoder
//Serial gps1(p26, p25);                // GPS1, Locosys LS20031
Serial ahrs(p26, p25);                  // CHR-6dm AHRS
Serial gps2(p9, p10);                   // GPS2, iGPS-500
Serial *dev;                            // For use with bridge
//TinyGPS gps1Parse;                    // GPS NMEA parser
TinyCHR6dm ahrsParser;                   // CHR-6dm AHRS parser
TinyGPS gps2Parse;                      // GPS NMEA parser

// COMM
Serial pc(USBTX, USBRX);                // PC usb communications
Serial *debug = &pc;

// MISC
Timer timer;                            // For main loop scheduling
SDFileSystem sd(p5, p6, p7, p8, "log"); // mosi, miso, sclk, cs
LocalFileSystem local("etc");         // Create the local filesystem under the name "local"

///////////////////////////////////////////////////////////////////////////////////////////////////////
// GLOBAL VARIABLES
///////////////////////////////////////////////////////////////////////////////////////////////////////

// GPS Variables
double gps1_lat;            // latitude
double gps1_lon;            // longitude
double gps2_lat;            // latitude
double gps2_lon;            // longitude
unsigned long age = 0;      // gps fix age
float gps1_hdop = 0.0;      // gps horizontal dilution of precision
float gps2_hdop = 0.0;      // gps horizontal dilution of precision
int year;                   // gps date variables
byte month;
byte day;
byte hour;
byte minute;
byte second;
byte hundredths;

// schedule for LED warning flasher
Schedule blink;

// Useful globals
float declination;              // compass declination for local correction
bool goGoGo = false;            // signal to start moving
bool done = false;              // signal that we're done navigating

// Gyro Variables
float gyro = 0;                 // gyro reading
float gyroBias = 2027.0;        // gyro bias in raw 12-bit ADC value
unsigned int temp = 0;          // gyro temp reading
float gyroSens = 4.89;          // in LSB/deg/sec since we're using ratiometric ADC and gyro
float gyroSum[UPDATE_PERIOD/GYRO_UPDATE];    // for summijng/averaging gyro between DR / compass updates
int gyroCount = 0;              // counter for gyroSum array

// Navigation Variables
GeoPosition wpt[MAXWPT];    // course waypoints
unsigned int wptCount = 0;  // number of waypoints configured
int wptCurrent = 0;         // current waypoint   
GeoPosition here1;          // current gps position
GeoPosition here2;          // current gps position
GeoPosition dr_here;        // current dead reckoning position
GeoPosition dr_here_last;   // DR position at last GPS packet

// Misc
FILE *fp = 0;
bool buttonPressed = false;
bool buttonReleased = false;

///////////////////////////////////////////////////////////////////////////////////////////////////////
// FUNCTION DEFINITIONS
///////////////////////////////////////////////////////////////////////////////////////////////////////

FILE *initLogfile(void);
void initButtons(void);
void initCompass(void);
void initGPS(void);
void initAHRS(void);
void initFlasher(void);
void initSteering(void);
void initThrottle(void);
void initDR(void);
void loadConfig(float &interceptDist, float &declination, float &compassGain, float &yawGain);
void doGPS(TinyGPS &parse, GeoPosition &here, DigitalOut status, char *date, char *time);
void autonomousMode(void);
void findGPSBias(double *brg, double *dist, int n, GeoPosition place);
void idleMode(void);
void compassCalibrate(void);
void servoCalibrate(void);
void serialBridge(Serial &gps);
void instrumentCheck(void);
float compassHeading(void);
float gyroRate(unsigned int adc);
float sonarDistance(unsigned int adc);
float irDistance(unsigned int adc);

// If we don't close the log file, when we restart, all the written data
// will be lost.  So we have to use a button to force mbed to close the
// file and preserve the data.
//
void assertButton() {
    buttonPressed = true;
    buttonReleased = false;
}

void deassertButton() {
    buttonPressed = false;
    buttonReleased = true;
}

// Use interrupt handler to receive AHRS serial comm and parse
// it using TinyCHR6dm library
//
void recv1() {
    while (ahrs.readable())
        ahrsParser.parse(ahrs.getc());
}

void recv2() {
    while (gps2.readable())
        gps2Parse.encode(gps2.getc());
}

char getInput(const char *prompt)
{
    char c;
    
    if (prompt) pc.printf("%s ", prompt);
    while (!pc.readable())
        wait(0.001);
    c = pc.getc();
    pc.printf("%c\n", c);

    return c;
}

int main()
{
    // Send data back to the PC
    pc.baud(115200);

    //receiver.rise(&killSwitch);                         // Detects remote kill switch / rc takeover
    initButtons();                                      // Initialize input buttons
    initCompass();
    initSteering();
    initThrottle();
    // initFlasher();                                   // Initialize autonomous mode flasher
    initGPS();
        
    // Insert menu system here w/ timeout
    bool autoBoot=true;
/*
    pc.printf("Booting to autonomous mode in 10 seconds, any key to abort.\n ");
    for (int i=1; i > 0; i--) {
        pc.printf("%d...", i);
        if (pc.readable()) {
            autoBoot = false;
            while (pc.readable()) pc.getc();        // clear buffer
            break;
        }
        wait(1.0);
    }
    pc.printf("\n");
*/
    
    char cmd;
    
    while (1) {

        if (autoBoot) {
            autoBoot = false;
            cmd = 'a';
        } else {
            pc.printf("==============\nData Bus Menu\n==============\n");
            pc.printf("(a)utonomous mode\n");
            pc.printf("(s)erial bridge\n  (1) Port 1 (2) Port 2 (GPS)\n");
            pc.printf("(c)ompass calibration\n");
            pc.printf("(i)nstrument check\n");
            //pc.printf("(s)ervo calibration\n");
            cmd = getInput("\nSelect from the above:");
        }
        
        switch (cmd) {
            case 'a' :
                autonomousMode();
                break;
            case 's' :
                // which GPS
                cmd = getInput("GPS2 (2) or AHRS(1)?");
                switch (cmd) {
                    case '1' :
                        serialBridge(ahrs);
                        break;
                    case '2' :
                        serialBridge(gps2);
                        break;
                    default :
                        break;
                }
                break;
            case 'i' :
                instrumentCheck();
                break;
            case 'c' :
                compassCalibrate();
                break;
            default :
                break;
        }         
    }

}

// Handle data from a GPS (there may be two GPS's so needed to put the code in one routine
//
void doGPS(TinyGPS &parse, GeoPosition &here, DigitalOut status, char *date, char *time)
{
    double lat, lon;
    unsigned long age;
    
    parse.reset_ready(); // reset the flags
    //pc.printf("%d GPS RMC are ready\n", millis);
    parse.f_get_position(&lat, &lon, &age);
    parse.crack_datetime(&year, &month, &day, &hour, &minute, &second, &hundredths, &age);

    sprintf(date, "%02d/%02d/%4d", month, day, year);
    sprintf(time, "%02d:%02d:%02d.%03d", hour, minute, second, hundredths);

    float hdop = parse.f_hdop();

    // Want to blink the LED when GPS update arrives
    // must toggle opposite
    //status = (hdop > 0.0 && hdop < 10.0) ? 0 : 1;

    // Bearing and distance to waypoint
    here.set(lat, lon);

    //pc.printf("HDOP: %.1f gyro: %d\n", gps1_hdop, gyro);

    return;
}



// convert character to an int
//
int ctoi(char c)
{
  int i=-1;
  
  if (c >= '0' && c <= '9') {
    i = c - '0';
  }

  //printf("char: %c  int %d\n", c, i); 
 
  return i;
}


// convert string to floating point
//
double cvstof(char *s)
{
  double f=0.0;
  double mult = 0.1;
  bool neg = false;
  //char dec = 1;
  
  // leading spaces
  while (*s == ' ' || *s == '\t') {
    s++;
    if (*s == 0) break;
  }

  // What about negative numbers?
  if (*s == '-') {
    neg = true;
    s++;
  }

  // before the decimal
  //
  while (*s != 0) {
    if (*s == '.') {
      s++;
      break;
    }
    f = (f * 10.0) + (double) ctoi(*s);
    s++;
  }
  // after the decimal
  while (*s != 0 && *s >= '0' && *s <= '9') {
    f += (double) ctoi(*s) * mult;
    mult /= 10;
    s++;
  }
  
  // if we were negative...
  if (neg) f = -f;
  
  return f;
}

// copy t to s until delimiter is reached
// return location of delimiter+1 in t
char *split(char *s, char *t, int max, char delim)
{
  int i = 0;
  
  if (s == 0 || t == 0)
    return 0;

  while (*t != 0 && *t != delim && i < max) {
    *s++ = *t++;
    i++;
  }
  *s = 0;
    
  return t+1;
}

#define MAXBUF 64
// load configuration from filesystem
void loadConfig(float &interceptDist, float &declination, float &compassGain, float &yawGain)
{
//    FILE *fp;
    char buf[MAXBUF];   // buffer to read in data
    char tmp[MAXBUF];   // temp buffer
    char *p;
    double lat, lon;
    bool declFound = false;
    
    // Just to be safe let's wait
    //wait(2.0);

    pc.printf("opening config file...\n");
    
    fp = fopen("/etc/config.txt", "r");
    if (fp == 0) {
        pc.printf("Could not open config.txt\n");
    } else {
        wptCount = 0;
        declination = 0.0;
        while (!feof(fp)) {
            fgets(buf, MAXBUF-1, fp);
            p = split(tmp, buf, MAXBUF, ',');           // split off the first field
            switch (tmp[0]) {
                case 'W' :                              // Waypoint
                    p = split(tmp, p, MAXBUF, ',');     // split off the latitude to tmp
                    lat = cvstof(tmp);
                    p = split(tmp, p, MAXBUF, ',');     // split off the longitude to tmp
                    lon = cvstof(tmp);
                    if (wptCount < MAXWPT) {
                        wpt[wptCount].set(lat, lon);
                        wptCount++;
                    }
                    break;
                case 'G' :                              // Gyro Bias
                    p = split(tmp, p, MAXBUF, ',');     // split off the declination to tmp
                    gyroBias = (float) cvstof(tmp);
                    break;
                case 'D' :                              // Compass Declination
                    p = split(tmp, p, MAXBUF, ',');     // split off the declination to tmp
                    declination = (float) cvstof(tmp);
                    declFound = true;
                    break;
                case 'I' :                              // Intercept distance
                    p = split(tmp, p, MAXBUF, ',');     // split off the number to tmp
                    interceptDist = (float) cvstof(tmp);
                    break;
                case 'S' :                              // Speed maximum
                    p = split(tmp, p, MAXBUF, ',');     // split off the number to tmp
                    maxSpeed = atoi(tmp);
                    //pc.printf("tmp:%s maxSpeed:%d\n", tmp, maxSpeed);
                    break;
                case 'E' :
                    p = split(tmp, p, MAXBUF, ',');     // split off the number to tmp
                    compassGain = (float) cvstof(tmp);
                    p = split(tmp, p, MAXBUF, ',');     // split off the number to tmp
                    yawGain = (float) cvstof(tmp);
                default :
                    break;
            } // switch
        } // while

        // Did we get the values we were looking for?
        if (wptCount > 0 && declFound) {
            confStatus = 1;
        }
        
    } // if fp
    
    if (fp != 0)
        fclose(fp);

    pc.printf("Intercept Dist: %.1f\n", interceptDist);
    pc.printf("Declination: %.1f\n", declination);
    pc.printf("MaxSpeed: %d\n", maxSpeed);
    pc.printf("CompassGain; %.3f YawGain: %.3f\n", compassGain, yawGain);
    for (int w = 0; w < MAXWPT && w < wptCount; w++) {
        pc.printf("Waypoint #%d lat: %.6f lon: %.6f\n", w, wpt[w].latitude(), wpt[w].longitude());
    }

}


///////////////////////////////////////////////////////////////////////////////////////////////////////
// INITIALIZATION ROUTINES
///////////////////////////////////////////////////////////////////////////////////////////////////////

// Find the next unused filename of the form logger##.csv where # is 0-9
//
FILE *initLogfile() 
{    
    FILE *fp = 0;
    char myname[64];
    
    pc.printf("Opening log file...\n");

    while (fp == 0) {
        if ((fp = fopen("/log/test.txt", "r")) == 0) {
            pc.printf("Waiting for filesystem to come online...");
            wait(0.200);
        }
    }    
    fclose(fp);

    for (int i = 0; i < 1000; i++) {
        sprintf(myname, "/log/log%04d.csv", i);
        //pc.printf("Try file: <%s>\n", myname);    
        if ((fp = fopen(myname, "r")) == 0) {
            //pc.printf("File not found: <%s>\n", myname);
            break;
        } else {
            //pc.printf("File exists: <%s>\n", myname);
            fclose(fp);
        }
    }    
    
    fp = fopen(myname, "w");
    if (fp == 0) {
        pc.printf("file write failed: %s\n", myname);
    } else {
        //status = true;
        pc.printf("opened %s for writing\n", myname);
        fprintf(fp, "Millis, Gyro, GyroHdg, CompassHeading, Latitude, Longitude, Age, Date, Time, Altitude, Course, Speed, HDOP, Bearing, Distance, Left Enc, Right Enc, Gyro Temp, OdoHdg\n");
        //fclose(fp);
    }
    
    return fp;
}


void initButtons()
{
    // Set up button (plugs into two GPIOs, active low
    buttonPower = 0;
    selectButton.mode(PullUp);
    selectButton.setSamplesTillAssert(20);
    selectButton.setAssertValue(0); // active low logic
    selectButton.setSampleFrequency(20); // 20us
    selectButton.attach_asserted( &assertButton );
    selectButton.attach_deasserted( &deassertButton );
}

void initCompass()
{
    // Initialize compass; continuous mode, periodic set/reset, 20Hz measurement rate.
    //compass.setOpMode(HMC6352_CONTINUOUS, 1, 20);
    
    // Set calibration parameters for this particular LSM303DLH
    //compass3d.setOffset(29.50, -0.50, 4.00);
    //compass3d.setScale(1.00, 1.03, 1.21);
    compass3d.setOffset(44.50, 5.00, -0.50);    // Apr 11 testing
    compass3d.setScale(1.00, 1.04, 1.29);       // Apr 11 testing
    
    //compass3d._debug = &pc;
}


void initGPS()
{    
    // Initialize the GPS comm and handler
    //gps1.baud(57600); // LOCOSYS LS20031

    // Set LCD baud rate ; has to be 4800
    // because we share with 4800 bps GPS\
    // send chr(124) and CTRL-L
    //gps2.baud(9600);
    //gps2.printf("Data Bus");
    //gps2.printf("%c%c", 124, 12);
   
    gps2.baud(4800); // Pharos iGPS-500

    // Synchronize with GPS
    //gps1Parse.reset_ready();
    gps2Parse.reset_ready();
}

void initAHRS()
{
    char data[MAX_BYTES];
    int status;
    int ok = 0; // counts number of command_complete messages
    int c = 10; // timeout for status

    ahrs.baud(115200);
    ahrs.attach(recv1, Serial::RxIrq);
    wait(0.5);
    
    // Configure AHRS to use only acceleromters and gyro, no magnetometer
    data[0] = Accel_EN;
    ahrsParser.send_packet(&ahrs, SET_EKF_CONFIG, 1, data);
    c = 10;
    while (!ahrsParser.statusReady() && c-- > 0) 
        wait(0.1);
    status = ahrsParser.status();
    if (status == PT_COMMAND_COMPLETE) ok++;
    pc.printf("SET_EKF_CONFIG: %02x %s\n", status, ahrsParser.statusString(status));
    
    ahrsParser.send_packet(&ahrs, ZERO_RATE_GYROS, 0, 0);
    c = 10;
    while (!ahrsParser.statusReady() && c-- > 0) 
        wait(0.1);
    status = ahrsParser.status();
    if (status == PT_COMMAND_COMPLETE) ok++;
    pc.printf("ZERO_RATE_GYROS: %02x %s\n", status, ahrsParser.statusString(status));

    data[0] = 0; // 20Hz
    ahrsParser.send_packet(&ahrs, SET_BROADCAST_MODE, 1, data);
    c = 10;
    while (!ahrsParser.statusReady() && c-- > 0) 
        wait(0.1);
    status = ahrsParser.status();
    if (status == PT_COMMAND_COMPLETE) ok++;
    pc.printf("SET_BROADCAST_MODE: %02x %s\n", status, ahrsParser.statusString(status));
    
    ahrsParser.send_packet(&ahrs, EKF_RESET, 0, 0);
    c = 10;
    while (!ahrsParser.statusReady() && c-- > 0)
        wait(0.1);
    status = ahrsParser.status();
    if (status == PT_COMMAND_COMPLETE) ok++;
    pc.printf("EKF_RESET: %02x %s\n", status, ahrsParser.statusString(status));
    //ahrs.printf("%s", ahrsParser.send_packet()) // <--mag calibration here//

    if (ok == 4) ahrsStatus = 1; // turn on status LED

    ahrsParser.resetReady();
}

   
void initDR()
{
    dr_here.set(wpt[0]);                                // Initialize Dead Reckoning to starting waypoint
    dr_here_last.set(wpt[0]);
}

    
void initFlasher()
{ 
    // Set up flasher schedule; 3 flashes every 80ms
    // for 80ms total, with a 9x80ms period
    blink.max(9);
    blink.scale(80);
    blink.mode(Schedule::repeat);
    blink.set(0, 1);  blink.set(2, 1);  blink.set(4, 1);
}


void initSteering()
{
    // Setup steering servo
    steering = 0.5;
    steering.calibrate(0.005, 45.0); 
}


void initThrottle()
{
    throttle = 0.5;
    throttle.calibrate(0.0005, 45.0); 
}


///////////////////////////////////////////////////////////////////////////////////////////////////////
// OPERATIONAL MODE FUNCTIONS
///////////////////////////////////////////////////////////////////////////////////////////////////////


void autonomousMode()
{
    // Navigation
    float interceptDist = 1.5;      // Course correction intercept distance ; GPS_MAX_HDOP calculates to 20* SA

    // Compass Variables
    float compassHdg = 0.0;         // compass heading
    float compassHdg_last = -999;   // heading at last GPS packet
    float compassGain = COMPASS_GAIN;

    // AHRS Variables
    float yaw = 0.0;                // course
    float yawHdg = -1.0;            // heading calculated from AHRS
    float yawRate = 0.0;            // calculated rate of change in yaw
    float initialHdg = -999;        // initial heading (course)
    float yawGain = YAW_GAIN;
    
    // Variables we calculate
    double bearing = 0.0;           // bearing to next waypoint
    double distance = 0.0;          // distance to next waypoint
    float heading = 0.0;            // estimated heading
    float relativeBrg = 0.0;        // relative bearing to next waypoint
    double gps2_bearing = 0.0;      // bearing, gps2
    double gps2_distance = 0.0;     // distance, gps2
    float gps2_heading = 0.0;       // current heading, gps2
    double dr_bearing = 0.0;        // bearing, dead reckoning
    double dr_distance = 0.0;       // distance, dead reckoning
    float dr_heading = 0.0;         // dead reckoning heading
    float odo_heading = 0.0;        // heading calc from odometry
    double err_bearing = 0.0;       // bearing between dr and gps    
    double err_distance = 0.0;      // distance between dr and gps  
    float err_yaw = 0.0;            // error in ahrs yaw versus gps heading.
    float err_compass = 0.0;        // error in compass versus gps heading
    double gps2_off_dist = 0.0;     // distance from gps fix to starting point
    double gps2_off_brg = 0.0;      // bearing from gps fix to starting point
    double encDistance = 0.0;       // encoder average distance recorded
    double encSpeed = 0.0;          // encoder calculated speed

    goGoGo = false;

    loadConfig(interceptDist, declination, compassGain, yawGain);   // Load the waypoints, declination, and other config stuff
    steerCalc.setIntercept(interceptDist);              // Setup steering calculator based on intercept distance

    go.set(UPDATE_PERIOD, 20, 650, maxSpeed, Schedule::hold);      // Set throttle profile
    //stop.set(UPDATE_PERIOD, 10, 500, 400, Schedule::hold);         // Set brake profile
    // TODO: Parameterize max brake
    // obstacle: brake, speed up
    // turn: brake or slowdown, speed up again
    // brake speed up
    
    initAHRS();    
    
    wptCurrent = 0;
    initDR();                                           // initalize dead reckoning
    wptCurrent++;                                       // Point to the next waypoint; first wpt is the starting point
    done = false;
    buttonReleased = buttonPressed = false;
    bool started = false;  // flag to indicate robot has exceeded min speed.
    
    // TODO--make sure all variables are initialized here    
    yawHdg = -1.0;
    gyroCount = 0;
    err_bearing = 0.0;
    err_distance = 0.0;
    err_compass = 0.0;
    err_yaw = 0.0;
    
    
    fp = initLogfile();                                 // Open the log file in sprintf format string style; numbers go in %d
    wait(0.2);

    //gps1.attach(recv1, Serial::RxIrq);
    ahrs.attach(recv1, Serial::RxIrq);
    gps2.attach(recv2, Serial::RxIrq);

    // Figure out the "offset" or "bias" of the GPS reading
    // since we know the robot's starting point
    
    // 20110419 1052
    findGPSBias(&gps2_off_brg, &gps2_off_dist, 2, wpt[0]);

    // Find average compass heading and use for
    // initializing base heading used by AHRS gyro+accel
    // Compass LSM303DLH runs at 15Hz = .06666 sec
    pc.printf("Computing initial yaw heading...\n");
    initialHdg = 0.0;
    for (int i = 0; i < 10; i++) {
        float hdg = compassHeading();
        initialHdg += hdg / 10.0;
        pc.printf("Compass: %.2f  Initial Heading: %.2f\n", hdg, initialHdg);
        wait(0.05);
    }
    initialHdg = 91.0; // hard code due to issues
    pc.printf("Initial Heading: %.2f\n", initialHdg);
    odo_heading = initialHdg;

    //while (!ahrsParser.dataReady());                  // sync to ahrs
    //ahrsParser.resetReady();    
    timer.reset();                                      // Keep track of milliseconds, elapsed
    timer.start();

    float lastYaw = ahrsParser.readYaw();               // try to capture rate of change
    float initialHdgFilt = initialHdg;                  // initialize the initial heading filter
    bool gpsSync = false;                               // Allows us to sync closer to actual fix time
    int syncTime = 0;                                   // stores next millisecond count at which to save DR data
    bool firstGPS = 0;                                  // is this the first GPS packet? If so, don't calc errors
    
    // Main loop
    //
    while(done == false) {
    
        int millis = timer.read_ms();
        
        // reset led status; allows blinking, 10ms long
        if ((millis % UPDATE_PERIOD) == 10) {
            logStatus = (fp != 0) ? 1 : 0;
            //ahrsStatus = (gps1Parse.f_hdop() > 0.0 && gps1Parse.f_hdop() < 10.0) ? 1 : 0;
            gps2Status = (gps2Parse.f_hdop() > 0.0 && gps2Parse.f_hdop() < 10.0) ? 1 : 0;
        }

        // Warning flasher
        //if (blink.ticked(millis)) {
        //    flasher = blink.get();
        //}
        
        // Button state machine
        // if we've not started going, button starts us
        // if we have started going, button stops us
        // but only if we've released it first
        //
        // set throttle only if goGoGo set
        if (goGoGo) {
            if (go.ticked(millis)) {
                throttle = go.get() / 1000.0;
                //pc.printf("throttle: %0.3f\n", throttle.read());
            }
            if (buttonPressed && started) {
                pc.printf(">>>>>>>>>>>>>>>>>>>>>>> HALT\n");
                done = true;
                goGoGo = false;
            }
        } else {
            if (buttonPressed == true) {
                pc.printf(">>>>>>>>>>>>>>>>>>>>>>> GO GO GO\n");
                goGoGo = true;
                buttonPressed = false;
            }
        }        
        
        
        // UPDATE EVERY UPDATE_PERIOD ms (50Hz)
        // The compass updates only ever 50ms
        // The gyro updates however fast we can read it
        //

        if ((millis % UPDATE_PERIOD) == 0) {
            unsigned int adcResult[8];

            //WHERE();
        
            adc.setChannel(0);
            for (int i=0; i < 8; i++) {
                adcResult[i] = adc.read();
            }

            temp = adcResult[TEMP_CHAN];        
            // <== read/temp calibrate here
            // Convert gyro adc reading to heading
            // TODO:
            // automatically calculate null at start
            //gyro = gyroRate(adcResult[GYRO_CHAN]);
            
            yaw = ahrsParser.readYaw(); // <-- this may have been causing trouble before. 20110420 1249
            // 20110421
            yawRate = yaw - lastYaw;
            lastYaw = yaw;

            // If we're stopped, set initialHdg to compass
            // But do a running average / leaky integrator to reduce some noise
            // 20110421
            if (encSpeed == 0) {
                findGPSBias(&gps2_off_brg, &gps2_off_dist, 1, wpt[0]);
                initialHdgFilt += compassHdg - (initialHdgFilt * 0.25);
                initialHdg = initialHdgFilt * 0.25;
                while (initialHdg < 0.0) initialHdg += 360.0;
                while (initialHdg >= 360.0) initialHdg -= 360.0;
            }

            // Substitute 6dof AHRS yaw for 1-axis gyro and 6dof compass
            yawHdg = initialHdg + yaw;
            
            while (yawHdg < 0) yawHdg += 360.0;
            while (yawHdg >= 360.0) yawHdg -= 360.0;

            compassHdg = compassHeading();

            // pc.printf("Gyro: %d  GyroHdg: %.1f\n", gyro, yaw);

            // Need a better filtered heading output
            // for now just use gyro heading as it seems to be most accurate
            // provided the bias is set right.
            
            // Odometry            
            unsigned int leftCount = left.read();
            unsigned int rightCount = right.read();
            
            // TODO--> sanity check on encoders; if difference between them
            //  is huge, what do we do?  Slipping wheel?  Skidding wheel?
            
            double leftDist  = (WHEEL_CIRC / 32) * (double) leftCount;
            double rightDist = (WHEEL_CIRC / 32) * (double) rightCount;
            encDistance = (leftDist + rightDist) / 2.0;
            encSpeed = encDistance / (UPDATE_PERIOD * 0.001);

            odo_heading += (leftDist - rightDist) / TRACK;

            if ((millis % 500) == 0) {
                pc.printf("Odo heading: %.1f\n", odo_heading);
            }

            // 20110421
            if (encSpeed < GPS_MIN_SPEED) {
                dr_heading = yawHdg;
            } else {
                started = true;
                dr_heading = compassHdg;
                
                // Yaw error
                // Let yaw track closely behind compass which
                // tracks closely behind GPS
                err_yaw = clamp180(compassHdg - yawHdg);

                // fix yaw by tweaking the initial heading
                // which is a kludge but... hey it's 2 days before the competition
                initialHdg += err_yaw * yawGain;
                clamp360(initialHdg);
                
            }
            while (dr_heading < 0) dr_heading += 360.0;
            while (dr_heading >= 360.0) dr_heading -= 360.0;
            
            //pc.printf("%d dr_heading: %.2f\n", __LINE__, dr_heading);

            // Dead Reckoning Position estimation, very simple stuff
            // lat: north +y, south -y ; cos(hdg)
            // long: west -x, east +x ; sin(hdg)
            // 1852m = 1 nautical mile = 1 deg lat / long
            dr_here.move(dr_heading, encDistance);

            ////////////////////////////////
            // Correct position here
 
            //
            //
            ////////////////////////////////

            dr_bearing = wpt[wptCurrent].bearing(dr_here);
            dr_distance = wpt[wptCurrent].distance(dr_here);

            //pc.printf("dr_heading: %.1f  encDistance: %.3f\n", dr_heading, encDistance);

            // Log dead reckoning info
            logStatus = 0;
            fprintf(fp, "%d, %.1f, %.1f, %.1f, %.8f, %.8f, , , , , , %.1f, %.1f, , %.1f, %.3f, %d, %d, %d, %.1f\n", 
                    millis, yaw, yawHdg, compassHdg, dr_here.latitude(), dr_here.longitude(), dr_heading, encSpeed,
                    dr_bearing, dr_distance, left.readTotal(), right.readTotal(), temp, odo_heading);
                
            //pc.printf("Yaw = %.1f\n", ahrsParser.readYaw());
                        
            // synchronize when RMC and GGA sentences received w/ AHRS
            if (gps2Parse.rmc_ready() && gps2Parse.gga_ready()) {
                char gps2date[32], gps2time[32];

                // We synchronize on the first GPS packet that doesn't have GSV sentences
                // then every 1000ms after, we will save DR data for error comparison
                if (!gps2Parse.gsv_ready() && !gpsSync) {
                    syncTime = millis + 1000;
                    gpsSync = true;
                }
            
                doGPS(gps2Parse, here2, gps2Status, gps2date, gps2time);

                if (gps2_hdop < GPS_MAX_HDOP) {

                    // Correct here2 for offset (bias)
                    here2.move(gps2_off_brg, gps2_off_dist);

                    //pc.printf("GPS2 %d HDOP: %.1f Compass: %.1f  Gyro: %d  Gyro Temp: %d\n", millis, gps1Parse.f_hdop(), compassHdg, gyro, temp);
        
                    gps2_bearing  = wpt[wptCurrent].bearing(here2);
                    gps2_distance = wpt[wptCurrent].distance(here2);
                    gps2_heading  = gps2Parse.f_course();
        
                    //pc.printf("GPS2: lat: %.6f lon: %.6f wpt[%d]: lat:%.6f  lon:%.6f  distance=%.2f\n", 
                    //            here2.latitude(), here2.longitude(), wptCurrent, 
                    //            wpt[wptCurrent].latitude(), wpt[wptCurrent].longitude(), distance);
        
                    // TODO --> Estimate new DR position here
                    // simple: take a weighted average midpoint
                    // TODO --> gradually move dr position by using same err distance/bearing but move a fraction of the distance
                    // over the next n samples between gps readings
                    // We have to address GPS lag. The easy (but probably incorrect way) is to use the DR info at the last time
                    // we received a GPS update.  Because the GPS is spitting out CSV sentences every 5 seconds or so, that
                    // throws off the timing.
                    
                    if (!firstGPS) {

                        // 20110421                    
                        // Position error
                        err_distance = here2.distance(dr_here_last);
                        err_bearing  = here2.bearing(dr_here_last);
                    
                        ////////////////////////////////////////////////////////////////////////////////////////////////////////////
                        // Error Correction
                        ////////////////////////////////////////////////////////////////////////////////////////////////////////////
                        // The strategy is: rely on GPS when hdop < 2; corrected by distance from initial starting point. At
                        // hdop > 2, gps position becomes unreliable, so fall back on compass and/or AHRS yaw and dead reckoning.
                        // The latter is pretty reliable.  But heading isn't.  Compass err varies based on, apparently, mag field
                        // from the motor/wires. We'll stick to a set speed and correct compass error while relying on gps.  That
                        // plus position correction should keep DR up to date with the last gps fix with hdop < GPS_MAX_HDOP
                        // Meanwhile, AHRS yaw seems to be filtered to the point that bandwidth can't track even moderate turn
                        // rates. The exact cause is yet undiscovered.  The onboard compass has a distortion I've been unable
                        // to resolve, so we're running only gyro+accelerometer
                        //
                        // At higher speeds, we can trust gps course, but at lower speeds we can't.  Initially when we start, the
                        // most reliable heading/DR information comes from encoders+AHRS.  At speed = 0, yaw and compass are very
                        // reliable, so yaw initial heading is set from compass.  So we'll use dead reckoning until the vehicle
                        // reaches a higher speed, at which point, position info comes from gps and is used for yaw/compass/position 
                        // correction.
                        //
                        // I wished I could figure out a mathematically fancy way to do this but I'm confounded by all the different
                        // sensor errors.   KF is the only thing I've sort-of learned so far and I don't yet see how I can use it
                        // for the types of (apparently non-gaussian) noise/error I'm seeing.
                        ////////////////////////////////////////////////////////////////////////////////////////////////////////////
                        // 20110421
                        if (encSpeed >= GPS_MIN_SPEED) {
                            // Heading error                    
                            err_compass  = compassHdg_last - gps2_heading;
                            if (err_compass < -180.0) err_compass += 360.0;
                            if (err_compass > 180.0) err_compass -= 360.0;
                            // we'll use err_compass when computing compass heading from now on
    
                            // fix compass by tweaking declination
                            // again, no time to do anything elegant, just hacking here
                            declination += err_compass * compassGain;
                            clamp360(declination);
                            
                            // 20110421
                            fprintf(fp, "ERR: err_dist: %.5f err_brg: %.2f compassHdg_last: %.2f gps2_heading: %.2f err_compass: %.5f declination: %.2f\n",
                                      err_distance, err_bearing, compassHdg_last, gps2_heading, err_compass, declination);
                        }
                    } // if (!firstGPS)

                    // 20110421
                    // Save currnt DR position / heading
                    // change this so that after gpsSync == true, we only save this
                    // when millis == syncTime, then syncTime += 1000
                    dr_here_last.set( dr_here );
                    compassHdg_last = compassHdg;
                    firstGPS = false;
                    
                    // less simple: find distance between & bearing, mult dist by weight, plot new position with move()
                    // harder: kalman filter
                    // ALSO---> need to do some kind of sanity check.  If distance between each exceeds threshold, then one is bad
                    // how do we guess which?  Will gps ever be way off with low hdop?
                    // maybe compare to predicted location based on last heading/speed?
                    // should we convert to UTM?
                }
                
                logStatus = 0;
                //WHERE();
                fprintf(fp, "%d, %.1f, %.1f, %.1f, %.8f, %.8f, GPS2, %s, %s, %.2f, %.1f, %.1f, %.1f, %.1f, %.3f, , , , %d, \n", 
                        millis, gyro, yawHdg, compassHdg, here2.latitude(), here2.longitude(), gps2date, gps2time,
                        gps2Parse.f_altitude(), // <-- was hanging here... but probably due to goof up somewhere else. Stack corruption??
                        gps2_heading, gps2Parse.f_speed_mph(), gps2Parse.f_hdop(), bearing, distance, temp);
                //WHERE();
            
            }

            //////////////////////////////////////////////////////////////////////////////
            // Update steering and throttle
            //////////////////////////////////////////////////////////////////////////////
            if ((millis % 100) == 0) {

                // TODO --> Calculate bearing/distance from GPS and DR
                
                // Might be able to do kalman filter here but... meanwhile:
                // 1) Weighted averaging of heading using GPS and Gyro to account for drift
                // 2) Correct GPS position for bias (brg/dist)
                // 3) Take corrected GPS position, go back 2 seconds, and find error brg/dist with DR at that time
                // 4) calculate a weighted average position based on DR and GPS, hdop and SV change
                // 5) apportion some of the error back into the GPS position bias (brg/dist) weighted on hdop and SV changes


                //////////////////////////////////////////////////////////////////////////////
                // Navigation -- see error correction above
                // We'll always navigate off DR but only because we're supposed to be
                // correcting it as we go via GPS
                //////////////////////////////////////////////////////////////////////////////
                // 20110421
                bearing  = dr_bearing;
                distance = dr_distance;
                heading  = dr_heading;
                
                relativeBrg = bearing - heading;         // 0 is desired heading

// limit steering angle based on object detection ?
// or limit relative brg perhaps?
                
                // if correction angle is < -180, express as negative degree
                if (relativeBrg < -180.0) relativeBrg += 360.0;
                if (relativeBrg > 180.0)  relativeBrg -= 360.0;
                    
                float steerAngle = steerCalc.calcSA(relativeBrg);
                
                // Convert steerAngle to servo value
                // Testing determined near linear conversion between servo ms setting and steering angle
                // up to 20*.  Assumes a particular servo library with range = 0.005
                // In that case, f(SA) = servoPosition = 0.500 + SA/762.5
                // between 20 and 24* the slop is approximately 475
                // What if we ignore the linearity and just set to a max angle
                // also range is 0.535-0.460 --> slope = 800
                //steering = 0.500 + (double) steerAngle / 762.5;

                if (encSpeed < GPS_MIN_SPEED) {
                    steering = 0.495;
                } else {
                    steering = 0.500 + (double) steerAngle / 808.0;
                }
                pc.printf("Wpt #%d: rel bearing: %.1f, bearing: %.1f, distance: %.5f\n", wptCurrent, relativeBrg, bearing, distance);

                // if within 3m move to next waypoint
                // PARAMETERIZE DISTANCE
                if (distance < 3.0) {
                    pc.printf("Arrived at wpt %d\n", wptCurrent);
                    wptCurrent++;
                }
                    
                // Are we at the last waypoint?
                if (wptCurrent == wptCount) {
                    pc.printf("Arrived at final destination. Done.\n");
                    done = true;
                }
                
            }


/*
            if ((millis % 1000) == 0) {
                pc.printf("Wpt #%d: rel bearing: %.1f, bearing: %.1f, distance: %.5f\n", wptCurrent, relativeBrg, bearing, distance);
                pc.printf("dr_heading: %.1f  encDistance: %.3f\n", dr_heading, encDistance);
                pc.printf("err_dist: %.5f\nerr_brg: %.1f\n\n", err_distance, err_bearing);
            }
  */
          
        }
        
    } // while
    
    // shut 'er down!
    throttle = 0.500;
    steering = 0.500;
    
    if (fp) {
        fclose(fp);
        logStatus = 0;
        pc.printf("closed log file.\n");
    }

    //ahrsStatus = 0;
    gps2Status = 0;
    confStatus = 0;
    flasher = 0;
        
} // autonomousMode


void idleMode()
{    
    while (1) {
        ahrsStatus = 0;
        wait(0.2);
        ahrsStatus = 1;
        wait(0.2);
    }
}

///////////////////////////////////////////////////////////////////////////////////////////////////////
// UTILITIY FUNCTIONS
///////////////////////////////////////////////////////////////////////////////////////////////////////


// Takes n position readings and averages the gps position
// in a pretty rudimentary fashion, returning bearing and distance
// from the specified place to the average position
void findGPSBias(double *brg, double *dist, int n, GeoPosition place)
{
    // GPS Position averaging
    double div = (double) n;
    double latavg = 0;
    double lonavg = 0;
    double lat = 0;
    double lon = 0;
    gps2Parse.reset_ready();
    
    pc.printf("Calculating GPS offset...\n");
    
    while (n > 0) {
        while (gps2Parse.rmc_ready() == false)
            wait(0.2);

        gps2Parse.reset_ready();
        gps2Parse.f_get_position(&lat, &lon, &age);

        if (gps2Parse.f_hdop() > 0 && gps2Parse.f_hdop() < 2.0) {
            pc.printf("GPS lat: %.7f lon %.7f\n", lat, lon);
            latavg += lat / div;
            lonavg += lon / div;
            n--;
        } else {
            pc.printf("Waiting for good GPS fix\n");
            gps2Status = 1;
            wait(0.1);
            gps2Status = 0;
        }
            
    }
    pc.printf("AVG lat: %.7f lon %.7f\n", latavg, lonavg);
    GeoPosition avg(latavg, lonavg);
    *dist = place.distance( avg );
    *brg  = place.bearing( avg );
    // Now that we've calculated a bearing and distance to a quickie offset/bias
    // we can subtract this from all future GPS readings by simply taking the
    // gps position and doing a move(gps2_off_brg, gps2_off_dist)
    // maybe do adjustments based on how far off predicted DR position is from
    // GPS reported pos.  I'd love to be able to factor in SV and HDOP info too
}


void compass3dCalibrate()
{
    int tick;
    FILE *fp;
    
    pc.printf("Entering calibration mode for 30 seconds\nRotate compass thru 360 degree sphere\n");
    for (int i=10; i > 0; i--) {
        pc.printf("%d...", i);
        if (pc.readable()) {
            char cmd = pc.getc();
        }
        wait(1.0);
    }
    pc.printf("Begin calibration\n");

    fp = fopen("/log/compass.txt", "w");

    if (fp == 0) {
        pc.printf("Error opening file\n");
    } else {
        // printf(fp, "# magX, magY, magZ\n");
        timer.reset();
        timer.start();
        tick = 30;
        while (tick > 0) {
            // run every 20ms
            // get all three axes
            // printf(fp, "%d, %d, %d\n"
            if (timer.read_ms() > 1000) {
                pc.printf("%d\n", tick--);
                timer.reset();
            }
            wait(0.2);
        }
        fclose(fp);
        pc.printf("\nData saved to compass.txt\n\n");
    }
}


// HMC6352 compass calibration mode
void compassCalibrate()
{
    int tick;
    
    pc.printf("Entering calibration mode for 60 seconds\nRotate compass at least once through 360 degrees\n");
    for (int i=10; i > 0; i--) {
        pc.printf("%d...", i);
        if (pc.readable()) {
            char cmd = pc.getc();
        }
        wait(1.0);
    }
    pc.printf("Begin calibration\n");

    //compass.setCalibrationMode(HMC6352_ENTER_CALIB);
    timer.start();
    tick = 60;
    while (tick > 0) {
        if (timer.read_ms() > 1000) {
            pc.printf("%d\n", tick--);
            timer.reset();
        }
        wait(0.2);
    }
    //compass.setCalibrationMode(HMC6352_EXIT_CALIB);
    pc.printf("Calibration complete.\n");
}

void servoCalibrate() 
{
}

void bridgeRecv()
{
    while (dev && dev->readable()) {
        pc.putc(dev->getc());
    }
}

void serialBridge(Serial &gps)
{
    char x;
    int count = 0;
    bool done=false;

    pc.printf("\nEntering serial bridge in 2 seconds, +++ to escape\n\n");
    wait(2.0);
    //dev = &gps;
    gps.attach(NULL, Serial::RxIrq);
    while (!done) {
        if (pc.readable()) {
            x = pc.getc();
            // escape sequence
            if (x == '+') {
                if (++count >= 3) done=true;
            } else {
                count = 0;
            }
            gps.putc(x);
        }
        if (gps.readable()) {
            pc.putc(gps.getc());
        }
    }
}


void instrumentCheck()
{
    bool done = false;
    float compassHdg = 0;
    float initialHdg = 0;
    float ahrsHdg = 0;
    unsigned int adcResult[8] = {0,0,0,0,0,0,0,0};
    //unsigned int sonar, gyro, temp;
    Timer timer;
    SimpleFilter ranger(8);
    
    initialHdg = compassHeading();
    initAHRS();

    timer.reset();
    timer.start();
    
    buttonReleased = buttonPressed = false;  
      
    pc.printf("press e to exit\n");
    while (!done) {
        if (buttonPressed) done=true;
        while (pc.readable()) {
            if (pc.getc() == 'e') {
                done = true;
                break;
            }
        }

        int millis = timer.read_ms();

        if ((millis % 20) == 0) {
        
            if ((millis % 100) == 0) {
                sonarStart = 1;
                wait_us(25);
                sonarStart = 0;
                wait_us(50);
            }
            
            adc.setChannel(0);
            for (int i = 0; i < 8; i++) {
                adcResult[i] = adc.read();
            }
            ranger.filter(adcResult[0]);
            
            if ((millis % 1000) == 0) {
                compassHdg = compassHeading();
                
                ahrsHdg = initialHdg + ahrsParser.readYaw();
                while (ahrsHdg >= 360.0) ahrsHdg -= 360.0;
                while (ahrsHdg < 0) ahrsHdg += 360.0;
    
                char data[4];
                
                // CMUcam1 I2C code goes here
    
                pc.printf("-----e to exit-----\nCompass: %.1f\nAHRS: %.1f\nGyro: %.3f\nGyro Temp: %d\nSonar Left: %.2f\nSonar Right: %.2f\nIR Left: %.5f\nIR Right: %.5f\nEncLeft: %d\nEncRight: %d\n\n",
                          compassHdg, ahrsHdg, gyroRate(adcResult[GYRO_CHAN]), adcResult[TEMP_CHAN], 
                          sonarDistance(adcResult[SONARLEFT_CHAN]), sonarDistance(adcResult[SONARRIGHT_CHAN]),
                          irDistance(adcResult[IRLEFT_CHAN]), irDistance(adcResult[IRRIGHT_CHAN]), left.readTotal(), right.readTotal());
    
                pc.printf("IR filter: %d %.1f\n", ranger.value(), irDistance(ranger.value()));
        
                pc.printf("\nCam Obj Box: (%d,%d) (%d,%d)\n\n", data[0], data[1], data[2], data[3]);
            
                for (int i = 0; i < 8; i++) {
                    pc.printf("ADC(%d)=%d\n", i, adcResult[i]);
                }
                pc.printf("\n");
            }
            wait_ms(2);
        }
    }
    // clear input buffer
    while (pc.readable()) pc.getc();
}


///////////////////////////////////////////////////////////////////////////////////////////////////////
// ADC CONVERSION FUNCTIONS
///////////////////////////////////////////////////////////////////////////////////////////////////////
float compassHeading() {
    //Timer t;
    //int usec1, usec2;
    //t.reset();
    //t.start();
    //float compassHdg = compass.sample() / 10.0;       // read compass
    //float compassHdg = compass3d.heading2d();
    ////WHERE();
    //__disable_irq();    // Disable Interrupts
    //usec1 = t.read_us();         
    float compassHdg = compass3d.heading();
    //usec2 = t.read_us();         
    //__enable_irq();     // Enable Interrupts
    
    //pc.printf("usec1: %d, usec2: %d, usec: %d\n", usec1, usec2, usec2-usec1);
    
    //WHERE();
    compassHdg -= declination; // Correct for local declination
    clamp360(compassHdg);
    
    return compassHdg;
}


// returns rate in */sec
//
// Gyro is ratiometric and so is ADC, so we can cancel out
// errors due to voltage supply by putting sensitivity in
// terms of adc reading and calculate rate from that.
//   (adc - bias) / sens
// UPDATE_PERIOD in ms, 5.91mV/degree/sec is scale factor
//
// TODO: use constants and defines
//
float gyroRate(unsigned int adc)
{
    float rate = 0.0;
    
    rate = ((float) (adc - gyroBias)) / gyroSens;
    
    return rate;
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

// returns distance in m for Sharp GP2YOA710K0F
// to get m and b, I wrote down volt vs. dist by eyeballin the
// datasheet chart plot. Then used Excel to do linear regression
//
float irDistance(unsigned int adc)
{
    float b = 1.0934; // Intercept from Excel
    float m = 1.4088; // Slope from Excel

    return m / (((float) adc) * 4.95/4096 - b);
}