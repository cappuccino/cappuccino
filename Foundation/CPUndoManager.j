/*
 * CPUndoManager.j
 * Foundation
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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
@import "CPException.j"
@import "CPInvocation.j"
@import "CPNotificationCenter.j"
@import "CPObject.j"
@import "CPProxy.j"
@import "CPKeyValueObserving.j"
@import "CPRunLoop.j"

var CPUndoManagerNormal     = 0,
    CPUndoManagerUndoing    = 1,
    CPUndoManagerRedoing    = 2;

CPUndoManagerCheckpointNotification         = @"CPUndoManagerCheckpointNotification";
CPUndoManagerDidOpenUndoGroupNotification   = @"CPUndoManagerDidOpenUndoGroupNotification";
CPUndoManagerDidCloseUndoGroupNotification  = @"CPUndoManagerDidCloseUndoGroupNotification";
CPUndoManagerDidRedoChangeNotification      = @"CPUndoManagerDidRedoChangeNotification";
CPUndoManagerDidUndoChangeNotification      = @"CPUndoManagerDidUndoChangeNotification";
CPUndoManagerWillCloseUndoGroupNotification = @"CPUndoManagerWillCloseUndoGroupNotification";
CPUndoManagerWillRedoChangeNotification     = @"CPUndoManagerWillRedoChangeNotification";
CPUndoManagerWillUndoChangeNotification     = @"CPUndoManagerWillUndoChangeNotification";

CPUndoCloseGroupingRunLoopOrdering          = 350000;

var _CPUndoGroupingPool         = [],
    _CPUndoGroupingPoolCapacity = 5;

/* @ignore */
@implementation _CPUndoGrouping : CPObject
{
    _CPUndoGrouping _parent;
    CPMutableArray  _invocations;
    CPString        _actionName;
}

+ (void)_poolUndoGrouping:(_CPUndoGrouping)anUndoGrouping
{
    if (!anUndoGrouping || _CPUndoGroupingPool.length >= _CPUndoGroupingPoolCapacity)
        return;

    _CPUndoGroupingPool.push(anUndoGrouping);
}

+ (id)undoGroupingWithParent:(_CPUndoGrouping)anUndoGrouping
{
    if (_CPUndoGroupingPool.length)
    {
        var grouping = _CPUndoGroupingPool.pop();

        grouping._parent = anUndoGrouping;

        if (grouping._invocations.length)
            grouping._invocations = [];

        return grouping;
    }

    return [[self alloc] initWithParent:anUndoGrouping];
}

- (id)initWithParent:(_CPUndoGrouping)anUndoGrouping
{
    self = [super init];

    if (self)
    {
        _parent = anUndoGrouping;
        _invocations = [];
        _actionName = @"";
    }

    return self;
}

- (_CPUndoGrouping)parent
{
    return _parent;
}

- (void)addInvocation:(CPInvocation)anInvocation
{
    _invocations.push(anInvocation);
}

- (void)addInvocationsFromArray:(CPArray)invocations
{
    [_invocations addObjectsFromArray:invocations];
}

- (BOOL)removeInvocationsWithTarget:(id)aTarget
{
    var index = _invocations.length;

    while (index--)
        if ([_invocations[index] target] == aTarget)
            _invocations.splice(index, 1);
}

- (CPArray)invocations
{
    return _invocations;
}

- (void)invoke
{
    var index = _invocations.length;

    while (index--)
        [_invocations[index] invoke];
}

- (void)setActionName:(CPString)aName
{
    _actionName = aName;
}

- (CPString)actionName
{
    return _actionName;
}

@end

var _CPUndoGroupingParentKey        = @"_CPUndoGroupingParentKey",
    _CPUndoGroupingInvocationsKey   = @"_CPUndoGroupingInvocationsKey",
    _CPUndoGroupingActionNameKey    = @"_CPUndoGroupingActionNameKey";

@implementation _CPUndoGrouping (CPCoder)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _parent = [aCoder decodeObjectForKey:_CPUndoGroupingParentKey];
        _invocations = [aCoder decodeObjectForKey:_CPUndoGroupingInvocationsKey];
        _actionName = [aCoder decodeObjectForKey:_CPUndoGroupingActionNameKey];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_parent forKey:_CPUndoGroupingParentKey];
    [aCoder encodeObject:_invocations forKey:_CPUndoGroupingInvocationsKey];
    [aCoder encodeObject:_actionName forKey:_CPUndoGroupingActionNameKey];
}

