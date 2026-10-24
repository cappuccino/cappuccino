/*
 * Library.j
 * SmartFoldersDemo
 *
 * The application model. Holds all people plus the three source list
 * sections (Library, Groups, Smart Folders), persists itself to
 * CPUserDefaults (local storage) and observes every Person via KVO so that
 * edits made anywhere in the UI are noticed, saved and reflected in the
 * smart folder badges.
 *
 * Change notifications:
 *   - structural changes (people added/removed, group membership, folders
 *     added/removed/renamed/reordered/edited) are posted synchronously;
 *   - property edits on a Person are coalesced and posted on the next run
 *     loop turn.
 */

@import <Foundation/Foundation.j>
@import "Person.j"

LibraryDidChangeNotification    = @"LibraryDidChangeNotification";
LibraryChangeKindKey            = @"kind";
LibraryChangeStructural         = @"structural";
LibraryChangePersonEdited       = @"personEdited";

PeopleDragType                  = @"SmartFoldersDemoPeopleDragType";
SourceItemDragType              = @"SmartFoldersDemoSourceItemDragType";

LibraryDepartments              = [@"Engineering", @"Design", @"Marketing", @"Sales", @"Support", @"Finance", @"Legal"];
LibraryCities                   = [@"Berlin", @"Hamburg", @"Munich", @"Zürich", @"Vienna", @"Paris", @"London", @"Lisbon", @"New York", @"San Francisco", @"Tokyo"];

var LibraryDefaultsKey          = @"SmartFoldersDemo.Library.v1",
    ObservedPersonKeys          = [@"firstName", @"lastName", @"email", @"department", @"city", @"birthDate", @"salary", @"isManager"],
    SourceItemUIDCounter        = 0;


// --------------------------------------------------------------------------------
// Source list items
// --------------------------------------------------------------------------------

@implementation SourceItem : CPObject
{
    CPString    uid     @accessors;
    CPString    name    @accessors;
}

- (id)initWithName:(CPString)aName
{
    if (self = [super init])
    {
        uid = [self className] + "-" + (++SourceItemUIDCounter);
        name = aName;
    }

    return self;
}

- (BOOL)isSection
{
    return NO;
}

- (BOOL)isSelectable
{
    return YES;
}

// Can be renamed, deleted and reordered by the user.
- (BOOL)isUserItem
{
    return NO;
}

@end


@implementation SourceSection : SourceItem
{
    CPMutableArray  children    @accessors;
}

- (id)initWithName:(CPString)aName
{
    if (self = [super initWithName:aName])
        children = [];

    return self;
}

- (BOOL)isSection
{
    return YES;
}

- (BOOL)isSelectable
{
    return NO;
}

@end


@implementation AllPeopleItem : SourceItem
@end


@implementation LibraryGroup : SourceItem
{
    CPMutableArray  memberIDs   @accessors;
}

- (id)initWithName:(CPString)aName memberIDs:(CPArray)theIDs
{
    if (self = [super initWithName:aName])
        memberIDs = [CPMutableArray arrayWithArray:theIDs || []];

    return self;
}

- (id)initWithDictionary:(CPDictionary)aDictionary
{
    return [self initWithName:[aDictionary objectForKey:@"name"] || @"Group"
                    memberIDs:[aDictionary objectForKey:@"members"] || []];
}

- (CPDictionary)dictionaryRepresentation
{
    return [CPDictionary dictionaryWithObjectsAndKeys:name, @"name", [memberIDs copy], @"members"];
}

- (BOOL)isUserItem
{
    return YES;
}

@end


@implementation SmartFolder : SourceItem
{
    CPPredicate     predicate   @accessors;
}

- (id)initWithName:(CPString)aName predicate:(CPPredicate)aPredicate
{
    if (self = [super initWithName:aName])
        predicate = aPredicate;

    return self;
}

- (id)initWithDictionary:(CPDictionary)aDictionary
{
    var format = [aDictionary objectForKey:@"predicate"],
        aPredicate = nil;

    try
    {
        if (format)
            aPredicate = [CPPredicate predicateWithFormat:format];
    }
    catch (e)
    {
        CPLog.warn("SmartFoldersDemo: could not parse stored predicate '" + format + "': " + e);
    }

    return [self initWithName:[aDictionary objectForKey:@"name"] || @"Smart Folder"
                    predicate:aPredicate || [CPPredicate predicateWithValue:YES]];
}

- (CPDictionary)dictionaryRepresentation
{
    return [CPDictionary dictionaryWithObjectsAndKeys:name, @"name", [predicate predicateFormat], @"predicate"];
}

