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

import "CPObject.j"
import "CPInvocation.j"

var CPUndoManagerNormal     = 0,
    CPUndoManagerUndoing    = 1,
    CPUndoManagerRedoing    = 2;
    
CPUndoManagerCheckpointNotification         = @"CPUndoManagerCheckpointNotification";
CPUndoManagerDidOpenUndoGroupNotification   = @"CPUndoManagerDidOpenUndoGroupNotification";
CPUndoManagerDidRedoChangeNotification      = @"CPUndoManagerDidRedoChangeNotification";
CPUndoManagerDidUndoChangeNotification      = @"CPUndoManagerDidUndoChangeNotification";
CPUndoManagerWillCloseUndoGroupNotification = @"CPUndoManagerWillCloseUndoGroupNotification";
CPUndoManagerWillRedoChangeNotification     = @"CPUndoManagerWillRedoChangeNotification";
CPUndoManagerWillUndoChangeNotification     = @"CPUndoManagerWillUndoChangeNotification";

CPUndoCloseGroupingRunLoopOrdering          = 350000;

var _CPUndoGroupingPool         = [],
    _CPUndoGroupingPoolCapacity = 5;

@implementation _CPUndoGrouping : CPObject
{
    _CPUndoGrouping _parent;
    CPMutableArray  _invocations;
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

@end

var _CPUndoGroupingParentKey        = @"_CPUndoGroupingParentKey",
    _CPUndoGroupingInvocationsKey   = @"_CPUndoGroupingInvocationsKey";

@implementation _CPUndoGrouping (CPCoder)

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        _parent = [aCoder decodeObjectForKey:_CPUndoGroupingParentKey];
        _invocations = [aCoder decodeObjectForKey:_CPUndoGroupingInvocationsKey];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_parent forKey:_CPUndoGroupingParentKey];
    [aCoder encodeObject:_invocations forKey:_CPUndoGroupingInvocationsKey];
}

@end

@implementation CPUndoManager : CPObject
{
    CPMutableArray  _redoStack;
    CPMutableArray  _undoStack;
    
    BOOL            _groupsByEvent;
    int             _disableCount;
    int             _levelsOfUndo;
    id              _currentGrouping;
    int             _state;
    CPString        _actionName;
    id              _preparedTarget;
    
    CPArray         _runLoopModes;
    BOOL            _registeredWithRunLoop;
}

- (id)init
{
    self = [super init];
    
    if (self)
    {
        _redoStack = [];
        _undoStack = [];
        
        _state = CPUndoManagerNormal;
        
        [self setRunLoopModes:[CPDefaultRunLoopMode]];
        [self setGroupsByEvent:YES];
        _performRegistered = NO;
    }
    
    return self;
}

// Registering Undo Operations

- (void)registerUndoWithTarget:(id)aTarget selector:(SEL)aSelector object:(id)anObject
{
    if (_disableCount > 0)
        return;

/*    if (_currentGroup == nil)
        [NSException raise:NSInternalInconsistencyException
                    format:@"forwardInvocation called without first opening an undo group"];
*/
    //signature = [target methodSignatureForSelector:selector];
    // FIXME: we need method signatures.
    var invocation = [CPInvocation invocationWithMethodSignature:nil];

    [invocation setTarget:aTarget];
    [invocation setSelector:aSelector];
    [invocation setArgument:anObject atIndex:2];

    [_currentGrouping addInvocation:invocation];

    if (_state == CPUndoManagerNormal)
        [_redoStack removeAllObjects];
}

- (id)prepareWithInvocationTarget:(id)aTarget
{
    _preparedTarget = aTarget;
    
    return self;
}

-(CPMethodSignature)methodSignatureForSelector:(SEL)aSelector
{
    if ([_preparedTarget respondsToSelector:aSelector])
        return 1;
    
    return nil;//[_preparedTarget methodSignatureForSelector:selector];
}

