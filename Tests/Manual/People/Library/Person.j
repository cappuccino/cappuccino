/*
 * Person.j
 * People
 *
 * Created by David Richardson.
 * Copyright 2026, The Cappuccino Project.
 *
 * The record type shown in the people table. Plain KVC/KVO compliant model
 * object: every property is exercised by bindings (table columns, detail
 * pane), by CPPredicate evaluation (smart folders, search) and by
 * CPSortDescriptor (column sorting).
 *
 * "age" and "fullName" are derived properties registered with
 * +keyPathsForValuesAffecting<Key> so that KVO dependent-key support is
 * exercised as well.
 *
 * "notes" is rich text (a CPAttributedString), edited in a CPTextView in the
 * detail pane. Two derived keys depend on it: "notesText", its plain string,
 * which search and smart folder predicates use, and "hasNotes", which the
 * table's notes column and the Has Notes smart folder use. The notes are saved
 * as a keyed archive, because an attributed string is not a property list
 * value.
 *
 * "tags" is an array of free-form strings, edited in a CPTokenField in the
 * detail pane. "tagsText", the tags joined by commas, is a derived key that
 * search uses.
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
    CPAttributedString notes @accessors;
    CPArray     tags        @accessors;
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

+ (CPSet)keyPathsForValuesAffectingNotesText
{
    return [CPSet setWithObject:@"notes"];
}

+ (CPSet)keyPathsForValuesAffectingHasNotes
{
    return [CPSet setWithObject:@"notes"];
}

+ (CPSet)keyPathsForValuesAffectingTagsText
{
    return [CPSet setWithObject:@"tags"];
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
        tags = [];
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

        var archivedNotes = [aDictionary objectForKey:@"notes"];
        notes = archivedNotes ? [CPKeyedUnarchiver unarchiveObjectWithData:[CPData dataWithRawString:archivedNotes]] : nil;

        tags = [([aDictionary objectForKey:@"tags"] || []) copy];
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
        isManager ? 1 : 0, @"isManager",
        [self hasNotes] ? [[CPKeyedArchiver archivedDataWithRootObject:notes] rawString] : @"", @"notes",
        [(tags || []) copy], @"tags"];
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

// The tags joined by commas, or the empty string when there are none.
- (CPString)tagsText
{
    return (tags || []).join(@", ");
}

// The plain text of the notes, or the empty string when there are none.
- (CPString)notesText
{
    return notes ? [notes string] : @"";
}

// YES when the notes hold more than white space.
- (BOOL)hasNotes
{
    return [[self notesText] stringByTrimmingWhitespace].length > 0;
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
