#ifndef __DEBUG_H
#define __DEBUG_H

#include <stdio.h>

#define WHERE(x) fprintf(stdout, "%d\n", __LINE__);

#endif