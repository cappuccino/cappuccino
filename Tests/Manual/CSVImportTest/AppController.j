/*
 *  AppController.j
 *  CSVImportTest
 *
 *  Created by David Richardson on 2026-11-02.
 *  Copyright David Richardson 2026.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
 */

/*
    A manual test of CPOpenPanel, CPItemProvider and the string encoding methods. The user
    imports CSV files into a table, and can assign the columns to fixed fields.

    What it exercises:

    - Import CSV… runs the open panel with a message and an accessory view, which hold the
      delimiter, the encoding and the header row option. The panel shows a Cappuccino panel
      first, and its Import button opens the browser's file dialog.
    - Quick Import runs the open panel with neither, so the browser's file dialog opens at once.
    - The check boxes run the panel as a sheet, allow several files, choose a folder instead of
      files, and set a delegate that rejects files whose names contain "bad".
    - The allowed file types are csv and text/csv, so other files are removed and reported.
    - Each file is read through its item provider, and decoded with the chosen encoding, or with
      encoding detection.
    - Map Fields… shows each column with sample values, and a pop-up to assign it to a field.
    - A progress panel shows each phase of an import, with a progress bar driven by a
      CPProgress object, and a Cancel button. Large files show how reading, decoding and
      parsing perform, and how CPTableView scrolls through millions of rows.

    Sample files are in Resources/Samples. Their names state their encoding and delimiter.
    contacts-mac-roman.csv is detected as Windows Latin 1, which shows wrong accents; choosing
    Western (Mac OS Roman) as the encoding reads it correctly.
*/

@import <Foundation/Foundation.j>
@import <AppKit/AppKit.j>

@import "CSVParser.j"

var CSVImportTestFields = [@"Name", @"Email", @"Phone", @"Notes"],
    CSVImportTestDelimiters = [nil, @",", @";", @"\t", @"|"],
    CSVImportTestDelimiterTitles = [@"Automatic", @"Comma", @"Semicolon", @"Tab", @"Vertical Bar"],
    CSVImportTestSampleRowCount = 3,
    CSVImportTestReadUnits = 40,
    CSVImportTestDecodeUnits = 10,
    CSVImportTestParseUnits = 50,
    CSVImportTestUnitsPerFile = CSVImportTestReadUnits + CSVImportTestDecodeUnits + CSVImportTestParseUnits,
    CSVImportTestChunkLength = 1000000,
    CSVImportTestMaximumElementHeight = 33554432;

