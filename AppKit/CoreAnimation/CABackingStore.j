/*
 * CABackingStore.j
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

@import "CGGeometry.j"
// REMOVED: @import "CPCompatibility.j" - Obsolete legacy compatibility layer removed.

// REMOVED: #define PIXEL(pixels) macro - Eliminated in favour of native inline string concatenation.

function CABackingStoreGetContext(aBackingStore)
{
	return aBackingStore.context;
}

// REMOVED: if (CPFeatureIsCompatible(CPHTMLCanvasFeature)) - HTMLCanvasElement is natively supported across modern targets. Legacy fallback block completely removed.
function CABackingStoreCreate()
{
	// MODERNIZED: Replaced legacy 'var' with block-scoped 'const' for immutable DOM reference.
	const DOMElement = document.createElement("canvas");

	DOMElement.style.position = "absolute";

	// FIXME: Consolidate drawImage to support this.
	return { context:DOMElement.getContext("2d"), buffer:DOMElement, _image:DOMElement };
}

function CABackingStoreSetSize(aBackingStore, aSize)
{
	// MODERNIZED: Replaced legacy 'var' with block-scoped 'const'.
	const buffer = aBackingStore.buffer;

	buffer.width = aSize.width;
	buffer.height = aSize.height;

	// MODERNIZED: Replaced macro expansion with native inline evaluation.
	buffer.style.width = aSize.width + "px";
	buffer.style.height = aSize.height + "px";
}

// REMOVED: Legacy else block utilizing CGBitmapGraphicsContextCreate due to guaranteed canvas support.
