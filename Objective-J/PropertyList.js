
var OBJECT_COUNT   = 0;

function generateObjectUID()
{
    return OBJECT_COUNT++;
}

function PropertyList()
{
    this._UID = generateObjectUID();
}

PropertyList.PLISTRE = /^\s*<\s*plist\s*>/i;
PropertyList.DTDRE = /^\s*<\?\s*xml\s+version\s*=\s*\"1.0\"[^>]*\?>\s*<\!DOCTYPE\s+plist\s+PUBLIC\s+\"-\/\/Apple(?:\sComputer)?\/\/DTD\s+PLIST\s+1.0\/\/EN\"\s+\"http:\/\/www\.apple\.com\/DTDs\/PropertyList-1\.0\.dtd\"\s*>/i;

PropertyList.FormatXMLDTD = "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">";
PropertyList.Format280NorthMagicNumber = "280NPLIST";

// Serialization Formats

PropertyList.FormatOpenStep         = 1,
PropertyList.FormatXML_v1_0         = 100,
PropertyList.FormatBinary_v1_0      = 200,
PropertyList.Format280North_v1_0    = -1000;

PropertyList.sniffedFormatOfString = function(/*String*/ aString)
{
    // If the string starts with the plist DTD
    if (aString.match(PropertyList.DTDRE))
        return PropertyList.FormatXML_v1_0;

    // If the string starts with <plist>...
    if (aString.match(PropertyList.PLISTRE))
        return PropertyList.FormatXML_v1_0;

    if (aString.substr(0, PropertyList.Format280NorthMagicNumber.length) === PropertyList.Format280NorthMagicNumber)
       return PropertyList.Format280North_v1_0;

    return null;
}

// Serialization

PropertyList.dataFromPropertyList = function(/*PropertyList*/ aPropertyList, /*Format*/ aFormat)
{
    return new Data(PropertyList.stringFromPropertyList(aPropertyList, aFormat));
}

PropertyList.stringFromPropertyList = function(/*PropertyList*/ aPropertyList, /*Format*/ aFormat)
{
    if (!aFormat)
        aFormat = PropertyList.Format280North_v1_0;

    var serializers = PropertyListSerializers[aFormat];

    return  serializers["start"]() +
            serializePropertyList(aPropertyList, serializers) +
            serializers["finish"]();
}

function serializePropertyList(/*PropertyList*/ aPropertyList, /*Object*/ serializers)
{
    var type = typeof aPropertyList,
        valueOf = aPropertyList.valueOf(),
        typeValueOf = typeof valueOf;

    if (type !== typeValueOf)
    {
        type = typeValueOf;
        aPropertyList = valueOf;
    }

    if (aPropertyList === true || aPropertyList === false)
        type = "boolean";
    
    else if (type === "number")
    {
        if (FLOOR(aPropertyList) === aPropertyList)
            type = "integer";
        else
            type = "real";
    }
    
    else if (type !== "string")
    {
        if (aPropertyList.slice)
            type = "array";
    
        else
            type = "dictionary";
    }

    return serializers[type](aPropertyList, serializers);
}

var PropertyListSerializers = { };

