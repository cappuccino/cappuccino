/*
 *  CPProgress.j
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

@import "CPArray.j"
@import "CPDictionary.j"
@import "CPException.j"
@import "CPKeyValueObserving.j"
@import "CPObject.j"
@import "CPSet.j"
@import "CPString.j"

CPProgressKindFile                          = @"CPProgressKindFile";

CPProgressEstimatedTimeRemainingKey         = @"CPProgressEstimatedTimeRemainingKey";
CPProgressThroughputKey                     = @"CPProgressThroughputKey";
CPProgressFileOperationKindKey              = @"CPProgressFileOperationKindKey";
CPProgressFileURLKey                        = @"CPProgressFileURLKey";
CPProgressFileTotalCountKey                 = @"CPProgressFileTotalCountKey";
CPProgressFileCompletedCountKey             = @"CPProgressFileCompletedCountKey";

CPProgressFileOperationKindDownloading      = @"CPProgressFileOperationKindDownloading";
CPProgressFileOperationKindDecompressingAfterDownloading = @"CPProgressFileOperationKindDecompressingAfterDownloading";
CPProgressFileOperationKindReceiving        = @"CPProgressFileOperationKindReceiving";
CPProgressFileOperationKindCopying          = @"CPProgressFileOperationKindCopying";
CPProgressFileOperationKindUploading        = @"CPProgressFileOperationKindUploading";
CPProgressFileOperationKindDuplicating      = @"CPProgressFileOperationKindDuplicating";

/*
    The keys whose values follow from the unit counts of a progress object and of its children.
    They change together, so they are announced together. See -_performCountChange:.
*/
var CPProgressCountKeys = [@"totalUnitCount", @"completedUnitCount", @"fractionCompleted", @"finished", @"indeterminate", @"localizedDescription", @"localizedAdditionalDescription"],
    CPProgressManuallyNotifiedKeys = [CPSet setWithArray:CPProgressCountKeys.concat([@"cancelled", @"paused", @"cancellable", @"pausable", @"kind", @"userInfo"])],
    CPProgressCurrentStack = [];

/*
    TODO: Gaps against NSProgress that can be filled:

    - The fileURL, fileTotalCount and fileCompletedCount properties. Only their user
      information keys exist.
    - The NSProgressReporting protocol, with its progress property.
    - The default descriptions. Cocoa's depend on the kind, and its additional description
      includes the estimated time remaining and the throughput. These are the percentage and
      the unit counts only.
    - The file icon and file animation user information keys.
    - Setting a cancellation or pausing handler on a progress object that is already cancelled
      or paused. Check whether Cocoa calls the handler at once; this class does not.
    - Key-value observing. Cocoa announces only the keys that change; this class announces
      every unit-count key of each progress object in the chain.
*/

/*!
    @class CPProgress
    @ingroup foundation
    @brief Reports the progress of a task, and lets the user cancel or pause it.

    This class is modelled on NSProgress. A progress object counts units of work: a total, and
    the units completed. Its fraction completed can be observed with key-value observing, and
    shown in a progress indicator.

    Progress objects form a tree. A child progress object stands for a number of its parent's
    units, its pending unit count. As the child advances, the parent's fraction completed
    advances in proportion. When the child finishes, its pending units are added to the
    parent's completed units. A child is attached explicitly, with
    -addChild:withPendingUnitCount:, or implicitly: a progress object made while its parent is
    the current progress object, between -becomeCurrentWithPendingUnitCount: and
    -resignCurrent, becomes its child.

    Cancelling or pausing a progress object also cancels or pauses its children, and calls its
    handler. A task checks -isCancelled, or sets a cancellation handler, to stop its work.

    In a browser there is one thread, so handlers are called at once, on that thread. The
    unit-count keys are announced together whenever a count changes in the tree, so an
    observer may receive a notification for a key whose value did not change.

    Publishing and subscribing (-publish, -unpublish, the subscriber methods and -isOld) are
    not provided. They share file progress between processes, and a page is one process.
*/
@implementation CPProgress : CPObject
{
    CPProgress          _parent;
    CPArray             _children;

    int                 _totalUnitCount;
    int                 _completedUnitCount;

    BOOL                _cancellable;
    BOOL                _pausable;
    BOOL                _cancelled;
    BOOL                _paused;

    Function            _cancellationHandler    @accessors(property=cancellationHandler);
    Function            _pausingHandler         @accessors(property=pausingHandler);
    Function            _resumingHandler        @accessors(property=resumingHandler);

    CPString            _localizedDescription;
    CPString            _localizedAdditionalDescription;
    CPString            _kind;
    CPMutableDictionary _userInfo;
}

