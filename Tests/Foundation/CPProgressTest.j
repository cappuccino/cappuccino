/*
 *  CPProgressTest.j
 *  Foundation
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

@import <Foundation/CPKeyValueObserving.j>
@import <Foundation/CPProgress.j>

@implementation CPProgressTestObserver : CPObject
{
    CPArray     values;
}

- (id)init
{
    if (self = [super init])
        values = [];

    return self;
}

- (CPArray)values
{
    return values;
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)aChange context:(id)aContext
{
    values.push([aChange objectForKey:CPKeyValueChangeNewKey]);
}

@end

@implementation CPProgressTest : OJTestCase
{
}

- (void)testCounts
{
    var progress = [CPProgress discreteProgressWithTotalUnitCount:10];

    [self assertTrue:[progress isCancellable]];
    [self assertFalse:[progress isPausable]];
    [self assert:0.0 equals:[progress fractionCompleted]];

    [progress setCompletedUnitCount:4];

    [self assert:0.4 equals:[progress fractionCompleted]];
    [self assertFalse:[progress isFinished]];
    [self assert:@"40% completed" equals:[progress localizedDescription]];
    [self assert:@"4 of 10" equals:[progress localizedAdditionalDescription]];

    [progress setCompletedUnitCount:10];

    [self assertTrue:[progress isFinished]];
}

- (void)testIndeterminate
{
    var progress = [CPProgress discreteProgressWithTotalUnitCount:0];

    [self assertTrue:[progress isIndeterminate]];

    [progress setTotalUnitCount:-1];
    [progress setCompletedUnitCount:3];

    [self assertTrue:[progress isIndeterminate]];
    [self assert:0.0 equals:[progress fractionCompleted]];
    [self assertFalse:[progress isFinished]];

    [progress setTotalUnitCount:6];

    [self assertFalse:[progress isIndeterminate]];
    [self assert:0.5 equals:[progress fractionCompleted]];
}

- (void)testExplicitChild
{
    var parent = [CPProgress discreteProgressWithTotalUnitCount:100],
        child = [CPProgress progressWithTotalUnitCount:4 parent:parent pendingUnitCount:50];

    [child setCompletedUnitCount:2];

    [self assert:0.25 equals:[parent fractionCompleted]];
    [self assert:0 equals:[parent completedUnitCount]];

    [child setCompletedUnitCount:4];

    [self assert:50 equals:[parent completedUnitCount]];
    [self assert:0.5 equals:[parent fractionCompleted]];
}

- (void)testFinishedChildFinishesAncestors
{
    var root = [CPProgress discreteProgressWithTotalUnitCount:1],
        middle = [CPProgress progressWithTotalUnitCount:1 parent:root pendingUnitCount:1],
        leaf = [CPProgress progressWithTotalUnitCount:2 parent:middle pendingUnitCount:1];

    [leaf setCompletedUnitCount:2];

    [self assertTrue:[middle isFinished]];
    [self assertTrue:[root isFinished]];
    [self assert:1.0 equals:[root fractionCompleted]];
}

- (void)testImplicitChild
{
    var parent = [CPProgress discreteProgressWithTotalUnitCount:10];

    [parent becomeCurrentWithPendingUnitCount:6];

    var child = [CPProgress progressWithTotalUnitCount:2],
        second = [CPProgress progressWithTotalUnitCount:2];

    [parent resignCurrent];

    [self assertNull:[CPProgress currentProgress]];

    [child setCompletedUnitCount:1];
    [second setCompletedUnitCount:2];

    [self assert:0.3 equals:[parent fractionCompleted]];
}

- (void)testResignWithoutChildCompletesPendingUnits
{
    var parent = [CPProgress discreteProgressWithTotalUnitCount:10];

    [parent performAsCurrentWithPendingUnitCount:3 usingBlock:function() {}];

    [self assert:3 equals:[parent completedUnitCount]];
}

- (void)testParentMustBeCurrent
{
    var parent = [CPProgress discreteProgressWithTotalUnitCount:10];

    [self assertThrows:function()
    {
        [[CPProgress alloc] initWithParent:parent userInfo:nil];
    }];

    [self assertThrows:function()
    {
        [parent resignCurrent];
    }];
}

- (void)testCancellationReachesChildren
{
    var parent = [CPProgress discreteProgressWithTotalUnitCount:10],
        child = [CPProgress progressWithTotalUnitCount:10 parent:parent pendingUnitCount:5],
        calls = 0;

    [child setCancellationHandler:function() { calls++; }];
    [parent cancel];
    [parent cancel];

    [self assertTrue:[parent isCancelled]];
    [self assertTrue:[child isCancelled]];
    [self assert:1 equals:calls];

    var late = [CPProgress progressWithTotalUnitCount:1 parent:parent pendingUnitCount:1];

    [self assertTrue:[late isCancelled]];
}

- (void)testPausingAndResuming
{
    var parent = [CPProgress discreteProgressWithTotalUnitCount:10],
        child = [CPProgress progressWithTotalUnitCount:10 parent:parent pendingUnitCount:5],
        events = [];

    [child setPausingHandler:function() { events.push(@"pause"); }];
    [child setResumingHandler:function() { events.push(@"resume"); }];

    [parent pause];

    [self assertTrue:[child isPaused]];

    [parent resume];

    [self assertFalse:[child isPaused]];
    [self assert:[@"pause", @"resume"] equals:events];
}

- (void)testObservingFractionCompletedThroughChild
{
    var parent = [CPProgress discreteProgressWithTotalUnitCount:2],
        child = [CPProgress progressWithTotalUnitCount:4 parent:parent pendingUnitCount:2],
        observer = [[CPProgressTestObserver alloc] init];

    [parent addObserver:observer forKeyPath:@"fractionCompleted" options:CPKeyValueObservingOptionNew context:nil];

    [child setCompletedUnitCount:1];
    [child setCompletedUnitCount:4];

    [parent removeObserver:observer forKeyPath:@"fractionCompleted"];

    [self assert:[0.25, 1.0] equals:[observer values]];
}

- (void)testUserInfo
{
    var progress = [CPProgress discreteProgressWithTotalUnitCount:1];

    [progress setThroughput:12];
    [progress setFileOperationKind:CPProgressFileOperationKindReceiving];

    [self assert:12 equals:[progress throughput]];
    [self assert:CPProgressFileOperationKindReceiving equals:[[progress userInfo] objectForKey:CPProgressFileOperationKindKey]];

    [progress setThroughput:nil];

    [self assertNull:[progress throughput]];
}

@end