- (BOOL)isUserItem
{
    return YES;
}

@end


// --------------------------------------------------------------------------------
// Library
// --------------------------------------------------------------------------------

@implementation Library : CPObject
{
    CPMutableArray  _people;
    Object          _peopleByUID;

    SourceSection   _librarySection;
    SourceSection   _groupsSection;
    SourceSection   _smartFoldersSection;
    AllPeopleItem   _allPeopleItem;
    CPArray         _sections;

    BOOL            _editNotificationScheduled;
    BOOL            _saveScheduled;
}

- (id)init
{
    if (self = [super init])
    {
        _people = [];
        _peopleByUID = {};

        _allPeopleItem = [[AllPeopleItem alloc] initWithName:@"All People"];

        _librarySection = [[SourceSection alloc] initWithName:@"LIBRARY"];
        [[_librarySection children] addObject:_allPeopleItem];

        _groupsSection = [[SourceSection alloc] initWithName:@"GROUPS"];
        _smartFoldersSection = [[SourceSection alloc] initWithName:@"SMART FOLDERS"];

        _sections = [_librarySection, _groupsSection, _smartFoldersSection];

        if (![self _loadFromDefaults])
            [self _populateWithSampleData];
    }

    return self;
}

// ---------------------------------------------------------------- Accessors

- (CPArray)people
{
    return _people;
}

- (CPArray)sections
{
    return _sections;
}

- (AllPeopleItem)allPeopleItem
{
    return _allPeopleItem;
}

- (SourceSection)groupsSection
{
    return _groupsSection;
}

- (SourceSection)smartFoldersSection
{
    return _smartFoldersSection;
}

- (CPArray)groups
{
    return [_groupsSection children];
}

- (CPArray)smartFolders
{
    return [_smartFoldersSection children];
}

- (CPArray)childrenOfItem:(id)anItem
{
    if (anItem == nil)
        return _sections;

    if ([anItem isSection])
        return [anItem children];

    return [];
}

- (SourceSection)sectionForItem:(id)anItem
{
    if ([anItem isKindOfClass:[AllPeopleItem class]])
        return _librarySection;

    if ([anItem isKindOfClass:[LibraryGroup class]])
        return _groupsSection;

    if ([anItem isKindOfClass:[SmartFolder class]])
        return _smartFoldersSection;

    return nil;
}

- (BOOL)containsItem:(id)anItem
{
    if (!anItem)
        return NO;

    if ([_sections indexOfObjectIdenticalTo:anItem] !== CPNotFound)
        return YES;

    var section = [self sectionForItem:anItem];
    return section && [[section children] indexOfObjectIdenticalTo:anItem] !== CPNotFound;
}

- (id)itemWithUID:(CPString)aUID
{
    for (var i = 0; i < _sections.length; i++)
    {
        var section = _sections[i],
            children = [section children];

        if ([section uid] === aUID)
            return section;

        for (var j = 0; j < children.length; j++)
            if ([children[j] uid] === aUID)
                return children[j];
    }

    return nil;
}

- (Person)personWithUID:(CPString)aUID
{
    return _peopleByUID[aUID] || nil;
}

- (CPArray)peopleWithUIDs:(CPArray)theUIDs
{
    var result = [];

    for (var i = 0; i < theUIDs.length; i++)
    {
        var person = _peopleByUID[theUIDs[i]];

        if (person)
            result.push(person);
    }

    return result;
}

// The unfiltered content for a source item (what goes into the array controller).
- (CPArray)baseContentForItem:(id)anItem
{
    if ([anItem isKindOfClass:[LibraryGroup class]])
        return [self peopleWithUIDs:[anItem memberIDs]];

    if ([anItem isKindOfClass:[AllPeopleItem class]] || [anItem isKindOfClass:[SmartFolder class]])
        return _people;

    return [];
}

- (CPPredicate)predicateForItem:(id)anItem
{
    if ([anItem isKindOfClass:[SmartFolder class]])
        return [anItem predicate];

    return nil;
}

- (CPArray)peopleMatchingPredicate:(CPPredicate)aPredicate
{
    if (!aPredicate)
        return _people;

    try
    {
        return [_people filteredArrayUsingPredicate:aPredicate];
    }
    catch (e)
    {
        CPLog.warn("SmartFoldersDemo: predicate evaluation failed: " + e);
        return nil;
    }
}

- (int)countForItem:(id)anItem
{
    if ([anItem isSection])
        return CPNotFound;

    var base = [self baseContentForItem:anItem],
        predicate = [self predicateForItem:anItem];

    if (!predicate)
        return [base count];

    var matches = [self peopleMatchingPredicate:predicate];
    return matches ? [matches count] : CPNotFound;
}