PropertyListSerializers[PropertyList.FormatXML_v1_0] =
{
    "start":        function()
                    {
                        return PropertyList.FormatXMLDTD + "<plist version = \"1.0\">";
                    },

    "finish":       function()
                    {
                        return "</plist>";
                    },

    "string":       function(/*String*/ aString)
                    {
                        return "<string>" + encodeHTMLComponent(aString) + "</string>";;
                    },

    "boolean" :     function(/*Boolean*/ aBoolean)
                    {
                        return aBoolean ? "<true/>" : "<false/>";
                    },

    "integer":      function(/*Integer*/ anInteger)
                    {
                        return "<integer>" + anInteger + "</integer>";
                    },

    "real":         function(/*Float*/ aFloat)
                    {
                        return "<real>" + anInteger + "</real>";
                    },

    "array":        function(/*Array*/ anArray, /*Object*/ serializers)
                    {
                        var index = 0,
                            count = anArray.length,
                            string = "<array>";

                        for (; index < count; ++index)
                            string += serializePropertyList(anArray[index], serializers);
    
                        return "</array>";
                    },

    "dictionary":   function(/*Dictionary*/ aDictionary, /*Object*/ serializers)
                    {
                        var keys = aDictionary._keys,
                            index = 0,
                            count = keys.length,
                            string = "<dict>";

                        for (; index < count; ++index)
                        {
                            var key = keys[index];

                            string += "<key>" + key.length + "</key>";
                            string += serializePropertyList(aDictionary.valueForKey(key), serializers);
                        }

                        return "</dict>";
                    }
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

PropertyListSerializers[PropertyList.Format280North_v1_0] =
{
    "start":        function()
                    {
                        return PropertyList.Format280NorthMagicNumber + ";1.0;";
                    },

    "finish":       function()
                    {
                        return "";
                    },

    "string" :      function(/*String*/ aString)
                    {
                        return STRING_MARKER + ';' + aString.length + ';' + aString;
                    },
    
    "boolean" :     function(/*Boolean*/ aBoolean)
                    {
                        return (aBoolean ? TRUE_MARKER : FALSE_MARKER) + ';';
                    },

    "integer":      function(/*Integer*/ anInteger)
                    {
                        var string = "" + anInteger;
    
                        return INTEGER_MARKER + ';' + string.length + ';' + string;
                    },

    "real":         function(/*Float*/ aFloat)
                    {
                        var string = "" + aFloat;
    
                        return FLOAT_MARKER + ';' + string.length + ';' + string;
                    },

    "array":        function(/*Array*/ anArray, /*Object*/ serializers)
                    {
                        var index = 0,
                            count = anArray.length,
                            string = ARRAY_MARKER + ';';

                        for (; index < count; ++index)
                            string += serializePropertyList(anArray[index], serializers);
    
                        return string + END_MARKER + ';';
                    },

    "dictionary":   function(/*Dictionary*/ aDictionary, /*Object*/ serializers)
                    {
                        var keys = aDictionary._keys,
                            index = 0,
                            count = keys.length,
                            string = DICTIONARY_MARKER +';';

                        for (; index < count; ++index)
                        {
                            var key = keys[index];

                            string += KEY_MARKER + ';' + key.length + ';' + key;
                            string += serializePropertyList(aDictionary.valueForKey(key), serializers);
                        }

                        return string + END_MARKER + ';';
                    }
}

// Deserialization

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
    PLIST_NUMBER_INTEGER    = "integer",
    PLIST_DATA              = "data";

#define NODE_NAME(anXMLNode)        (String(anXMLNode.nodeName))
#define NODE_TYPE(anXMLNode)        (anXMLNode.nodeType)
#define NODE_VALUE(anXMLNode)       (String(anXMLNode.nodeValue))
#define FIRST_CHILD(anXMLNode)      (anXMLNode.firstChild)
#define NEXT_SIBLING(anXMLNode)     (anXMLNode.nextSibling)
#define PARENT_NODE(anXMLNode)      (anXMLNode.parentNode)
#define DOCUMENT_ELEMENT(aDocument) (aDocument.documentElement)

#define IS_OF_TYPE(anXMLNode, aType) (NODE_NAME(anXMLNode) === aType)
#define IS_PLIST(anXMLNode) IS_OF_TYPE(anXMLNode, PLIST_PLIST)

#define IS_WHITESPACE(anXMLNode) (NODE_TYPE(anXMLNode) === 8 || NODE_TYPE(anXMLNode) === 3)
#define IS_DOCUMENTTYPE(anXMLNode) (NODE_TYPE(anXMLNode) === 10)

#define PLIST_NEXT_SIBLING(anXMLNode) while ((anXMLNode = NEXT_SIBLING(anXMLNode)) && IS_WHITESPACE(anXMLNode)) ;
#define PLIST_FIRST_CHILD(anXMLNode) anXMLNode = FIRST_CHILD(anXMLNode); if (anXMLNode !== null && IS_WHITESPACE(anXMLNode)) PLIST_NEXT_SIBLING(anXMLNode)

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
    if (NODE_NAME(anXMLNode) === PLIST_ARRAY || NODE_NAME(anXMLNode) === PLIST_DICTIONARY)
        stack.pop();
    
    // If not, next check whether it has a sibling.
    else
    {
        if (node === stayWithin)
            return null;
        
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
        if (stayWithin && node === stayWithin)
            return null;
        
        // Pop the stack if we have officially "moved up"
        stack.pop();
    }
        
    return null;
}

