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
    CSVImportTestSampleRowCount = 3;

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

/*
    Loads the files one after another, so that their rows keep the order the user chose.
*/
- (void)_importItemProviders:(CPArray)someItemProviders delimiter:(CPString)aDelimiter encoding:(CPStringEncoding)anEncoding hasHeaderRow:(BOOL)hasHeaderRow
{
    var results = [],
        loadNext = function(anIndex)
        {
            if (anIndex >= [someItemProviders count])
            {
                [self _showResults:results delimiter:aDelimiter hasHeaderRow:hasHeaderRow];
                return;
            }

            var itemProvider = someItemProviders[anIndex];

            [itemProvider loadDataRepresentationForTypeIdentifier:@"*/*" completionHandler:function(data, error)
            {
                var result = data ? [self _decodeData:data encoding:anEncoding] : { error: [error localizedDescription] };

                result.name = [itemProvider suggestedName];
                results.push(result);

                loadNext(anIndex + 1);
            }];
        };

    [self _setStatus:@"Loading " + [someItemProviders count] + @" file(s)…"];
    loadNext(0);
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
    Parses the decoded files and shows their rows in the table. The first file's header row
    names the columns. With several files, a first column names the file of each row.
*/
- (void)_showResults:(CPArray)someResults delimiter:(CPString)aDelimiter hasHeaderRow:(BOOL)hasHeaderRow
{
    var headers = nil,
        rows = [],
        lines = [],
        showsFileColumn = [someResults count] > 1;

    for (var i = 0; i < [someResults count]; i++)
    {
        var result = someResults[i];

        if (result.error)
        {
            lines.push(result.name + @": " + result.error);
            continue;
        }

        var delimiter = aDelimiter || [CSVParser detectedDelimiterForString:result.string],
            records = [CSVParser recordsFromString:result.string delimiter:delimiter];

        if (hasHeaderRow && records.length)
        {
            var headerRecord = records.shift();

            if (!headers)
                headers = headerRecord;
        }

        lines.push(result.name + @": " + result.encodingDescription + @", " + [self _nameOfDelimiter:delimiter] + @", " + records.length + @" row(s)");

        for (var j = 0; j < records.length; j++)
            rows.push(showsFileColumn ? [result.name].concat(records[j]) : records[j]);
    }

    headers = headers || [];

    if (showsFileColumn)
        headers = [@"File"].concat(headers);

    for (var i = 0; i < rows.length; i++)
        while (headers.length < rows[i].length)
            headers.push(@"Column " + (headers.length + 1));

    [self _setHeaders:headers rows:rows];
    [self _setStatus:lines.join(@" · ")];
}

- (CPString)_nameOfDelimiter:(CPString)aDelimiter
{
    var index = CSVImportTestDelimiters.indexOf(aDelimiter);

    return index > 0 ? CSVImportTestDelimiterTitles[index].toLowerCase() + @" delimiter" : @"delimiter " + aDelimiter;
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