@end

/*!
    @class CPUndoManager
    @ingroup foundation
    @brief A general mechanism for user action "undo".

    CPUndoManager provides a general mechanism supporting implementation of user
    action "undo" in applications. Essentially, it allows you to store sequences
    of messages and receivers that need to be invoked to undo or redo an action.
    The various methods in this class provide for grouping of sets of actions,
    execution of undo or redo actions, and tuning behavior parameters such as
    the size of the undo stack. Each application entity with its own editing
    history (e.g., a document) should have its own undo manager instance.
    Obtain an instance through a simple \c [[CPUndoManager \c alloc] \c init]
     message.
*/
@implementation CPUndoManager : CPObject
{
    CPMutableArray  _redoStack;
    CPMutableArray  _undoStack;

    BOOL            _groupsByEvent;
    int             _disableCount;
    int             _levelsOfUndo;
    id              _currentGrouping;
    int             _state;

    id              _preparedTarget;
    id              _undoManagerProxy;

    CPArray         _runLoopModes;
    BOOL            _registeredWithRunLoop;
}

/*!
    Initializes the undo manager
    @return the initialized undo manager
*/
- (id)init
{
    self = [super init];

    if (self)
    {
        _redoStack = [];
        _undoStack = [];

        _disableCount = 0;
        _state = CPUndoManagerNormal;

        [self setRunLoopModes:[CPDefaultRunLoopMode]];
        [self setGroupsByEvent:YES];

        _undoManagerProxy = [_CPUndoManagerProxy alloc];
        _undoManagerProxy._undoManager = self;
    }

    return self;
}

- (void)_addUndoInvocation:(CPInvocation)anInvocation
{
    if (!_currentGrouping)
        // Remember that we create these lazily...
        if ([self groupsByEvent])
            [self _beginUndoGroupingForEvent];
        else
            [CPException raise:CPInternalInconsistencyException reason:"No undo group is currently open"];

    [_currentGrouping addInvocation:anInvocation];

    if (_state === CPUndoManagerNormal)
        [_redoStack removeAllObjects];
}

// Registering Undo Operations
/*!
    Registers an undo operation. You invoke this method with the target of the undo action providing the selector which can perform the undo with the provided object. The object is often a dictionary of the identifying the attribute and their values before the change. The invocation will be added to the current grouping. If the registrations have been disabled through \c -disableUndoRegistration, this method does nothing.
    @param aTarget the target for the undo invocation
    @param aSelector the selector for the action message
    @param anObject the argument for the action message
    @throws CPInternalInconsistencyException if no undo group is currently open
*/
- (void)registerUndoWithTarget:(id)aTarget selector:(SEL)aSelector object:(id)anObject
{
    // Don't do anything if we're disabled.
    if (_disableCount > 0)
        return;

    //signature = [target methodSignatureForSelector:selector];
    // FIXME: we need method signatures.
    var invocation = [CPInvocation invocationWithMethodSignature:nil];

    [invocation setTarget:aTarget];
    [invocation setSelector:aSelector];
    [invocation setArgument:anObject atIndex:2];

    [self _addUndoInvocation:invocation];
}
/*!
    Prepares the specified target for the undo action.
    @param aTarget the target to receive the action
    @return the undo manager
*/
- (id)prepareWithInvocationTarget:(id)aTarget
{
    _preparedTarget = aTarget;

    return _undoManagerProxy;
}

/*
    FIXME This method doesn't seem to do anything right
    @ignore
*/
- (CPMethodSignature)_methodSignatureOfPreparedTargetForSelector:(SEL)aSelector
{
    if ([_preparedTarget respondsToSelector:aSelector])
        return 1;

    return nil;//[_preparedTarget methodSignatureForSelector:selector];
}