+ (BOOL)automaticallyNotifiesObserversForKey:(CPString)aKey
{
    if ([CPProgressManuallyNotifiedKeys containsObject:aKey])
        return NO;

    return [super automaticallyNotifiesObserversForKey:aKey];
}

// MARK: Creating Progress Objects

/*!
    Returns the progress object that is current, or nil. See -becomeCurrentWithPendingUnitCount:.
*/
+ (CPProgress)currentProgress
{
    var entry = CPProgressCurrentStack[CPProgressCurrentStack.length - 1];

    return entry ? entry.progress : nil;
}

/*!
    Returns a progress object with a total unit count. If a progress object is current, the new
    one becomes its child.
*/
+ (CPProgress)progressWithTotalUnitCount:(int)aCount
{
    var progress = [[self alloc] initWithParent:[self currentProgress] userInfo:nil];

    [progress setTotalUnitCount:aCount];

    return progress;
}

/*!
    Returns a progress object with a total unit count and no parent, even if a progress object
    is current.
*/
+ (CPProgress)discreteProgressWithTotalUnitCount:(int)aCount
{
    var progress = [[self alloc] initWithParent:nil userInfo:nil];

    [progress setTotalUnitCount:aCount];

    return progress;
}

/*!
    Returns a progress object with a total unit count, attached to \c aParent as a child that
    stands for \c aPendingUnitCount of its units.
*/
+ (CPProgress)progressWithTotalUnitCount:(int)aCount parent:(CPProgress)aParent pendingUnitCount:(int)aPendingUnitCount
{
    var progress = [self discreteProgressWithTotalUnitCount:aCount];

    [aParent addChild:progress withPendingUnitCount:aPendingUnitCount];

    return progress;
}

/*!
    Initializes a progress object. If a progress object is current, the new one becomes its
    child.
*/
- (id)init
{
    return [self initWithParent:[CPProgress currentProgress] userInfo:nil];
}

/*!
    Initializes a progress object. \c aParent must be nil or the current progress object; the
    new progress object becomes its child, standing for the pending unit count given to
    -becomeCurrentWithPendingUnitCount:. Only the first progress object made while a parent is
    current becomes its child.

    @throws CPInvalidArgumentException if \c aParent is not nil and not current
*/
- (id)initWithParent:(CPProgress)aParent userInfo:(CPDictionary)aUserInfo
{
    if (self = [super init])
    {
        _children = [];
        _totalUnitCount = 0;
        _completedUnitCount = 0;
        _cancellable = YES;
        _pausable = NO;
        _cancelled = NO;
        _paused = NO;
        _userInfo = aUserInfo ? [aUserInfo mutableCopy] : [CPMutableDictionary dictionary];

        if (aParent)
        {
            var entry = CPProgressCurrentStack[CPProgressCurrentStack.length - 1];

            if (!entry || entry.progress !== aParent)
                [CPException raise:CPInvalidArgumentException reason:@"The parent of a progress object must be nil or the current progress object."];

            if (!entry.hasAttachedChild)
            {
                entry.hasAttachedChild = YES;
                [aParent addChild:self withPendingUnitCount:entry.pendingUnitCount];
            }
        }
    }

    return self;
}

// MARK: The Current Progress Object

