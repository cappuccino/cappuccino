/*
 *  SCString.j
 *
 *  Created by Aparajita on 8/9/10.
 *  Copyright Victory-Heart Productions 2010. All rights reserved.
*/

@import <Foundation/CPString.j>


@implementation SCString : CPObject

/*
    A string template engine.

    Long ago I was poking through the resources used by the Macintosh Finder and saw strings like this:

        The folder ^1 contains #2#no#^2# file|2||s|#2## for ^3 byte|3||s|#

    I realized they had created a meta-language to allow a single string to allow dynamic argument
    substitution and express two types of linguistic variations:

        - Zero/non-zero
        - Singular/plural

    In most languages, the syntax changes based on those two factors. For example, let's suppose we want
    to tell users how many messages they have after logging in. In natural English,
    there are three distinct forms:

        - Zero:     "You have no messages"
        - Singular: "You have 1 message"
        - Plural:   "You have 7 messages"

    In French it would be something like this:

        - Zero:     "Vous n'avez aucun message"
        - Singular: "Vous avez 1 message"
        - Plural:   "Vous avez 7 messages"

    You could encode these linguistic rules in your code,
    but that doesn't work very well if you need to translate your application into languages
    that don't follow the same rules. Or you could just give up and do something like this:

        You have 0 message(s)

    If that solution doesn't satisfy you, then stringWithTemplate is the solution.

    stringWithTemplate is an Objective-J port of the meta-language used in the original Mac Finder,
    but with an extended and more familiar syntax.

    You apply one or more arguments to a template. Argument placeholders indicated by "$key" or "${key}"
    in the template are replaced with the corresponding replacement arguments. Replacement arguments
    can be passed in several ways:

        - You may pass one or more unnamed parameters following the last named parameter.
        - If there is only unnamed parameter and it is a CPDictionary, <key> should be the key in that dictionary.
        - If there is only unnamed parameter and it is an array, <key> should be a numeric, zero-based
          index into that array.
        - If there is only unnamed parameter and it is an object (but not a CPDictionary),
          <key> should be a property of that object.
        - Otherwise <key> should be a numeric, zero-based index of an unnamed parameter, with 0 being
          the first unnamed parameter, 1 the second, and so on.

    Note that because stringWithTemplate supports indexing, the <key> can be a number in addition to an identifier.
    If <key> does not exist in an argument dictionary or is out of the range of positional arguments,
    the argument placeholder is replaced with an empty string.

    When using the ${key} syntax for replacement parameters, you may add a format separated by a semicolon
    like this:

        ${key:format}

    If the replacement argument is a date and the Date object has had the function dateFormat()
    added to its prototype, then [argsDict objectForKey:key].dateFormat(format)
    is used to format it. One such dateFormat() function is available here:

        http://code.google.com/p/flexible-js-formatting/

    For the available date formats of this library, see:

        http://www.xaprb.com/articles/date-formatting-demo.html

    The formatting options of flexible-js-formatting are basically the same as the date() function in php:

        http://php.net/manual/en/function.date.php

    If the argument is not a date, the equivalent of:

        [SCKit stringWithFormat:format, [argsDict objectForKey:key]]

    is performed.

    For example:

        ${total:.2f}
        ${date:F j, Y}

    is the same as:

        [SCKit stringWithFormat:@"%.2f", [argsDict objectForKey:@"total"]]
        [argsDict objectForKey:@"date"].dateFormat("F j, Y")

    In addition to a format, you may also add a default value after a vertical bar:

        ${key|default}  or  ${key:format|default}

    The default is used if [argsDict objectForKey:key] evaluates to false, which means nil, an empty string, etc.

    Inline formats and defaults are nice, but the real power of stringWithTemplate is the meta-language that
    allows you to deal with linguistic rules and alternatives in a single template.
    In addition to argument replacement, you can specify alternate subsections of
    the template to be used. Which subsection is used depends on the value of the replacement arguments.
    Alternate subsections are marked in the form:

        <delim><key><delim><alt1><delim><alt2><delim>

    where <delim> is a delimiter character, <key> is in the same format as a replacement argument,
    <alt1> is the "true" choice, and <alt2> is the "false" choice. The delimiter characters are taken from the first
    two characters of the delimiters parameter in stringWithTemplate:delimiters:. If you use stringWithTemplate:
    or if the length of the delimiters < 2, the default delimiters are "#|".

    Three passes are made over the template:

        1. Zero/non-zero (false/true) subsections (<delim> == delimiters[0]) are matched. If [argsDict objectForKey:key]
           evaluates to zero, <alt1> is used, else <alt2> is used. An argument is considered zero if:
             - It is a number and == 0
             - !arg == true

        2. Singular/plural subsections (<delim> == delimiters[1]) are matched, and if [argsDict objectForKey:key]
           evaluates to 1, <alt1> is used, else <alt2> is used. An argument evaluates to 1 if:
             - It is a number and == 1
             - It is a string and can be converted to a number which == 1.0
             - It is an object with a length property which == 1

        3. Any occurrence of $key or ${key} is replaced with the corresponding replacement argument according
           to the rules stated above.

    IMPORTANT: Subsections with the same delimiter may not be nested.

    If all of the matching rules for a subsection fail, the entire subsection is replaced with an empty string.

    ESCAPING/CHANGING THE DELIMITERS
    If your template string uses one of the defaults delimiters ("#" or "|") or the key marker ("$")
    in its regular text, you have two options:

    - Precede the literal delimiter characters with backslashes
    - Change the delimiters by using stringWithTemplate:delimiters: instead of stringWithTemplate:
    - Use "$$" to represent a literal "$"

    EXAMPLES
    Let's look at some examples to see how we might use stringWithTemplate. We'll start with a simple example. We
    have a song object parsed from JSON for which we want to display the date it was composed and the name of the
    composer:

       var args = {composer:song.composer, date:song.dateComposed},
           text = [SCKit stringWithTemplate:@"Composed by $composer on $dateComposed", args]

       RESULT: "Composed by Pat Metheny on 2005-03-30"

    Simple enough. Now we want to format the date to be a little more friendly:

       text = [SCKit stringWithTemplate:@"Composed by $composer on ${dateComposed:F j, Y}", args];

       RESULT: "Composed by Pat Metheny on March 30, 2005"

    That's better. Now we want to translate it into French:

       text = [SCKit stringWithTemplate:@"Composée par $composer le ${dateComposed:j F, Y}", args];

       RESULT: "Composée par Pat Metheny le 30 March, 2005"

    Now we realize that that we may not know the composition date, in which case the date is nil.
    So we use the default value:

       text = [SCKit stringWithTemplate:@"Composed by $composer ${dateComposed:\\o\\n F j, Y|(date unknown)}", args];

       RESULT: "Composed by Pat Metheny (date unknown)"  # if dateComposed is nil

    Note that we backslash escaped the characters in "on" so they would not be interpreted as format
    characters.

    Now we want to add "and translated" if the song has a translation by the composer:

       var args = {composer:song.composer, date:song.dateComposed, translated:song.hasTranslation},
           template = @"Composed #translated##and translated #by $composer ${dateComposed:\o\n F j, Y|(date unknown)}",
           text = [SCKit stringWithTemplate:template, args];

    Note that we are using the zero/non-zero selector as a false/true selector in this case.

    Just for reference, here is how the template would look if you wanted to pass the arguments as positional
    arguments:

        var template = @"Composed #0##and translated #by $1 ${2:\o\n F j, Y|(date unknown)}",
            text = [SCKit stringWithTemplate:template, song.hasTranslation, song.composer, song.dateComposed];

    Finally, we find that sometimes we don't know the exact date of composition, but we know the month
    or year. In that case we have a text date like "February 1980". So our logic ends up like this:

        - If there is a text date, display that
        - If there is an exact date, format and display that
        - Otherwise display "(date unknown)"

    Here's how we encode all of this into the stringWithTemplate:

       var args = {
            composer:song.composer,
            date:song.dateComposed,
            textDate:song.textDate,
            translated:song.hasTranslation
       };

       var template = @"Composed #translated##and translated #by $composer " +
                      @"#textDate#${dateComposed:\o\n F j, Y|(date unknown)}#$textDate#",
           text = [SCKit stringWithTemplate:template, args];

    Now let's see how the singular/plural selector works. Returning to a variation on the first example at the top
    of this doc, we want to encode these three variations into a single template:

        You don't have any messages
        You have only 1 message
        You have 7 messages

    Here is the template:

       var template = @"You #count#don't ##have #count#any#|count|only ||$count# message|count||s|.",
           text = [SCKit stringWithTemplate:template, {count:messageCount};

    Let's break down the pattern:

       #count#don't ##
       If $count evaluates to zero, insert "don't ".

       #count#any#|count|only ||$count#
       Here we have a one selector and argument placeholder nested inside a zero selector.

       - The zero selector is evaluated first. If $count evaluates to zero, substitute "any",
         else substitute "|count|only ||$count".

       - Then the one selector is evaluated. If the zero selector returned "|count|only ||$count",
         that is parsed. If $count evaluates to 1, "only " is substituted, otherwise nothing.

       - Finally the argument placeholders are substituted.

       message|count||s|
       This is a common idiom for expressing singular/plural. If count evaluates to 1, add no
       suffix to "message", otherwise add "s" as a suffix to make it plural.

    To help you picture what is happening, let's view the steps of the transformation of the string given
    a count of zero, 1 and 7.

    count == 0

    1. Zero selector applied -> "You don't have any message|count||s|."
    2. One selector applied  -> "You don't have any messages."
    3. Arguments replaced    -> "You don't have any messages."

    count == 1

    1. Zero selector applied -> "You have |count|only ||$count message|count||s|."
    2. One selector applied  -> "You have only $count message."
    3. Arguments replaced    -> "You have only 1 message."

    count == 7

    1. Zero selector applied -> "You have |count|only ||$count message|count||s|."
    2. One selector applied  -> "You have $count messages."
    3. Arguments replaced    -> "You have only 7 messages."

    Hopefully that should be enough to give you an idea how to use stringWithTemplate. Enjoy!
*/
+ (id)stringWithTemplate:(CPString)template, ...
{
    var args = [template, SCKit.TemplateDefaultDelimiters];

    return SCKit.stringWithTemplate.apply(self, args.concat(Array.prototype.slice.call(arguments, 3)));
}