PropertyList.propertyListFromData = function(/*Data*/ aData)
{
    return PropertyList.propertyListFromString(aData.encodedString(), aFormat);
}

PropertyList.propertyListFromString = function(/*String*/ aString, /*Format*/ aFormat)
{
    if (!aFormat)
        aFormat = PropertyList.sniffedFormatOfString(aString);

    if (aFormat === PropertyList.FormatXML_v1_0)
        return PropertyList.propertyListFromXML(aString);

    if (aFormat === PropertyList.Format280North_v1_0)
        return propertyListFrom280NorthString(aString);

    return null;
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

function propertyListFrom280NorthString(/*String*/ aString)
{
    var stream = new MarkedStream(aString),
    
        marker = NULL,
        
        key = "",
        object = NULL,
        plistObject = NULL,
        
        containers = [],
        currentContainer = NULL;

    while (marker = stream.getMarker())
    {
        if (marker === END_MARKER)
        {
            containers.pop();
            continue;
        }
        
        var count = containers.length;
        
        if (count)
            currentContainer = containers[count - 1];
        
        if (marker === KEY_MARKER)
        {
            key = stream.getString();
            marker = stream.getMarker();
        }

        switch (marker)
        {
            case ARRAY_MARKER:      object = []
                                    containers.push(object);
                                    break;
            case DICTIONARY_MARKER: object = new MutableDictionary();
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
                currentContainer.setValueForKey(key, object);
    }
    
    return plistObject;
}

function encodeHTMLComponent(/*String*/ aString)
{
    return aString.replace(/&/g,'&amp;').replace(/"/g, '&quot;').replace(/'/g, '&apos;').replace(/</g,'&lt;').replace(/>/g,'&gt;');
}

function decodeHTMLComponent(/*String*/ aString)
{
    return aString.replace(/&quot;/g, '"').replace(/&apos;/g, '\'').replace(/&lt;/g,'<').replace(/&gt;/g,'>').replace(/&amp;/g,'&');
}

PropertyList.propertyListFromXML = function(/*String | XMLNode*/ aStringOrXMLNode)
{
    var XMLNode = aStringOrXMLNode;

    if (typeof aStringOrXMLNode.valueOf() === "string")
    {
        if (window.DOMParser)
            XMLNode = DOCUMENT_ELEMENT(new window.DOMParser().parseFromString(aStringOrXMLNode, "text/xml"));

        else
        {
            XMLNode = new ActiveXObject("Microsoft.XMLDOM");

            if (aStringOrXMLNode.substr(0, PropertyList.DTD.length) === PropertyList.DTD)
                aStringOrXMLNode = aStringOrXMLNode.substr(PropertyList.DTD.length);

            XMLNode.loadXML(aStringOrXMLNode);
        }
    }

    // Skip over DOCTYPE and so forth.
    while (IS_OF_TYPE(XMLNode, XML_DOCUMENT) || IS_OF_TYPE(XMLNode, XML_XML))
        PLIST_FIRST_CHILD(XMLNode);
    
    // Skip over the DOCTYPE... see a pattern?
    if (IS_DOCUMENTTYPE(XMLNode))
        PLIST_NEXT_SIBLING(XMLNode);
    
    // If this is not a PLIST, bail.
    if (!IS_PLIST(XMLNode))
        return null;

    var key = "",
        object = null,
        plistObject = null,
        
        plistNode = XMLNode,
        
        containers = [],
        currentContainer = null;
    
    while (XMLNode = _plist_traverseNextNode(XMLNode, plistNode, containers))
    {
        var count = containers.length;
        
        if (count)
            currentContainer = containers[count - 1];
            
        if (NODE_NAME(XMLNode) === PLIST_KEY)
        {
            key = CHILD_VALUE(XMLNode);
            PLIST_NEXT_SIBLING(XMLNode);
        }

        switch (String(NODE_NAME(XMLNode)))
        {
            case PLIST_ARRAY:           object = []
                                        containers.push(object);
                                        break;
            case PLIST_DICTIONARY:      object = new MutableDictionary();
                                        containers.push(object);
                                        break;
            
            case PLIST_NUMBER_REAL:     object = parseFloat(CHILD_VALUE(XMLNode));
                                        break;
            case PLIST_NUMBER_INTEGER:  object = parseInt(CHILD_VALUE(XMLNode));
                                        break;
                                        
            case PLIST_STRING:          object = decodeHTMLComponent(FIRST_CHILD(XMLNode) ? CHILD_VALUE(XMLNode) : "");
                                        break;
                                        
            case PLIST_BOOLEAN_TRUE:    object = true;
                                        break;
            case PLIST_BOOLEAN_FALSE:   object = false;
                                        break;
                                        
            case PLIST_DATA:            object = new MutableData();
                                        object.bytes = FIRST_CHILD(XMLNode) ? base64_decode_to_array(CHILD_VALUE(XMLNode), true) : [];
                                        break;
                                        
            default:                    throw new Error("*** " + NODE_NAME(XMLNode) + " tag not recognized in Plist.");
        }

        if (!plistObject)
            plistObject = object;
            
        else if (currentContainer)
            // If the container is an array...
            if (currentContainer.slice)
                currentContainer.push(object);
            else
                currentContainer.setValueForKey(key, object);
    }
    
    return plistObject;
}

exports.generateObjectUID = generateObjectUID;
exports.PropertyList = PropertyList;

global.CFPropertyList = PropertyList;
global.CFPropertyListCreate = function()
{
    return new PropertyList();
}

global.kCFPropertyListOpenStepFormat        = PropertyList.FormatOpenStep;
global.kCFPropertyListXMLFormat_v1_0        = PropertyList.FormatXML_v1_0;
global.kCFPropertyListBinaryFormat_v1_0     = PropertyList.FormatBinary_v1_0;
global.kCFPropertyList280NorthFormat_v1_0   = PropertyList.Format280North_v1_0;

global.CFPropertyListCreateFromXMLData = function(/*Data*/ data)
{
    return PropertyList.createFromDataWithFormat(data, PropertyList.FormatXML_v1_0);
}

global.CFPropertyListCreateXMLData = function(/*PropertyList*/ aPropertyList)
{
    return aPropertyList.createDataWithFormat(PropertyList.FormatXML_v1_0);
}

global.CFPropertyListCreateFrom280NorthData = function(/*Data*/ data)
{
    return PropertyList.createFromDataWithFormat(data, PropertyList.Format280North_v1_0);
}

global.CFPropertyListCreate280NorthData = function(/*PropertyList*/ aPropertyList)
{
    return aPropertyList.createDataWithFormat(PropertyList.Format280North_v1_0);
}

global.CPPropertyListCreateFromXMLData      = CFPropertyListCreateFromXMLData;
global.CPPropertyListCreateXMLData          = CFPropertyListCreateXMLData;
global.CPPropertyListCreateFrom280NorthData = CFPropertyListCreateFrom280NorthData;
global.CPPropertyListCreate280NorthData     = CFPropertyListCreate280NorthData;

global.CPPropertyListCreateFromData = function(/*PropertyList*/ aPropertyList)
{
    return PropertyList.createFromDataWithFormat(aPropertyList);
}

global.CPPropertyListCreateData = function(/*PropertyList*/ aPropertyList)
{
    return aPropertyList.createDataWithFormat(aPropertyList)
}