/*!
    Makes the receiver the current progress object. The first progress object made before
    -resignCurrent becomes its child, standing for \c aPendingUnitCount of its units.
*/
- (void)becomeCurrentWithPendingUnitCount:(int)aPendingUnitCount
{
    CPProgressCurrentStack.push({ progress: self, pendingUnitCount: aPendingUnitCount, hasAttachedChild: NO });
}

/*!
    Ends the receiver's time as the current progress object. If no child was made meanwhile,
    the pending units are completed.

    @throws CPInternalInconsistencyException if the receiver is not current
*/
- (void)resignCurrent
{
    var entry = CPProgressCurrentStack[CPProgressCurrentStack.length - 1];

    if (!entry || entry.progress !== self)
        [CPException raise:CPInternalInconsistencyException reason:@"-resignCurrent was sent to a progress object that is not current."];

    CPProgressCurrentStack.pop();

    if (!entry.hasAttachedChild)
        [self setCompletedUnitCount:_completedUnitCount + entry.pendingUnitCount];
}

/*!
    Makes the receiver current, calls \c aBlock, and resigns.
*/
- (void)performAsCurrentWithPendingUnitCount:(int)aPendingUnitCount usingBlock:(Function)aBlock
{
    [self becomeCurrentWithPendingUnitCount:aPendingUnitCount];

    try
    {
        aBlock();
    }
    finally
    {
        [self resignCurrent];
    }
}

// MARK: Children

/*!
    Attaches \c aChild, which stands for \c aPendingUnitCount of the receiver's units. A child
    attached to a cancelled or paused progress object is cancelled or paused at once.

    @throws CPInvalidArgumentException if \c aChild already has a parent
*/
- (void)addChild:(CPProgress)aChild withPendingUnitCount:(int)aPendingUnitCount
{
    if (aChild._parent)
        [CPException raise:CPInvalidArgumentException reason:@"A progress object can have only one parent."];

    [self _performCountChange:function()
    {
        aChild._parent = self;
        _children.push({ progress: aChild, pendingUnitCount: aPendingUnitCount });
        [aChild _finishIfComplete];
    }];

    if (_cancelled)
        [aChild cancel];

    if (_paused)
        [aChild pause];
}

// MARK: Unit Counts

/*!
    Returns the total number of units of work.
*/
- (int)totalUnitCount
{
    return _totalUnitCount;
}

/*!
    Sets the total number of units of work. A negative total makes the progress indeterminate.
*/
- (void)setTotalUnitCount:(int)aCount
{
    if (aCount === _totalUnitCount)
        return;

    [self _performCountChange:function()
    {
        _totalUnitCount = aCount;
        [self _finishIfComplete];
    }];
}

/*!
    Returns the number of units of work completed.
*/
- (int)completedUnitCount
{
    return _completedUnitCount;
}

/*!
    Sets the number of units of work completed. When it reaches the total, a parent completes
    the units this progress object stands for.
*/
- (void)setCompletedUnitCount:(int)aCount
{
    if (aCount === _completedUnitCount)
        return;

    [self _performCountChange:function()
    {
        _completedUnitCount = aCount;
        [self _finishIfComplete];
    }];
}

/*!
    Returns the fraction of the work completed, including the progress of children that have
    not finished, from 0.0. It is 0.0 while the progress is indeterminate.
*/
- (double)fractionCompleted
{
    if (_totalUnitCount <= 0)
        return 0.0;

    var units = _completedUnitCount;

    for (var i = 0; i < _children.length; i++)
        units += [_children[i].progress fractionCompleted] * _children[i].pendingUnitCount;

    return units / _totalUnitCount;
}

/*!
    Returns YES when the work is complete: the total is positive, and the completed units have
    reached it.
*/
- (BOOL)isFinished
{
    return _totalUnitCount > 0 && _completedUnitCount >= _totalUnitCount;
}

/*!
    Returns YES when the amount of work is unknown: either count is negative, or both are 0.
*/
- (BOOL)isIndeterminate
{
    return _totalUnitCount < 0 || _completedUnitCount < 0 || (_totalUnitCount === 0 && _completedUnitCount === 0);
}

