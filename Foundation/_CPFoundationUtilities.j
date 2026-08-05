/*
 * _CPFoundationUtilities.j
 * Foundation
 *
 * Created by David Richardson.
 * Copyright 2026, Cappuccino Project.
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

//#define _IS_NUMERIC(n) (!isNaN(parseFloat(n)) && isFinite(n))

/*
 Objective-J is a strict superset of JavaScript and compiles down to a shared global runtime scope.
 This file (_CPFoundationUtilities.j) is the canonical place for otherwise "homeless" low-level
 utilities, stateless helpers, and former C-style preprocessor macros that do not belong to a
 specific class but are required across the framework.

 While modern JavaScript ecosystems (e.g., ES6 modules, bundlers) treat the global scope as something
 to be strictly avoided, Cappuccino's architecture predates these paradigms. It relies entirely on
 global scope sharing for its runtime and toll-free bridging with native JavaScript, much like C and
 Objective-C. Therefore, injecting `CP`-prefixed functions into the global scope is the intended design
 pattern here, not an anti-pattern or "pollution."

 ----------------------------------------------------------------------------
 New compiler does not provide a pre-processor.
 The macro is expanded here to a concrete function.

 The alternative is inlining at call site.
 On a cold call, this provides a very minor performance advantage.
 Conversely, it provides the Javascript engine fewer opportunities to optimize,
 which is only done when a call site is invoked.
 Additionally, it depends on individual maintainers to correctly implement the call every time.

 The macro is expanded here precisely to maintain identical semantics.

 Every current, popular browser engine optimizes a small, hot, monomorphic function like a numeric check almost immediately:

 V8 (Chrome, Edge, Opera, Brave, Node) — tiered JIT (Ignition → Sparkplug → Maglev → TurboFan).
 A function called this often gets promoted within tens of calls.
 SpiderMonkey (Firefox) — Baseline Interpreter → Baseline JIT → Ion. Same pattern.
 JavaScriptCore (Safari, all iOS browsers, since iOS forces WebKit) — LLInt → Baseline → DFG → FTL.

 All three engines specialize aggressively on exactly this shape of code: a tiny, pure, argument-type-stable function with no side effects. It is close to the ideal case for JIT optimization — the compiler will likely inline the call at the machine-code level, which is the same outcome as hand-inlining the expression, achieved automatically.

 There is no browser in current popular use — desktop or mobile — where this function call would remain a meaningful cost.
 Additionally, modern hardware and Javascript engines are so much faster than in 2008, when Cappuccino was conceived,
 that even a cold execution of this function is trivial.
 The performance objection which originally required in-lining via a macro does not exist for current targets.

 Javascript, Objective-J, C, and Objective-C all lack native namespacing.
 'CP' is the canonical namespace prefix used throughout Cappuccino to address potential collisions.
 It is reserved by convention.
 */

/*
 Checks if a value is a valid, finite number.

 This implements the legacy `_IS_NUMERIC` behavior exactly. It returns true for
 numbers and strings that can be successfully parsed into a finite number (e.g., 42, "3.14"),
 and false for NaN, Infinity, null, and purely non-numeric strings.

 This specific logic (parseFloat + global isFinite) is deliberately preserved to prevent
 regressions in code that historically relied on its lenient string parsing, rather than
 using the stricter modern ES6 `Number.isFinite()`.

 TODO: Modernize this check to use ES6 `Number.isFinite()`. This is currently deferred
 to maintain strict semantic continuity during the Go/Lisette toolchain migration and
 requires a full audit of all call sites to ensure string coercion is no longer expected.

 @param n The value to evaluate.
 @return {Boolean} YES if the value is numeric, NO otherwise.
 */
function CPIsNumeric(n) {
    return !isNaN(parseFloat(n)) && isFinite(n);
}