@implementation AppController : CPObject
{
    CPWindow        _window;
    CPTableView     _tableView;
    CPTextField     _statusField;

    CPCheckBox      _sheetCheckBox;
    CPCheckBox      _multipleCheckBox;
    CPCheckBox      _folderCheckBox;
    CPCheckBox      _rejectCheckBox;

    CPView          _accessoryView;
    CPPopUpButton   _delimiterPopUp;
    CPPopUpButton   _encodingPopUp;
    CPCheckBox      _headerCheckBox;
    CPArray         _encodings;

    CPProgress      _importProgress;
    JSObject        _import;
    CPPanel         _progressPanel;
    CPProgressIndicator _progressIndicator;
    CPTextField     _phaseField;
    CPTextField     _detailField;

    CPArray         _headers;
    CPArray         _rows;

    CPWindow        _mappingSheet;
    CPArray         _mappingPopUps;
    CPTextField     _mappingWarningField;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    _headers = [];
    _rows = [];

    _window = [[CPWindow alloc] initWithContentRect:CGRectMakeZero() styleMask:CPBorderlessBridgeWindowMask];

    var contentView = [_window contentView],
        width = CGRectGetWidth([contentView bounds]),
        height = CGRectGetHeight([contentView bounds]);

    [contentView addSubview:[self _buttonWithTitle:@"Import CSV…" action:@selector(importCSV:) frame:CGRectMake(20.0, 20.0, 130.0, 24.0)]];
    [contentView addSubview:[self _buttonWithTitle:@"Quick Import" action:@selector(quickImport:) frame:CGRectMake(160.0, 20.0, 120.0, 24.0)]];
    [contentView addSubview:[self _buttonWithTitle:@"Map Fields…" action:@selector(mapFields:) frame:CGRectMake(290.0, 20.0, 120.0, 24.0)]];

    _sheetCheckBox = [self _checkBoxWithTitle:@"As a sheet" origin:CGPointMake(20.0, 58.0)];
    _multipleCheckBox = [self _checkBoxWithTitle:@"Several files" origin:CGPointMake(140.0, 58.0)];
    _folderCheckBox = [self _checkBoxWithTitle:@"Choose a folder" origin:CGPointMake(270.0, 58.0)];
    _rejectCheckBox = [self _checkBoxWithTitle:@"Delegate rejects names containing \"bad\"" origin:CGPointMake(410.0, 58.0)];

    [contentView addSubview:_sheetCheckBox];
    [contentView addSubview:_multipleCheckBox];
    [contentView addSubview:_folderCheckBox];
    [contentView addSubview:_rejectCheckBox];

    _statusField = [CPTextField labelWithTitle:@"Import a CSV file. Sample files are in Resources/Samples."];
    [_statusField setLineBreakMode:CPLineBreakByWordWrapping];
    [_statusField setFrame:CGRectMake(20.0, 88.0, width - 40.0, 48.0)];
    [_statusField setAutoresizingMask:CPViewWidthSizable];
    [contentView addSubview:_statusField];

    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(20.0, 140.0, width - 40.0, height - 160.0)];

    _tableView = [[CPTableView alloc] initWithFrame:[[scrollView contentView] bounds]];
    [_tableView setUsesAlternatingRowBackgroundColors:YES];
    [_tableView setColumnAutoresizingStyle:CPTableViewNoColumnAutoresizing];
    [_tableView setDataSource:self];

    [scrollView setDocumentView:_tableView];
    [scrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [scrollView setBorderType:CPBezelBorder];
    [contentView addSubview:scrollView];

    [self _buildAccessoryView];

    [_window orderFront:self];
}

- (CPButton)_buttonWithTitle:(CPString)aTitle action:(SEL)anAction frame:(CGRect)aFrame
{
    var button = [CPButton buttonWithTitle:aTitle];

    [button setFrame:aFrame];
    [button setTarget:self];
    [button setAction:anAction];

    return button;
}

- (CPCheckBox)_checkBoxWithTitle:(CPString)aTitle origin:(CGPoint)anOrigin
{
    var checkBox = [CPCheckBox checkBoxWithTitle:aTitle];

    [checkBox sizeToFit];
    [checkBox setFrameOrigin:anOrigin];

    return checkBox;
}

/*
    Builds the open panel's accessory view: the delimiter, the encoding, and whether the first
    row is a header. The encoding pop-up lists every encoding the browser can decode.
*/
- (void)_buildAccessoryView
{
    _accessoryView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 400.0, 96.0)];

    var delimiterLabel = [CPTextField labelWithTitle:@"Delimiter:"],
        encodingLabel = [CPTextField labelWithTitle:@"Encoding:"];

    [delimiterLabel setFrame:CGRectMake(0.0, 4.0, 85.0, 20.0)];
    [delimiterLabel setAlignment:CPRightTextAlignment];
    [_accessoryView addSubview:delimiterLabel];

    _delimiterPopUp = [[CPPopUpButton alloc] initWithFrame:CGRectMake(90.0, 0.0, 160.0, 24.0) pullsDown:NO];
    [_delimiterPopUp addItemsWithTitles:CSVImportTestDelimiterTitles];
    [_accessoryView addSubview:_delimiterPopUp];

    [encodingLabel setFrame:CGRectMake(0.0, 36.0, 85.0, 20.0)];
    [encodingLabel setAlignment:CPRightTextAlignment];
    [_accessoryView addSubview:encodingLabel];

    _encodings = [CPString availableStringEncodings];
    _encodingPopUp = [[CPPopUpButton alloc] initWithFrame:CGRectMake(90.0, 32.0, 300.0, 24.0) pullsDown:NO];
    [_encodingPopUp addItemWithTitle:@"Automatic"];

    /*
        The array ends with 0, as in Cocoa, so the loop stops there rather than at its count.
    */
    for (var i = 0; _encodings[i] !== 0; i++)
        [_encodingPopUp addItemWithTitle:[CPString localizedNameOfStringEncoding:_encodings[i]]];

    [_accessoryView addSubview:_encodingPopUp];

    _headerCheckBox = [CPCheckBox checkBoxWithTitle:@"The first row holds column names"];
    [_headerCheckBox sizeToFit];
    [_headerCheckBox setFrameOrigin:CGPointMake(90.0, 68.0)];
    [_headerCheckBox setState:CPOnState];
    [_accessoryView addSubview:_headerCheckBox];
}

