#include "Config.h"
#include "Actuators.h"
#include "Sensors.h"
#include "SystemState.h"
#include "GPS.h"
#include "Steering.h"
#include "Servo.h"
#include "Mapping.h"
#include "CartPosition.h"
#include "GeoPosition.h"
#include "kalman.h"

#define _x_ 0
#define _y_ 1
#define _z_ 2

// Every ...
//  10ms (100Hz) -- update gyro, encoders; update AHRS; update navigation; set log data
//  10ms (100Hz) -- camera (actually runs 30fps
//  20ms  (50Hz) -- update compass sensor
//  50ms  (20Hz) -- create new log entry in log FIFO
// 100ms  (10Hz) -- GPS update
// 100ms  (10Hz) -- control update

#define CTRL_SKIP 5
#define MAG_SKIP 2
#define LOG_SKIP 5

int control_count=CTRL_SKIP;
int update_count=MAG_SKIP;              // call Update_mag() every update_count calls to schedHandler()
int log_count=LOG_SKIP;                 // buffer a new status entry for logging every log_count calls to schedHandler
int tReal;                              // calculate real elapsed time

// TODO: 3 better encapsulation, please
extern Sensors sensors;
extern SystemState state[SSBUF];
extern unsigned char inState;
extern unsigned char outState;
extern bool ssBufOverrun;
extern GPS gps;
extern Mapping mapper;
extern Steering steerCalc;              // steering calculator
extern Timer timer;
extern DigitalOut ahrsStatus;           // AHRS status LED

// Navigation
extern Config config;
int nextWaypoint = 0;                   // next waypoint destination
int lastWaypoint = 1;
double bearing;                         // bearing to next waypoint
double distance;                        // distance to next waypoint
float steerAngle;                       // steering angle
float cte;                              // Cross Track error
float cteI;                             // Integral of Cross Track Error

// Throttle PID
float speedDt=0;                        // dt for the speed PID
float integral=0;                       // error integral for speed PID
float lastError=0;                      // previous error, used for calculating derivative
bool go=false;                          // initiate throttle (or not)
float desiredSpeed;                     // speed set point
float nowSpeed;


// Pose Estimation
bool initNav = true;
float initHdg = true;                   // indiciates that heading needs to be initialized by gps
float initialHeading=-999;              // initial heading
float myHeading=0;                      // heading sent to KF
CartPosition cartHere;                  // position estimate, cartesian
GeoPosition here;                       // position estimate, lat/lon
extern GeoPosition gps_here;
int timeZero=0;
int lastTime=-1;                        // used to calculate dt for KF
int thisTime;                           // used to calculate dt for KF
float dt;                               // dt for the KF
float lagHeading = 0;                   // lagged heading estimate
//GeoPosition lagHere;                  // lagged position estimate; use here as the current position estimate
float errAngle;                         // error between gyro hdg estimate and gps hdg estimate
float gyroBias=0;                       // exponentially weighted moving average of gyro error
float Ag = (2.0/(1000.0+1.0));          // Gyro bias filter alpha, gyro; # of 10ms steps
float Kbias = 0.995;            
float filtErrRate = 0;
float biasErrAngle = 0;

#define MAXHIST 128 // must be multiple of 0x08
#define inc(x)  (x) = ((x)+1)&(MAXHIST-1)
struct {
    float x;        // x coordinate
    float y;        // y coordinate
    float hdg;      // heading
    float dist;     // distance
    float gyro;     // heading rate
    float ghdg;     // uncorrected gyro heading
    float dt;       // delta time
} history[MAXHIST]; // fifo for sensor data, position, heading, dt

int hCount=0;       // history counter; one > 100, we can go back in time to reference gyro history
int now = 0;        // fifo input index
int prev = 0;      // previous fifo iput index
int lag = 0;        // fifo output index
int lagPrev = 0;    // previous fifo output index


/** set flag to initialize navigation at next schedHandler() call
 */
void restartNav()
{
    initNav = true;
    initHdg = true;
    return;
}

/** instruct the controller to throttle up
 */
