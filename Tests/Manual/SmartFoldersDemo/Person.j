/*
 * Person.j
 * SmartFoldersDemo
 *
 * The record type shown in the people table. Plain KVC/KVO compliant model
 * object: every property is exercised by bindings (table columns, detail
 * pane), by CPPredicate evaluation (smart folders, search) and by
 * CPSortDescriptor (column sorting).
 *
 * "age" and "fullName" are derived properties registered with
 * +keyPathsForValuesAffecting<Key> so that KVO dependent-key support is
 * exercised as well.
 */

@import <Foundation/Foundation.j>

var PersonUIDCounter = 0;

@implementation Person : CPObject
{
    CPString    uid         @accessors;
    CPString    firstName   @accessors;
    CPString    lastName    @accessors;
    CPString    email       @accessors;
    CPString    department  @accessors;
    CPString    city        @accessors;
    CPDate      birthDate   @accessors;
    CPNumber    salary      @accessors;
    BOOL        isManager   @accessors;
}

+ (CPString)nextUID
{
    return @"p" + (new Date()).getTime().toString(36) + "-" + (++PersonUIDCounter);
}

+ (CPSet)keyPathsForValuesAffectingAge
{
    return [CPSet setWithObject:@"birthDate"];
}

+ (CPSet)keyPathsForValuesAffectingFullName
{
    return [CPSet setWithObjects:@"firstName", @"lastName"];
}

- (id)init
{
    return [self initWithUID:[Person nextUID]];
}

- (id)initWithUID:(CPString)aUID
{
    if (self = [super init])
    {
        uid = aUID;
        firstName = @"";
        lastName = @"";
        email = @"";
        department = @"Engineering";
        city = @"";
        birthDate = new Date(1990, 0, 1);
        salary = 50000;
        isManager = NO;
    }

    return self;
}

- (id)initWithDictionary:(CPDictionary)aDictionary
{
    if (self = [self initWithUID:[aDictionary objectForKey:@"uid"] || [Person nextUID]])
    {
        firstName = [aDictionary objectForKey:@"firstName"] || @"";
        lastName = [aDictionary objectForKey:@"lastName"] || @"";
        email = [aDictionary objectForKey:@"email"] || @"";
        department = [aDictionary objectForKey:@"department"] || @"";
        city = [aDictionary objectForKey:@"city"] || @"";

        var interval = [aDictionary objectForKey:@"birthDate"];
        birthDate = (interval !== nil && interval !== undefined) ? [CPDate dateWithTimeIntervalSince1970:interval] : nil;

        salary = Number([aDictionary objectForKey:@"salary"] || 0);
        isManager = !![aDictionary objectForKey:@"isManager"];
    }

    return self;
}

// Property-list safe representation used for CPUserDefaults persistence.
- (CPDictionary)dictionaryRepresentation
{
    return [CPDictionary dictionaryWithObjectsAndKeys:
        uid, @"uid",
        firstName || @"", @"firstName",
        lastName || @"", @"lastName",
        email || @"", @"email",
        department || @"", @"department",
        city || @"", @"city",
        birthDate ? [birthDate timeIntervalSince1970] : 0, @"birthDate",
        Number(salary || 0), @"salary",
        isManager ? 1 : 0, @"isManager"];
}

- (int)age
{
    if (!birthDate)
        return 0;

    var now = new Date(),
        years = now.getFullYear() - birthDate.getFullYear(),
        months = now.getMonth() - birthDate.getMonth();

    if (months < 0 || (months === 0 && now.getDate() < birthDate.getDate()))
        years--;

    return years;
}

- (CPString)fullName
{
    return [[CPString stringWithFormat:@"%@ %@", firstName || @"", lastName || @""] stringByTrimmingWhitespace];
}

// One line of tab separated text; used for copy / paste and drag & drop.
- (CPString)tabSeparatedRepresentation
{
    return [firstName || @"", lastName || @"", email || @"", department || @"", city || @"", String(salary || 0)].join("\t");
}

+ (CPString)tabSeparatedHeader
{
    return ["First Name", "Last Name", "Email", "Department", "City", "Salary"].join("\t");
}

- (CPString)description
{
    return [CPString stringWithFormat:@"<Person %@ %@>", uid, [self fullName]];
}

@end
