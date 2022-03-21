/*
    imagesize

    Copyright 2012 Aparajita Fishman
*/

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>


enum {
    kErrInvalidArguments = 1,
    kErrInvalidPath
};


int getImageSize(const char* utf8Path, BOOL appendLineFeed)
{
	NSString* path = [NSString stringWithUTF8String:utf8Path];
	NSImage* image = [[NSImage alloc] initWithContentsOfFile:path];
	
	if (!image)
		return kErrInvalidPath;
		
    NSArray *representations = [image representations];

    if ([representations count] == 0)
        return kErrInvalidPath;

    NSImageRep *representation = representations[0];
    NSInteger width  = [representation pixelsWide];
    NSInteger height = [representation pixelsHigh];

    NSMutableString* result = [NSMutableString stringWithFormat:@"{\"width\":%ld, \"height\":%ld}", (long)width, (long)height];

	if (appendLineFeed)
		[result appendString:@"\n"];

	printf("%s", [result UTF8String]);	
	return 0;
}


int main(int argc, const char* argv[])
{
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int exitCode = 0;

    // usage: imagesize [-n] path

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
			exitCode = getImageSize(argv[nextArgument], appendLineFeed);
	}
    else
    {
        exitCode = kErrInvalidArguments;
    }

    [pool drain];
    return exitCode;
}