- (void)_setStatus:(CPString)aStatus
{
    [_statusField setStringValue:aStatus];
}

// MARK: Importing

- (@action)importCSV:(id)aSender
{
    [self _runOpenPanelWithOptions:YES];
}

- (@action)quickImport:(id)aSender
{
    [self _runOpenPanelWithOptions:NO];
}

/*
    Runs the open panel. This is called from an action method, which is the user action the
    browser requires before it opens its file dialog.
*/
- (void)_runOpenPanelWithOptions:(BOOL)showsOptions
{
    var openPanel = [CPOpenPanel openPanel],
        choosesFolder = [_folderCheckBox state] === CPOnState;

    [openPanel setAllowedFileTypes:[@"csv", @"text/csv"]];
    [openPanel setAllowsMultipleSelection:[_multipleCheckBox state] === CPOnState];
    [openPanel setCanChooseDirectories:choosesFolder];
    [openPanel setCanChooseFiles:!choosesFolder];

    if ([_rejectCheckBox state] === CPOnState)
        [openPanel setDelegate:self];

    if (showsOptions)
    {
        [openPanel setMessage:@"Choose CSV files to import. Options sets the delimiter, the encoding and the header row."];
        [openPanel setAccessoryView:_accessoryView];
        [openPanel setPrompt:@"Import"];
    }

    var completionHandler = function(aResponse)
    {
        if (aResponse !== CPOKButton)
        {
            [self _setStatus:@"The import was cancelled."];
            return;
        }

        var delimiter = showsOptions ? CSVImportTestDelimiters[[_delimiterPopUp indexOfSelectedItem]] : nil,
            encodingIndex = showsOptions ? [_encodingPopUp indexOfSelectedItem] : 0,
            encoding = encodingIndex > 0 ? _encodings[encodingIndex - 1] : 0,
            hasHeaderRow = showsOptions ? [_headerCheckBox state] === CPOnState : YES;

        [self _importItemProviders:[openPanel itemProviders] delimiter:delimiter encoding:encoding hasHeaderRow:hasHeaderRow];
    };

    if ([_sheetCheckBox state] === CPOnState)
        [openPanel beginSheetModalForWindow:_window completionHandler:completionHandler];
    else
        [openPanel beginWithCompletionHandler:completionHandler];
}

/*
    The open panel's delegate method. It rejects files whose names contain "bad".
*/
- (BOOL)panel:(id)aSender validateURL:(CPURL)aURL error:(CPError)outError
{
    if ([aURL relativeString].indexOf("bad") < 0)
        return YES;

    @deref(outError) = [CPError errorWithDomain:@"CSVImportTestErrorDomain"
                                           code:1
                                       userInfo:@{ CPLocalizedDescriptionKey: @"The delegate rejected " + decodeURIComponent([aURL relativeString]) + @", because its name contains \"bad\"." }];

    return NO;
}

// MARK: Importing with Progress

