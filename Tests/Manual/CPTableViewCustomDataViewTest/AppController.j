/*
 * AppController.j
 * CPTableViewCustomDataViewTest
 *
 * Created by You on July 4, 2012.
 * Copyright 2012, Your Company All rights reserved.
 */

@import <Foundation/CPObject.j>
@import <Foundation/CPMutableArray.j>
@import <AppKit/CPTableView.j>
@import <AppKit/CPCheckBox.j>
@import <AppKit/CPPopUpButton.j>

@implementation AppController : CPObject
{
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    var theWindow = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask],
        contentView = [theWindow contentView],
        contentWidth = [contentView frame].size.width, 
        contentHeight = [contentView frame].size.height;

    // create scroll view
    var scroll = [[CPScrollView alloc] initWithFrame:CGRectMake(20, 20, contentWidth - 20, contentHeight - 20)];
    [scroll setAutoresizingMask:CPViewWidthSizable|CPViewHeightSizable];

    // create table view
    var table = [[CPTableView alloc] initWithFrame:CGRectMakeZero()];

    // create table columns
    var idArtistName = "artistName";
    var columnArtistName = [[CPTableColumn alloc] initWithIdentifier:idArtistName];
    var titleArtistName = "Artist";
    [[columnArtistName headerView] setStringValue:titleArtistName];
    [columnArtistName setEditable:YES];
    [columnArtistName setWidth:150];
    [table addTableColumn:columnArtistName];

    var idSongTitle = "songTitle";
    var columnSongTitle = [[CPTableColumn alloc] initWithIdentifier:idSongTitle];
    var titleSongTitle = "Title";
    [[columnSongTitle headerView] setStringValue:titleSongTitle];
    [columnSongTitle setEditable:YES];
    [columnSongTitle setWidth:150];
    // popup
    var popUpButton = [[CPPopUpButton alloc] initWithFrame:CGRectMakeZero()];
    var menuItemStardust = [[CPMenuItem alloc] initWithTitle:@"Stardust" action:nil keyEquivalent:nil];
    [menuItemStardust setTag:1];
    [popUpButton addItem:menuItemStardust];
    var menuItemRainbow = [[CPMenuItem alloc] initWithTitle:@"Over The Rainbow" action:nil keyEquivalent:nil];
    [menuItemRainbow setTag:2];
    [popUpButton addItem:menuItemRainbow];
    var menuItemAngel = [[CPMenuItem alloc] initWithTitle:@"Angel Eyes" action:nil keyEquivalent:nil];
    [menuItemAngel setTag:3];
    [popUpButton addItem:menuItemAngel];
    var menuItemEstate = [[CPMenuItem alloc] initWithTitle:@"Estate" action:nil keyEquivalent:nil];
    [menuItemEstate setTag:4];
    [popUpButton addItem:menuItemEstate];
    [columnSongTitle setDataView:popUpButton];
    [table addTableColumn:columnSongTitle];

    var idSongNumber = "songNumber";
    var columnSongNumber = [[CPTableColumn alloc] initWithIdentifier:idSongNumber];
    var titleSongNumber = "Song Number";
    [[columnSongNumber headerView] setStringValue:titleSongNumber];
    [columnSongNumber setEditable:YES];
    [columnSongNumber setWidth:150];
    [table addTableColumn:columnSongNumber];

    var idOwns = "owns";
    var columnOwns = [[CPTableColumn alloc] initWithIdentifier:idOwns];
    var titleOwns = "Owns";
    [[columnOwns headerView] setStringValue:titleOwns];
    [columnOwns setEditable:YES];
    [columnOwns setWidth:150];
    var checkBox = [CPCheckBox checkBoxWithTitle:@""];
    [columnOwns setDataView:checkBox];
    [table addTableColumn:columnOwns];

    // add subviews
    [scroll setDocumentView:table];
    [contentView addSubview:scroll];

    // bind
    var songs = [self createSongs];
    var songsController = [[CPArrayController alloc] init];
    [songsController setContent:songs];

    var columns = [table tableColumns];
    for(var i=0; i<[columns count]; i++){
        var column = columns[i];
        [column bind:@"value" toObject:songsController withKeyPath:@"arrangedObjects." + [column identifier] options:nil];
    }

    // show
    [theWindow orderFront:self];
    
}

- (CPArray)createSongs
{
    var songs = [CPMutableArray array];

    // 1. 
    var song1 = [[Song alloc] initWithArtistName:@"Clifford Brown" songTitle:@"Stardust" songNumber:12 owns:YES];
    [songs addObject:song1];

    // 2. 
    var song2 = [[Song alloc] initWithArtistName:@"Dave Koz" songTitle:@"Over The Rainbow" songNumber:1 owns:NO];
    [songs addObject:song2];

    // 3.
    var song3 = [[Song alloc] initWithArtistName:@"Chet Baker" songTitle:@"Angel Eyes" songNumber:8 owns:YES];
    [songs addObject:song3];

    return songs;
}

@end

@implementation Song : CPObject
{
    CPString _artistName;
    CPString _songTitle;
    int _songNumber;
    BOOL _owns;
}

- (id)initWithArtistName:(CPString)artistName songTitle:(CPString)songTitle songNumber:(int)songNumber owns:(BOOL)owns
{
    self = [super init];
    if (self)
    {
        _artistName = artistName;
        _songTitle = songTitle;
        _songNumber = songNumber;
        _owns = owns;
    }
    return self;
}

- (CPString)artistName
{
    return _artistName;
}

- (void)setArtistName:(CPString)artistName
{
    _artistName = artistName;
}

- (CPString)songTitle
{
    return _songTitle;
}

- (void)setSongTitle:(CPString)songTitle
{
    CPLog("Setting songTitle from " + _songTitle + " to " + songTitle);
    _songTitle = songTitle;
}

- (int)songNumber
{
    return _songNumber;
}

- (void)setSongNumber:(int)songNumber
{
    _songNumber = songNumber;
}

- (BOOL)owns
{
    return _owns;
}

- (void)setOwns:(BOOL)owns
{
    CPLog("Setting owns to " + owns);
    _owns = owns;
}

@end
