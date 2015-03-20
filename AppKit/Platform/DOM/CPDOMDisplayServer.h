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

#define CPDOMDisplayServerSetStyleBackgroundSize(aDOMElement, aWidth, aHeight)\
    aDOMElement.style.backgroundSize = aWidth + ' ' + aHeight;

#define CPDOMDisplayServerAppendChild(aParentElement, aChildElement) \
    aParentElement.appendChild(aChildElement);

#define CPDOMDisplayServerInsertBefore(aParentElement, aChildElement, aBeforeElement) \
    aParentElement.insertBefore(aChildElement, aBeforeElement);

#define CPDOMDisplayServerRemoveChild(aParentElement, aChildElement) \
    aParentElement.removeChild(aChildElement);

#define PREPARE_DOM_OPTIMIZATION()
#define EXECUTE_DOM_INSTRUCTIONS()