/*
    An import runs in phases, for each file in turn: reading, decoding and parsing. Then the
    table is built. One CPProgress object counts the whole import, so one progress bar covers
    every phase of every file:

    - Reading is the item provider's load. The progress object it returns counts the bytes
      read, and becomes a child of the import's progress object.
    - Decoding turns the bytes into text in one step, which cannot be divided.
    - Parsing runs in chunks between run loop passes, so the panel stays responsive and the
      user can cancel at any time. A child progress object counts the characters parsed.

    Cancelling the import's progress object cancels the read in progress, through its child.
    The parser stops before its next chunk. The table keeps its previous contents.
*/
- (void)_importItemProviders:(CPArray)someItemProviders delimiter:(CPString)aDelimiter encoding:(CPStringEncoding)anEncoding hasHeaderRow:(BOOL)hasHeaderRow
{
    _importProgress = [CPProgress discreteProgressWithTotalUnitCount:[someItemProviders count] * CSVImportTestUnitsPerFile];
    _import = {
        itemProviders: someItemProviders,
        delimiter: aDelimiter,
        encoding: anEncoding,
        hasHeaderRow: hasHeaderRow,
        index: 0,
        results: [],
        rowCount: 0,
        startTime: new Date(),
        hasEnded: NO
    };

    [self _beginProgressPanel];
    [self _importNextFile];
}

/*
    Reads the next file, or builds the table when every file has been read.
*/
- (void)_importNextFile
{
    if (!_import)
        return;

    if ([_importProgress isCancelled])
        return [self _endImportCancelled];

    if (_import.index >= [_import.itemProviders count])
        return [self _buildTable];

    var itemProvider = _import.itemProviders[_import.index],
        name = [itemProvider suggestedName],
        readHasEnded = NO,
        readProgress = nil;

    [self _setPhase:@"Reading " + name + @"…"];

    readProgress = [itemProvider loadDataRepresentationForTypeIdentifier:@"*/*" completionHandler:function(data, error)
    {
        readHasEnded = YES;

        if (!_import)
            return;

        if ([_importProgress isCancelled])
            return [self _endImportCancelled];

        if (!data)
        {
            if (readProgress && ![readProgress isFinished])
                [readProgress setCompletedUnitCount:[readProgress totalUnitCount]];

            [self _skipFileNamed:name error:[error localizedDescription]];
            return;
        }

        [self _setPhase:@"Decoding " + name + @"…"];

        /*
            Decoding blocks until it ends. Waiting one run loop pass first lets the panel show
            the new phase.
        */
        [CPTimer scheduledTimerWithTimeInterval:0.0 callback:function()
        {
            [self _decodeData:data name:name];
        } repeats:NO];
    }];

    if (!readHasEnded)
        [_importProgress addChild:readProgress withPendingUnitCount:CSVImportTestReadUnits];
}

/*
    Records a file that could not be read or decoded, completes its units, and goes on.
*/
- (void)_skipFileNamed:(CPString)aName error:(CPString)anError
{
    _import.results.push({ name: aName, error: anError });
    [_importProgress setCompletedUnitCount:(_import.index + 1) * CSVImportTestUnitsPerFile];
    _import.index++;
    [self _importNextFile];
}

/*
    Decodes a file's data, then starts parsing it.
*/
- (void)_decodeData:(CPData)someData name:(CPString)aName
{
    if (!_import)
        return;

    if ([_importProgress isCancelled])
        return [self _endImportCancelled];

    var result = [self _decodeData:someData encoding:_import.encoding],
        base = _import.index * CSVImportTestUnitsPerFile;

    result.name = aName;

    if (result.error)
        return [self _skipFileNamed:aName error:result.error];

    [_importProgress setCompletedUnitCount:base + CSVImportTestReadUnits + CSVImportTestDecodeUnits];

    result.delimiter = _import.delimiter || [CSVParser detectedDelimiterForString:result.string];
    result.parser = [[CSVParser alloc] initWithString:result.string delimiter:result.delimiter];
    result.string = nil;

    var parseProgress = [CPProgress progressWithTotalUnitCount:MAX([result.parser length], 1) parent:_importProgress pendingUnitCount:CSVImportTestParseUnits];

    [self _setPhase:@"Parsing " + aName + @"…"];
    [self _parseNextChunkOfResult:result progress:parseProgress];
}

