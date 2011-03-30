/*
	font_info

	Copyright 2010 Aparajita Fishman
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#define resultFormat @"{\"familyName\":\"%@\", \"bold\":%@, \"italic\":%@, \"ascender\":%g, \"descender\":%g, \"lineHeight\":%g, \"width\":%g}"

enum {
	kErrInvalidArguments = 1,
	kErrInvalidFontName
};


int main(int argc, const char* argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
	int exitCode = 0;
	NSString* stringToMeasure = nil;

    // usage: fontinfo [-n] face [size [string]]

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
			}
			else
				exitCode = kErrInvalidArguments;
		}

		if (exitCode == 0)
		{
			CGFloat fontSize = 12;

			NSString* fontName = [NSString stringWithUTF8String:argv[nextArgument++]];

			if (argc > nextArgument)
				fontSize = atof(argv[nextArgument++]);

			if (fontSize > 0.0)
			{
				NSFont* font = [NSFont fontWithName:fontName size:fontSize];

				if (font)
				{
					if (argc > nextArgument)
						stringToMeasure = [NSString stringWithUTF8String:argv[nextArgument]];

					NSString* familyName = [font familyName];
					NSFontDescriptor* descriptor = [font fontDescriptor];
					NSFontSymbolicTraits traits = [descriptor symbolicTraits];
					BOOL isBold = traits & NSFontBoldTrait;
					BOOL isItalic = traits & NSFontItalicTrait;
					CGFloat ascender = [font ascender];
					CGFloat descender = [font descender];

					NSLayoutManager* layout = [NSLayoutManager new];
					CGFloat lineHeight = [layout defaultLineHeightForFont:font];
                    [layout release];

					CGFloat width = 0.0;

					if (stringToMeasure)
					{
						NSDictionary* attributes = [NSDictionary dictionaryWithObject:font forKey:NSFontAttributeName];
						NSAttributedString* attrString = [[NSAttributedString alloc] initWithString:stringToMeasure attributes:attributes];

						if (attrString)
							width = [attrString size].width;

                        [attrString release];
					}

					NSMutableString* result = [NSMutableString stringWithFormat:resultFormat,
												familyName,
												isBold ? @"true" : @"false", isItalic ? @"true" : @"false",
												ascender, descender, lineHeight,
												width];

					if (appendLineFeed)
						[result appendString:@"\n"];

					printf("%s", [result UTF8String]);
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
		}
	}
	else
	{
		exitCode = kErrInvalidArguments;
	}

    [pool drain];
    return exitCode;
}