// ---------------------------------------------------------------- People mutation

- (Person)createPerson
{
    var person = [[Person alloc] init];

    [person setFirstName:@"New"];
    [person setLastName:@"Person"];
    [person setEmail:@"new.person@example.com"];
    [person setCity:LibraryCities[0]];

    [self addPeople:[person]];

    return person;
}

- (void)addPeople:(CPArray)thePeople
{
    if (![thePeople count])
        return;

    for (var i = 0; i < thePeople.length; i++)
        [self _insertPerson:thePeople[i]];

    [self _noteStructuralChange];
}

- (void)removePeople:(CPArray)thePeople
{
    if (![thePeople count])
        return;

    var uids = [];

    for (var i = 0; i < thePeople.length; i++)
    {
        var person = thePeople[i];

        if (!_peopleByUID[[person uid]])
            continue;

        [self _stopObservingPerson:person];
        [_people removeObjectIdenticalTo:person];
        delete _peopleByUID[[person uid]];
        uids.push([person uid]);
    }

    var groups = [self groups];

    for (var i = 0; i < groups.length; i++)
        [[groups[i] memberIDs] removeObjectsInArray:uids];

    [self _noteStructuralChange];
}

- (void)addPeople:(CPArray)thePeople toGroup:(LibraryGroup)aGroup
{
    var members = [aGroup memberIDs],
        changed = NO;

    for (var i = 0; i < thePeople.length; i++)
    {
        var uid = [thePeople[i] uid];

        if (![members containsObject:uid])
        {
            [members addObject:uid];
            changed = YES;
        }
    }

    if (changed)
        [self _noteStructuralChange];
}

- (void)removePeople:(CPArray)thePeople fromGroup:(LibraryGroup)aGroup
{
    [[aGroup memberIDs] removeObjectsInArray:[thePeople valueForKey:@"uid"]];
    [self _noteStructuralChange];
}

// ---------------------------------------------------------------- Source item mutation

- (LibraryGroup)addGroupWithName:(CPString)aName people:(CPArray)thePeople
{
    var group = [[LibraryGroup alloc] initWithName:aName memberIDs:[thePeople valueForKey:@"uid"] || []];

    [[_groupsSection children] addObject:group];
    [self _noteStructuralChange];

    return group;
}

- (SmartFolder)addSmartFolderWithName:(CPString)aName predicate:(CPPredicate)aPredicate
{
    var folder = [[SmartFolder alloc] initWithName:aName predicate:aPredicate];

    [[_smartFoldersSection children] addObject:folder];
    [self _noteStructuralChange];

    return folder;
}

- (void)updateSmartFolder:(SmartFolder)aFolder name:(CPString)aName predicate:(CPPredicate)aPredicate
{
    [aFolder setName:aName];
    [aFolder setPredicate:aPredicate];
    [self _noteStructuralChange];
}

- (void)renameItem:(SourceItem)anItem to:(CPString)aName
{
    if (![anItem isUserItem] || ![aName length])
        return;

    [anItem setName:aName];
    [self _noteStructuralChange];
}

- (void)removeItem:(SourceItem)anItem
{
    var section = [self sectionForItem:anItem];

    if (![anItem isUserItem] || !section)
        return;

    [[section children] removeObjectIdenticalTo:anItem];
    [self _noteStructuralChange];
}

// Moves a user item to a new index inside its own section.
// anIndex is the proposed insertion index *before* removal (outline view semantics).
- (void)moveItem:(SourceItem)anItem toIndex:(int)anIndex
{
    var section = [self sectionForItem:anItem],
        children = [section children],
        oldIndex = [children indexOfObjectIdenticalTo:anItem];

    if (oldIndex === CPNotFound)
        return;

    if (anIndex > oldIndex)
        anIndex--;

    anIndex = MAX(0, MIN(anIndex, [children count] - 1));

    if (anIndex === oldIndex)
        return;

    [children removeObjectAtIndex:oldIndex];
    [children insertObject:anItem atIndex:anIndex];
    [self _noteStructuralChange];
}

- (void)resetToSampleData
{
    var people = [_people copy];

    for (var i = 0; i < people.length; i++)
        [self _stopObservingPerson:people[i]];

    _people = [];
    _peopleByUID = {};
    [[_groupsSection children] removeAllObjects];
    [[_smartFoldersSection children] removeAllObjects];

    [[CPUserDefaults standardUserDefaults] removeObjectForKey:LibraryDefaultsKey];

    [self _populateWithSampleData];
    [self _noteStructuralChange];
}

