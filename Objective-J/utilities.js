// sprintf:

var _sprintfFormatRegex = new RegExp("([^%]+|%[\\+\\-\\ \\#0]*[0-9\\*]*(.[0-9\\*]+)?[hlL]?[cbBdieEfgGosuxXpn%@])", "g");
var _sprintfTagRegex = new RegExp("(%)([\\+\\-\\ \\#0]*)([0-9\\*]*)((.[0-9\\*]+)?)([hlL]?)([cbBdieEfgGosuxXpn%@])");

function sprintf(format)
{
    var format = arguments[0],
        tokens = format.match(_sprintfFormatRegex),
        index = 0,
        result = "",
        arg = 1;

    for (var i = 0; i < tokens.length; i++)
    {
        var t = tokens[i];
        if (format.substring(index, index + t.length) != t)
        {
            return result;
        }
        index += t.length;

        if (t.charAt(0) != "%")
        {
            result += t;
        }
        else
        {
            var subtokens = t.match(_sprintfTagRegex);
            if (subtokens.length != 8 || subtokens[0] != t)
            {
                return result;
            }

            var percentSign     = subtokens[1],
                flags           = subtokens[2],
                widthString     = subtokens[3],
                precisionString = subtokens[4],
                length          = subtokens[6],
                specifier       = subtokens[7];

            var width = null;
            if (widthString == "*")
                width = arguments[arg++];
            else if (widthString != "")
                width = Number(widthString);

            var precision = null;
            if (precisionString == ".*")
                precision = arguments[arg++];
            else if (precisionString != "")
                precision = Number(precisionString.substring(1));

            var leftJustify = (flags.indexOf("-") >= 0);
            var padZeros    = (flags.indexOf("0") >= 0);

            var subresult = "";

            if (RegExp("[bBdiufeExXo]").test(specifier))
            {
                var num = Number(arguments[arg++]);

                var sign = "";
                if (num < 0)
                {
                    sign = "-";
                }
                else
                {
                    if (flags.indexOf("+") >= 0)
                        sign = "+";
                    else if (flags.indexOf(" ") >= 0)
                        sign = " ";
                }

                if (specifier == "d" || specifier == "i" || specifier == "u")
                {
                    var number = String(Math.abs(Math.floor(num)));

                    subresult = _sprintf_justify(sign, "", number, "", width, leftJustify, padZeros)
                }

                if (specifier == "f")
                {
                    var number = String((precision != null) ? Math.abs(num).toFixed(precision) : Math.abs(num));
                    var suffix = (flags.indexOf("#") >= 0 && number.indexOf(".") < 0) ? "." : "";

                    subresult = _sprintf_justify(sign, "", number, suffix, width, leftJustify, padZeros);
                }

                if (specifier == "e" || specifier == "E")
                {
                    var number = String(Math.abs(num).toExponential(precision != null ? precision : 21));
                    var suffix = (flags.indexOf("#") >= 0 && number.indexOf(".") < 0) ? "." : "";

                    subresult = _sprintf_justify(sign, "", number, suffix, width, leftJustify, padZeros);
                }

                if (specifier == "x" || specifier == "X")
                {
                    var number = String(Math.abs(num).toString(16));
                    var prefix = (flags.indexOf("#") >= 0 && num != 0) ? "0x" : "";

                    subresult = _sprintf_justify(sign, prefix, number, "", width, leftJustify, padZeros);
                }

                if (specifier == "b" || specifier == "B")
                {
                    var number = String(Math.abs(num).toString(2));
                    var prefix = (flags.indexOf("#") >= 0 && num != 0) ? "0b" : "";

                    subresult = _sprintf_justify(sign, prefix, number, "", width, leftJustify, padZeros);
                }

                if (specifier == "o")
                {
                    var number = String(Math.abs(num).toString(8));
                    var prefix = (flags.indexOf("#") >= 0 && num != 0) ? "0" : "";

                    subresult = _sprintf_justify(sign, prefix, number, "", width, leftJustify, padZeros);
                }

                if (RegExp("[A-Z]").test(specifier))
                    subresult = subresult.toUpperCase();
                else
                    subresult = subresult.toLowerCase();
            }
            else
            {
                var subresult = "";

                if (specifier == "%")
                    subresult = "%";
                else if (specifier == "c")
                    subresult = String(arguments[arg++]).charAt(0);
                else if (specifier == "s" || specifier == "@")
                    subresult = String(arguments[arg++]);
                else if (specifier == "p" || specifier == "n")
                {
                    arg++;
                    subresult = "";
                }

                subresult = _sprintf_justify("", "", subresult, "", width, leftJustify, false);
            }

            result += subresult;
        }
    }
    return result;
}

