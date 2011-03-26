/*
	font_info

	Copyright 2010 Aparajita Fishman
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

enum {
	kErrInvalidArguments = 1,
	kErrInvalidFontName
};


int main (int argc, const char * argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	int exitCode = 0;

    if (argc >= 2)
	{
		BOOL appendLineFeed = YES;
		int nextArgument = 1;

		if (argv[1][0] == '-')
		{
			if (argv[1][1] == 'n')
			{
				appendLineFeed = NO;
				++nextArgument;
				--argc;
			}
			else
				exitCode = kErrInvalidArguments;
		}

		if (exitCode == 0)
		{
			CGFloat fontSize = 12;

			NSString* fontName = [NSString stringWithUTF8String:argv[nextArgument++]];

			if (argc > 2)
				fontSize = atof(argv[nextArgument]);

			if (fontSize > 0.0)
			{
				NSFont* font = [NSFont fontWithName:fontName size:fontSize];

				if (font)
				{
					NSString* familyName = [font familyName];
					NSFontDescriptor* descriptor = [font fontDescriptor];
					NSFontSymbolicTraits traits = [descriptor symbolicTraits];
					BOOL isBold = traits & NSFontBoldTrait;
					BOOL isItalic = traits & NSFontItalicTrait;
					CGFloat ascender = [font ascender];
					CGFloat descender = [font descender];
					NSRect box = [font boundingRectForFont];
					NSMutableString* result = [NSMutableString stringWithFormat:@"{\"familyName\": \"%@\", \"bold\": %@, \"italic\": %@, \"ascender\": %g, \"descender\": %g, \"lineHeight\": %g}",
												familyName,
												isBold ? @"true" : @"false", isItalic ? @"true" : @"false",
												ascender, descender, box.size.height];

					if (appendLineFeed)
						[result appendString:@"\n"];

					printf("%s", [result UTF8String]);

					[familyName release];
					[font release];
				}
				else
				{
					exitCode = kErrInvalidFontName;
				}
			}
			else
			{
				exitCode = kErrInvalidArguments;
			}

			[fontName release];
		}
	}
	else
	{
		exitCode = kErrInvalidArguments;
	}

    [pool drain];
    return exitCode;
}
