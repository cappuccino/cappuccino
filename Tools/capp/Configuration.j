
@import <Foundation/CPDictionary.j>
@import <Foundation/CPString.j>
@import <Foundation/CPObject.j>
@import <Foundation/CPSet.j>


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

    DefaultDictionary = @{};

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
        temporaryDictionary = @{};

        if (path && FILE.isReadable(path))
            dictionary = CFPropertyList.readPropertyListFromFile(path);

        // readPlist will return nil if the file is empty
        if (!dictionary)
            dictionary = @{};
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

- (void)removeValueForKey:(CPString)aKey
{
    [dictionary removeObjectForKey:aKey];
}

- (void)setTemporaryValue:(CPString)aString forKey:(CPString)aKey
{
    [temporaryDictionary setObject:aString forKey:aKey];
}

- (void)save
{
    var aPath = [self path];

    if (!aPath)
        return;

    CFPropertyList.writePropertyListToFile(dictionary, aPath);
}

@end

function config(/*va_args*/)
{
    var count = arguments.length;

    if (count === 0 || count > 2)
    {
        printUsage();
        return;
    }

    var argument = arguments[0],
        key = nil,
        value = nil,
        action = nil,
        valid = YES;

    switch (argument)
    {
        case "--get":
        case "--remove":    action = argument.substring(2);

                            if (count === 2)
                                key = arguments[1];
                            else
                                valid = NO;
                            break;

        case "-l":
        case "--list":      action = "list";
                            valid = count === 1;
                            break;


        default:            action = "set";
                            key = argument;

                            if (count === 2)
                                value = arguments[1];
                            else
                                valid = NO;
    }

    if (!valid)
    {
        printUsage();
        return;
    }

    var configuration = [Configuration userConfiguration];

    if (action === "list")
    {
        var key = nil,
            keyEnumerator = [configuration storedKeyEnumerator];

        while ((key = [keyEnumerator nextObject]) !== nil)
            print(key + '=' + [configuration valueForKey:key]);
    }
    else if (action === "get")
    {
        var value = [configuration valueForKey:key];

        if (value != nil)
            print(value);
    }
    else if (action === "remove")
    {
        var value = [configuration valueForKey:key];

        if (value != nil)
        {
            [configuration removeValueForKey:key];
            [configuration save];
        }
    }
    else if (key !== nil && value !== nil)
    {
        [configuration setValue:value forKey:key];
        [configuration save];
    }
}