var _sprintf_justify = function(sign, prefix, string, suffix, width, leftJustify, padZeros)
{
    var length = (sign.length + prefix.length + string.length + suffix.length);
    if (leftJustify)
    {
        return sign + prefix + string + suffix + _sprintf_pad(width - length, " ");
    }
    else
    {
        if (padZeros)
            return sign + prefix + _sprintf_pad(width - length, "0") + string + suffix;
        else
            return _sprintf_pad(width - length, " ") + sign + prefix + string + suffix;
    }
}

var _sprintf_pad = function(n, ch)
{
    var result = "";
    for (var i = 0; i < n; i++)
        result += ch;
    return result;
}

// Base64 encoding and decoding

var base64_map_to = [
        "A","B","C","D","E","F","G","H","I","J","K","L","M","N","O","P","Q","R","S","T","U","V","W","X","Y","Z",
        "a","b","c","d","e","f","g","h","i","j","k","l","m","n","o","p","q","r","s","t","u","v","w","x","y","z",
        "0","1","2","3","4","5","6","7","8","9","+","/","="],
    base64_map_from = [];

for (var i = 0; i < base64_map_to.length; i++)
    base64_map_from[base64_map_to[i].charCodeAt(0)] = i;

function base64_decode_to_array(input, strip)
{
    if (strip)
        input = input.replace(/[^A-Za-z0-9\+\/\=]/g, "");
    
    var pad = (input[input.length-1] == "=" ? 1 : 0) + (input[input.length-2] == "=" ? 1 : 0),
        length = input.length,
        output = [];
    
    var i = 0;
    while (i < length)
    {
        var bits =  (base64_map_from[input.charCodeAt(i++)] << 18) |
                    (base64_map_from[input.charCodeAt(i++)] << 12) |
                    (base64_map_from[input.charCodeAt(i++)] << 6) |
                    (base64_map_from[input.charCodeAt(i++)]);
                    
        output.push((bits & 0xFF0000) >> 16);
        output.push((bits & 0xFF00) >> 8);
        output.push(bits & 0xFF);
    }
    
    // strip "=" padding from end
    if (pad > 0)
        return output.slice(0, -1 * pad);
    
    return output;
}

function base64_encode_array(input)
{
    var pad = (3 - (input.length % 3)) % 3,
        length = input.length + pad,
        output = [];
    
    // pad with nulls
    if (pad > 0) input.push(0);
    if (pad > 1) input.push(0);
    
    var i = 0;
    while (i < length)
    {
        var bits =  (input[i++] << 16) |
                    (input[i++] << 8)  |
                    (input[i++]);
                    
        output.push(base64_map_to[(bits & 0xFC0000) >> 18]);
        output.push(base64_map_to[(bits & 0x3F000) >> 12]);
        output.push(base64_map_to[(bits & 0xFC0) >> 6]);
        output.push(base64_map_to[bits & 0x3F]);
    }

    // pad with "=" and revert array to previous state
    if (pad > 0)
    {
        output[output.length-1] = "=";
        input.pop();
    }
    if (pad > 1)
    {
        output[output.length-2] = "=";
        input.pop();
    }

    return output.join("");
}

function base64_decode_to_string(input, strip)
{
    return bytes_to_string(base64_decode_to_array(input, strip));
}

function bytes_to_string(bytes)
{
    // This is relatively efficient, I think:
    return String.fromCharCode.apply(null, bytes);
}

function base64_encode_string(input)
{
    var temp = [];
    for (var i = 0; i < input.length; i++)
        temp.push(input.charCodeAt(i));

    return base64_encode_array(temp);
}
