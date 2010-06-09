//
//  Server.m
//  NativeHost
//
//  Created by Francisco Tolmasky on 8/18/09.
//  Copyright 2009 280 North, Inc.. All rights reserved.
//

#import "Server.h"
#import "AppController.h"

#import <sys/socket.h>
#import <netinet/in.h>

@implementation Server

- (BOOL)start
{
    NSBundle *mainBundle = [NSBundle mainBundle];
    NSString *serverPath = [mainBundle pathForResource:@"NativeHostServer" ofType:@"" inDirectory:@"Server"];

    if (!serverPath)
    {
        return YES;
    }

    // find an available port
    struct sockaddr_in addr;
    int sockfd;
	int attempts = 0;

	while (SERVER_PORT == 9191 && attempts++ < 5)
	{
		// Create a socket
		sockfd = socket( AF_INET, SOCK_STREAM, 0 );

		// Setup its address structure
		bzero( &addr, sizeof(struct sockaddr_in));
		addr.sin_family = AF_INET;
		addr.sin_addr.s_addr = htonl( INADDR_ANY );
		addr.sin_port = htons( 0 );

		// Bind it to an address and port
		bind( sockfd, (struct sockaddr *)&addr, sizeof(struct sockaddr));

		// Set it listening for connections
		listen( sockfd, 5 );

		// Find out what port the socket was bound to
		socklen_t namelen = sizeof(struct sockaddr_in);
		getsockname( sockfd, (struct sockaddr *)&addr, &namelen );

		if (addr.sin_port <= 1024)
			addr.sin_port = 9191;
		else
		    SERVER_PORT = addr.sin_port;

		shutdown(sockfd, 2);
	}
    
    if (SERVER_PASSWORD == nil)
    {
        CFUUIDRef uuidObj = CFUUIDCreate(nil);
        SERVER_PASSWORD = (NSString*)CFUUIDCreateString(nil, uuidObj);
        CFRelease(uuidObj);
    }

    if (SERVER_USER == nil)
    {
        CFUUIDRef uuidObj = CFUUIDCreate(nil);
        SERVER_USER = (NSString*)CFUUIDCreateString(nil, uuidObj);
        CFRelease(uuidObj);
        // usernames can't have "-" in them
        SERVER_USER = [[SERVER_USER autorelease] stringByReplacingOccurrencesOfString:@"-" withString:@""];
    }

    // setup environment variables
    NSDictionary *env = [[[NSProcessInfo processInfo] environment] mutableCopy];
    [env setValue:[mainBundle resourcePath] forKey:@"NATIVEHOST_RESOURCES"];
    [env setValue:[[NSNumber numberWithInt:SERVER_PORT] stringValue] forKey:@"NATIVEHOST_SERVER_PORT"];
    [env setValue:SERVER_USER forKey:@"NATIVEHOST_SERVER_USER"];
    [env setValue:SERVER_PASSWORD forKey:@"NATIVEHOST_SERVER_PASSWORD"];

    // create pipes for stdout and stderr
    NSPipe  * outputPipe = [NSPipe pipe];
    outputFile = [outputPipe fileHandleForReading];
    NSPipe  * errorPipe = [NSPipe pipe];
    errorFile = [errorPipe fileHandleForReading];

    // setup the process
    process = [[NSTask alloc] init];
    [process setLaunchPath:serverPath];
    [process setStandardOutput:outputPipe];
    [process setStandardError:errorPipe];
    [process setEnvironment:env];
    [env release];

    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(serverDidTerminate:) 
                                                 name:NSTaskDidTerminateNotification 
                                               object:process];

    [process launch];

    BOOL didStartup = NO;
    NSData * data = nil;

    while (!didStartup && (data = [outputFile availableData]) && [data length])
    {
        NSString * string = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (string)
        {
            NHLog(@"SERVER-OUT", string);

            didStartup = [string rangeOfString:@"Jack is starting up"].location != NSNotFound;

            [string release];
        }
    }
    NSLog(@"Server has started.");

    [[NSNotificationCenter defaultCenter]
        addObserver:self
          selector:@selector(didReadStdOut:)
              name:NSFileHandleReadCompletionNotification
            object:outputFile];

    [[NSNotificationCenter defaultCenter]
        addObserver:self
          selector:@selector(didReadStdErr:)
              name:NSFileHandleReadCompletionNotification
            object:errorFile];

    [outputFile readInBackgroundAndNotify];
    [errorFile readInBackgroundAndNotify];

    return didStartup;
}

- (void)stop
{
    [process terminate];
}

- (void)didReadStdOut:(NSNotification *)aNotification
{
    NSString * string = [[NSString alloc] initWithData:[[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem]
                                              encoding:NSASCIIStringEncoding];
    NHLog(@"SERVER-OUT", string);
    [string release];
    [outputFile readInBackgroundAndNotify];
}

- (void)didReadStdErr:(NSNotification *)aNotification
{
    NSString * string = [[NSString alloc] initWithData:[[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem]
                                              encoding:NSASCIIStringEncoding];
    NHLog(@"SERVER-ERR", string);
    [string release];
    [errorFile readInBackgroundAndNotify];
}

- (void)serverDidTerminate:(NSNotification *)note
{
    if ([process terminationStatus] != 0)
    {
        NSString *appName = [[[NSBundle mainBundle] localizedInfoDictionary] objectForKey:@"CFBundleDisplayName"];
        if (appName == nil)
            appName = [[NSProcessInfo processInfo] processName];

        if (SERVER_PORT != 9191 && [self start])
        {
            NSRunAlertPanel(@"Unexpected Error",
                [NSString stringWithFormat:@"%@ was not able to complete the last action you performed. Try again, and report the problem if it continues to occur.", appName],
                @"OK", nil, nil);
        }
        else
        {
            NSRunAlertPanel(@"Unexpected Error",
                [NSString stringWithFormat:@"A fatal error occurred. %@ could not recover and must terminate.", appName],
                @"Terminate", nil, nil);
            exit(1);
        }
    }
}

- (void)dealloc
{
    [process release];
    [super dealloc];
}

@end
