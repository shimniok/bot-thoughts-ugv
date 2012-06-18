#ifndef __KALMAN_H
#define __KALMAN_H

float kfGetX(int i);
void headingKalmanInit(float x0);
float headingKalman(float dt, float Hgps, bool gps, float dHgyro, bool gyro);

#endif