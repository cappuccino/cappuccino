/*
 * CPDOMDisplayServer.h
 * AppKit
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

#define DOM_OPTIMIZATION 0

#define SetStyleOrigin      0
#define SetStyleLeftTop     0
#define SetStyleRightTop    1
#define SetStyleLeftBottom  2
#define SetStyleRightBottom 3
#define SetStyleSize        4
#define SetSize             5
#define AppendChild         6
#define InsertBefore        7
#define RemoveChild         8

#define CPDOMDisplayServerSetStyleOrigin(anInstruction, aDOMElement, aTransform, x, y)\
    if (!aDOMElement.CPDOMDisplayContext)\
        aDOMElement.CPDOMDisplayContext = [];\
    var __index = aDOMElement.CPDOMDisplayContext[SetStyleOrigin];\
    if (!(__index >= 0))\
    {\
        __index = aDOMElement.CPDOMDisplayContext[SetStyleOrigin] = CPDOMDisplayServerInstructionCount;\
        CPDOMDisplayServerInstructionCount += 5;\
    }\
    CPDOMDisplayServerInstructions[__index] = anInstruction;\
    CPDOMDisplayServerInstructions[__index + 1] = aDOMElement;\
    CPDOMDisplayServerInstructions[__index + 2] = aTransform;\
    CPDOMDisplayServerInstructions[__index + 3] = x;\
    CPDOMDisplayServerInstructions[__index + 4] = y;
#if !DOM_OPTIMIZATION
#define CPDOMDisplayServerSetStyleLeftTop(aDOMElement, aTransform, aLeft, aTop) \
if (aTransform) var ____p = CGPointApplyAffineTransform(CGPointMake(aLeft, aTop), aTransform); \
else var ____p = CGPointMake(aLeft, aTop); \
aDOMElement.style.left = ROUND(____p.x) + "px";\
aDOMElement.style.top = ROUND(____p.y) + "px";

#define CPDOMDisplayServerSetStyleRightTop(aDOMElement, aTransform, aRight, aTop) \
if (aTransform) var ____p = CGPointApplyAffineTransform(CGPointMake(aRight, aTop), aTransform); \
else var ____p = CGPointMake(aRight, aTop); \
aDOMElement.style.right = ROUND(____p.x) + "px";\
aDOMElement.style.top = ROUND(____p.y) + "px";

#define CPDOMDisplayServerSetStyleLeftBottom(aDOMElement, aTransform, aLeft, aBottom) \
if (aTransform) var ____p = CGPointApplyAffineTransform(CGPointMake(aLeft, aBottom), aTransform); \
else var ____p = CGPointMake(aLeft, aBottom); \
aDOMElement.style.left = ROUND(____p.x) + "px";\
aDOMElement.style.bottom = ROUND(____p.y) + "px";

#define CPDOMDisplayServerSetStyleRightBottom(aDOMElement, aTransform, aRight, aBottom) \
if (aTransform) var ____p = CGPointApplyAffineTransform(CGPointMake(aRight, aBottom), aTransform); \
else var ____p = CGPointMake(aRight, aBottom); \
aDOMElement.style.right = ROUND(____p.x) + "px";\
aDOMElement.style.bottom = ROUND(____p.y) + "px";

#define CPDOMDisplayServerSetStyleSize(aDOMElement, aWidth, aHeight) \
    aDOMElement.style.width = MAX(0.0, ROUND(aWidth)) + "px";\
    aDOMElement.style.height = MAX(0.0, ROUND(aHeight)) + "px";

#define CPDOMDisplayServerSetSize(aDOMElement, aWidth, aHeight) \
    aDOMElement.width = MAX(0.0, ROUND(aWidth));\
    aDOMElement.height = MAX(0.0, ROUND(aHeight));

#define CPDOMDisplayServerAppendChild(aParentElement, aChildElement) aParentElement.appendChild(aChildElement)

#define CPDOMDisplayServerInsertBefore(aParentElement, aChildElement, aBeforeElement) aParentElement.insertBefore(aChildElement, aBeforeElement)

#define CPDOMDisplayServerRemoveChild(aParentElement, aChildElement) aParentElement.removeChild(aChildElement)

#define PREPARE_DOM_OPTIMIZATION()
#define EXECUTE_DOM_INSTRUCTIONS()

#else
#define CPDOMDisplayServerSetStyleLeftTop(aDOMElement, aTransform, aLeft, aTop) CPDOMDisplayServerSetStyleOrigin(SetStyleLeftTop, aDOMElement, aTransform, aLeft, aTop)

#define CPDOMDisplayServerSetStyleRightTop(aDOMElement, aTransform, aRight, aTop) CPDOMDisplayServerSetStyleOrigin(SetStyleRightTop, aDOMElement, aTransform, aRight, aTop)

#define CPDOMDisplayServerSetStyleLeftBottom(aDOMElement, aTransform, aLeft, aBottom) CPDOMDisplayServerSetStyleOrigin(SetStyleLeftBottom, aDOMElement, aTransform, aLeft, aBottom)

#define CPDOMDisplayServerSetStyleRightBottom(aDOMElement, aTransform, aRight, aBottom) CPDOMDisplayServerSetStyleOrigin(SetStyleRightBottom, aDOMElement, aTransform, aRight, aBottom)

#define CPDOMDisplayServerSetStyleSize(aDOMElement, aWidth, aHeight)\
    if (!aDOMElement.CPDOMDisplayContext)\
        aDOMElement.CPDOMDisplayContext = [];\
    var __index = aDOMElement.CPDOMDisplayContext[SetStyleSize];\
    if (!(__index >= 0))\
    {\
        __index = aDOMElement.CPDOMDisplayContext[SetStyleSize] = CPDOMDisplayServerInstructionCount;\
        CPDOMDisplayServerInstructionCount += 4;\
    }\
    CPDOMDisplayServerInstructions[__index] = SetStyleSize;\
    CPDOMDisplayServerInstructions[__index + 1] = aDOMElement;\
    CPDOMDisplayServerInstructions[__index + 2] = aWidth;\
    CPDOMDisplayServerInstructions[__index + 3] = aHeight;

#define CPDOMDisplayServerSetSize(aDOMElement, aWidth, aHeight)\
    if (!aDOMElement.CPDOMDisplayContext)\
        aDOMElement.CPDOMDisplayContext = [];\
    var __index = aDOMElement.CPDOMDisplayContext[SetSize];\
    if (!(__index >= 0))\
    {\
        __index = aDOMElement.CPDOMDisplayContext[SetSize] = CPDOMDisplayServerInstructionCount;\
        CPDOMDisplayServerInstructionCount += 4;\
    }\
    CPDOMDisplayServerInstructions[__index] = SetSize;\
    CPDOMDisplayServerInstructions[__index + 1] = aDOMElement;\
    CPDOMDisplayServerInstructions[__index + 2] = aWidth;\
    CPDOMDisplayServerInstructions[__index + 3] = aHeight;

#define CPDOMDisplayServerAppendChild(aParentElement, aChildElement)\
    if (aChildElement.CPDOMDisplayContext) aChildElement.CPDOMDisplayContext[SetStyleOrigin] = -1;\
    CPDOMDisplayServerInstructions[CPDOMDisplayServerInstructionCount++] = AppendChild;\
    CPDOMDisplayServerInstructions[CPDOMDisplayServerInstructionCount++] = aParentElement;\
    CPDOMDisplayServerInstructions[CPDOMDisplayServerInstructionCount++] = aChildElement;

#define CPDOMDisplayServerInsertBefore(aParentElement, aChildElement, aBeforeElement)\
    if (aChildElement.CPDOMDisplayContext) aChildElement.CPDOMDisplayContext[SetStyleOrigin] = -1;\
    CPDOMDisplayServerInstructions[CPDOMDisplayServerInstructionCount++] = InsertBefore;\
    CPDOMDisplayServerInstructions[CPDOMDisplayServerInstructionCount++] = aParentElement;\
    CPDOMDisplayServerInstructions[CPDOMDisplayServerInstructionCount++] = aChildElement;\
    CPDOMDisplayServerInstructions[CPDOMDisplayServerInstructionCount++] = aBeforeElement;

#define CPDOMDisplayServerRemoveChild(aParentElement, aChildElement)\
    CPDOMDisplayServerInstructions[CPDOMDisplayServerInstructionCount++] = RemoveChild;\
    CPDOMDisplayServerInstructions[CPDOMDisplayServerInstructionCount++] = aParentElement;\
    CPDOMDisplayServerInstructions[CPDOMDisplayServerInstructionCount++] = aChildElement;

#define PREPARE_DOM_OPTIMIZATION()\
CPDOMDisplayServerInstructions = [];\
CPDOMDisplayServerInstructionCount = 0;
#define EXECUTE_DOM_INSTRUCTIONS()\
    var index = 0;\
    while (index < CPDOMDisplayServerInstructionCount)\
    {\
        var instruction = CPDOMDisplayServerInstructions[index++];\
        try{\
            switch (instruction)\
            {\
                case SetStyleLeftTop:\
                case SetStyleRightTop:\
                case SetStyleLeftBottom:\
                case SetStyleRightBottom:   var element = CPDOMDisplayServerInstructions[index],\
                                                style = element.style,\
                                                x = (instruction == SetStyleLeftTop || instruction == SetStyleLeftBottom) ? "left" : "right",\
                                                y = (instruction == SetStyleLeftTop || instruction == SetStyleRightTop) ? "top" : "bottom";\
                                            CPDOMDisplayServerInstructions[index++] = nil;\
                                            var transform = CPDOMDisplayServerInstructions[index++];\
                                            if (transform)\
                                            {\
                                                var point = CGPointMake(CPDOMDisplayServerInstructions[index++], CPDOMDisplayServerInstructions[index++]),\
                                                    transformed = CGPointApplyAffineTransform(point, transform);\
                                                style[x] = ROUND(transformed.x) + "px";\
                                                style[y] = ROUND(transformed.y) + "px";\
                                            }\
                                            else\
                                            {\
                                                style[x] = ROUND(CPDOMDisplayServerInstructions[index++]) + "px";\
                                                style[y] = ROUND(CPDOMDisplayServerInstructions[index++]) + "px";\
                                            }\
                                            element.CPDOMDisplayContext[SetStyleOrigin] = -1;\
                                            break;\
                case SetStyleSize:          var element = CPDOMDisplayServerInstructions[index],\
                                                style = element.style;\
                                            CPDOMDisplayServerInstructions[index++] = nil;\
                                            element.CPDOMDisplayContext[SetStyleSize] = -1;\
                                            style.width = MAX(0.0, ROUND(CPDOMDisplayServerInstructions[index++])) + "px";\
                                            style.height = MAX(0.0, ROUND(CPDOMDisplayServerInstructions[index++])) + "px";\
                                            break;\
                case SetSize:               var element = CPDOMDisplayServerInstructions[index];\
                                            CPDOMDisplayServerInstructions[index++] = nil;\
                                            element.CPDOMDisplayContext[SetSize] = -1;\
                                            element.width = MAX(0.0, ROUND(CPDOMDisplayServerInstructions[index++]));\
                                            element.height = MAX(0.0, ROUND(CPDOMDisplayServerInstructions[index++]));\
                                            break;\
                case AppendChild:           CPDOMDisplayServerInstructions[index].appendChild(CPDOMDisplayServerInstructions[index + 1]);\
                                            CPDOMDisplayServerInstructions[index++] = nil;\
                                            CPDOMDisplayServerInstructions[index++] = nil;\
                                            break;\
                case InsertBefore:          CPDOMDisplayServerInstructions[index].insertBefore(CPDOMDisplayServerInstructions[index + 1], CPDOMDisplayServerInstructions[index + 2]);\
                                            CPDOMDisplayServerInstructions[index++] = nil;\
                                            CPDOMDisplayServerInstructions[index++] = nil;\
                                            CPDOMDisplayServerInstructions[index++] = nil;\
                                            break;\
                case RemoveChild:           CPDOMDisplayServerInstructions[index].removeChild(CPDOMDisplayServerInstructions[index + 1]);\
                                            CPDOMDisplayServerInstructions[index++] = nil;\
                                            CPDOMDisplayServerInstructions[index++] = nil;\
                                            break;\
                }\
            }\
            catch(e) { CPLog("e " + e + " " + instruction); }\
        }\
        CPDOMDisplayServerInstructionCount = 0;
#endif
