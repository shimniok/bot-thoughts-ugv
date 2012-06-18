#ifndef __ACTUATORS_H
#define __ACTUATORS_H

void initSteering(void);
void initThrottle(void);
void setThrottle(int value);
void setSteering(float steerAngle);

#endif