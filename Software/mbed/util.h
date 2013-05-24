#ifndef __UTIL_H
#define __UTIL_H

/** Utility routines */

#define clamp360(x) \
                while ((x) >= 360.0) (x) -= 360.0; \
                while ((x) < 0) (x) += 360.0;
#define clamp180(x) ((x) - floor((x)/360.0) * 360.0 - 180.0);

#ifndef M_PI
#define M_PI 3.14159265358979323846
#endif

/** Convert char to integer */
int ctoi(char c);
/** Convert string to floating point */
double cvstof(char *s);
/** Tokenize a string 
 * @param s is the string to tokenize
 * @param max is the maximum number of characters
 * @param delim is the character delimiter on which to tokenize
 * @returns t is the pointer to the next token
 */
char *split(char *s, char *t, int max, char delim);

#endif