- (void)forwardInvocation:(CPInvocation)anInvocation
{
    if (_disableCount > 0)
        return;
        
/*    if (_preparedTarget == nil)
        [NSException raise:NSInternalInconsistencyException
                    format:@"forwardInvocation called without first preparing a target"];
    if (_currentGroup == nil)
        [NSException raise:NSInternalInconsistencyException
                    format:@"forwardInvocation called without first opening an undo group"];
*/
    [anInvocation setTarget:_preparedTarget];
    [_currentGrouping addInvocation:anInvocation];

    if (_state == CPUndoManagerNormal)
        [_redoStack removeAllObjects];

    _preparedTarget = nil;
}

// Checking Undo Ability

- (BOOL)canRedo
{
    return _redoStack.length > 0;
}

- (BOOL)canUndo
{
    if (_undoStack.length > 0)
        return YES;
    
    return [_currentGrouping actions].length > 0;
}

// Preform Undo and Redo

- (void)undo
{
    if ([self groupingLevel] == 1)
        [self endUndoGrouping];
    
    [self undoNestedGroup];
}

- (void)undoNestedGroup
{ 
    if (_undoStack.length == 0)
        return;
    
    var defaultCenter = [CPNotificationCenter defaultCenter];
/*    [[NSNotificationCenter defaultCenter] postNotificationName:NSUndoManagerCheckpointNotification
                                                        object:self];
*/
    [defaultCenter postNotificationName:CPUndoManagerWillUndoChangeNotification object:self];

    var undoGrouping = _undoStack.pop();
    
    _state = CPUndoManagerUndoing;

    [self beginUndoGrouping];
    [undoGrouping invoke];
    [self endUndoGrouping];
    
    [_CPUndoGrouping _poolUndoGrouping:undoGrouping];
    
    _state = CPUndoManagerNormal;

    [defaultCenter postNotificationName:CPUndoManagerDidUndoChangeNotification object:self];
}

- (void)redo
{
    // Don't do anything if we have no redos.
    if (_redoStack.length == 0)
        return;
    
/*    if (_state == NSUndoManagerUndoing)
        [NSException raise:NSInternalInconsistencyException
                    format:@"redo called while undoing"];

    [[NSNotificationCenter defaultCenter] postNotificationName:NSUndoManagerCheckpointNotification
                                                        object:self];
*/
    var defaultCenter = [CPNotificationCenter defaultCenter];

    [defaultCenter postNotificationName:CPUndoManagerWillRedoChangeNotification object:self];
    
    var oldUndoGrouping = _currentGrouping,
        undoGrouping = _redoStack.pop();
    
    _currentGrouping = nil;
    _state = CPUndoManagerRedoing;

    [self beginUndoGrouping];
    [undoGrouping invoke];
    [self endUndoGrouping];
    
    [_CPUndoGrouping _poolUndoGrouping:undoGrouping];
    
    _currentGrouping = oldUndoGrouping;
    _state = CPUndoManagerNormal;

    [defaultCenter postNotificationName:CPUndoManagerDidRedoChangeNotification object:self];
}

// Creating Undo Groups

- (void)beginUndoGrouping
{
    _currentGrouping = [_CPUndoGrouping undoGroupingWithParent:_currentGrouping];
}

- (void)endUndoGrouping
{
    if (!_currentGrouping)
        alert("FIXME: this should be an exception endUndoGrouping - currentUndoGrouping = nil.");

    var parent = [_currentGrouping parent];
    
    if (!parent && [_currentGrouping invocations].length > 0)
    {
        [[CPNotificationCenter defaultCenter]
            postNotificationName:CPUndoManagerWillCloseUndoGroupNotification
                          object:self];
                              
        // Put this group on the redo stack if we are currently undoing, otherwise 
        // put it on the undo stack.  That way, "undos" become "redos".
        var stack = _state == CPUndoManagerUndoing ? _redoStack : _undoStack;
        
        stack.push(_currentGrouping);
    
        if (_levelsOfUndo > 0 && stack.length > _levelsOfUndo)
            stack.splice(0, 1);        
    }
    
    // Nested Undo Grouping
    else
    {
        [parent addInvocationsFromArray:[_currentGrouping invocations]];
        
        [_CPUndoGrouping _poolUndoGrouping:_currentGrouping];
    }
    
    _currentGrouping = parent;
}

- (void)enableUndoRegistration
{
    if (_disableCount <= 0)
        return;
        
    _disableCount--;
}