/*
    Changes unit counts in the tree. Every count key of the receiver and of each of its
    ancestors is announced before and after the change, so that an observer of any of them sees
    a consistent value. A parent's counts and fraction depend on its children, so a change
    anywhere below reaches every ancestor.
*/
- (void)_performCountChange:(Function)aChange
{
    var chain = [];

    for (var progress = self; progress; progress = progress._parent)
        chain.push(progress);

    for (var i = 0; i < chain.length; i++)
        for (var j = 0; j < CPProgressCountKeys.length; j++)
            [chain[i] willChangeValueForKey:CPProgressCountKeys[j]];

    aChange();

    for (var i = chain.length - 1; i >= 0; i--)
        for (var j = CPProgressCountKeys.length - 1; j >= 0; j--)
            [chain[i] didChangeValueForKey:CPProgressCountKeys[j]];
}

/*
    When the receiver has finished, its parent removes it and completes the units it stood for.
    That may finish the parent in turn. Called inside -_performCountChange:, which has already
    announced the change for every ancestor.
*/
- (void)_finishIfComplete
{
    var parent = _parent;

    if (![self isFinished] || !parent)
        return;

    for (var i = 0; i < parent._children.length; i++)
    {
        var entry = parent._children[i];

        if (entry.progress !== self)
            continue;

        parent._children.splice(i, 1);
        parent._completedUnitCount += entry.pendingUnitCount;
        _parent = nil;

        [parent _finishIfComplete];
        return;
    }
}

// MARK: Cancelling and Pausing

/*!
    Returns YES if the user may cancel the work. This is a hint for a user interface: -cancel
    works either way. The default is YES.
*/
- (BOOL)isCancellable
{
    return _cancellable;
}

- (void)setCancellable:(BOOL)isCancellable
{
    [self _setValue:!!isCancellable forIvar:@"_cancellable" key:@"cancellable"];
}

/*!
    Returns YES if the user may pause the work. This is a hint for a user interface. The
    default is NO.
*/
- (BOOL)isPausable
{
    return _pausable;
}

- (void)setPausable:(BOOL)isPausable
{
    [self _setValue:!!isPausable forIvar:@"_pausable" key:@"pausable"];
}

/*!
    Returns YES once the work has been cancelled.
*/
- (BOOL)isCancelled
{
    return _cancelled;
}

/*!
    Returns YES while the work is paused.
*/
- (BOOL)isPaused
{
    return _paused;
}

/*!
    Cancels the work: marks the receiver cancelled, calls its cancellation handler, and cancels
    its children. Cancelling again does nothing.
*/
- (void)cancel
{
    if (_cancelled)
        return;

    [self _setValue:YES forIvar:@"_cancelled" key:@"cancelled"];

    if (_cancellationHandler)
        _cancellationHandler();

    var children = _children.slice();

    for (var i = 0; i < children.length; i++)
        [children[i].progress cancel];
}

/*!
    Pauses the work: marks the receiver paused, calls its pausing handler, and pauses its
    children.
*/
- (void)pause
{
    if (_paused)
        return;

    [self _setValue:YES forIvar:@"_paused" key:@"paused"];

    if (_pausingHandler)
        _pausingHandler();

    var children = _children.slice();

    for (var i = 0; i < children.length; i++)
        [children[i].progress pause];
}

/*!
    Resumes paused work: marks the receiver not paused, calls its resuming handler, and resumes
    its children.
*/
- (void)resume
{
    if (!_paused)
        return;

    [self _setValue:NO forIvar:@"_paused" key:@"paused"];

    if (_resumingHandler)
        _resumingHandler();

    var children = _children.slice();

    for (var i = 0; i < children.length; i++)
        [children[i].progress resume];
}

// MARK: Descriptions

