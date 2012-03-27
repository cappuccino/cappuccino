#! /usr/bin/env ruby
#
# NOTE: The working directory should be the main capp directory when this script is run
#
# $1 Cappuccino documentation directory


ACCESSOR_GET_TEMPLATE = <<EOS
/*!
Synthesized accessor method.
*/
- (\#{ivarType})\#{getter}
{
    return \#{ivar};
}

EOS

ACCESSOR_SET_TEMPLATE = <<EOS
/*!
Synthesized accessor method.
*/
- (void)\#{setter}:(\#{ivarType})aValue
{
    \#{ivar} = aValue;
}

EOS

ACCESSORS_IMPLEMENTATION_TEMPLATE = <<EOS

@implementation \#{className} (CPSynthesizedAccessors)

\#{accessorsSource}@end
EOS

DUMMY_IVAR = "    id __doxygen__;"


def makeHeaderFileFrom(fileName)
    # Grab the entire file (text)
    sourceFile = File.new(fileName, "r")
    source = sourceFile.read
    sourceFile.close()

    # Add a @ before @implementation within comments so they are not considered as code
    source.gsub!(/(\/\*.*?\*\/)/m)  {|text| $1.gsub(/^(\s*)@implementation /, "\\1@@implementation ")}

    # If an implementation does not have an ivar block or an empty ivar block,
    # add one with a dummy ivar so that doxygen will parse the file correctly.
    source.gsub!(/^\s*(@implementation \s*\w+(?:\s*:\s*\w+)?)\n(\s*[^{])/, "\\1\n{\n#{DUMMY_IVAR}\n}\n\\2")
    source.gsub!(/^\s*(@implementation \s*\w+(?:\s*:\s*\w+)?)\n\s*\{\s*\}/, "\\1\n{\n#{DUMMY_IVAR}\n}")

    sourceFile = File.new(fileName, "w")

    # Remove @accessor declarations from ivars before writing the source file
    sourceFile.write(source.gsub(/(\s*\w+\s+\w+)\s+@accessors(\(.+?\))?;/m, "\\1;"))

    # Extract all the @implementations blocks. Note, there may be more than one in a given .j file.
    m = source.scan(/^\s*(@implementation\s*(\w+)\s*(?::\s*\w+)?)\s*(?:\{(.*?)\})?(.*?)^\s*@end\s*$/m)

    return if m.length == 0

    for i in 0...m.length
        groups = m[i]
        declaration = groups[0]
        className = groups[1]
        ivars = groups[2]

        # Change "implementation" to "interface", create the .h file, and write the interface
        interfaceDeclaration = declaration.sub("@implementation", "@interface")
        interfaceFileName = File.dirname(fileName) + "/" + className + ".h"
        interfaceFile = File.new(interfaceFileName, "a")

        # Everything after this is ivar processing
        next unless ivars

        # Change @accessors declarations to a comment, doxygen chokes on them
        strippedIvars = ivars.gsub("@accessors", "// @accessors")
        interfaceFile.write("\n#{interfaceDeclaration}\n{#{strippedIvars}}\n@end\n")

        # Skip @accessors if it's a private class
        next if className[0, 1] == "_"

        writeAccessors(className, ivars, sourceFile, interfaceFile)
    end

    sourceFile.close()

    sourceFile = File.new(fileName, "r")
    source = sourceFile.read
    sourceFile.close()

    # Restore @implementation within comments
    sourceFile = File.new(fileName, "w")
    source.gsub!(/(\/\*.*?\*\/)/m)  {|text| $1.gsub(/^(\s*)@@implementation /, "\\1@implementation ")}
    sourceFile.write(source)
    sourceFile.close()
end

def writeAccessors(className, ivars, sourceFile, interfaceFile)
    # See if there are any @accessors in the ivars
    accessorsMatches = ivars.scan(/\s*(\w+)\s+(\w+)\s+@accessors(\(.+?\))?;/m)
    return if accessorsMatches.length == 0

    accessorsSource = ""

    # Create a CPSynthesizedAccessor category for the class with synthesized
    # accessor methods for each @accessors declaration.
    for accessorIndex in 0...accessorsMatches.length
        ivarDeclaration = accessorsMatches[accessorIndex]
        attributes = ivarDeclaration[2]
        next if attributes.nil?
        ivarType = ivarDeclaration[0];
        ivar = ivarDeclaration[1];

        attributesMatch = attributes.scan(/(\bproperty\s*=\s*(\w+)|\b(readonly)\b|\bgetter\s*=\s*(\w+)|\bsetter\s*=\s*(\w+))/m)
        next if attributesMatch.length == 0

        getter = nil
        setter = nil
        readonly = false

        for attributeIndex in 0...attributesMatch.length
            if not attributesMatch[attributeIndex][1].nil?   # property
                getter = attributesMatch[attributeIndex][1]
                setter = readonly ? nil : "set#{getter[0,1].upcase}#{getter[1..-1]}"
            elsif not attributesMatch[attributeIndex][2].nil?   # readonly
                readonly = true
                setter = nil
            elsif not attributesMatch[attributeIndex][3].nil?   # getter
                getter = attributesMatch[attributeIndex][3]
            elsif not attributesMatch[attributeIndex][4].nil? and not readonly   # setter
                setter = attributesMatch[attributeIndex][4]
            end
        end

        # Check for @accessors with no attributes
        if getter.nil? and setter.nil?
            getter = ivar
            setter = "set#{getter[0,1].upcase}#{getter[1..-1]}"
        end

        accessorsSource += makeAccessors(getter, setter, ivar, ivarType)
    end

    sourceFile.write(eval('"' + ACCESSORS_IMPLEMENTATION_TEMPLATE + '"'))
end

def makeAccessors(getter, setter, ivar, ivarType)
    accessors = ""

    if not getter.nil?
        accessors += eval('"' + ACCESSOR_GET_TEMPLATE + '"')
    end

    if not setter.nil?
        accessors += eval('"' + ACCESSOR_SET_TEMPLATE + '"')
    end

    return accessors
end

print "\033[36mGenerating header files...\033[0m\n"
fileList = Dir['AppKit.doc/**/*.j'] + Dir['Foundation.doc/**/*.j']

for fileName in fileList
    makeHeaderFileFrom(fileName)
end
