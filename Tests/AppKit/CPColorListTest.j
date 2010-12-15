@import <AppKit/CPColorList.j>

@implementation CPColorListTest : OJTestCase
{
    BOOL listChanged;
}

- (void)testAvailableColorLists
{
    var cl = [CPColorList availableColorLists];
    [self assertNotNull:cl];
    // expect 'Apple' list first
    var list = [cl objectAtIndex:0];
    [self assert:@"Apple" equals:[list name]];
}

- (void)testColorListNamed
{
    var cl = [CPColorList colorListNamed:@"Crayons"];
    [self assertNotNull:cl];
    [self assert:[cl class] equals:[CPColorList class]];
    [self assertNotNull:[cl colorWithKey:"Orchid"]];
}

- (void)testInitWithName
{
    var cl = [[CPColorList alloc] initWithName:@"System"];
    [self assertNotNull:cl];
    // path should be empty
    [self assert:@"" equals:cl._path];
    [self assert:@"System" equals:[cl name]];
    [self assertNull:[cl colorWithKey:"AColor"]];
}

- (void)testInitWithNameFromFile
{
    /*var testfile = @"Resources/TestColorList.plist",
        cl = [[CPColorList alloc] initWithName:@"MyColors" fromFile:testfile];
    [self assertNotNull:cl];
    [self assert:CPOrderedSame equals:[cl._path compare:testfile]];
    [self assert:@"MyColors" equals:[cl name]];
    var color = [cl colorWithKey:@"Red"];
    [self assertNotNull:color];
    [self assert:0 equals:[color blueComponent]];
    [self assert:1 equals:[color redComponent]];
    [self assertNull:[cl colorWithKey:"AColor"]];
    */
}

- (void)testName
{
    var cl = [[CPColorList alloc] initWithName:@"System"];
    [self assert:@"System" equals:[cl name]];
}

- (void)testColorWithKey
{
    var cl = [CPColorList colorListNamed:@"Apple"],
        color = [cl colorWithKey:@"Brown"],
        color2 = [cl colorWithKey:@"W"],
        color3 = [cl colorWithKey:@"Green"];

    [self assert:[CPColor greenColor] equals:color3];
    [self assert:0.6 equals:[color redComponent]];
    [self assertNull:color2];
}

- (void)testSetColorForKey
{
    var cl = [CPColorList colorListNamed:@"Apple"];

    [self assertThrows:function(){[cl setColor:[CPColor redColor] forKey:@"Black"];}];
    [self assertThrows:function(){[cl setColor:[CPColor redColor] forKey:@"NewKey"];}];

    var newlist = [[CPColorList alloc] initWithName:@"MyList"];
    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(listDidChange:)
                                                 name:CPColorListDidChangeNotification
                                               object:newlist];
   [self assertNoThrow:function(){[newlist setColor:[CPColor whiteColor] forKey:@"Black"];}];
   listChanged = NO;
   [self assertNoThrow:function(){[newlist setColor:[CPColor blackColor] forKey:@"Black"];}];
   [self assert:YES equals:listChanged message:@"The notification CPColorListDidChangeNotification did not get sent."];
   listChanged = NO;
}

- (void)listDidChange:(id)sender
{
    listChanged = YES;
}

- (void)testInsertColorKeyAtIndex
{
    var cl = [CPColorList colorListNamed:@"Apple"];

    [self assertThrows:function(){[cl setColor:[CPColor redColor] forKey:@"NewKey"];}];

    var newlist = [[CPColorList alloc] initWithName:@"MyList"];
    listChanged = NO;
    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(listDidChange:)
                                                 name:CPColorListDidChangeNotification
                                               object:newlist];

    [self assertNoThrow:function(){[newlist insertColor:[CPColor whiteColor] key:@"Black" atIndex:0];}];
    [self assert:[CPColor whiteColor] equals:[newlist colorWithKey:@"Black"]];

    [self assert:YES equals:listChanged message:@"The notification CPColorListDidChangeNotification did not get sent."];
    listChanged = NO;
}

- (void)testRemoveColorWithKey
{
    var cl = [CPColorList colorListNamed:@"Apple"];
    listChanged = NO;

    [self assertThrows:function(){[cl removeColorWithKey:@"Brown"];}];
    [self assertThrows:function(){[cl removeColorWithKey:@"Unknown"];}];

    [self assert:NO equals:listChanged message:@"The notification CPColorListDidChangeNotification was incorrectly sent."];

    var newlist = [[CPColorList alloc] initWithName:@"MyList"];

    [[CPNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(listDidChange:)
                                                 name:CPColorListDidChangeNotification
                                               object:newlist];

    [self assertNoThrow:function(){[newlist insertColor:[CPColor whiteColor] key:@"Black" atIndex:0];}];
    [self assert:[CPColor whiteColor] equals:[newlist colorWithKey:@"Black"]];
    [self assertNoThrow:function(){[newlist removeColorWithKey:@"Black"];}];
    [self assertNull:[newlist colorWithKey:@"Black"]];
    [self assert:YES equals:listChanged message:@"The notification CPColorListDidChangeNotification did not get sent."];
    listChanged = NO;

    [self assertNoThrow:function(){[newlist insertColor:[CPColor whiteColor] key:@"White" atIndex:0];}];
    [self assertNoThrow:function(){[newlist insertColor:[CPColor blackColor] key:@"Black" atIndex:1];}];
    [self assertNoThrow:function(){[newlist insertColor:[CPColor redColor] key:@"Red" atIndex:2];}];
    [self assert:[@"White", @"Black", @"Red"] equals:[newlist allKeys]];
    [self assertNoThrow:function(){[newlist insertColor:[CPColor greenColor] key:@"Red" atIndex:0];}];
    [self assert:[@"Red", @"White", @"Black"] equals:[newlist allKeys]];
}

- (void)testAllKeys
{
    var cl = [CPColorList colorListNamed:@"Apple"],
        keys = [cl allKeys];

    [self assert:[@"Black", @"Blue", @"Brown", @"Cyan", @"Green", @"Magenta", @"Orange", @"Purple", @"Red", @"Yellow", @"White"] equals:keys];
}

- (void)testIsEditable
{
    [self assertFalse:[[CPColorList colorListNamed:@"Apple"] isEditable]];
}

- (void)testCPCoding
{
    var cl = [CPColorList colorListNamed:@"Apple"],
        encoded = [CPKeyedArchiver archivedDataWithRootObject:cl],
        dcl = [CPKeyedUnarchiver unarchiveObjectWithData:encoded];

    [self assert:@"Apple" equals:[dcl name]];
    [self assert:NO equals:dcl._loaded];
    [self assertNotNull:[dcl colorWithKey:@"Red"]];
    [self assert:YES equals:dcl._loaded];
}

@end