/*
    Decodes a file's data with the chosen encoding, or detects the encoding when none is chosen.
    Returns the string and a description of the encoding, or an error.
*/
- (JSObject)_decodeData:(CPData)someData encoding:(CPStringEncoding)anEncoding
{
    if (anEncoding)
    {
        var string = [[CPString alloc] initWithData:someData encoding:anEncoding],
            name = [CPString localizedNameOfStringEncoding:anEncoding];

        if (string === nil)
            return { error: @"The file is not valid " + name + @"." };

        return { string: string, encodingDescription: name };
    }

    var detectedString = nil,
        usedLossyConversion = NO,
        detectedEncoding = [CPString stringEncodingForData:someData encodingOptions:nil convertedString:@ref(detectedString) usedLossyConversion:@ref(usedLossyConversion)];

    if (!detectedEncoding)
        return { error: @"No encoding fits the file." };

    return {
        string: detectedString,
        encodingDescription: [CPString localizedNameOfStringEncoding:detectedEncoding] + @" (detected" + (usedLossyConversion ? @", lossy" : @"") + @")"
    };
}

/*
    Parses one chunk, then waits for the next run loop pass before the next chunk, so that the
    panel can draw and the Cancel button can be clicked.
*/
- (void)_parseNextChunkOfResult:(JSObject)aResult progress:(CPProgress)aProgress
{
    if (!_import)
        return;

    if ([_importProgress isCancelled])
        return [self _endImportCancelled];

    var parser = aResult.parser,
        isDone = [parser parseNextChunkOfLength:CSVImportTestChunkLength];

    [aProgress setCompletedUnitCount:isDone ? [aProgress totalUnitCount] : [parser position]];
    [self _setDetail:(_import.rowCount + [[parser records] count]).toLocaleString() + @" rows"];

    if (!isDone)
    {
        [CPTimer scheduledTimerWithTimeInterval:0.0 callback:function()
        {
            [self _parseNextChunkOfResult:aResult progress:aProgress];
        } repeats:NO];

        return;
    }

    aResult.records = [parser records];
    aResult.parser = nil;

    _import.rowCount += aResult.records.length;
    _import.results.push(aResult);
    _import.index++;

    [self _importNextFile];
}

/*
    Builds the table from the parsed files. The first file's header row names the columns. With
    several files, a first column names the file of each row.
*/
- (void)_buildTable
{
    [self _setPhase:@"Building the table…"];

    [CPTimer scheduledTimerWithTimeInterval:0.0 callback:function()
    {
        if (!_import)
            return;

        if ([_importProgress isCancelled])
            return [self _endImportCancelled];

        var results = _import.results,
            headers = nil,
            rows = [],
            lines = [],
            showsFileColumn = results.length > 1;

        for (var i = 0; i < results.length; i++)
        {
            var result = results[i];

            if (result.error)
            {
                lines.push(result.name + @": " + result.error);
                continue;
            }

            var records = result.records;

            if (_import.hasHeaderRow && records.length)
            {
                var headerRecord = records.shift();

                if (!headers)
                    headers = headerRecord;
            }

            lines.push(result.name + @": " + result.encodingDescription + @", " + [self _nameOfDelimiter:result.delimiter] + @", " + records.length.toLocaleString() + @" row(s)");

            if (showsFileColumn)
            {
                for (var j = 0; j < records.length; j++)
                    rows.push([result.name].concat(records[j]));
            }
            else
                rows = rows.length ? rows.concat(records) : records;
        }

        headers = headers || [];

        if (showsFileColumn)
            headers = [@"File"].concat(headers);

        var widestRow = 0;

        for (var i = 0; i < rows.length; i++)
            widestRow = MAX(widestRow, rows[i].length);

        while (headers.length < widestRow)
            headers.push(@"Column " + (headers.length + 1));

        [self _setHeaders:headers rows:rows];

        var seconds = ((new Date() - _import.startTime) / 1000).toFixed(1),
            rowHeight = [_tableView rowHeight] + [_tableView intercellSpacing].height,
            displayableRowCount = FLOOR(CSVImportTestMaximumElementHeight / rowHeight);

        lines.unshift(@"Imported " + rows.length.toLocaleString() + @" rows in " + seconds + @" s");

        /*
            The table's document view is as tall as all its rows, and browsers limit an element's
            height to 33,554,432 pixels. Rows past that height cannot be shown.
        */
        if (rows.length > displayableRowCount)
            lines.push(@"Rows after " + displayableRowCount.toLocaleString() + @" cannot be shown: the table would be taller than the browser allows");

        [self _setStatus:lines.join(@" · ")];
        [self _endProgressPanel];
    } repeats:NO];
}

