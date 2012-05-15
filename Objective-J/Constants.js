/*
 * Constants.js
 * Objective-J
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008-2010, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

var undefined;

if (typeof window !== "undefined")
{
    window.setNativeTimeout = window.setTimeout;
    window.clearNativeTimeout = window.clearTimeout;
    window.setNativeInterval = window.setInterval;
    window.clearNativeInterval = window.clearInterval;
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
GLOBAL(LOG)     = Math.log;
GLOBAL(LOG2E)   = Math.LOG2E;
GLOBAL(LOG10E)  = Math.LOG10E;

GLOBAL(PI)      = Math.PI;
GLOBAL(PI2)     = Math.PI * 2.0;
GLOBAL(PI_2)    = Math.PI / 2.0;

GLOBAL(SQRT1_2) = Math.SQRT1_2;
GLOBAL(SQRT2)   = Math.SQRT2;
