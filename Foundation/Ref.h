/*
 * Ref.h
 * Foundation
 *
 * Created by Alexander Ljungberg.
 * Copyright 2011, WireLoad Inc.
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

/*
Temporary macros to substitute for @ref and @deref functionality in a future version of Objective-J. Since these are C macros rather than a part of Preprocessor.js they can only be used within Cappuccino itself.
*/

// @ref
#define AT_REF(x) function(__input) { if (arguments.length) return x = __input; return x; }
// @deref (kind of)
#define AT_DEREF(x, ...) x(##__VA_ARGS__)
