
@import <Foundation/CPDictionary.j>
@import <Foundation/CPString.j>
@import <Foundation/CPObject.j>


var DefaultDictionary       = nil,
    DefaultConfiguration    = nil,
    UserConfiguration       = nil;

@implementation Configuration : CPObject
{
    CPString        path;
    CPDictionary    dictionary;
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
        months = ["Janurary", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"];

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
        UserConfiguration = [[self alloc] initWithPath:String(new java.io.File(java.lang.System.getProperty("user.home") + "/.cappconfig").getCanonicalPath())];

    return UserConfiguration;
}

- (id)initWithPath:(CPString)aPath
{
    self = [super init];

    if (self)
    {
        path = aPath;
        dictionary = [CPDictionary dictionary],
        temporaryDictionary = [CPDictionary dictionary];

        if (aPath)
        {
            var file = new java.io.File([self path]);
    
            if (file.canRead())
            {
                try
                {
                    var data = [CPData dataWithString:readFile(file.getCanonicalPath())],
                        string = [data string];
        
                    if (string && string.length)
                        dictionary = CPPropertyListCreateFromData(data);
                }
                catch (e) { }
            }
        }
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
    if (![self path])
        return;

    var writer = new BufferedWriter(new FileWriter(new java.io.File([self path])));

    writer.write([CPPropertyListCreate280NorthData(dictionary, kCFPropertyListXMLFormat_v1_0) string]);

    writer.close();
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
