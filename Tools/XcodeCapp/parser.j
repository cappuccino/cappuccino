/*
 * parser.j
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

@import <Foundation/Foundation.j>

var FILE = require("file");

function main(args)
{
    var fileURL = new CFURL(args[1]),
        outputURL = new CFURL(args[2]),
        source = FILE.read(fileURL, { charset: "UTF-8" }),
        flags = ObjectiveJ.Preprocessor.Flags.IncludeDebugSymbols |
                ObjectiveJ.Preprocessor.Flags.IncludeTypeSignatures,
        superClasses = { };

    source = ObjectiveJ.preprocess(source, fileURL, flags).code();

    source = source.replace(/objj_allocateClassPair\([a-zA-Z_$](\w|$)*/g, function(aString)
    {
        var superClassName = aString.substr("objj_allocateClassPair(".length);

        return "objj_allocateClassPair(\"" + superClassName + "\", CPObject";
    });

    var allocateClassPair = objj_allocateClassPair;

    objj_allocateClassPair = function(superClassName)
    {
        superClasses[arguments[2]] = superClassName;
        return allocateClassPair(arguments[1], arguments[2]);
    }

    var classes = [],
        registerClassPair = objj_registerClassPair;

    objj_registerClassPair = function(aClass)
    {
        aClass.actual_super_class;
        registerClassPair(aClass);
        classes.push(aClass);
    }

    objj_executeFile = function()
    {
    }

    eval(source);

    var ObjectiveCSource = "";

    classes.forEach(function(aClass)
    {
        var outlets = [];

        class_copyIvarList(aClass).forEach(function(anIvar)
        {
            var types = ivar_getTypeEncoding(anIvar).split(" ");

            if (types.indexOf("IBOutlet") !== CPNotFound || types.indexOf("@outlet") !== CPNotFound)
            {
                types.forEach(function(aType, anIndex)
                {
                    if (aType === "@outlet")
                        types[anIndex] = "IBOutlet";

                    else if (aType !== "IBOutlet")
                        types[anIndex] = NSCompatibleClassName(aType, YES);
                });

                outlets.push("    " + types.join(" ") + " " + ivar_getName(anIvar) + ";");
            }
        });

        var actions = [];

        class_copyMethodList(aClass).forEach(function(aMethod)
        {
            var types = aMethod.types,
                type = types[0];

            if (type === "IBAction" || type === "@action")
                actions.push("- (IBAction)" + method_getName(aMethod) + "(" + NSCompatibleClassName(types[1] || "id", YES)+ ")aSender;");
        });

        var className = class_getName(aClass),
            superClassName = superClasses[className];

        ObjectiveCSource +=
            "\n@interface " + class_getName(aClass) +
            (superClassName === "Nil" ? "" : (" : " + NSCompatibleClassName(superClassName))) +
            "\n{\n" +
            outlets.join("\n") +
            "\n}\n" +
            actions.join("\n") +
            "\n@end";
    });

    if (ObjectiveCSource.length)
        FILE.write(outputURL, ObjectiveCSource, { charset:"UTF-8" });
}

function NSCompatibleClassName(aClassName, asPointer)
{
    if (aClassName === "var" || aClassName === "id")
        return "id";

    var suffix = aClassName.substr(0, 2),
        asterisk = asPointer ? "*" : "";

    if (suffix !== "CP")
        return aClassName + asterisk;

    var NSClassName = "NS" + aClassName.substr(2);

    if (NSClasses[NSClassName])
        return NSClassName + asterisk;

    return aClassName + asterisk;
}