+ (id)stringWithTemplate:(CPString)template delimiters:(CPString)delimiters, ...
{
    var args = [template, delimiters];

    return SCKit.stringWithTemplate.apply(self, args.concat(Array.prototype.slice.call(arguments, 4)));
}

@end


SCKit = (function() {

    var my = {},

        // Template argument RE
        TemplateArgREPattern =
            '\\$' +                     // template argument indicator followed by...
            '(?:' +
                '(\\$)' +               // another arg indicator, indicating a literal
                '|(\\w+)' +             // or an identifer
                '|{' +                  // or the start of a braced identifier, followed by...
                    '(\\w+)' +          // an identifier
                    '(?::([^}|]+))?' +  //   followed by an optional format
                    '(?:\\|([^}]+))?' + //   followed by an optional default
                '}' +                   // end of braced identifier
                '|(\\S+)' +             // invalid stuff following arg indicator
            ')',

        TemplateArgRE = new RegExp(TemplateArgREPattern, "g"),

        // Tests for an integer or float
        DigitRE = new RegExp("^(?:\\d+|\\d*\\.\\d+)$");

    // Default subsection delimiters. The first character delimits zero/non-zero subsections,
    // the second character delimits singular/plural subsections.
    TemplateDefaultDelimiters = "#|";

    // Default argument delimiter
    TemplateDefaultArgDelimiter = "$";

    function _selectorReplace(text, selector, delimiter, argsDict)
    {
        // First see if the first part of the text is <identifier>#.
        // If not, continue the after leading delimiter.
        var re = new RegExp("^[" + delimiter + "](\\w+)[" + delimiter + "]"),
            match = re.exec(text);

        if (!match)
            return {text:delimiter, nextIndex:1};

        var identifier = match[1],
            valid = NO,
            lastChar = "",
            alternatives = ["", ""],
            haveAlternative = NO,
            lastIndex = match[0].length;

        // Now scan for the two alternatives
        for (var alternative = 0; alternative < 2; ++alternative)
        {
            for (; lastIndex < text.length; ++lastIndex)
            {
                var c = text.charAt(lastIndex);

                if (c === delimiter && lastChar !== "\\")
                {
                    ++lastIndex;
                    haveAlternative = YES;
                    break;
                }
                else if (c !== "\\")
                    alternatives[alternative] += c;

                lastChar = c;
            }

            // Make sure we didn't exhaust the source before finding the alternative.
            if (!haveAlternative)
                return {text:text, endIndex:text.length};
        }

        // Get the specified argument, convert to a string
        var arg = [argsDict objectForKey:identifier],
            type = typeof arg,
            result = nil;

        if (selector === 0)
        {
            var isZero;

            switch (type)
            {
                case "string":
                    if (arg.length === 0)
                        isZero = true;
                    else
                        isZero = DigitRE.test(arg) && parseFloat(arg) === 0;
                    break;

                case "number":
                    isZero = arg === 0;
                    break;

                case "boolean":
                    isZero = arg === false;
                    break;

                case "object":
                    isZero = arg === nil || (arg.hasOwnProperty("length") && arg.length === 0);
                    break;

                default:
                    result = "";
            }

            if (result === nil)
                result = isZero ? alternatives[0] : alternatives[1];
        }
        else
        {
            var isOne;

            switch (type)
            {
                case "string":
                    isOne = arg.length && DigitRE.test(arg) && parseFloat(arg) === 1;
                    break;

                case "number":
                    isOne = arg === 1;
                    break;

                case "boolean":
                    isOne = arg === true;
                    break;

                case "object":
                    isOne = arg !== nil && arg.hasOwnProperty("length") && arg.length === 1;
                    break;

                default:
                    result = "";
            }

            if (result === nil)
                result = isOne ? alternatives[0] : alternatives[1];
        }

        return {text:result, nextIndex:lastIndex};
    }

    // Helper function for replacing args
    function _convert(value, format, defaultValue)
    {
        if (!value)
            return defaultValue ? defaultValue : "";

        if (format)
        {
            if (value.constructor === Date)
            {
                if (Date.prototype.dateFormat)
                    return value.dateFormat(format);
                else
                    return value.toLocaleString();
            }
            else
            {
                format = "%" + format;
                return ObjectiveJ.sprintf(format, value);
            }
        }
        else
            return String(value, 10);
    }

    my.stringWithTemplate = function(/* CPString */ template, /* CPString */ delimiters, /* CPArray|CPDictionary */ args)
    {
        if (!template)
            return "";

        if (!delimiters || delimiters.length < 2)
            delimiters = TemplateDefaultDelimiters;

        // Normalize the arguments into a dictionary
        var argsDict = null,
            argsArray = [];

        if (arguments.length < 3)
            return "";

        if (arguments.length === 3)
        {
            var arg = arguments[2];

            if (arg.hasOwnProperty("isa"))
            {
                if ([arg isKindOfClass:[CPArray class]])
                    argsArray = arg;
                else if ([arg isKindOfClass:[CPDictionary class]])
                    argsDict = arg;
            }
            else if (arg.constructor === Array)
                argsArray = arg;
            else if (typeof(arg) === "object")
                argsDict = [CPDictionary dictionaryWithJSObject:arg];
            else
                argsArray = [arguments[2]];
        }
        else
        {
            argsArray = Array.prototype.slice.call(arguments, 2);
        }

        if (!argsDict)
        {
            if (argsArray.length === 0)
                return template;

            argsDict = @{};

            for (var i = 0; i < argsArray.length; ++i)
                [argsDict setObject:argsArray[i] forKey:String(i, 10)];
        }

        var text = template;

        // We have a zero/non-zero selector and one/non-one selector
        for (var selector = 0; selector <= 1; ++selector)
        {
            var delim = delimiters.charAt(selector),
                lastChar = "";

            for (var i = 0; i < text.length; ++i)
            {
                var c = text.charAt(i);

                if (c === delim)
                {
                    if (lastChar !== "\\")
                    {
                        var leftContext = text.slice(0, i),
                            rightContext = text.slice(i),
                            replacement = _selectorReplace(rightContext, selector, delim, argsDict);

                        text = leftContext + replacement.text + rightContext.slice(replacement.nextIndex);
                        i += replacement.text.length - 1;
                    }
                }
                else if (c === "\\")
                    text = text.slice(0, i) + text.slice(i + 1);

                lastChar = c;
            }
        }

        // Define as a closure so we can access argsDict
        var argReplace = function(str, escaped, named, braced, format, defaultValue, invalid)
        {
            named = named || braced;

            if (named)
                return _convert([argsDict objectForKey:named], format, defaultValue);

            if (escaped)
                return TemplateDefaultArgDelimiter;

            // FIXME: raise
            return "";
        };

        return text.replace(TemplateArgRE, argReplace);
    };

    return my;
}());