- (CPString)_nameOfDelimiter:(CPString)aDelimiter
{
    var index = CSVImportTestDelimiters.indexOf(aDelimiter);

    return index > 0 ? CSVImportTestDelimiterTitles[index].toLowerCase() + @" delimiter" : @"delimiter " + aDelimiter;
}

// MARK: The Progress Panel

/*
    Shows a modal panel with the current phase, a progress bar and a Cancel button. The progress
    bar follows the import's progress object through key-value observing.
*/
- (void)_beginProgressPanel
{
    _progressPanel = [[CPPanel alloc] initWithContentRect:CGRectMake(0.0, 0.0, 440.0, 140.0) styleMask:CPTitledWindowMask];
    [_progressPanel setTitle:@"Importing"];

    var contentView = [_progressPanel contentView],
        cancelButton = [self _buttonWithTitle:@"Cancel" action:@selector(cancelImport:) frame:CGRectMake(330.0, 100.0, 90.0, 24.0)];

    _phaseField = [CPTextField labelWithTitle:@""];
    [_phaseField setFrame:CGRectMake(20.0, 18.0, 400.0, 20.0)];
    [_phaseField setFont:[CPFont boldSystemFontOfSize:12.0]];
    [contentView addSubview:_phaseField];

    _progressIndicator = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(20.0, 46.0, 400.0, 20.0)];
    [_progressIndicator setStyle:CPProgressIndicatorBarStyle];
    [_progressIndicator setIndeterminate:NO];
    [_progressIndicator setMinValue:0.0];
    [_progressIndicator setMaxValue:1.0];
    [_progressIndicator setDoubleValue:0.0];
    [contentView addSubview:_progressIndicator];

    _detailField = [CPTextField labelWithTitle:@""];
    [_detailField setFrame:CGRectMake(20.0, 72.0, 400.0, 20.0)];
    [_detailField setTextColor:[CPColor grayColor]];
    [contentView addSubview:_detailField];

    [cancelButton setKeyEquivalent:CPEscapeFunctionKey];
    [contentView addSubview:cancelButton];

    [_importProgress addObserver:self forKeyPath:@"fractionCompleted" options:CPKeyValueObservingOptionNew context:nil];

    [_progressPanel center];
    [CPApp runModalForWindow:_progressPanel];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)aChange context:(id)aContext
{
    if (anObject === _importProgress)
        [_progressIndicator setDoubleValue:[_importProgress fractionCompleted]];
}

- (void)_setPhase:(CPString)aPhase
{
    [_phaseField setStringValue:aPhase];
}

- (void)_setDetail:(CPString)aDetail
{
    var seconds = ((new Date() - _import.startTime) / 1000).toFixed(1);

    [_detailField setStringValue:aDetail + @" · " + seconds + @" s"];
}

/*
    Cancels the import. Cancelling the progress object reaches the read in progress, and the
    parser checks it before each chunk.
*/
- (@action)cancelImport:(id)aSender
{
    [self _setPhase:@"Cancelling…"];
    [_importProgress cancel];
}

- (void)_endImportCancelled
{
    if (!_import || _import.hasEnded)
        return;

    [self _setStatus:@"The import was cancelled. The table is unchanged."];
    [self _endProgressPanel];
}