/*!
    Records the specified invocation as an undo operation. Sets the
    target on the invocation, and adds it to the current grouping.
    @param anInvocation the message to record
*/
- (void)_forwardInvocationToPreparedTarget:(CPInvocation)anInvocation
{
    // Don't do anything if we're disabled.
    if (_disableCount > 0)
        return;

/*
if (_currentGroup == nil)
        [NSException raise:NSInternalInconsistencyException
                    format:@"forwardInvocation called without first opening an undo group"];
*/
    [anInvocation setTarget:_preparedTarget];

    [self _addUndoInvocation:anInvocation];

    _preparedTarget = nil;
}

// Checking Undo Ability
/*!
    Returns \c YES if the user can perform a redo operation.
*/
- (BOOL)canRedo
{
    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPUndoManagerCheckpointNotification
                      object:self];

    return [_redoStack count] > 0;
}

/*!
    Returns \c YES if the user can perform an undo operation.
*/
- (BOOL)canUndo
{
    if (_undoStack.length > 0)
        return YES;

    return [[_currentGrouping invocations] count] > 0;
}

// Preform Undo and Redo
/*!
    Ends the current grouping, and performs an 'undo' operation.
*/
- (void)undo
{
    if ([self groupingLevel] === 1)
        [self endUndoGrouping];

    [self undoNestedGroup];
}

/*!
    Performs an undo on the last undo group.
*/
- (void)undoNestedGroup
{
    if ([_undoStack count] <= 0)
        return;

    var defaultCenter = [CPNotificationCenter defaultCenter];

    [defaultCenter postNotificationName:CPUndoManagerCheckpointNotification
                                 object:self];

    [defaultCenter postNotificationName:CPUndoManagerWillUndoChangeNotification
                                 object:self];

    var undoGrouping = _undoStack.pop(),
        actionName = [undoGrouping actionName];

    _state = CPUndoManagerUndoing;

    [self _beginUndoGrouping];
    [undoGrouping invoke];
    [self endUndoGrouping];

    [_CPUndoGrouping _poolUndoGrouping:undoGrouping];

    _state = CPUndoManagerNormal;

    [[_redoStack lastObject] setActionName:actionName];

    [defaultCenter postNotificationName:CPUndoManagerDidUndoChangeNotification
                                 object:self];
}

/*!
    Performs the redo operation using the last grouping on the redo stack.
*/
- (void)redo
{
    // Don't do anything if we have no redos.
    if ([_redoStack count] <= 0)
        return;

/*    if (_state == NSUndoManagerUndoing)
        [NSException raise:NSInternalInconsistencyException
                    format:@"redo called while undoing"];
*/

    var defaultCenter = [CPNotificationCenter defaultCenter];

    [defaultCenter postNotificationName:CPUndoManagerCheckpointNotification
                                 object:self];

    [defaultCenter postNotificationName:CPUndoManagerWillRedoChangeNotification
                                 object:self];

    var oldUndoGrouping = _currentGrouping,
        undoGrouping = _redoStack.pop(),
        actionName = [undoGrouping actionName];

    _currentGrouping = nil;
    _state = CPUndoManagerRedoing;

    [self _beginUndoGrouping];
    [undoGrouping invoke];
    [self endUndoGrouping];

    [_CPUndoGrouping _poolUndoGrouping:undoGrouping];

    _currentGrouping = oldUndoGrouping;
    _state = CPUndoManagerNormal;

    [[_undoStack lastObject] setActionName:actionName];
    [defaultCenter postNotificationName:CPUndoManagerDidRedoChangeNotification object:self];
}

// Creating Undo Groups
/*!
    Starts a new grouping of undo tasks, and makes it the current grouping.
*/
- (void)beginUndoGrouping
{
    // It doesn't matter that the user is creating a group themselves, we are
    // pretending to have opened the group at the beginning of the run loop,
    // so create an implicit one here.
    if (!_currentGrouping && [self groupsByEvent])
        [self _beginUndoGroupingForEvent];

    [[CPNotificationCenter defaultCenter]
        postNotificationName:CPUndoManagerCheckpointNotification
                      object:self];

    [self _beginUndoGrouping];
}

/* @ignore */
- (void)_beginUndoGroupingForEvent
{
    [self _beginUndoGrouping];
    [self _registerWithRunLoop];
}

/* @ignore */
- (void)_beginUndoGrouping
{
    _currentGrouping = [_CPUndoGrouping undoGroupingWithParent:_currentGrouping];
}