// ---------------------------------------------------------------- KVO

- (void)_insertPerson:(Person)aPerson
{
    if (_peopleByUID[[aPerson uid]])
        return;

    _people.push(aPerson);
    _peopleByUID[[aPerson uid]] = aPerson;

    for (var i = 0; i < ObservedPersonKeys.length; i++)
        [aPerson addObserver:self forKeyPath:ObservedPersonKeys[i] options:CPKeyValueObservingOptionNew context:nil];
}

- (void)_stopObservingPerson:(Person)aPerson
{
    for (var i = 0; i < ObservedPersonKeys.length; i++)
        [aPerson removeObserver:self forKeyPath:ObservedPersonKeys[i]];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)aChange context:(id)aContext
{
    if (_editNotificationScheduled)
        return;

    _editNotificationScheduled = YES;
    [CPTimer scheduledTimerWithTimeInterval:0 target:self selector:@selector(_postEditNotification:) userInfo:nil repeats:NO];
}

- (void)_postEditNotification:(CPTimer)aTimer
{
    _editNotificationScheduled = NO;
    [self _scheduleSave];

    [[CPNotificationCenter defaultCenter] postNotificationName:LibraryDidChangeNotification
                                                        object:self
                                                      userInfo:[CPDictionary dictionaryWithObject:LibraryChangePersonEdited forKey:LibraryChangeKindKey]];
}

- (void)_noteStructuralChange
{
    [self _scheduleSave];

    [[CPNotificationCenter defaultCenter] postNotificationName:LibraryDidChangeNotification
                                                        object:self
                                                      userInfo:[CPDictionary dictionaryWithObject:LibraryChangeStructural forKey:LibraryChangeKindKey]];
}

// ---------------------------------------------------------------- Persistence

- (void)_scheduleSave
{
    if (_saveScheduled)
        return;

    _saveScheduled = YES;
    [CPTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(_saveTimerFired:) userInfo:nil repeats:NO];
}

- (void)_saveTimerFired:(CPTimer)aTimer
{
    _saveScheduled = NO;
    [self save];
}

- (void)save
{
    var people = [],
        groups = [],
        folders = [],
        groupItems = [self groups],
        folderItems = [self smartFolders];

    for (var i = 0; i < _people.length; i++)
        people.push([_people[i] dictionaryRepresentation]);

    for (var i = 0; i < groupItems.length; i++)
        groups.push([groupItems[i] dictionaryRepresentation]);

    for (var i = 0; i < folderItems.length; i++)
        folders.push([folderItems[i] dictionaryRepresentation]);

    var defaults = [CPUserDefaults standardUserDefaults],
        dictionary = [CPDictionary dictionaryWithObjectsAndKeys:
            1, @"version",
            people, @"people",
            groups, @"groups",
            folders, @"smartFolders"];

    [defaults setObject:dictionary forKey:LibraryDefaultsKey];
    [defaults synchronize];
}

- (BOOL)_loadFromDefaults
{
    var dictionary = [[CPUserDefaults standardUserDefaults] objectForKey:LibraryDefaultsKey];

    if (!dictionary || ![dictionary isKindOfClass:[CPDictionary class]])
        return NO;

    try
    {
        var people = [dictionary objectForKey:@"people"] || [],
            groups = [dictionary objectForKey:@"groups"] || [],
            folders = [dictionary objectForKey:@"smartFolders"] || [];

        for (var i = 0; i < people.length; i++)
            [self _insertPerson:[[Person alloc] initWithDictionary:people[i]]];

        for (var i = 0; i < groups.length; i++)
            [[_groupsSection children] addObject:[[LibraryGroup alloc] initWithDictionary:groups[i]]];

        for (var i = 0; i < folders.length; i++)
            [[_smartFoldersSection children] addObject:[[SmartFolder alloc] initWithDictionary:folders[i]]];
    }
    catch (e)
    {
        CPLog.warn("SmartFoldersDemo: stored library is unreadable, using sample data. " + e);

        _people = [];
        _peopleByUID = {};
        [[_groupsSection children] removeAllObjects];
        [[_smartFoldersSection children] removeAllObjects];

        return NO;
    }

    return [_people count] > 0;
}

// ---------------------------------------------------------------- Sample data

