
@import <Foundation/CPDictionary.j>
@import <Foundation/CPString.j>
@import <Foundation/CPObject.j>

var FILE = require("file"),
    SYSTEM = require("system");

var DefaultDictionary       = nil,
    DefaultConfiguration    = nil,
    UserConfiguration       = nil;

@implementation Configuration : CPObject
{
    CPString        path;
    CPDictionary    dictionary;
    CPDictionary    temporaryDictionary;
}

+ (void)initialize
{
    if (self !== [Configuration class])
        return;

    DefaultDictionary = [CPDictionary dictionary];

    [DefaultDictionary setObject:@"You" forKey:@"user.name"];
    [DefaultDictionary setObject:@"you@yourcompany.com" forKey:@"user.email"];
    [DefaultDictionary setObject:@"Your Company" forKey:@"organization.name"];
    [DefaultDictionary setObject:@"feedback @nospam@ yourcompany.com" forKey:@"organization.email"];
    [DefaultDictionary setObject:@"http://yourcompany.com" forKey:@"organization.url"];
    [DefaultDictionary setObject:@"com.yourcompany" forKey:@"organization.identifier"];

    var date = new Date(),
        months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

    [DefaultDictionary setObject:date.getFullYear() forKey:@"project.year"];
    [DefaultDictionary setObject:months[date.getMonth()] + ' ' + date.getDate() + ", " + date.getFullYear() forKey:@"project.date"];
}

+ (id)defaultConfiguration
{
    if (!DefaultConfiguration)
        DefaultConfiguration = [[self alloc] initWithPath:nil];

    return DefaultConfiguration;
}

+ (id)userConfiguration
{
    if (!UserConfiguration)
        UserConfiguration = [[self alloc] initWithPath:FILE.join(SYSTEM.env["HOME"], ".cappconfig")];

    return UserConfiguration;
}

- (id)initWithPath:(CPString)aPath
{
    self = [super init];

    if (self)
    {
        path = aPath;
        temporaryDictionary = [CPDictionary dictionary];

        if (path && FILE.isReadable(path))
            dictionary = CFPropertyList.readPropertyListFromFile(path);

        // readPlist will return nil if the file is empty
        if (!dictionary)
            dictionary = [CPDictionary dictionary];
    }

    return self;
}

- (CPString)path
{
    return path;
}

- (CPEnumerator)storedKeyEnumerator
{
    return [dictionary keyEnumerator];
}

- (CPEnumerator)keyEnumerator
{
    var set = [CPSet setWithArray:[dictionary allKeys]];

    [set addObjectsFromArray:[temporaryDictionary allKeys]];
    [set addObjectsFromArray:[DefaultDictionary allKeys]];

    return [set objectEnumerator];
}

- (CPString)valueForKey:(CPString)aKey
{
    var value = [dictionary objectForKey:aKey];

    if (!value)
        value = [temporaryDictionary objectForKey:aKey];

    if (!value)
        value = [DefaultDictionary objectForKey:aKey];

    return value;
}

- (void)setValue:(CPString)aString forKey:(CPString)aKey
{
    [dictionary setObject:aString forKey:aKey];
}

- (void)setTemporaryValue:(CPString)aString forKey:(CPString)aKey
{
    [temporaryDictionary setObject:aString forKey:aKey];
}

- (void)save
{
    var path = [self path];

    if (!path)
        return;

    CFPropertyList.writePropertyListToFile(dictionary, path);
}

@end

function config(/*va_args*/)
{
    var index = 0,
        count = arguments.length,
        key = NULL,
        value = NULL,
        shouldGet = NO,
        shouldList = NO;

    for (; index < count; ++index)
    {
        var argument = arguments[index];

        switch (argument)
        {
            case "--get":   shouldGet = YES;
                            break;

            case "-l":
            case "--list":  shouldList = YES;
                            break;

            default:        if (key === NULL)
                                key = argument;
                            else
                                value = argument;
        }
    }

    var configuration = [Configuration userConfiguration];

    if (shouldList)
    {
        var key = nil,
            keyEnumerator = [configuration storedKeyEnumerator];

        while (key = [keyEnumerator nextObject])
            print(key + '=' + [configuration valueForKey:key]);
    }
    else if (shouldGet)
    {
        var value = [configuration valueForKey:key];

        if (value)
            print(value);
    }
    else if (key !== NULL && value !== NULL)
    {
        [configuration setValue:value forKey:key];
        [configuration save];
    }
}