/*!
    Closes the current undo grouping.
    @throws CPInternalInconsistencyException if no undo group is open
*/
- (void)endUndoGrouping
{
    if (!_currentGrouping)
        [CPException raise:CPInternalInconsistencyException reason:"endUndoGrouping. No undo group is currently open."];

    var defaultCenter = [CPNotificationCenter defaultCenter];

    [defaultCenter postNotificationName:CPUndoManagerCheckpointNotification
                                 object:self];

    var parent = [_currentGrouping parent];

    if (!parent && [_currentGrouping invocations].length > 0)
    {
        [defaultCenter
            postNotificationName:CPUndoManagerWillCloseUndoGroupNotification
                          object:self];

        // Put this group on the redo stack if we are currently undoing, otherwise
        // put it on the undo stack.  That way, "undos" become "redos".
        var stack = _state === CPUndoManagerUndoing ? _redoStack : _undoStack;

        stack.push(_currentGrouping);

        if (_levelsOfUndo > 0 && stack.length > _levelsOfUndo)
            stack.splice(0, 1);

        [defaultCenter
            postNotificationName:CPUndoManagerDidCloseUndoGroupNotification
                          object:self];
    }

    // Nested Undo Grouping
    else
    {
        [parent addInvocationsFromArray:[_currentGrouping invocations]];

        [_CPUndoGrouping _poolUndoGrouping:_currentGrouping];
    }

    _currentGrouping = parent;
}

/*!
    Enables undo registrations. Calls to this method must
    be balanced with calls to disableUndoRegistration.
    So, if two disable calls were made, two enable calls are required
    to actually enable undo registration again.
*/
- (void)enableUndoRegistration
{
    if (_disableCount <= 0)
        [CPException raise:CPInternalInconsistencyException
                    reason:"enableUndoRegistration. There are no disable messages in effect right now."];

    _disableCount--;
}

/*!
    Returns \c YES if the manager groups undo operations at every iteration of the run loop.
*/
- (BOOL)groupsByEvent
{
    return _groupsByEvent;
}

/*!
    Sets whether the manager should group undo operations at every iteration of the run loop.
    @param aFlag \c YES groups undo operations
*/
- (void)setGroupsByEvent:(BOOL)aFlag
{
    aFlag = !!aFlag;

    if (_groupsByEvent === aFlag)
        return;

    _groupsByEvent = aFlag;

    if (![self groupsByEvent])
        [self _unregisterWithRunLoop];
}

/*!
    Returns the number of undo/redo groups.
*/
- (unsigned)groupingLevel
{
    var grouping = _currentGrouping,
        level = _currentGrouping ? 1 : 0;

    while (grouping = [grouping parent])
        ++level;

    return level;
}

// Disabling Undo
/*!
    Disables undo registrations.
*/
- (void)disableUndoRegistration
{
    ++_disableCount;
}

/*!
    Returns \c YES if undo registration is enabled.
*/
- (BOOL)isUndoRegistrationEnabled
{
    return _disableCount == 0;
}

// Checking Whether Undo or Redo Is Being Performed
/*!
    Returns \c YES if the manager is currently performing an undo.
*/
- (BOOL)isUndoing
{
    return _state === CPUndoManagerUndoing;
}

/*!
    Returns \c YES if the manager is currently performing a redo.
*/
- (BOOL)isRedoing
{
    return _state === CPUndoManagerRedoing;
}

// Clearing Undo Operations
/*!
    Clears all redo and undo operations and enables undo registrations.
*/
- (void)removeAllActions
{
    // Close off any groupings.
    while (_currentGrouping)
        [self endUndoGrouping];

    // Won't need this anymore
    [self _unregisterWithRunLoop];

    _state = CPUndoManagerNormal;
    _redoStack = [];
    _undoStack = [];
    _disableCount = 0;
}

/*!
    Removes any redo and undo operations that use the specified target.
    @param aTarget the target for which operations should be removed.
*/
- (void)removeAllActionsWithTarget:(id)aTarget
{
    [_currentGrouping removeInvocationsWithTarget:aTarget];

    var index = _redoStack.length;

    while (index--)
    {
        var grouping = _redoStack[index];

        [grouping removeInvocationsWithTarget:aTarget];

        if (![grouping invocations].length)
            _redoStack.splice(index, 1);
    }

    index = _undoStack.length;

    while (index--)
    {
        var grouping = _undoStack[index];

        [grouping removeInvocationsWithTarget:aTarget];

        if (![grouping invocations].length)
            _undoStack.splice(index, 1);
    }
}

