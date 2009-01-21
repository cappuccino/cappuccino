/*
 * plist.js
 * Objective-J
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

kCFPropertyListOpenStepFormat       = 1;
kCFPropertyListXMLFormat_v1_0       = 100;
kCFPropertyListBinaryFormat_v1_0    = 200;
kCFPropertyList280NorthFormat_v1_0  = -1000;

OBJJPlistParseException = "OBJJPlistParseException";
OBJJPlistSerializeException = "OBJJPlistSerializeException";

var kCFPropertyList280NorthMagicNumber  = "280NPLIST";

function objj_data()
{
    this.string         = "";
    this._plistObject   = NULL;
    this.bytes          = NULL;
    this.base64         = NULL;
}

var objj_markedStream = function(aString)
{
    var index = aString.indexOf(';');
    
    // Grab the magic number.
    this._magicNumber = aString.substr(0, index);
    
    this._location = aString.indexOf(';', ++index);

    // Grab the version number.
    this._version = aString.substring(index, this._location++);    
    this._string = aString;
}

objj_markedStream.prototype.magicNumber = function()
{
    return this._magicNumber;
}

objj_markedStream.prototype.version = function()
{
    return this._version;
}

objj_markedStream.prototype.getMarker = function()
{
    var string = this._string,
        location = this._location;
    
    if (location >= string.length)
        return NULL;
        
    var next = string.indexOf(';', location);
    
    if (next < 0)
        return NULL;
        
    var marker = string.substring(location, next);
    
    this._location = next + 1;

    return marker;
}

objj_markedStream.prototype.getString = function()
{
    var string = this._string,
        location = this._location;
    
    if (location >= string.length)
        return NULL;
        
    var next = string.indexOf(';', location);
    
    if (next < 0)
        return NULL;

    var size = parseInt(string.substring(location, next)),
        text = string.substr(next + 1, size);
    
    this._location = next + 1 + size;
    
    return text;
}

//

function CPPropertyListCreateData(aPlistObject, aFormat)
{
    if (aFormat == kCFPropertyListXMLFormat_v1_0)
        return CPPropertyListCreateXMLData(aPlistObject);

    if (aFormat == kCFPropertyList280NorthFormat_v1_0)
        return CPPropertyListCreate280NorthData(aPlistObject);

    return NULL;
}

function CPPropertyListCreateFromData(aData, aFormat)
{
    if (!aFormat)
    {
        // Attempt to guess the format.
        if (aData instanceof objj_data)
        {
            var string = aData.string ? aData.string : objj_msgSend(aData, "string");
            
            if (string.substr(0, kCFPropertyList280NorthMagicNumber.length) == kCFPropertyList280NorthMagicNumber)
                aFormat = kCFPropertyList280NorthFormat_v1_0;
            else
                aFormat = kCFPropertyListXMLFormat_v1_0;
        }
        else
            aFormat = kCFPropertyListXMLFormat_v1_0;
    }
    
    if (aFormat == kCFPropertyListXMLFormat_v1_0)
        return CPPropertyListCreateFromXMLData(aData);

    if (aFormat == kCFPropertyList280NorthFormat_v1_0)
        return CPPropertyListCreateFrom280NorthData(aData);

    return NULL;
}

var _CPPropertyListSerializeObject = function(aPlist, serializers)
{
    var type = typeof aPlist,
        valueOf = aPlist.valueOf(),
        typeValueOf = typeof valueOf;
    
    if (type != typeValueOf)
    {
        type = typeValueOf;
        aPlist = valueOf;
    }
    
    if (type == "string")
        return serializers["string"](aPlist, serializers);
    
    else if (aPlist === true || aPlist === false)
        return serializers["boolean"](aPlist, serializers);
    
    else if (type == "number")
    {
        var integer = FLOOR(aPlist);
        
        if (integer == aPlist)
            return serializers["integer"](aPlist, serializers);
        else
            return serializers["real"](aPlist, serializers);
    }
    
    else if (aPlist.slice)
        return serializers["array"](aPlist, serializers);
        
    else
        return serializers["dictionary"](aPlist, serializers);
}

// XML Format 1.0

var XML_XML                 = "xml",
    XML_DOCUMENT            = "#document",

    PLIST_PLIST             = "plist",
    PLIST_KEY               = "key",
    PLIST_DICTIONARY        = "dict",
    PLIST_ARRAY             = "array",
    PLIST_STRING            = "string",
    PLIST_BOOLEAN_TRUE      = "true",
    PLIST_BOOLEAN_FALSE     = "false",
    PLIST_NUMBER_REAL       = "real",
    PLIST_NUMBER_INTEGER    = "integer";
    PLIST_DATA              = "data";


#define NODE_NAME(anXMLNode)        (String(anXMLNode.nodeName))
#define NODE_TYPE(anXMLNode)        (anXMLNode.nodeType)
#define NODE_VALUE(anXMLNode)       (String(anXMLNode.nodeValue))
#define FIRST_CHILD(anXMLNode)      (anXMLNode.firstChild)
#define NEXT_SIBLING(anXMLNode)     (anXMLNode.nextSibling)
#define PARENT_NODE(anXMLNode)      (anXMLNode.parentNode)
#define DOCUMENT_ELEMENT(aDocument) (aDocument.documentElement)


#define IS_OF_TYPE(anXMLNode, aType) (NODE_NAME(anXMLNode) == aType)
#define IS_PLIST(anXMLNode) IS_OF_TYPE(anXMLNode, PLIST_PLIST)

#define IS_WHITESPACE(anXMLNode) (NODE_TYPE(anXMLNode) == 8 || NODE_TYPE(anXMLNode) == 3)
#define IS_DOCUMENTTYPE(anXMLNode) (NODE_TYPE(anXMLNode) == 10)

#define PLIST_NEXT_SIBLING(anXMLNode) while ((anXMLNode = NEXT_SIBLING(anXMLNode)) && IS_WHITESPACE(anXMLNode)) ;
#define PLIST_FIRST_CHILD(anXMLNode) anXMLNode = FIRST_CHILD(anXMLNode); if (anXMLNode != NULL && IS_WHITESPACE(anXMLNode)) PLIST_NEXT_SIBLING(anXMLNode)

// FIXME: no first child?
#define CHILD_VALUE(anXMLNode) (NODE_VALUE(FIRST_CHILD(anXMLNode)))

var _plist_traverseNextNode = function(anXMLNode, stayWithin, stack)
{
    var node = anXMLNode;
    
    PLIST_FIRST_CHILD(node);
    
    // If this element has a child, traverse to it.
    if (node)
        return node;
    
    // If not, first check if it is a container class (as opposed to a designated leaf).
    // If it is, then we have to pop this container off the stack, since it is empty.
    if (NODE_NAME(anXMLNode) == PLIST_ARRAY || NODE_NAME(anXMLNode) == PLIST_DICTIONARY)
        stack.pop();
    
    // If not, next check whether it has a sibling.
    else
    {
        if (node == stayWithin)
            return NULL;
        
        node = anXMLNode;
        
        PLIST_NEXT_SIBLING(node);
        
        if (node)
            return node; 
    }
    
    // If it doesn't, start working our way back up the node tree.
    node = anXMLNode;
    
    // While we have a node and it doesn't have a sibling (and we're within our stayWithin),
    // keep moving up.
    while (node)
    {
        var next = node;
        
        PLIST_NEXT_SIBLING(next);
        
        // If we have a next sibling, just go to it.
        if (next)
            return next;
            
        var node = PARENT_NODE(node);
            
        // If we are being asked to move up, and our parent is the stay within, then just 
        if (stayWithin && node == stayWithin)
            return NULL;
        
        // Pop the stack if we have officially "moved up"
        stack.pop();
    }
        
    return NULL;
}

function CPPropertyListCreateFromXMLData(XMLNodeOrData)
{
    var XMLNode = XMLNodeOrData;
    
    if (XMLNode.string)
    {
#if RHINO
        XMLNode = DOCUMENT_ELEMENT(_documentBuilder.parse(
            new Packages.org.xml.sax.InputSource(new Packages.java.io.StringReader(XMLNode.string))));
#else
        if (window.ActiveXObject)
        {
            XMLNode = new ActiveXObject("Microsoft.XMLDOM");
            XMLNode.loadXML(XMLNodeOrData.string.substr(XMLNodeOrData.string.indexOf(".dtd\">") + 6));
        }
        else
            XMLNode = DOCUMENT_ELEMENT(new DOMParser().parseFromString(XMLNodeOrData.string, "text/xml"));
#endif
    }

    // Skip over DOCTYPE and so forth.
    while (IS_OF_TYPE(XMLNode, XML_DOCUMENT) || IS_OF_TYPE(XMLNode, XML_XML))
        PLIST_FIRST_CHILD(XMLNode);
    
    // Skip over the DOCTYPE... see a pattern?
    if (IS_DOCUMENTTYPE(XMLNode))
        PLIST_NEXT_SIBLING(XMLNode);
    
    // If this is not a PLIST, bail.
    if (!IS_PLIST(XMLNode))
        return NULL;

    var key = "",
        object = NULL,
        plistObject = NULL,
        
        plistNode = XMLNode,
        
        containers = [],
        currentContainer = NULL;
    
    while (XMLNode = _plist_traverseNextNode(XMLNode, plistNode, containers))
    {
        var count = containers.length;
        
        if (count)
            currentContainer = containers[count - 1];
            
        if (NODE_NAME(XMLNode) == PLIST_KEY)
        {
            key = CHILD_VALUE(XMLNode);
            PLIST_NEXT_SIBLING(XMLNode);
        }

        switch (String(NODE_NAME(XMLNode)))
        {
            case PLIST_ARRAY:           object = []
                                        containers.push(object);
                                        break;
            case PLIST_DICTIONARY:      object = new objj_dictionary();
                                        containers.push(object);
                                        break;
            
            case PLIST_NUMBER_REAL:     object = parseFloat(CHILD_VALUE(XMLNode));
                                        break;
            case PLIST_NUMBER_INTEGER:  object = parseInt(CHILD_VALUE(XMLNode));
                                        break;
                                        
            case PLIST_STRING:          object = _decodeHTMLComponent(FIRST_CHILD(XMLNode) ? CHILD_VALUE(XMLNode) : "");
                                        break;
                                        
            case PLIST_BOOLEAN_TRUE:    object = true;
                                        break;
            case PLIST_BOOLEAN_FALSE:   object = false;
                                        break;
                                        
            case PLIST_DATA:            object = new objj_data();
                                        object.bytes = FIRST_CHILD(XMLNode) ? base64_decode_to_array(CHILD_VALUE(XMLNode), true) : [];
                                        break;
                                        
            default:                    objj_exception_throw(new objj_exception(OBJJPlistParseException, "*** " + NODE_NAME(XMLNode) + " tag not recognized in Plist."));
        }

        if (!plistObject)
            plistObject = object;
            
        else if (currentContainer)
            // If the container is an array...
            if (currentContainer.slice)
                currentContainer.push(object);
            else
                dictionary_setValue(currentContainer, key, object);
    }
    
    return plistObject;
}

function CPPropertyListCreateXMLData(aPlist)
{
    var data = new objj_data();
    
    data.string = "";
    
    data.string += "<?xml version=\"1.0\" encoding=\"UTF-8\"?>";
    data.string += "<!DOCTYPE plist PUBLIC \"-//Apple Computer//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">";
    data.string += "<plist version = \"1.0\">";
    
    _CPPropertyListAppendXMLData(data, aPlist, "");
    
    data.string += "</plist>";
    
    return data;
}

// CPPropertyListCreateXMLData Helper Functions

var _CPArrayAppendXMLData = function(XMLData, anArray)
{
    var i = 0,
        count = anArray.length;
    
    XMLData.string += "<array>";
    
    for (; i < count; ++i)
        _CPPropertyListAppendXMLData(XMLData, anArray[i]);
    
    XMLData.string += "</array>";
}

var _CPDictionaryAppendXMLData = function(XMLData, aDictionary)
{
    var keys = aDictionary._keys,
        i = 0,
        count = keys.length;
        
    XMLData.string += "<dict>";
        
    for (; i < count; ++i)
    {
        XMLData.string += "<key>" + keys[i] + "</key>";
        _CPPropertyListAppendXMLData(XMLData, dictionary_getValue(aDictionary, keys[i]));
    }
    
    XMLData.string += "</dict>";
}

var _encodeHTMLComponent = function(aString)
{
    return aString.replace('<', "&lt;").replace('>', "&gt;").replace('\"', "&quot;").replace('\'', "&apos;").replace('&', "&amp;");
}

var _decodeHTMLComponent = function(aString)
{
    return aString.replace("&lt;", '<').replace("&gt;", '>').replace("&quot;", '\"').replace("&apos;", '\'').replace("&amp;", '&');
}

var _CPPropertyListAppendXMLData = function(XMLData, aPlist)
{
    var type = typeof aPlist,
        valueOf = aPlist.valueOf(),
        typeValueOf = typeof valueOf;
    
    if (type != typeValueOf)
    {
        type = typeValueOf;
        aPlist = valueOf;
    }
    
    if (type == "string")
        XMLData.string += "<string>" + _encodeHTMLComponent(aPlist) + "</string>";
    
    else if (aPlist === true)
        XMLData.string += "<true/>";
    else if (aPlist === false)
        XMLData.string += "<false/>";
    
    else if (type == "number")
    {
        var integer = FLOOR(aPlist);
        
        if (integer == aPlist)
            XMLData.string += "<integer>" + aPlist + "</integer>";
        else
            XMLData.string += "<real>" + aPlist + "</real>";
    }
    
    else if (aPlist.slice)
        _CPArrayAppendXMLData(XMLData, aPlist);
        
    else if (aPlist._keys)
        _CPDictionaryAppendXMLData(XMLData, aPlist);
    else
        objj_exception_throw(new objj_exception(OBJJPlistSerializeException, "*** unknown plist ("+aPlist+") type: " + type));
        
}

// 280 North Plist Format

var ARRAY_MARKER        = "A",
    DICTIONARY_MARKER   = "D",
    FLOAT_MARKER        = "f",
    INTEGER_MARKER      = "d",
    STRING_MARKER       = "S",
    TRUE_MARKER         = "T",
    FALSE_MARKER        = "F",
    KEY_MARKER          = "K",
    END_MARKER          = "E";

function CPPropertyListCreateFrom280NorthData(aData)
{
    var stream = new objj_markedStream(aData.string),
    
        marker = NULL,
        
        key = "",
        object = NULL,
        plistObject = NULL,
        
        containers = [],
        currentContainer = NULL;

    while (marker = stream.getMarker())
    {
        if (marker == END_MARKER)
        {
            containers.pop();
            continue;
        }
        
        var count = containers.length;
        
        if (count)
            currentContainer = containers[count - 1];
        
        if (marker == KEY_MARKER)
        {
            key = stream.getString();
            marker = stream.getMarker();
        }

        switch (marker)
        {
            case ARRAY_MARKER:      object = []
                                    containers.push(object);
                                    break;
            case DICTIONARY_MARKER: object = new objj_dictionary();
                                    containers.push(object);
                                    break;
            
            case FLOAT_MARKER:      object = parseFloat(stream.getString());
                                    break;
            case INTEGER_MARKER:    object = parseInt(stream.getString());
                                    break;
                                        
            case STRING_MARKER:     object = stream.getString();
                                    break;
                                        
            case TRUE_MARKER:       object = true;
                                    break;
            case FALSE_MARKER:      object = false;
                                    break;
                                        
            default:                objj_exception_throw(new objj_exception(OBJJPlistParseException, "*** " + marker + " marker not recognized in Plist."));
        }

        if (!plistObject)
            plistObject = object;
            
        else if (currentContainer)
            // If the container is an array...
            if (currentContainer.slice)
                currentContainer.push(object);
            else
                dictionary_setValue(currentContainer, key, object);
    }
    
    return plistObject;
}

function CPPropertyListCreate280NorthData(aPlist)
{
    var data = new objj_data();
    
    data.string = kCFPropertyList280NorthMagicNumber + ";1.0;" + _CPPropertyListSerializeObject(aPlist, _CPPropertyList280NorthSerializers);
    
    return data;
}

var _CPPropertyList280NorthSerializers = {};

_CPPropertyList280NorthSerializers["string"] = function(aString)
{
    return STRING_MARKER + ';' + aString.length + ';' + aString;
}

_CPPropertyList280NorthSerializers["boolean"] = function(aBoolean)
{
    return (aBoolean ? TRUE_MARKER : FALSE_MARKER) + ';';
}

_CPPropertyList280NorthSerializers["integer"] = function(anInteger)
{
    var string = "" + anInteger;
    
    return INTEGER_MARKER + ';' + string.length + ';' + string;
}

_CPPropertyList280NorthSerializers["real"] = function(aFloat)
{
    var string = "" + aFloat;
    
    return FLOAT_MARKER + ';' + string.length + ';' + string;
}

_CPPropertyList280NorthSerializers["array"] = function(anArray, serializers)
{
    var index = 0,
        count = anArray.length,
        string = ARRAY_MARKER + ';';
    
    for (; index < count; ++index)
        string += _CPPropertyListSerializeObject(anArray[index], serializers);
    
    return string + END_MARKER + ';';
}

_CPPropertyList280NorthSerializers["dictionary"] = function(aDictionary, serializers)
{
    var keys = aDictionary._keys,
        index = 0,
        count = keys.length,
        string = DICTIONARY_MARKER +';';
        
    for (; index < count; ++index)
    {
        var key = keys[index];
        
        string += KEY_MARKER + ';' + key.length + ';' + key;
        string += _CPPropertyListSerializeObject(dictionary_getValue(aDictionary, key), serializers);
    }
    
    return string + END_MARKER + ';';
}
