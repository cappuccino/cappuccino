/*
 * This file is a part of program XcodeCapp
 * Copyright (C) 2011  Aparajita Fishman (<aparajita@aparajitaworld.com>)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef xcodecapp_cocoa_macros_h
#define xcodecapp_cocoa_macros_h

#if DEBUG
#   define DLog(fmt, ...) NSLog((fmt), ##__VA_ARGS__)
#else
#   define DLog(...)
#endif

#endif