- (BOOL)groupsByEvent
{
    return _groupsByEvent;
}

- (void)setGroupsByEvent:(BOOL)aFlag
{
    if (_groupsByEvent == aFlag)
        return;

    _groupsByEvent = aFlag;
    
    if (_groupsByEvent)
    {
        [self _registerWithRunLoop];
    
        // There is a chance that the event loop selector won't fire before our first register,
        // so kick it off here.
        if (!_currentGrouping)
            [self beginUndoGrouping];
    }    
    else
        [self _unregisterWithRunLoop];
}

- (unsigned)groupingLevel
{
    var grouping = _currentGrouping,
        level = _currentGrouping != nil;
    
    while (grouping = [grouping parent])
        ++level;
    
    return level;
}

// Disabling Undo

- (void)disableUndoRegistration
{
    ++_disableCount;
}

- (BOOL)isUndoRegistrationEnabled
{
    return _disableCount == 0;
}

// Checking Whether Undo or Redo Is Being Performed

- (BOOL)isUndoing
{
    return _state == CPUndoManagerUndoing;
}

- (BOOL)isRedoing
{
    return _state == CPUndoManagerRedoing;
}

// Clearing Undo Operations

- (void)removeAllActions
{
    _redoStack = [];
    _undoStack = [];
    _disableCount = 0;
}

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

- (void)setActionName:(CPString)anActionName
{
    _actionName = anActionName;
}

- (CPString)redoActionName
{
    return [self canRedo] ? _actionName : nil;
}

- (CPString)undoActionName
{
    return [self canUndo] ? _actionName : nil;
}

// Working With Run Loops

- (CPArray)runLoopModes
{
    return _runLoopModes;
}

- (void)setRunLoopModes:(CPArray)modes
{
    _runLoopModes = modes;
    
    [self _unregisterWithRunLoop];
    
    if (_groupsByEvent)
        [self _registerWithRunLoop];
}

- (void)beginUndoGroupingForEvent
{
    if (!_groupsByEvent)
        return;
    
    if (_currentGrouping != nil)
        [self endUndoGrouping];

    [self beginUndoGrouping];

    [[CPRunLoop currentRunLoop] performSelector:@selector(beginUndoGroupingForEvent)
        target:self argument:nil order:CPUndoCloseGroupingRunLoopOrdering modes:_runLoopModes];
}

- (void)_registerWithRunLoop
{
    if (_registeredWithRunLoop)
        return;

    _registeredWithRunLoop = YES;
    [[CPRunLoop currentRunLoop] performSelector:@selector(beginUndoGroupingForEvent)
        target:self argument:nil order:CPUndoCloseGroupingRunLoopOrdering modes:_runLoopModes];
}

- (void)_unregisterWithRunLoop
{
    if (!_registeredWithRunLoop)
        return;

    _registeredWithRunLoop = NO;
    [[CPRunLoop currentRunLoop] cancelPerformSelector:@selector(beginUndoGroupingForEvent) target:self argument:nil];
}

@end

var CPUndoManagerRedoStackKey       = @"CPUndoManagerRedoStackKey",
    CPUndoManagerUndoStackKey       = @"CPUndoManagerUndoStackKey";

    CPUndoManagerLevelsOfUndoKey    = @"CPUndoManagerLevelsOfUndoKey";
    CPUndoManagerActionNameKey      = @"CPUndoManagerActionNameKey";
    CPUndoManagerCurrentGroupingKey = @"CPUndoManagerCurrentGroupingKey";
    
    CPUndoManagerRunLoopModesKey    = @"CPUndoManagerRunLoopModesKey";
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
        _actionName = [aCoder decodeObjectForKey:CPUndoManagerActionNameKey];
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
    [aCoder encodeObject:_actionName forKey:CPUndoManagerActionNameKey];
    
    [aCoder encodeObject:_currentGrouping forKey:CPUndoManagerCurrentGroupingKey];

    [aCoder encodeObject:_runLoopModes forKey:CPUndoManagerRunLoopModesKey];
    [aCoder encodeBool:_groupsByEvent forKey:CPUndoManagerGroupsByEventKey];
}

@end