- (void)_endProgressPanel
{
    if (!_import || _import.hasEnded)
        return;

    _import.hasEnded = YES;

    [_importProgress removeObserver:self forKeyPath:@"fractionCompleted"];
    [CPApp abortModal];
    [_progressPanel close];

    _progressPanel = nil;
    _importProgress = nil;
    _import = nil;
}

// MARK: The Table

/*
    Replaces the table's columns with one column for each header.
*/
- (void)_setHeaders:(CPArray)someHeaders rows:(CPArray)someRows
{
    _headers = someHeaders;
    _rows = someRows;

    var columns = [[_tableView tableColumns] copy];

    for (var i = 0; i < [columns count]; i++)
        [_tableView removeTableColumn:columns[i]];

    for (var i = 0; i < [_headers count]; i++)
    {
        var column = [[CPTableColumn alloc] initWithIdentifier:String(i)];

        [[column headerView] setStringValue:_headers[i]];
        [column setWidth:160.0];
        [_tableView addTableColumn:column];
    }

    [_tableView reloadData];
}

- (int)numberOfRowsInTableView:(CPTableView)aTableView
{
    return [_rows count];
}

- (id)tableView:(CPTableView)aTableView objectValueForTableColumn:(CPTableColumn)aTableColumn row:(int)aRow
{
    var value = _rows[aRow][parseInt([aTableColumn identifier], 10)];

    return value === undefined ? @"" : value;
}

// MARK: Mapping Fields