- (void)_populateWithSampleData
{
    // Deterministic Park-Miller generator so every fresh launch shows identical data.
    var seed = 20101125;

    function random()
    {
        seed = (seed * 16807) % 2147483647;
        return (seed - 1) / 2147483646;
    }

    function pick(anArray)
    {
        return anArray[Math.floor(random() * anArray.length)];
    }

    // Intentionally includes diacritics to exercise [cd] predicate options.
    var firstNames = [@"Anna", @"Ben", @"Chloé", @"David", @"Elif", @"François", @"Greta", @"Hiro", @"Ingrid", @"José",
                      @"Karl", @"Lena", @"Mateo", @"Nina", @"Oskar", @"Paula", @"Quentin", @"Renée", @"Søren", @"Tomás",
                      @"Ute", @"Viktor", @"Wiebke", @"Xavier", @"Yuki", @"Zoë", @"Amélie", @"Björn", @"Clara", @"Dario"],
        lastNames = [@"Müller", @"Schmidt", @"Bauer", @"García", @"Dubois", @"Rossi", @"Nowak", @"Jensen", @"Tanaka", @"Smith",
                     @"Johnson", @"Öztürk", @"Novák", @"Silva", @"Fischer", @"Weber", @"Lefèvre", @"Kowalski", @"Andersson", @"Brown",
                     @"Costa", @"Hoffmann", @"Ivanova", @"Kim", @"Lambert", @"Martín", @"Nilsson", @"O'Brien", @"Peña", @"Wagner"];

    function emailFor(aFirst, aLast)
    {
        var raw = (aFirst + "." + aLast).toLowerCase();

        if (raw.normalize)
            raw = raw.normalize("NFD").replace(/[\u0300-\u036f]/g, "");

        return raw.replace(/ø/g, "o").replace(/[^a-z.]/g, "") + "@example.com";
    }

    var count = 240;

    for (var i = 0; i < count; i++)
    {
        var uid = "p" + ("000" + i).slice(-4),
            person = [[Person alloc] initWithUID:uid],
            first = pick(firstNames),
            last = pick(lastNames);

        [person setFirstName:first];
        [person setLastName:last];
        [person setEmail:emailFor(first, last)];
        [person setDepartment:pick(LibraryDepartments)];
        [person setCity:pick(LibraryCities)];
        [person setBirthDate:new Date(1955 + Math.floor(random() * 48), Math.floor(random() * 12), 1 + Math.floor(random() * 28))];
        [person setSalary:38000 + Math.round(random() * 240) * 500];
        [person setIsManager:random() < 0.12];

        [self _insertPerson:person];
    }

    // Groups (static membership)
    var someIDs = function(n)
    {
        var ids = [];

        while (ids.length < n)
        {
            var candidate = _people[Math.floor(random() * _people.length)];

            if (ids.indexOf([candidate uid]) === -1)
                ids.push([candidate uid]);
        }

        return ids;
    };

    [[_groupsSection children] addObject:[[LibraryGroup alloc] initWithName:@"Favorites" memberIDs:someIDs(6)]];
    [[_groupsSection children] addObject:[[LibraryGroup alloc] initWithName:@"Hiking Club" memberIDs:someIDs(14)]];
    [[_groupsSection children] addObject:[[LibraryGroup alloc] initWithName:@"Book Club" memberIDs:someIDs(9)]];
    [[_groupsSection children] addObject:[[LibraryGroup alloc] initWithName:@"Drop People Here" memberIDs:[]]];

    // Smart folders. Every predicate below is representable by the row templates
    // in SmartFolderEditorController, so CPPredicateEditor -setObjectValue: is
    // exercised on all of them.
    var folders = [
        [@"Engineering over 40",     [CPPredicate predicateWithFormat:@"department == %@ AND age > %@", @"Engineering", 40]],
        [@"Names starting with A",   [CPPredicate predicateWithFormat:@"firstName BEGINSWITH[cd] %@", @"a"]],
        [@"Müller (diacritics test)",[CPPredicate predicateWithFormat:@"lastName CONTAINS[cd] %@", @"muller"]],
        [@"High earners in Berlin",  [CPPredicate predicateWithFormat:@"salary >= %@ AND city ==[cd] %@", 120000, @"berlin"]],
        [@"Sales or Marketing",      [CPPredicate predicateWithFormat:@"department == %@ OR department == %@", @"Sales", @"Marketing"]],
        [@"Not in Support",          [CPPredicate predicateWithFormat:@"NOT (department == %@)", @"Support"]],
        [@"Nested compound",         [CPPredicate predicateWithFormat:@"age < %@ AND (city ==[cd] %@ OR city ==[cd] %@)", 35, @"tokyo", @"lisbon"]]
    ];

    for (var i = 0; i < folders.length; i++)
        [[_smartFoldersSection children] addObject:[[SmartFolder alloc] initWithName:folders[i][0] predicate:folders[i][1]]];
}

@end
