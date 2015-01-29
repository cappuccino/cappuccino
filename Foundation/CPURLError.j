
/*
 *  The CPURL Error Domain
 */
CPURLErrorDomain =                      @"CPURLErrorDomain";

/*
 *  CPURL UserInfo Error Keys
 */
CPURLErrorFailingURLErrorKey =          @"CPErrorFailingURLKey";
CPURLErrorFailingURLStringErrorKey =    @"CPURLErrorFailingURLStringKey";

/*
 *  CPURL Error Codes
 */
CPURLErrorUnknown =                     -1;
CPURLErrorCancelled =                   kCFURLErrorCancelled;
CPURLErrorBadURL =                      kCFURLErrorBadURL;
CPURLErrorTimedOut =                    kCFURLErrorTimedOut;
CPURLErrorUnsupportedURL =              kCFURLErrorUnsupportedURL;
CPURLErrorCannotFindHost =              kCFURLErrorCannotFindHost;
CPURLErrorCannotConnectToHost =         kCFURLErrorCannotConnectToHost;
CPURLErrorNetworkConnectionLost =       kCFURLErrorNetworkConnectionLost;
CPURLErrorDNSLookupFailed =             kCFURLErrorDNSLookupFailed;
CPURLErrorHTTPTooManyRedirects =        kCFURLErrorHTTPTooManyRedirects;
CPURLErrorResourceUnavailable =         kCFURLErrorResourceUnavailable;
CPURLErrorNotConnectedToInternet =      kCFURLErrorNotConnectedToInternet;
CPURLErrorRedirectToNonExistentLocation =   kCFURLErrorRedirectToNonExistentLocation;
CPURLErrorBadServerResponse =           kCFURLErrorBadServerResponse;
CPURLErrorUserCancelledAuthentication = kCFURLErrorUserCancelledAuthentication;
CPURLErrorUserAuthenticationRequired =  kCFURLErrorUserAuthenticationRequired;
CPURLErrorZeroByteResource =            kCFURLErrorZeroByteResource;
CPURLErrorCannotDecodeRawData =         kCFURLErrorCannotDecodeRawData;
CPURLErrorCannotDecodeContentData =     kCFURLErrorCannotDecodeContentData;
CPURLErrorCannotParseResponse =         kCFURLErrorCannotParseResponse;
CPURLErrorFileDoesNotExist =            kCFURLErrorFileDoesNotExist;
CPURLErrorFileIsDirectory =             kCFURLErrorFileIsDirectory;
CPURLErrorNoPermissionsToReadFile =     kCFURLErrorNoPermissionsToReadFile;
CPURLErrorDataLengthExceedsMaximum =    kCFURLErrorDataLengthExceedsMaximum;