/*
    Shows a sheet with one line for each column: its name, sample values from the first rows,
    and a pop-up to assign it to a field. A column whose name matches a field is assigned to it.
*/
- (@action)mapFields:(id)aSender
{
    if (![_headers count])
    {
        [self _setStatus:@"Import a file before mapping its fields."];
        return;
    }

    var lineHeight = 32.0,
        listHeight = MIN(300.0, [_headers count] * lineHeight),
        sheetWidth = 640.0,
        sheetHeight = 60.0 + listHeight + 90.0;

    _mappingSheet = [[CPWindow alloc] initWithContentRect:CGRectMake(0.0, 0.0, sheetWidth, sheetHeight) styleMask:CPDocModalWindowMask];
    _mappingPopUps = [];

    var contentView = [_mappingSheet contentView],
        introField = [CPTextField labelWithTitle:@"Assign each column to a field. The samples come from the first " + CSVImportTestSampleRowCount + @" rows."],
        scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(20.0, 50.0, sheetWidth - 40.0, listHeight)],
        listView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, sheetWidth - 60.0, [_headers count] * lineHeight)];

    [introField setFrame:CGRectMake(20.0, 20.0, sheetWidth - 40.0, 20.0)];
    [contentView addSubview:introField];

    for (var i = 0; i < [_headers count]; i++)
    {
        var y = i * lineHeight + 4.0,
            nameField = [CPTextField labelWithTitle:_headers[i]],
            sampleField = [CPTextField labelWithTitle:[self _samplesForColumn:i]],
            popUp = [[CPPopUpButton alloc] initWithFrame:CGRectMake(sheetWidth - 60.0 - 150.0, y - 2.0, 150.0, 24.0) pullsDown:NO];

        [nameField setFrame:CGRectMake(0.0, y, 150.0, 20.0)];
        [nameField setFont:[CPFont boldSystemFontOfSize:12.0]];
        [listView addSubview:nameField];

        [sampleField setFrame:CGRectMake(160.0, y, sheetWidth - 60.0 - 330.0, 20.0)];
        [sampleField setTextColor:[CPColor grayColor]];
        [listView addSubview:sampleField];

        [popUp addItemWithTitle:@"Ignore"];
        [popUp addItemsWithTitles:CSVImportTestFields];
        [popUp selectItemAtIndex:[self _fieldIndexForHeader:_headers[i]] + 1];
        [listView addSubview:popUp];

        _mappingPopUps.push(popUp);
    }

    [scrollView setDocumentView:listView];
    [scrollView setHasHorizontalScroller:NO];
    [contentView addSubview:scrollView];

    _mappingWarningField = [CPTextField labelWithTitle:@""];
    [_mappingWarningField setFrame:CGRectMake(20.0, 60.0 + listHeight, sheetWidth - 40.0, 20.0)];
    [_mappingWarningField setTextColor:[CPColor redColor]];
    [contentView addSubview:_mappingWarningField];

    var applyButton = [self _buttonWithTitle:@"Apply" action:@selector(_applyMapping:) frame:CGRectMake(sheetWidth - 20.0 - 90.0, sheetHeight - 44.0, 90.0, 24.0)],
        cancelButton = [self _buttonWithTitle:@"Cancel" action:@selector(_cancelMapping:) frame:CGRectMake(sheetWidth - 20.0 - 190.0, sheetHeight - 44.0, 90.0, 24.0)];

    [contentView addSubview:applyButton];
    [contentView addSubview:cancelButton];
    [_mappingSheet setDefaultButton:applyButton];

    [CPApp beginSheet:_mappingSheet modalForWindow:_window modalDelegate:self didEndSelector:@selector(_mappingSheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

/*
    Returns the first non-empty values of a column, joined.
*/
- (CPString)_samplesForColumn:(int)aColumn
{
    var samples = [];

    for (var i = 0; i < [_rows count] && samples.length < CSVImportTestSampleRowCount; i++)
    {
        var value = _rows[i][aColumn];

        if (value)
            samples.push(value.replace(/\s+/g, " "));
    }

    return samples.join(@" · ") || @"(empty)";
}

/*
    Returns the index of the field whose name matches a header, ignoring case, or -1.
*/
- (int)_fieldIndexForHeader:(CPString)aHeader
{
    var header = (aHeader || @"").toLowerCase();

    for (var i = 0; i < CSVImportTestFields.length; i++)
        if (CSVImportTestFields[i].toLowerCase() === header)
            return i;

    return -1;
}

- (@action)_applyMapping:(id)aSender
{
    var usedFields = {};

    for (var i = 0; i < _mappingPopUps.length; i++)
    {
        var fieldIndex = [_mappingPopUps[i] indexOfSelectedItem] - 1;

        if (fieldIndex < 0)
            continue;

        if (usedFields[fieldIndex] !== undefined)
        {
            [_mappingWarningField setStringValue:@"The field " + CSVImportTestFields[fieldIndex] + @" is assigned to both " + _headers[usedFields[fieldIndex]] + @" and " + _headers[i] + @"."];
            return;
        }

        usedFields[fieldIndex] = i;
    }

    [_mappingSheet orderOut:self];
    [CPApp endSheet:_mappingSheet returnCode:CPOKButton];
}

- (@action)_cancelMapping:(id)aSender
{
    [_mappingSheet orderOut:self];
    [CPApp endSheet:_mappingSheet returnCode:CPCancelButton];
}

/*
    Rebuilds the table with one column for each assigned field, in the fields' order.
*/
- (void)_mappingSheetDidEnd:(CPWindow)aSheet returnCode:(int)aReturnCode contextInfo:(id)contextInfo
{
    var popUps = _mappingPopUps;

    _mappingSheet = nil;
    _mappingPopUps = nil;

    if (aReturnCode !== CPOKButton)
        return;

    var headers = [],
        sourceColumns = [];

    for (var fieldIndex = 0; fieldIndex < CSVImportTestFields.length; fieldIndex++)
        for (var i = 0; i < popUps.length; i++)
            if ([popUps[i] indexOfSelectedItem] - 1 === fieldIndex)
            {
                headers.push(CSVImportTestFields[fieldIndex]);
                sourceColumns.push(i);
            }

    var rows = _rows.map(function(aRow)
    {
        return sourceColumns.map(function(aColumn) { return aRow[aColumn] || @""; });
    });

    [self _setHeaders:headers rows:rows];
    [self _setStatus:@"Mapped " + headers.length + @" column(s) to fields: " + headers.join(@", ") + @"."];
}

@end
