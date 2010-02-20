
var undefined;

if (typeof window !== "undefined")
{
    window.setNativeTimeout = window.setTimeout;
    window.clearNativeTimeout = window.clearTimeout;
    window.setNativeInterval = window.setInterval;
    window.clearNativeInterval = window.clearNativeInterval;
}

// Objective-J Constants
GLOBAL(NO)      = false;
GLOBAL(YES)     = true;

GLOBAL(nil)     = null;
GLOBAL(Nil)     = null;
GLOBAL(NULL)    = null;

GLOBAL(ABS)     = Math.abs;

GLOBAL(ASIN)    = Math.asin;
GLOBAL(ACOS)    = Math.acos;
GLOBAL(ATAN)    = Math.atan;
GLOBAL(ATAN2)   = Math.atan2;
GLOBAL(SIN)     = Math.sin;
GLOBAL(COS)     = Math.cos;
GLOBAL(TAN)     = Math.tan;

GLOBAL(EXP)     = Math.exp;
GLOBAL(POW)     = Math.pow;

GLOBAL(CEIL)    = Math.ceil;
GLOBAL(FLOOR)   = Math.floor;
GLOBAL(ROUND)   = Math.round;

GLOBAL(MIN)     = Math.min;
GLOBAL(MAX)     = Math.max;

GLOBAL(RAND)    = Math.random;
GLOBAL(SQRT)    = Math.sqrt;

GLOBAL(E)       = Math.E;
GLOBAL(LN2)     = Math.LN2;
GLOBAL(LN10)    = Math.LN10;
GLOBAL(LOG2E)   = Math.LOG2E;
GLOBAL(LOG10E)  = Math.LOG10E;

GLOBAL(PI)      = Math.PI;
GLOBAL(PI2)     = Math.PI * 2.0;
GLOBAL(PI_2)    = Math.PI / 2.0;

GLOBAL(SQRT1_2) = Math.SQRT1_2;
GLOBAL(SQRT2)   = Math.SQRT2;