var NSClasses = {
                    "NSAffineTransform" : YES,
                    "NSAppleEventDescriptor" : YES,
                    "NSAppleEventManager" : YES,
                    "NSAppleScript" : YES,
                    "NSArchiver" : YES,
                    "NSArray" : YES,
                    "NSAssertionHandler" : YES,
                    "NSAttributedString" : YES,
                    "NSAutoreleasePool" : YES,
                    "NSBlockOperation" : YES,
                    "NSBundle" : YES,
                    "NSCache" : YES,
                    "NSCachedURLResponse" : YES,
                    "NSCalendar" : YES,
                    "NSCharacterSet" : YES,
                    "NSClassDescription" : YES,
                    "NSCloneCommand" : YES,
                    "NSCloseCommand" : YES,
                    "NSCoder" : YES,
                    "NSComparisonPredicate" : YES,
                    "NSCompoundPredicate" : YES,
                    "NSCondition" : YES,
                    "NSConditionLock" : YES,
                    "NSConnection" : YES,
                    "NSCountCommand" : YES,
                    "NSCountedSet" : YES,
                    "NSCreateCommand" : YES,
                    "NSData" : YES,
                    "NSDate" : YES,
                    "NSDateComponents" : YES,
                    "NSDateFormatter" : YES,
                    "NSDecimalNumber" : YES,
                    "NSDecimalNumberHandler" : YES,
                    "NSDeleteCommand" : YES,
                    "NSDeserializer" : YES,
                    "NSDictionary" : YES,
                    "NSDirectoryEnumerator" : YES,
                    "NSDistantObject" : YES,
                    "NSDistantObjectRequest" : YES,
                    "NSDistributedLock" : YES,
                    "NSDistributedNotificationCenter" : YES,
                    "NSEnumerator" : YES,
                    "NSError" : YES,
                    "NSException" : YES,
                    "NSExistsCommand" : YES,
                    "NSExpression" : YES,
                    "NSFileHandle" : YES,
                    "NSFileManager" : YES,
                    "NSFileWrapper" : YES,
                    "NSFormatter" : YES,
                    "NSGarbageCollector" : YES,
                    "NSGetCommand" : YES,
                    "NSHashTable" : YES,
                    "NSHost" : YES,
                    "NSHTTPCookie" : YES,
                    "NSHTTPCookieStorage" : YES,
                    "NSHTTPURLResponse" : YES,
                    "NSIndexPath" : YES,
                    "NSIndexSet" : YES,
                    "NSIndexSpecifier" : YES,
                    "NSInputStream" : YES,
                    "NSInvocation" : YES,
                    "NSInvocationOperation" : YES,
                    "NSKeyedArchiver" : YES,
                    "NSKeyedUnarchiver" : YES,
                    "NSLocale" : YES,
                    "NSLock" : YES,
                    "NSLogicalTest" : YES,
                    "NSMachBootstrapServer" : YES,
                    "NSMachPort" : YES,
                    "NSMapTable" : YES,
                    "NSMessagePort" : YES,
                    "NSMessagePortNameServer" : YES,
                    "NSMetadataItem" : YES,
                    "NSMetadataQuery" : YES,
                    "NSMetadataQueryAttributeValueTuple" : YES,
                    "NSMetadataQueryResultGroup" : YES,
                    "NSMethodSignature" : YES,
                    "NSMiddleSpecifier" : YES,
                    "NSMoveCommand" : YES,
                    "NSMutableArray" : YES,
                    "NSMutableAttributedString" : YES,
                    "NSMutableCharacterSet" : YES,
                    "NSMutableData" : YES,
                    "NSMutableDictionary" : YES,
                    "NSMutableIndexSet" : YES,
                    "NSMutableSet" : YES,
                    "NSMutableString" : YES,
                    "NSMutableURLRequest" : YES,
                    "NSNameSpecifier" : YES,
                    "NSNetService" : YES,
                    "NSNetServiceBrowser" : YES,
                    "NSNotification" : YES,
                    "NSNotificationCenter" : YES,
                    "NSNotificationQueue" : YES,
                    "NSNull" : YES,
                    "NSNumber" : YES,
                    "NSNumberFormatter" : YES,
                    "NSObject" : YES,
                    "NSOperation" : YES,
                    "NSOperationQueue" : YES,
                    "NSOrthography" : YES,
                    "NSOutputStream" : YES,
                    "NSPipe" : YES,
                    "NSPointerArray" : YES,
                    "NSPointerFunctions" : YES,
                    "NSPort" : YES,
                    "NSPortCoder" : YES,
                    "NSPortMessage" : YES,
                    "NSPortNameServer" : YES,
                    "NSPositionalSpecifier" : YES,
                    "NSPredicate" : YES,
                    "NSProcessInfo" : YES,
                    "NSPropertyListSerialization" : YES,
                    "NSPropertySpecifier" : YES,
                    "NSProtocolChecker" : YES,
                    "NSProxy" : YES,
                    "NSPurgeableData" : YES,
                    "NSQuitCommand" : YES,
                    "NSRandomSpecifier" : YES,
                    "NSRangeSpecifier" : YES,
                    "NSRecursiveLock" : YES,
                    "NSRelativeSpecifier" : YES,
                    "NSRunLoop" : YES,
                    "NSScanner" : YES,
                    "NSScriptClassDescription" : YES,
                    "NSScriptCoercionHandler" : YES,
                    "NSScriptCommand" : YES,
                    "NSScriptCommandDescription" : YES,
                    "NSScriptExecutionContext" : YES,
                    "NSScriptObjectSpecifier" : YES,
                    "NSScriptSuiteRegistry" : YES,
                    "NSScriptWhoseTest" : YES,
                    "NSSerializer" : YES,
                    "NSSet" : YES,
                    "NSSetCommand" : YES,
                    "NSSocketPort" : YES,
                    "NSSocketPortNameServer" : YES,
                    "NSSortDescriptor" : YES,
                    "NSSpecifierTest" : YES,
                    "NSSpellServer" : YES,
                    "NSStream" : YES,
                    "NSString" : YES,
                    "NSTask" : YES,
                    "NSTextCheckingResult" : YES,
                    "NSThread" : YES,
                    "NSTimer" : YES,
                    "NSTimeZone" : YES,
                    "NSUnarchiver" : YES,
                    "NSUndoManager" : YES,
                    "NSUniqueIDSpecifier" : YES,
                    "NSURL" : YES,
                    "NSURLAuthenticationChallenge" : YES,
                    "NSURLCache" : YES,
                    "NSURLConnection" : YES,
                    "NSURLCredential" : YES,
                    "NSURLCredentialStorage" : YES,
                    "NSURLDownload" : YES,
                    "NSURLHandle" : YES,
                    "NSURLProtectionSpace" : YES,
                    "NSURLProtocol" : YES,
                    "NSURLRequest" : YES,
                    "NSURLResponse" : YES,
                    "NSUserDefaults" : YES,
                    "NSValue" : YES,
                    "NSValueTransformer" : YES,
                    "NSWhoseSpecifier" : YES,
                    "NSXMLDocument" : YES,
                    "NSXMLDTD" : YES,
                    "NSXMLDTDNode" : YES,
                    "NSXMLElement" : YES,
                    "NSXMLNode" : YES,
                    "NSXMLParser" : YES,
                                        "NSActionCell" : YES,
                    "NSAffineTransform Additions" : YES,
                    "NSAlert" : YES,
                    "NSAnimation" : YES,
                    "NSAnimationContext" : YES,
                    "NSAppleScript Additions" : YES,
                    "NSApplication" : YES,
                    "NSArrayController" : YES,
                    "NSATSTypesetter" : YES,
                    "NSAttributedString Application Kit Additions" : YES,
                    "NSBezierPath" : YES,
                    "NSBitmapImageRep" : YES,
                    "NSBox" : YES,
                    "NSBrowser" : YES,
                    "NSBrowserCell" : YES,
                    "NSBundle Additions" : YES,
                    "NSButton" : YES,
                    "NSButtonCell" : YES,
                    "NSCachedImageRep" : YES,
                    "NSCell" : YES,
                    "NSCIImageRep" : YES,
                    "NSClipView" : YES,
                    "NSCoder Application Kit Additions" : YES,
                    "NSCollectionView" : YES,
                    "NSCollectionViewItem" : YES,
                    "NSColor" : YES,
                    "NSColorList" : YES,
                    "NSColorPanel" : YES,
                    "NSColorPicker" : YES,
                    "NSColorSpace" : YES,
                    "NSColorWell" : YES,
                    "NSComboBox" : YES,
                    "NSComboBoxCell" : YES,
                    "NSControl" : YES,
                    "NSController" : YES,
                    "NSCursor" : YES,
                    "NSCustomImageRep" : YES,
                    "NSDatePicker" : YES,
                    "NSDatePickerCell" : YES,
                    "NSDictionaryController" : YES,
                    "NSDockTile" : YES,
                    "NSDocument" : YES,
                    "NSDocumentController" : YES,
                    "NSDrawer" : YES,
                    "NSEPSImageRep" : YES,
                    "NSEvent" : YES,
                    "NSFileWrapper" : YES,
                    "NSFont" : YES,
                    "NSFontDescriptor" : YES,
                    "NSFontManager" : YES,
                    "NSFontPanel" : YES,
                    "NSForm" : YES,
                    "NSFormCell" : YES,
                    "NSGlyphGenerator" : YES,
                    "NSGlyphInfo" : YES,
                    "NSGradient" : YES,
                    "NSGraphicsContext" : YES,
                    "NSHelpManager" : YES,
                    "NSImage" : YES,
                    "NSImageCell" : YES,
                    "NSImageRep" : YES,
                    "NSImageView" : YES,
                    "NSLayoutManager" : YES,
                    "NSLevelIndicator" : YES,
                    "NSLevelIndicatorCell" : YES,
                    "NSMatrix" : YES,
                    "NSMenu" : YES,
                    "NSMenuItem" : YES,
                    "NSMenuItemCell" : YES,
                    "NSMenuView" : YES,
                    "NSMutableAttributedString Additions" : YES,
                    "NSMutableParagraphStyle" : YES,
                    "NSNib" : YES,
                    "NSNibConnector" : YES,
                    "NSNibControlConnector" : YES,
                    "NSNibOutletConnector" : YES,
                    "NSObjectController" : YES,
                    "NSOpenGLContext" : YES,
                    "NSOpenGLLayer" : YES,
                    "NSOpenGLPixelBuffer" : YES,
                    "NSOpenGLPixelFormat" : YES,
                    "NSOpenGLView" : YES,
                    "NSOpenPanel" : YES,
                    "NSOutlineView" : YES,
                    "NSPageLayout" : YES,
                    "NSPanel" : YES,
                    "NSParagraphStyle" : YES,
                    "NSPasteboard" : YES,
                    "NSPasteboardItem" : YES,
                    "NSPathCell" : YES,
                    "NSPathComponentCell" : YES,
                    "NSPathControl" : YES,
                    "NSPDFImageRep" : YES,
                    "NSPersistentDocument" : YES,
                    "NSPICTImageRep" : YES,
                    "NSPopUpButton" : YES,
                    "NSPopUpButtonCell" : YES,
                    "NSPredicateEditor" : YES,
                    "NSPredicateEditorRowTemplate" : YES,
                    "NSPrinter" : YES,
                    "NSPrintInfo" : YES,
                    "NSPrintOperation" : YES,
                    "NSPrintPanel" : YES,
                    "NSProgressIndicator" : YES,
                    "NSResponder" : YES,
                    "NSRuleEditor" : YES,
                    "NSRulerMarker" : YES,
                    "NSRulerView" : YES,
                    "NSRunningApplication" : YES,
                    "NSSavePanel" : YES,
                    "NSScreen" : YES,
                    "NSScroller" : YES,
                    "NSScrollView" : YES,
                    "NSSearchField" : YES,
                    "NSSearchFieldCell" : YES,
                    "NSSecureTextField" : YES,
                    "NSSecureTextFieldCell" : YES,
                    "NSSegmentedCell" : YES,
                    "NSSegmentedControl" : YES,
                    "NSShadow" : YES,
                    "NSSlider" : YES,
                    "NSSliderCell" : YES,
                    "NSSound" : YES,
                    "NSSpeechRecognizer" : YES,
                    "NSSpeechSynthesizer" : YES,
                    "NSSpellChecker" : YES,
                    "NSSplitView" : YES,
                    "NSStatusBar" : YES,
                    "NSStatusItem" : YES,
                    "NSStepper" : YES,
                    "NSStepperCell" : YES,
                    "NSString Application Kit Additions" : YES,
                    "NSTableColumn" : YES,
                    "NSTableHeaderCell" : YES,
                    "NSTableHeaderView" : YES,
                    "NSTableView" : YES,
                    "NSTabView" : YES,
                    "NSTabViewItem" : YES,
                    "NSText" : YES,
                    "NSTextAttachment" : YES,
                    "NSTextAttachmentCell" : YES,
                    "NSTextBlock" : YES,
                    "NSTextContainer" : YES,
                    "NSTextField" : YES,
                    "NSTextFieldCell" : YES,
                    "NSTextInputContext" : YES,
                    "NSTextList" : YES,
                    "NSTextStorage" : YES,
                    "NSTextTab" : YES,
                    "NSTextTable" : YES,
                    "NSTextTableBlock" : YES,
                    "NSTextView" : YES,
                    "NSTokenField" : YES,
                    "NSTokenFieldCell" : YES,
                    "NSToolbar" : YES,
                    "NSToolbarItem" : YES,
                    "NSToolbarItemGroup" : YES,
                    "NSTouch" : YES,
                    "NSTrackingArea" : YES,
                    "NSTreeController" : YES,
                    "NSTreeNode" : YES,
                    "NSTypesetter" : YES,
                    "NSURL Additions" : YES,
                    "NSUserDefaultsController" : YES,
                    "NSView" : YES,
                    "NSViewAnimation" : YES,
                    "NSViewController" : YES,
                    "NSWindow" : YES,
                    "NSWindowController" : YES,
                    "NSWorkspace" : YES,
                    "NSPopover": YES
                };