// Managing the Action Name
/*!
    Sets the name associated with the actions of the current group.
    Typically, you can call this method while registering the actions for the current group.
    @param anActionName the new name for the current group
*/
- (void)setActionName:(CPString)anActionName
{
    if (anActionName !== nil && _currentGrouping)
        [_currentGrouping setActionName:anActionName];
}

/*!
    If the receiver can perform a redo, this method returns the action
    name previously associated with the top grouping with
    \c -setActionName:. This name should identify the action to be redone.
    @return the redo action's name, or \c nil if no there's no redo on the stack.
*/
- (CPString)redoActionName
{
    if (![self canRedo])
        return nil;

    return [[_redoStack lastObject] actionName];
}

/*!
    Returns the full localized title of the actions to be displayed
    as a menu item.  This method first invokes [-redoActionName] and
    passes it to [-redoMenuTitleForUndoActionName:] and returns the result.
*/
- (CPString)redoMenuItemTitle
{
    return [self redoMenuTitleForUndoActionName:[self redoActionName]];
}

/*!
    Returns the localized title of the actions to be displayed
    as a menu item identified by actionName, by appending a
    localized command string like @"Redo <localized(actionName)>".
*/
- (CPString)redoMenuTitleForUndoActionName:(CPString)anActionName
{
    // This handles the empty string ("") case as well.
    if (anActionName || anActionName === 0)

        // FIXME: The terms @"Redo" and @"Redo %@" should be localized.
        // KEYWORDS: Localization
        return @"Redo " + anActionName;

    return @"Redo";
}

/*!
    If the receiver can perform an undo, this method returns the action
    name previously associated with the top grouping with
    \c -setActionName:. This name should identify the action to be undone.
    @return the undo action name or \c nil if no if there's no undo on the stack.
*/
- (CPString)undoActionName
{
    if (![self canUndo])
        return nil;

    return [[_undoStack lastObject] actionName];
}

/*!
    Returns the full localized title of the actions to be displayed
    as a menu item.  This method first invokes [-undoActionName] and
    passes it to [-undoMenuTitleForUndoActionName:] and returns the result.
*/
- (CPString)undoMenuItemTitle
{
    return [self undoMenuTitleForUndoActionName:[self undoActionName]];
}

/*!
    Returns the localized title of the actions to be displayed
    as a menu item identified by actionName, by appending a
    localized command string like @"Undo <localized(actionName)>".
*/
- (CPString)undoMenuTitleForUndoActionName:(CPString)anActionName
{
    // This handles the empty string ("") case as well.
    if (anActionName || anActionName === 0)

        // FIXME: The terms @"Undo" and @"Undo %@" should be localized.
        // KEYWORDS: Localization
        return @"Undo " + anActionName;

    return @"Undo";
}

// Working With Run Loops
/*!
    Returns the CPRunLoopModes in which the receiver registers
    the \c -endUndoGrouping processing when it \c -groupsByEvent.
*/
- (CPArray)runLoopModes
{
    return _runLoopModes;
}

/*!
    Sets the modes in which the receiver registers the calls
    with the current run loop to invoke \c -endUndoGrouping
    when it \c -groupsByEvent. This method first
    cancels any pending registrations in the old modes and
    registers the invocation in the new modes.
    @param modes the modes in which calls are registered
*/
- (void)setRunLoopModes:(CPArray)modes
{
    _runLoopModes = [modes copy];

    if (_registeredWithRunLoop)
    {
        [self _unregisterWithRunLoop];
        [self _registerWithRunLoop];
    }
}

- (void)_runLoopEndUndoGrouping
{
    [self endUndoGrouping];
    _registeredWithRunLoop = NO;
}

/* @ignore */
- (void)_registerWithRunLoop
{
    if (_registeredWithRunLoop)
        return;

    _registeredWithRunLoop = YES;
    [[CPRunLoop currentRunLoop]
        performSelector:@selector(_runLoopEndUndoGrouping)
                 target:self
               argument:nil
                  order:CPUndoCloseGroupingRunLoopOrdering
                  modes:_runLoopModes];
}

