
var undefined;

exports.environments = function() 
{
    return ENVIRONMENTS;
}

if (window)
{
    window.setNativeTimeout = window.setTimeout;
    window.clearNativeTimeout = window.clearTimeout;
    window.setNativeInterval = window.setInterval;
    window.clearNativeInterval = window.clearNativeInterval;
}

// Objective-J Constants
var NO      = false,
    YES     = true,
    
    nil     = null,
    Nil     = null,
    NULL    = null,

    ABS     = Math.abs,
    
    ASIN    = Math.asin,
    ACOS    = Math.acos,
    ATAN    = Math.atan,
    ATAN2   = Math.atan2,
    
    SIN     = Math.sin,
    COS     = Math.cos,
    TAN     = Math.tan,
    
    EXP     = Math.exp,
    POW     = Math.pow,
    
    CEIL    = Math.ceil,
    FLOOR   = Math.floor,
    ROUND   = Math.round,
    
    MIN     = Math.min,
    MAX     = Math.max,
    
    RAND    = Math.random,
    SQRT    = Math.sqrt,
    
    E       = Math.E,
    
    LN2     = Math.LN2,
    LN10    = Math.LN10,
    LOG2E   = Math.LOG2E,
    LOG10E  = Math.LOG10E,
    
    PI      = Math.PI,
    PI2     = Math.PI * 2.0,
    PI_2    = Math.PI / 2.0,
    
    SQRT1_2 = Math.SQRT1_2,
    SQRT2   = Math.SQRT2;

exports.NO       = NO;
exports.YES      = YES;
exports.nil      = nil;
exports.Nil      = Nil;
exports.NULL     = NULL;
exports.ABS      = ABS;
exports.ASIN     = ASIN;
exports.ACOS     = ACOS;
exports.ATAN     = ATAN;
exports.ATAN2    = ATAN2;
exports.SIN      = SIN;
exports.COS      = COS;
exports.TAN      = TAN;
exports.EXP      = EXP;
exports.POW      = POW;
exports.CEIL     = CEIL;
exports.FLOOR    = FLOOR;
exports.ROUND    = ROUND;
exports.MIN      = MIN;
exports.MAX      = MAX;
exports.RAND     = RAND;
exports.SQRT     = SQRT;
exports.E        = E;
exports.LN2      = LN2;
exports.LN10     = LN10;
exports.LOG2E    = LOG2E;
exports.LOG10E   = LOG10E;
exports.PI       = PI;
exports.PI2      = PI * 2.0;
exports.PI_2     = PI / 2.0;
exports.SQRT1_2  = SQRT1_2;
exports.SQRT2    = SQRT2;
