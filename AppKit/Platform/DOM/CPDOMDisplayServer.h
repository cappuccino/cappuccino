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
    
//#dfeine CPDOMDisplayServerCustomAction()

#define CPDOMDisplayServerAddView(aView)\
    {\
        var ___hash = [aView hash];\
        if (typeof (CPDOMDisplayServerViewsContext[___hash]) == "undefined")\
        {\
            CPDOMDisplayServerViews[CPDOMDisplayServerViewsCount++] = aView;\
            CPDOMDisplayServerViewsContext[___hash] = aView;\
        }\
    }\

#define CPDOMDisplayServerRemoveView(aView)\
    {\
        var index = CPDOMDisplayServerViewsContext[[aView hash]];\
        if (typeof index != "undefined") \
        {\
            CPDOMDisplayServerViewsContext[[aView hash]];\
            CPDOMDisplayServerViews[index] = NULL;\
        }\
    }\

    