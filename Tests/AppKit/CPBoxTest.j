/*
 *  CPBoxTest.j
 *  AppKit
 *
 *  Created by David Richardson on 31/10/2026.
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

@import <AppKit/AppKit.j>

/*
    A box that is archived and read back must keep its content view, its title and
    its internal views, and the content view must remain inside the box.
*/
@implementation CPBoxTest : OJTestCase
{
    CPBox       box;
    CPView      contentView;
    Function    logWarning;
    CPArray     warnings;
}

- (void)setUp
{
    // This will init the global var CPApp which are used internally in the AppKit
    [[CPApplication alloc] init];

    warnings = [];
    logWarning = CPLog.warn;

    CPLog.warn = function(aMessage)
    {
        warnings.push(String(aMessage));
    };

    box = [[CPBox alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 100.0)];
    contentView = [[CPView alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 40.0)];

    [contentView addSubview:[[CPView alloc] initWithFrame:CGRectMake(3.0, 5.0, 20.0, 10.0)]];
    [box setContentView:contentView];
}

- (void)tearDown
{
    CPLog.warn = logWarning;
}

- (CPBox)archivedBox
{
    return [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:box]];
}

- (void)testArchivingKeepsTheContentView
{
    var decodedContentView = [[self archivedBox] contentView];

    [self assertNotNull:decodedContentView];
    [self assert:1 equals:[[decodedContentView subviews] count]];
    [self assertTrue:CGRectEqualToRect([contentView frame], [decodedContentView frame])];
}

- (void)testArchivingKeepsTheContentViewInsideTheBox
{
    var decodedBox = [self archivedBox],
        boxView = [[decodedBox contentView] superview];

    [self assertNotNull:boxView];
    [self assert:decodedBox equals:[boxView superview]];
    [self assertTrue:[[decodedBox subviews] containsObject:boxView]];
}

- (void)testArchivingLeavesTheBoxUnchanged
{
    var subviews = [box subviews];

    [self archivedBox];

    [self assert:subviews equals:[box subviews]];
    [self assert:contentView equals:[box contentView]];
}

- (void)testArchivingKeepsTheTitle
{
    [box setTitle:@"Title"];
    [box setTitlePosition:CPAtTop];

    var decodedBox = [self archivedBox];

    [self assert:@"Title" equals:[decodedBox title]];
    [self assert:CPAtTop equals:[decodedBox titlePosition]];
}

- (void)testUntitledBoxDecodesWithoutAWarning
{
    [self archivedBox];

    [self assert:[] equals:warnings];
}

@end