/* @ignore */
- (void)_unregisterWithRunLoop
{
    if (!_registeredWithRunLoop)
        return;

    _registeredWithRunLoop = NO;
    [[CPRunLoop currentRunLoop]
        cancelPerformSelector:@selector(_runLoopEndUndoGrouping)
                       target:self
                     argument:nil];
}

- (void)observeChangesForKeyPath:(CPString)aKeyPath ofObject:(id)anObject
{
    [anObject addObserver:self
              forKeyPath:aKeyPath
                 options:CPKeyValueObservingOptionOld | CPKeyValueObservingOptionNew
                 context:NULL];
}

- (void)stopObservingChangesForKeyPath:(CPString)aKeyPath ofObject:(id)anObject
{
    [anObject removeObserver:self forKeyPath:aKeyPath];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath
                      ofObject:(id)anObject
                        change:(CPDictionary)aChange
                       context:(id)aContext
{
    // Don't add no-ops to the undo stack.
    var before = [aChange valueForKey:CPKeyValueChangeOldKey],
        after = [aChange valueForKey:CPKeyValueChangeNewKey];
    if (before === after || (before !== nil && before.isa && (after === nil || after.isa) && [before isEqual:after]))
        return;

    [[self prepareWithInvocationTarget:anObject]
        applyChange:[aChange inverseChangeDictionary]
          toKeyPath:aKeyPath];
}

@end

var CPUndoManagerRedoStackKey       = @"CPUndoManagerRedoStackKey",
    CPUndoManagerUndoStackKey       = @"CPUndoManagerUndoStackKey",

    CPUndoManagerLevelsOfUndoKey    = @"CPUndoManagerLevelsOfUndoKey",
    CPUndoManagerActionNameKey      = @"CPUndoManagerActionNameKey",
    CPUndoManagerCurrentGroupingKey = @"CPUndoManagerCurrentGroupingKey",

    CPUndoManagerRunLoopModesKey    = @"CPUndoManagerRunLoopModesKey",
    CPUndoManagerGroupsByEventKey   = @"CPUndoManagerGroupsByEventKey";

@implementation CPUndoManager (CPCoding)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];

    if (self)
    {
        _redoStack = [aCoder decodeObjectForKey:CPUndoManagerRedoStackKey];
        _undoStack = [aCoder decodeObjectForKey:CPUndoManagerUndoStackKey];

        _levelsOfUndo = [aCoder decodeObjectForKey:CPUndoManagerLevelsOfUndoKey];
//        _actionName = [aCoder decodeObjectForKey:CPUndoManagerActionNameKey];
        _currentGrouping = [aCoder decodeObjectForKey:CPUndoManagerCurrentGroupingKey];

        _state = CPUndoManagerNormal;

        [self setRunLoopModes:[aCoder decodeObjectForKey:CPUndoManagerRunLoopModesKey]];
        [self setGroupsByEvent:[aCoder decodeBoolForKey:CPUndoManagerGroupsByEventKey]];
    }

    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_redoStack forKey:CPUndoManagerRedoStackKey];
    [aCoder encodeObject:_undoStack forKey:CPUndoManagerUndoStackKey];

    [aCoder encodeInt:_levelsOfUndo forKey:CPUndoManagerLevelsOfUndoKey];
//    [aCoder encodeObject:_actionName forKey:CPUndoManagerActionNameKey];

    [aCoder encodeObject:_currentGrouping forKey:CPUndoManagerCurrentGroupingKey];

    [aCoder encodeObject:_runLoopModes forKey:CPUndoManagerRunLoopModesKey];
    [aCoder encodeBool:_groupsByEvent forKey:CPUndoManagerGroupsByEventKey];
}

@end

@implementation _CPUndoManagerProxy : CPProxy
{
    CPUndoManager   _undoManager;
}

- (CPMethodSignature)methodSignatureForSelector:(SEL)aSelector
{
    return [_undoManager _methodSignatureOfPreparedTargetForSelector:aSelector];
}

- (void)forwardInvocation:(CPInvocation)anInvocation
{
    [_undoManager _forwardInvocationToPreparedTarget:anInvocation];
}

@end
