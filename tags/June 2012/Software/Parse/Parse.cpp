#include "Parse.h"

int Parse::ctoi(char c)
{
  int i=-1;

  if (c >= '0' && c <= '9') {
    i = c - '0';
  }

  //printf("char: %c  int %d\n", c, i);

  return i;
}


float Parse::cvstof(char *s)
{
  float f=0.0;
  float mult = 0.1;
  char dec = 1;

  // leading spaces
  while (*s == ' ' || *s == '\t') {
    s++;
    if (*s == 0) break;
  }

  // What about negative numbers?

  // before the decimal
  //
  while (*s != 0) {
    if (*s == '.') {
      s++;
      break;
    }
    f = (f * 10.0) + (float) ctoi(*s);
    s++;
  }
  // after the decimal
  while (*s != 0 && *s >= '0' && *s <= '9') {
    f += (float) ctoi(*s) * mult;
    mult /= 10;
    s++;
  }

  return f;
}

// copy t to s until delimiter is reached
// return location of delimiter+1 in t
char *Parse::split(char *s, char *t, int max, char delim)
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