void beginRun()
{
    go = true;
    timeZero = thisTime; // initialize 
    return;
}

void endRun()
{
    go = false;
    initNav = true;
    return;
}

/** get elasped time in update loop
 */
int getUpdateTime()
{
    return tReal;
}

void setSpeed(float speed) 
{
    if (desiredSpeed != speed) {
        desiredSpeed = speed;
        integral = 0;
    }
    return;
}

/** schedHandler fires off the various routines at appropriate schedules
 *
 */
void update()
{
    tReal = timer.read_us();

    ahrsStatus = 0;
    thisTime = timer.read_ms();
    dt = (lastTime < 0) ? 0 : ((float) thisTime - (float) lastTime) / 1000.0; // first pass let dt=0
    lastTime = thisTime;

    // Add up dt to speedDt
    speedDt += dt;
    
    // Log Data Timestamp    
    int timestamp = timer.read_ms();

    //////////////////////////////////////////////////////////////////////////////
    // NAVIGATION INIT
    //////////////////////////////////////////////////////////////////////////////
    // initNav is set with call to restartNav() when the "go" button is pressed.  Up
    // to 10ms later this function is called and the code below will initialize the
    // dead reckoning position and estimated position variables
    // 
    if (initNav == true) {
        initNav = false;
        here.set(config.wpt[0]);
        nextWaypoint = 1; // Point to the next waypoint; 0th wpt is the starting point
        lastWaypoint = 1; // Init to waypoint 1, we we don't start from wpt 0 at the turning speed
        // Initialize lag estimates
        //lagHere.set( here );
        // Initialize fifo
        hCount = 0;
        now = 0;
        // initialize what will become lag data in 1 second from now
        history[now].dt = 0;
        // initial position is waypoint 0
        history[now].x = config.cwpt[0]._x;
        history[now].y = config.cwpt[0]._y;
        cartHere.set(history[now].x, history[now].y);
        // initialize heading to bearing between waypoint 0 and 1
        //history[now].hdg = here.bearingTo(config.wpt[nextWaypoint]);
        history[now].hdg = cartHere.bearingTo(config.cwpt[nextWaypoint]);
        history[now].ghdg = history[now].hdg;
        initialHeading = history[now].hdg;
        // Initialize Kalman Filter
        headingKalmanInit(history[now].hdg);
        // initialize cross track error
        cte = 0;
        cteI = 0;
        // point next fifo input to slot 1, slot 0 occupied/initialized, now
        lag = 0;
        lagPrev = 0;
        prev = now; // point to the most recently entered data
        now = 1;    // new input slot
    }


    //////////////////////////////////////////////////////////////////////////////
    // SENSOR UPDATES
    //////////////////////////////////////////////////////////////////////////////

    // TODO: 3 This really should run infrequently
    sensors.Read_Power();

    sensors.Read_Encoders(); 
    nowSpeed = sensors.encSpeed;

    sensors.Read_Gyro(); 

    sensors.Read_Rangers();

    //sensors.Read_Camera();

    //////////////////////////////////////////////////////////////////////////////
    // Obtain GPS data                        
    //////////////////////////////////////////////////////////////////////////////

    // synchronize when RMC and GGA sentences received w/ AHRS
    // Do this in schedHandler??  GPS data is coming in not entirely in sync
    // with the logging info
    if (gps.nmea.rmc_ready() && gps.nmea.gga_ready()) {
        char gpsdate[32], gpstime[32];

        gps.process(gps_here, gpsdate, gpstime);
        //gpsStatus = (gps.hdop > 0.0 && gps.hdop < 3.0) ? 1 : 0;

        // update system status struct for logging
        state[inState].gpsLatitude = gps_here.latitude();
        state[inState].gpsLongitude = gps_here.longitude();
        state[inState].gpsHDOP = gps.hdop;
        state[inState].gpsCourse = gps.nmea.f_course();
        state[inState].gpsSpeed = gps.nmea.f_speed_mph(); // can we just do kph/1000 ? or mps?
        state[inState].gpsSats = gps.nmea.sat_count();
    }
    
    //////////////////////////////////////////////////////////////////////////////
    // HEADING AND POSITION UPDATE
    //////////////////////////////////////////////////////////////////////////////

    // TODO: 2 Position filtering
    //    position will be updated based on heading error from heading estimate
    // TODO: 2 Distance/speed filtering
    //    this might be useful, but not sure it's worth the effort

    // So the big pain in the ass is that the GPS data coming in represents the
    // state of the system ~1s ago. Yes, a full second of lag despite running
    // at 10hz (or whatever).  So if we try and fuse a lagged gps heading with a
    // relatively current gyro heading rate, the gyro is ignored and the heading
    // estimate lags reality
    //
    // In real life testing, the robot steering control was highly unstable with
    // too much gain (typical of any negative feedback system with a very high
    // phase shift and too much feedback). It'd drive around in circles trying to
    // hunt for the next waypoint.  Dropping the gain restored stability but the
    // steering overshot significantly, because of the lag.  It sort of worked but
    // it was ugly. So here's my lame attempt to fix all this. 
    // 
    // We'll find out how much error there is between gps heading and the integrated
    // gyro heading from a second ago.

    // stick precalculated gyro data, with bias correction, into fifo
    //history[now].gyro = sensors.gyro[_z_] - gyroBias;   
    history[now].gyro = sensors.gyro[_z_];   

    // Have to store dt history too (feh)
    history[now].dt = dt;
    
    // Store distance travelled in a fifo for later use
    history[now].dist = (sensors.lrEncDistance + sensors.rrEncDistance) / 2.0;


    // Calc and store heading
    history[now].ghdg = history[prev].ghdg + dt*history[now].gyro; // raw gyro calculated heading
    //history[now].hdg = history[prev].ghdg - dt*gyroBias;           // bias-corrected gyro heading
    history[now].hdg = history[prev].hdg + dt*history[now].gyro;
    if (history[now].hdg >= 360.0) history[now].hdg -= 360.0;
    if (history[now].hdg < 0)      history[now].hdg += 360.0;

    //fprintf(stdout, "%d %d %.4f %.4f\n", now, prev, history[now].hdg, history[prev].hdg);

    // We can't do anything until the history buffer is full
    if (hCount < 100) {
        // Until the fifo is full, only keep track of current gyro heading
        hCount++; // after n iterations the fifo will be full
    } else {
        // Now that the buffer is full, we'll maintain a Kalman Filtered estimate that is
        // time-shifted to the past because the GPS output represents the system state from
        // the past. We'll also take our history of gyro readings from the most recent 
        // filter update to the present time and update our current heading and position
        
        ////////////////////////////////////////////////////////////////////////////////
        // UPDATE LAGGED ESTIMATE
        
        // Recover data from 1 second ago which will be used to generate
        // updated lag estimates

        // GPS heading is unavailable from this particular GPS at speeds < 0.5 mph
        bool useGps = (state[inState].gpsLatitude != 0 &&
                       state[inState].lrEncSpeed > 1.0 &&
                       state[inState].rrEncSpeed > 1.0 &&
                       (thisTime-timeZero) > 3000); // gps hdg converges by 3-5 sec.

        // This represents the best estimate for heading... for one second ago
        // If we do nothing else, the robot will think it is located at a position 1 second behind
        // where it actually is. That means that any control feedback needs to have a longer time
        // constant than 1 sec or the robot will have unstable heading correctoin.
        // Use gps data when available, always use gyro data

        // Clamp heading to initial heading when we're not moving; hopefully this will
        // give the KF a head start figuring out how to deal with the gyro
        if (go) {
            lagHeading = headingKalman(history[lag].dt, state[inState].gpsCourse, useGps, history[lag].gyro, true);
        } else {    
            lagHeading = headingKalman(history[lag].dt, initialHeading, true, history[lag].gyro, true);
        }

        // TODO 1: need to figure out exactly how to update t-1 position correctly
        // Update the lagged position estimate
        //lagHere.move(lagHeading, history[lag].dist);
        history[lag].x = history[lagPrev].x + history[lag].dist * sin(lagHeading);
        history[lag].y = history[lagPrev].y + history[lag].dist * cos(lagHeading);
        
        ////////////////////////////////////////////////////////////////////////////////
        // UPDATE CURRENT ESTIMATE
       
        // Now we need to re-calculate the current heading and position, starting with the most recent
        // heading estimate representing the heading 1 second ago.
        //        
        // Nuance: lag and now have already been incremented so that works out beautifully for this loop
        //
        // Heading is easy. Original heading - estimated heading gives a tiny error. Add this to all the historical
        // heading data up to present.
        //
        // For position re-calculation, we iterate 100 times up to present record. Haversine is way, way too slow,
        // so is trig calcs is marginal. Update rate is 10ms and we can't hog more than maybe 2-3ms as the outer
        // loop has logging work to do. Rotating each point is faster; pre-calculate sin/cos, etc.
        //
        // initialize these once
        errAngle = (lagHeading - history[lag].hdg);
        if (errAngle <= -180.0) errAngle += 360.0;
        if (errAngle > 180) errAngle -= 360.0;

        //fprintf(stdout, "%d %.2f, %.2f, %.4f %.4f\n", lag, lagHeading, history[lag].hdg, lagHeading - history[lag].hdg, errAngle);
        float cosA = cos(errAngle * PI / 180);
        float sinA = sin(errAngle * PI / 180);
        // Start at the out side of the fifo which is from 1 second ago
        int i = lag;
        for (int j=0; j < 100; j++) {
            history[i].hdg += errAngle;
            // Rotate x, y by errAngle around pivot point; no need to rotate pivot point (j=0)
            if (j > 0) {
                float dx = history[i].x-history[lag].x;
                float dy = history[i].y-history[lag].y;
                history[i].x = history[lag].x + dx*cosA - dy*sinA;
                history[i].y = history[lag].y + dx*sinA + dy*cosA;
            }
            inc(i);
        }
        
        // gyro bias, correct only with shallow steering angles
        // if we're not going, assume heading rate is 0 and correct accordingly
        // If we are going, compare gyro-generated heading estimate with kalman
        // heading estimate and correct bias accordingly using PI controller with
        // fairly long time constant
        // TODO: 3 Add something in here to stop updating if the gps is unreliable; need to find out what indicates poor gps heading
        if (history[lag].dt > 0 && fabs(steerAngle) < 5.0 && useGps) {
            biasErrAngle = Kbias*biasErrAngle + (1-Kbias)*(history[lag].ghdg - state[inState].gpsCourse); // can use this to compute gyro bias
            if (biasErrAngle <= -180.0) biasErrAngle += 360.0;
            if (biasErrAngle > 180) biasErrAngle -= 360.0;
        
            float errRate = biasErrAngle / history[lag].dt;

            //if (!go) errRate = history[lag].gyro;

            // Filter bias based on errRate which is based on filtered biasErrAngle
            gyroBias = Kbias*gyroBias + (1-Kbias)*errRate;
            //fprintf(stdout, "%d %.2f, %.2f, %.4f %.4f %.4f\n", lag, lagHeading, history[lag].hdg, errAngle, errRate, gyroBias);
        }
        
        // make sure we update the lag heading with the new estimate
        history[lag].hdg = lagHeading;
        
        // increment lag pointer and wrap        
        lagPrev = lag;
        inc(lag);
        
    }
    state[inState].estHeading = history[lag].hdg;
    // the variable "here" is the current position
    //here.move(history[now].hdg, history[now].dist);
    float r = PI/180 * history[now].hdg;
    // update current position
    history[now].x = history[prev].x + history[now].dist * sin(r);
    history[now].y = history[prev].y + history[now].dist * cos(r);
    cartHere.set(history[now].x, history[now].y);
    mapper.cartToGeo(cartHere, &here);

    // TODO: don't update gyro heading if speed ~0 -- or use this time to re-calc bias?
    // (sensors.lrEncSpeed == 0 && sensors.rrEncSpeed == 0)

    //////////////////////////////////////////////////////////////////////////////
    // NAVIGATION UPDATE
    //////////////////////////////////////////////////////////////////////////////
    
    //bearing = here.bearingTo(config.wpt[nextWaypoint]);
    bearing = cartHere.bearingTo(config.cwpt[nextWaypoint]);
    //distance = here.distanceTo(config.wpt[nextWaypoint]);
    distance = cartHere.distanceTo(config.cwpt[nextWaypoint]);
    //float prevDistance = here.distanceTo(config.wpt[lastWaypoint]);
    float prevDistance = cartHere.distanceTo(config.cwpt[lastWaypoint]);
    double relativeBrg = bearing - history[now].hdg;

    // if correction angle is < -180, express as negative degree
    // TODO: 3 turn this into a function
    if (relativeBrg < -180.0) relativeBrg += 360.0;
    if (relativeBrg > 180.0)  relativeBrg -= 360.0;

    // if within config.waypointDist distance threshold move to next waypoint
    // TODO: 3 figure out how to output feedback on wpt arrival external to this function
    if (go) {

        // if we're within brakeDist of next or previous waypoint, run @ turn speed
        // This would normally mean we run at turn speed until we're brakeDist away
        // from waypoint 0, but we trick the algorithm by initializing prevWaypoint to waypoint 1
        if (distance < config.brakeDist || prevDistance < config.brakeDist) {
            setSpeed( config.turnSpeed );
        } else if ( (thisTime - timeZero) < 1000 ) {
            setSpeed( config.startSpeed );
        } else {
            setSpeed( config.topSpeed );
        }

        if (distance < config.waypointDist) {
            //fprintf(stdout, "Arrived at wpt %d\n", nextWaypoint);
            //speaker.beep(3000.0, 0.5); // non-blocking
            lastWaypoint = nextWaypoint;
            nextWaypoint++;
            cteI = 0;
        }
        
    } else {
        setSpeed( 0.0 );
    }
    // Are we at the last waypoint?
    // currently handled external to this routine
        
    //////////////////////////////////////////////////////////////////////////////
    // OBSTACLE DETECTION & AVOIDANCE
    //////////////////////////////////////////////////////////////////////////////
    // TODO: 1 limit steering angle based on object detection ?
    // or limit relative brg perhaps?
    // TODO: 1 add vision obstacle detection and filtering
    // TODO: 1 add ranger obstacle detection and filtering/fusion with vision


    //////////////////////////////////////////////////////////////////////////////
    // CONTROL UPDATE
    //////////////////////////////////////////////////////////////////////////////

    if (--control_count == 0) {
  
        // Compute cross track error
        cte = steerCalc.crossTrack(history[now].x, history[now].y,
                                   config.cwpt[lastWaypoint]._x, config.cwpt[lastWaypoint]._y,
                                   config.cwpt[nextWaypoint]._x, config.cwpt[nextWaypoint]._y);
        cteI += cte;

        // Use either pure pursuit algorithm or original algorithm  
        if (config.usePP) {
            steerAngle = steerCalc.purePursuitSA(state[inState].estHeading, 
                                                 history[now].x, history[now].y,
                                                 config.cwpt[lastWaypoint]._x, config.cwpt[lastWaypoint]._y,
                                                 config.cwpt[nextWaypoint]._x, config.cwpt[nextWaypoint]._y);
        } else {
            steerAngle = steerCalc.calcSA(relativeBrg, config.minRadius); // use the configured minimum turn radius
        }
        
        // Apply gain factor for near straight line
        if (fabs(steerAngle) < config.steerGainAngle) steerAngle *= config.steerGain;

        // Curb avoidance
        if (sensors.rightRanger < config.curbThreshold) {
            steerAngle -= config.curbGain * (config.curbThreshold - sensors.rightRanger);
        }
                    
        setSteering( steerAngle );

// void throttleUpdate( float speed, float dt )

        // PID control for throttle
        // TODO: 3 move all this PID crap into Actuators.cpp
        // TODO: 3 probably should do KF or something for speed/dist; need to address GPS lag, too
        // if nothing else, at least average the encoder speed over mult. samples
        if (desiredSpeed <= 0.1) {
            setThrottle( config.escZero );
        } else {
            // PID loop for throttle control
            // http://www.codeproject.com/Articles/36459/PID-process-control-a-Cruise-Control-example
            float error = desiredSpeed - nowSpeed; 
            // track error over time, scaled to the timer interval
            integral += (error * speedDt);
            // determine the amount of change from the last time checked
            float derivative = (error - lastError) / speedDt; 
            // calculate how much to drive the output in order to get to the 
            // desired setpoint. 
            int output = config.escZero + (config.speedKp * error) + (config.speedKi * integral) + (config.speedKd * derivative);
            if (output > config.escMax) output = config.escMax;
            if (output < config.escMin) output = config.escMin;
            //fprintf(stdout, "s=%.1f d=%.1f o=%d\n", nowSpeed, desiredSpeed, output);
            setThrottle( output );
            // remember the error for the next time around.
            lastError = error; 
        }

        speedDt = 0; // reset dt to begin counting for next time
        control_count = CTRL_SKIP;
    }      

    //////////////////////////////////////////////////////////////////////////////
    // DATA FOR LOGGING
    //////////////////////////////////////////////////////////////////////////////

    // Periodically, we enter a new SystemState into the FIFO buffer
    // The main loop handles logging and will catch up to us provided 
    // we feed in new log entries slowly enough.
    if (--log_count == 0) {
        // Copy data into system state for logging
        inState++;                      // Get next state struct in the buffer
        inState &= SSBUF;               // Wrap around
        ssBufOverrun = (inState == outState);
        //
        // Need to clear out encoder distance counters; these are incremented
        // each time this routine is called.
        state[inState].lrEncDistance = 0;
        state[inState].rrEncDistance = 0;
        //
        // need to initialize gps data to be safe
        //
        state[inState].gpsLatitude = 0;
        state[inState].gpsLongitude = 0;
        state[inState].gpsHDOP = 0;
        state[inState].gpsCourse = 0;
        state[inState].gpsSpeed = 0;
        state[inState].gpsSats = 0;
        log_count = LOG_SKIP;       // reset counter
    }

    // Log Data Timestamp    
    state[inState].millis = timestamp;
    
    // TODO: 3 recursive filtering on each of the state values
    state[inState].voltage = sensors.voltage;
    state[inState].current = sensors.current;
    for (int i=0; i < 3; i++) {
        state[inState].m[i] = sensors.m[i];
        state[inState].g[i] = sensors.g[i];
        state[inState].a[i] = sensors.a[i];
    }
    state[inState].gTemp = sensors.gTemp;
    state[inState].gHeading = history[now].hdg;
    state[inState].lrEncSpeed = sensors.lrEncSpeed;
    state[inState].rrEncSpeed = sensors.rrEncSpeed;
    state[inState].lrEncDistance += sensors.lrEncDistance;
    state[inState].rrEncDistance += sensors.rrEncDistance;
    //state[inState].encHeading += (state[inState].lrEncDistance - state[inState].rrEncDistance) / TRACK;
    state[inState].estLatitude = here.latitude();
    state[inState].estLongitude = here.longitude();
    state[inState].estX = history[now].x;
    state[inState].estY = history[now].y;
    state[inState].bearing = bearing;
    state[inState].distance = distance;
    state[inState].nextWaypoint = nextWaypoint;
    state[inState].gbias = gyroBias;
    state[inState].errAngle = biasErrAngle;
    state[inState].leftRanger = sensors.leftRanger;
    state[inState].rightRanger = sensors.rightRanger;
    state[inState].centerRanger = sensors.centerRanger;
    state[inState].crossTrackErr = cte;
    // Copy AHRS data into logging data
    //state[inState].roll = ToDeg(ahrs.roll);
    //state[inState].pitch = ToDeg(ahrs.pitch);
    //state[inState].yaw = ToDeg(ahrs.yaw);

    // increment fifo pointers with wrap-around
    prev = now;
    inc(now);

    // timing
    tReal = timer.read_us() - tReal;

    ahrsStatus = 1;
}