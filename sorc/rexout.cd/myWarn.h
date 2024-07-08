#ifndef MYWARN_H
#define MYWARN_H

#include <stdarg.h>

int myWarn_Loc(unsigned char f_errCode, const char *file, int lineNum,
               const char *fmt, ...);

#define myWarn_Err1Arg(f) myWarn_Loc(3, __FILE__, __LINE__, f)
#define myWarn_Err2Arg(f,g) myWarn_Loc(3, __FILE__, __LINE__, f, g)

#endif
