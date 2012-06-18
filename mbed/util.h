#ifndef __UTIL_H
#define __UTIL_H

#define clamp360(x) \
                while ((x) >= 360.0) (x) -= 360.0; \
                while ((x) < 0) (x) += 360.0;
#define clamp180(x) ((x) - floor((x)/360.0) * 360.0 - 180.0);

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

int ctoi(char c);
double cvstof(char *s);
char *split(char *s, char *t, int max, char delim);

#endif