/*!
    Returns a description of the progress. Unless one has been set, it is the percentage
    completed, such as "42% completed".
*/
- (CPString)localizedDescription
{
    if (_localizedDescription !== nil && _localizedDescription !== undefined)
        return _localizedDescription;

    return ROUND([self fractionCompleted] * 100) + @"% completed";
}

- (void)setLocalizedDescription:(CPString)aDescription
{
    [self _setValue:aDescription forIvar:@"_localizedDescription" key:@"localizedDescription"];
}

/*!
    Returns more detail about the progress. Unless one has been set, it is the units completed
    and the total, such as "42 of 100".
*/
- (CPString)localizedAdditionalDescription
{
    if (_localizedAdditionalDescription !== nil && _localizedAdditionalDescription !== undefined)
        return _localizedAdditionalDescription;

    if ([self isIndeterminate])
        return @"";

    return _completedUnitCount + @" of " + _totalUnitCount;
}

- (void)setLocalizedAdditionalDescription:(CPString)aDescription
{
    [self _setValue:aDescription forIvar:@"_localizedAdditionalDescription" key:@"localizedAdditionalDescription"];
}

/*!
    Returns the kind of progress, such as CPProgressKindFile, or nil.
*/
- (CPString)kind
{
    return _kind;
}

- (void)setKind:(CPString)aKind
{
    [self _setValue:aKind forIvar:@"_kind" key:@"kind"];
}

// MARK: User Information

/*!
    Returns a copy of the receiver's user information.
*/
- (CPDictionary)userInfo
{
    return [_userInfo copy];
}

/*!
    Sets a value in the receiver's user information, or removes it when \c anObject is nil.
*/
- (void)setUserInfoObject:(id)anObject forKey:(CPString)aKey
{
    [self willChangeValueForKey:@"userInfo"];

    if (anObject === nil || anObject === undefined)
        [_userInfo removeObjectForKey:aKey];
    else
        [_userInfo setObject:anObject forKey:aKey];

    [self didChangeValueForKey:@"userInfo"];
}

/*!
    Returns the estimated time remaining, in seconds, or nil. It is stored in the user
    information under CPProgressEstimatedTimeRemainingKey.
*/
- (CPNumber)estimatedTimeRemaining
{
    return [_userInfo objectForKey:CPProgressEstimatedTimeRemainingKey];
}

- (void)setEstimatedTimeRemaining:(CPNumber)aTime
{
    [self setUserInfoObject:aTime forKey:CPProgressEstimatedTimeRemainingKey];
}

/*!
    Returns the throughput, in units per second, or nil. It is stored in the user information
    under CPProgressThroughputKey.
*/
- (CPNumber)throughput
{
    return [_userInfo objectForKey:CPProgressThroughputKey];
}

- (void)setThroughput:(CPNumber)aThroughput
{
    [self setUserInfoObject:aThroughput forKey:CPProgressThroughputKey];
}

/*!
    Returns the kind of file operation, such as CPProgressFileOperationKindDownloading, or nil.
    It is stored in the user information under CPProgressFileOperationKindKey.
*/
- (CPString)fileOperationKind
{
    return [_userInfo objectForKey:CPProgressFileOperationKindKey];
}

- (void)setFileOperationKind:(CPString)aKind
{
    [self setUserInfoObject:aKind forKey:CPProgressFileOperationKindKey];
}

/*
    Sets an instance variable and announces the change of its key, when the value changes.
*/
- (void)_setValue:(id)aValue forIvar:(CPString)anIvarName key:(CPString)aKey
{
    if (self[anIvarName] === aValue)
        return;

    [self willChangeValueForKey:aKey];
    self[anIvarName] = aValue;
    [self didChangeValueForKey:aKey];
}

/*!
    Returns a description of the progress object: its counts and fraction completed.
*/
- (CPString)description
{
    return [super description] + @" " + _completedUnitCount + @"/" + _totalUnitCount + @" (" + [self fractionCompleted] + @")" + (_cancelled ? @" cancelled" : @"") + (_paused ? @" paused" : @"");
}

@end
