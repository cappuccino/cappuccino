/*
 * CPPredicateEditor.j
 * AppKit
 *
 * Created by JC Bordes [jcbordes at gmail dot com] Copyright 2012 JC Bordes
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

@import "CPRuleEditor.j"
@import "CPPredicateEditorRowTemplate.j"

@implementation CPPredicateEditor : CPRuleEditor
{
    CPArray _rowTemplates;
    CPArray _simpleCriteriaRoot;
    CPArray _compoundCriteriaRoot;
}

#pragma mark public methods
/*!
    @ingroup appkit
    @class CPPredicateEditor

    @brief CPPredicateEditor is a subclass of CPRuleEditor that is specialized for editing CPPredicate objects.

    CPPredicateEditor provides a CPPredicate property—objectValue (inherited from CPControl)—that you can get and set directly, and that you can bind using bindings (you typically configure a predicate editor in Interface Builder). CPPredicateEditor depends on another class, CPPredicateEditorRowTemplate, that describes the available predicates and how to display them.

    Unlike CPRuleEditor, CPPredicateEditor does not depend on its delegate to populate its rows (and does not call the populating delegate methods). Instead, its rows are populated from its objectValue property (an instance of CPPredicate). CPPredicateEditor relies on instances CPPredicateEditorRowTemplate, which are responsible for mapping back and forth between the displayed view values and various predicates.

    CPPredicateEditor exposes one property, rowTemplates, which is an array of CPPredicateEditorRowTemplate objects.
*/

/*!
    @brief Returns the row templates for the receiver.
    @return The row templates for the receiver.
    @discussion Until otherwise set, this contains a single compound CPPredicateEditorRowTemplate object.
    @see setRowTemplates:
*/
- (CPArray)rowTemplates
{
    return _rowTemplates;
}

/*!
    @brief Sets the row templates for the receiver.
    @param rowTemplates An array of CPPredicateEditorRowTemplate objects.
    @see rowTemplates
*/
- (void)setRowTemplates:(id)rowTemplates
{
//    _criteriaToTemplatesMap=[CPMutableDictionary dictionary];
    _rowTemplates=rowTemplates;
    [self setupRowTemplates];
}

/*! @cond */

#pragma mark CPRuleEditor _build override 

- (void)_build
{
    [super _build];
    [super setDelegate:self];
}

#pragma mark Properties

- (id)objectValue
{
    return [super predicate];
}

- (void)setObjectValue:(id)objectValue
{
	if(!objectValue)
	{
		[_model removeAllRows];
		return;
	}
		
	if(![objectValue isKindOfClass:CPPredicate])
		[CPException raise:CPInvalidArgumentException reason:_cmd+@" : argument must be a CPPredicate"];
	
	var nestingMode=[_model nestingMode];
	var predicate=objectValue;

    [self willChangeValueForKey:@"objectValue"];
	
	var predicates;
	
	switch(nestingMode)
	{
		case CPRuleEditorNestingModeCompound :
		case CPRuleEditorNestingModeSimple :
			if(![predicate isKindOfClass:CPCompoundPredicate])
				predicate=[[CPCompoundPredicate alloc] initWithType:[self defaultCompoundType] subpredicates:[CPArray arrayWithObject:predicate]];
			predicates=[CPMutableArray arrayWithObject:predicate];
		break;
		case CPRuleEditorNestingModeList :
			if([predicate isKindOfClass:CPCompoundPredicate])
				predicates=[predicate subpredicates];
			else
				predicates=[CPMutableArray arrayWithObject:predicate];
		break;
		case CPRuleEditorNestingModeSingle :
			if([predicate isKindOfClass:CPCompoundPredicate])
			{
				predicates=[predicate subpredicates];
				if(predicates&&[predicates count])
					predicates=[CPMutableArray arrayWithObject:[predicates objectAtIndex:0]];
			}
			else
				predicates=[CPMutableArray arrayWithObject:predicate];
		break;
	}
	
	[_model removeAllRows];
	
	if(predicates)
	{
		var predicate;
		var template;		
		var row;
		var count=[predicates count];
		for(var i=0;i<count;i++)
		{
			predicate=[predicates objectAtIndex:i];
			row=[self createRowForPredicate:predicate];
			[_model addRow:row];
		}
	}

    [self didChangeValueForKey:@"objectValue"];
}

-(CPNumber)defaultCompoundType
{
	if(!_compoundCriteriaRoot||![_compoundCriteriaRoot count])
		return CPAndPredicateType;
	
	var view=[_compoundCriteriaRoot objectAtIndex:0];
	if(!view||![view isKindOfClass:CPPopUpButton])
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : invalid compound template view"];
	
	var items=[view itemArray];
	if(!items||![items count])	
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : invalid compound template view"];
	
	var value=[items objectAtIndex:0];
	var template=[self mappedTemplateForObject:value];
	if(!template)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : invalid compound template view"];
	
	var types=[template compoundTypes];
	if(!types||![types count])	
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : invalid compound template"];
	
	return types[0];
}

#pragma mark Matching templates and predicates

-(CPPredicateEditorRowTemplate)templateForPredicate:(CPPredicate)predicate
{
	if(!predicate)
		return nil;
	
	var result;
	var bestResult=0;
	var matchIndex=CPNotFound;

	var template;	
	var count=_rowTemplates?[_rowTemplates count]:0;	
	for(var i=0;i<count;i++)
	{
		template=_rowTemplates[i];
		result=[template matchForPredicate:predicate];
		if(result>bestResult)
		{
			bestResult=result;
			matchIndex=i;
		}
	}
	
	if(matchIndex==CPNotFound)
		return nil;
		
	return [_rowTemplates objectAtIndex:matchIndex];
}

#pragma mark Creating rows from a predicate

-(CPRuleEditorModelItem)createRowForPredicate:(CPPredicate)predicate
{
	if(!predicate)
		return nil;
		
	var template=[self templateForPredicate:predicate];
	if(!template)
		return nil;

	var criteria=[self criteriaForPredicate:predicate usingTemplate:template];
	criteria=[template preProcessCriteria:criteria];
	
	var rowType=[predicate isKindOfClass:CPCompoundPredicate]?CPRuleEditorRowTypeCompound:CPRuleEditorRowTypeSimple;
	
	var row=[[CPRuleEditorModelItem alloc] initWithType:rowType criteria:criteria data:template];
	var subpredicates=[template displayableSubpredicatesOfPredicate:predicate];
	if(!subpredicates)
		return row;
	
	var subrow;
	var subpredicate;
	var count=[subpredicates count];
	for(var i=0;i<count;i++)
	{
		subpredicate=subpredicates[i];
		template=[self templateForPredicate:subpredicate];
		subrow=[self createRowForPredicate:subpredicate];
		if(subrow)
			[row addChild:subrow context:nil];
	}
	
	return row;
}

#pragma mark Creating row criteria from a template

-(id)criteriaForPredicate:(CPPredicate)predicate usingTemplate:(CPPredicateEditorRowTemplate)template
{
	if([predicate isKindOfClass:CPCompoundPredicate])
		return [self criteriaForCompoundPredicate:predicate usingTemplate:template];
	if([predicate isKindOfClass:CPComparisonPredicate])
		return [self criteriaForComparisonPredicate:predicate usingTemplate:template];
	return nil;
}

-(id)criteriaForCompoundPredicate:(CPPredicate)predicate usingTemplate:(CPPredicateEditorRowTemplate)template
{
	if(!_compoundCriteriaRoot
		||!template
		||!predicate
		||![predicate isKindOfClass:CPCompoundPredicate])
		return nil;
	
	var type=[predicate compoundPredicateType];
	var count=[_compoundCriteriaRoot count];
	
	var rootItem=nil;
	var criterionItem;
	var aTemplate;
	
	for(var i=0;i<count;i++)
	{
		criterionItem=[_compoundCriteriaRoot objectAtIndex:i];
		if(![criterionItem isKindOfClass:CPMenuItem]||[criterionItem representedObject]!==type)
			continue;
		aTemplate=[self mappedTemplateForObject:criterionItem];
		if(aTemplate!=template)
			continue;
		
		rootItem=criterionItem;
		break;
	}
	
	if(!rootItem)
		return nil;
	
	var criterion=[[CPRuleEditorCriterion alloc] initWithItems:_compoundCriteriaRoot displayValue:rootItem];
	var criteria=[CPMutableArray arrayWithObject:criterion];

	var currentCriterionItem=rootItem;
	var target;

	while((target=[currentCriterionItem target])!=nil)
	{
		criterion=[self createCriterionFromView:target];
		if([target isKindOfClass:CPPopUpButton]) 
		{
			currentCriterionItem=[criterion displayValue];
			[criteria addObject:criterion]; 
			continue;
		}
		if([target isKindOfClass:CPView]) 
		{
			currentCriterionItem=target;
			[criteria addObject:criterion]; 
			continue;
		}
		break;
	}
	
	return criteria;
}

-(id)criteriaForComparisonPredicate:(CPPredicate)predicate usingTemplate:(CPPredicateEditorRowTemplate)template
{
	if(!_simpleCriteriaRoot
		||!template
		||!predicate
		||![predicate isKindOfClass:CPComparisonPredicate])
		return nil;
	
	var expression=[predicate leftExpression];
	if(!expression)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : invalid predicate"];
	
	var aTemplate;
	var criterionItem;
	var keypath=[expression keyPath];
	var count=[_simpleCriteriaRoot count];
	
	for(var i=0;i<count;i++)
	{
		criterionItem=[_simpleCriteriaRoot objectAtIndex:i];
		if(![criterionItem isKindOfClass:CPMenuItem]||[criterionItem title]!==keypath)
			continue;
		aTemplate=[self mappedTemplateForObject:criterionItem];
		if(aTemplate!=template)
			continue;	

		rootItem=criterionItem;
		break;
	}

	var criterion=[[CPRuleEditorCriterion alloc] initWithItems:_simpleCriteriaRoot displayValue:rootItem];
	var criteria=[CPMutableArray arrayWithObject:criterion];

	var target=[rootItem target];
	var opType=[predicate predicateOperatorType];
	criterion=[self createCriterionFromView:target representedObject:opType];
	if(!criterion)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : invalid predicate"];
	[criteria addObject:criterion];

	target=[[criterion displayValue] target];
	expression=[predicate rightExpression];
	if(!expression)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : invalid predicate"];
	keypath=[expression keyPath];
	criterion=[self createCriterionFromView:target representedObject:keypath];
	if(!criterion)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : invalid predicate"];

	[criteria addObject:criterion];
	
	if([template options])
	{
		target=[[criterion displayValue] target];
		criterion=[self createCriterionFromView:target representedObject:[predicate options]];
		if(!criterion)
			[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : invalid predicate"];
		[criteria addObject:criterion];
	}

	var currentCriterionItem=[[criterion displayValue] target];
	while((target=[currentCriterionItem target])!=nil)
	{
		criterion=[self createCriterionFromView:target];
		if([target isKindOfClass:CPPopUpButton]) 
		{
			currentCriterionItem=[criterion displayValue];
			[criteria addObject:criterion]; 
			continue;
		}
		if([target isKindOfClass:CPView]) 
		{
			currentCriterionItem=target;
			[criteria addObject:criterion]; 
			continue;
		}
		break;
	}
	
	return criteria;
}

-(CPRuleEditorCriterion)createCriterionFromView:(CPView)view
{
	var criterionItems;
	var criterionDisplayValue;

	if([view isKindOfClass:CPPopUpButton]) 
	{
		criterionItems=[view itemArray];
		criterionDisplayValue=criterionItems&&[criterionItems count]?criterionItems[0]:nil;
		return [[CPRuleEditorCriterion alloc] initWithItems:criterionItems displayValue:criterionDisplayValue];			
	}

	if([view isKindOfClass:CPView]) 
	{
		criterionItems=[CPMutableArray arrayWithObject:view];
	    criterionDisplayValue=[CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:view]];
	    [criterionDisplayValue setTarget:[view target]];
		return [[CPRuleEditorCriterion alloc] initWithItems:criterionItems displayValue:criterionDisplayValue];			
	}
	
	return nil;
}

-(CPRuleEditorCriterion)createCriterionFromView:(CPView)view representedObject:(id)object
{
	var criterionItems;
	var criterionDisplayValue;

	if([view isKindOfClass:CPPopUpButton]) 
	{
		criterionItems=[view itemArray];
		if([object isKindOfClass:CPString])
			criterionDisplayValue=[view itemWithTitle:object];
		else
		{
			var valueIndex=[view indexOfItemWithRepresentedObject:object];
			if(valueIndex==CPNotFound)
				return nil;
			criterionDisplayValue=[view itemAtIndex:valueIndex];
		}
		
		return [[CPRuleEditorCriterion alloc] initWithItems:criterionItems displayValue:criterionDisplayValue];			
	}

	if([view isKindOfClass:CPView]) 
	{
		criterionItems=[CPMutableArray arrayWithObject:view];
	    criterionDisplayValue=[CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:view]];
	    [criterionDisplayValue setTarget:[view target]];
	    if([object isKindOfClass:CPString]&&[view respondsToSelector:@selector(setStringValue:)])
	    	[view setStringValue:object];
	    else
	    if([view respondsToSelector:@selector(setObjectValue:)])
	    	[view setObjectValue:object];
		return [[CPRuleEditorCriterion alloc] initWithItems:criterionItems displayValue:criterionDisplayValue];			
	}
	
	return nil;
}

#pragma mark Criteria setup

-(void)setupRowTemplates
{
	if(!_rowTemplates||![_rowTemplates count])
	{
		_simpleCriteriaRoot=nil;
		_compoundCriteriaRoot=nil;
		return;
	}
	
	var template;
	var views;
	var count=[_rowTemplates count];
	for(var i=0;i<count;i++)
		[self setupCriteriaForTemplate:[_rowTemplates objectAtIndex:i]];
}

-(void)setupCriteriaForTemplate:(CPPredicateEditorRowTemplate)template
{
	if(!template)
		return;

	var views=[template templateViews];
	if(!views||![views count])
		return;
	
	var root;
	var rowType=[template _rowType];
	
	if(rowType==CPRuleEditorRowTypeSimple)
	{
		if(!_simpleCriteriaRoot)
			_simpleCriteriaRoot=[CPMutableArray array];
		root=_simpleCriteriaRoot;
	}
	else
	if(rowType==CPRuleEditorRowTypeCompound)
	{
		if(!_compoundCriteriaRoot)
			_compoundCriteriaRoot=[CPMutableArray array];
		root=_compoundCriteriaRoot;
	}
	else
		return;
	
	var view;
	var nextView=nil;
	var count=[views count];
	for(var i=0;i<count;i++)
	{
		view=[views objectAtIndex:i];
		nextView=(i<count-1)?[views objectAtIndex:i+1]:nil;
		[self setTarget:nextView forView:view];
		if(i==0)
			[self retainItemsOfView:view inRoot:root forTemplate:template];
	}
}

-(void)setTarget:(CPView)target forView:(CPView)view
{
	if(!view)
		[CPException raise:CPInvalidArgumentException reason:_cmd+@" : template views must not be nil."];
		
	if(![view isKindOfClass:CPControl])
		[CPException raise:CPInvalidArgumentException reason:_cmd+@" : template views must extend CPControl"];
	
	if([view isKindOfClass:CPPopUpButton])
	{
		var items=[view itemArray];
		var count=[items count];
		var item;
		for(var i=0;i<count;i++)
		{
			item=[items objectAtIndex:i];
			if([item isSeparatorItem])
				continue;
			[item setTarget:target];
		}
		return;
	}
	
	[view setTarget:target];
}

-(void)retainItemsOfView:(CPView)view inRoot:(CPArray)root forTemplate:(CPPredicateEditorRowTemplate)template
{
	if(!view)
		[CPException raise:CPInvalidArgumentException reason:_cmd+@" : template views must not be nil."];
		
	if(![view isKindOfClass:CPPopUpButton])
		[CPException raise:CPInvalidArgumentException reason:_cmd+@" : template root (the first view) must extend CPPopUpButton"];
	
	var items=[view itemArray];
	var count=[items count];
	var item;
	for(var i=0;i<count;i++)
	{
		item=[items objectAtIndex:i];
		if([item isSeparatorItem])
			continue;
		[root addObject:item];
		[self mapObject:item withTemplate:template protect:YES];
	}
}

#pragma mark CPRuleEditorDelegate implementation

-(CPInteger)ruleEditor:(CPRuleEditor)editor numberOfChildrenForCriterion:(id)criterion withRowType:(int)rowType 
{
    if(!criterion) 
    {
		if(rowType==CPRuleEditorRowTypeSimple) 
			return [_simpleCriteriaRoot count];
		return [_compoundCriteriaRoot count];
    }

	if(![criterion respondsToSelector:@selector(target)])
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : invalid criterion"];
		
	var target=[criterion target];
	if(!target||target==criterion)
		return 0;
	
	if([target isKindOfClass:CPPopUpButton]) 
		return [target numberOfItems];
	else
	if([target isKindOfClass:CPControl]) 
		return 1;
	return 0;
}

-(id)ruleEditor:(CPRuleEditor)editor child:(CPInteger)index forCriterion:(id)criterion withRowType:(int)rowType 
{
    if(!criterion) 
    {
		if(rowType==CPRuleEditorRowTypeSimple) 
			return [_simpleCriteriaRoot objectAtIndex:index];
		
		return [_compoundCriteriaRoot objectAtIndex:index];
    }

	var target=[criterion target];

	if([target isKindOfClass:[CPPopUpButton class]]) 
		return [target itemAtIndex:index];
	
	if([target isKindOfClass:[CPView class]]) 
	{
	    var newTarget=[CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:target]];
	    [newTarget setTarget:[target target]];
	    return newTarget;
	}
	
	return nil;
}

-(id)ruleEditor:(CPRuleEditor)editor displayValueForCriterion:(id)criterion inRow:(CPInteger)row 
{
    if([criterion isKindOfClass:[CPMenuItem class]]) 
    {
		if([criterion isSeparatorItem])
			return [CPMenuItem separatorItem];
		return criterion;
    }

	return [CPKeyedUnarchiver unarchiveObjectWithData:[CPKeyedArchiver archivedDataWithRootObject:criterion]];
}

#pragma mark Creating a predicate

-(CPPredicate)predicateForRow:(CPInteger)aRowIndex
{
	var row=[_model rowAtIndex:aRowIndex];
	if(!row)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : invalid row index"];
	
	var template=[row data];
	if(!template||![template isKindOfClass:CPPredicateEditorRowTemplate])
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : invalid row data, no template ref"];
	
	var views=[template templateViews];
	if(!views)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : invalid template, no views"];

	var criteria=[row criteria];
	if(!criteria)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : invalid row, missing criteria"];
	
	var count=[views count];

	if([criteria count]<count)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : invalid row or template, criteria and views number do not match"];
	
	var view;
	var displayValue;
	var criterion;
	
	var subpredicates=[self subpredicatesForRow:row];
		
	for(var i=0;i<count;i++)
	{
		view=[views objectAtIndex:i];
		criterion=[criteria objectAtIndex:i];
		displayValue=[criterion displayValue];
		[self selectValue:displayValue inCriterionView:view];
	}
	
	return [template predicateWithSubpredicates:subpredicates];
}

-(CPArray)subpredicatesForRow:(CPRuleEditorModelItem)row
{
	if(!row||[row rowType]!=CPRuleEditorRowTypeCompound)
		return [CPMutableArray array];
		
	var subrow;
    var subpredicate;
    var subpredicates=[CPMutableArray array];
    
    var count=[row subrowsCount];
    for(var i=0;i<count;i++)
    {
    	subrow=[row childAtIndex:i];
    	subpredicate=[self predicateForRow:[_model indexOfRow:subrow]];
    	if(!subpredicate)
    		continue;
    	[subpredicates addObject:subpredicate];
    }
    
    return subpredicates;
}

-(void)selectValue:(id)displayValue inCriterionView:(CPView)view
{
	if(!displayValue)
		[CPException raise:CPInternalInconsistencyException 
			reason:_cmd+@" : invalid display value for criterion, must not be nil"];

	if(!view)
		[CPException raise:CPInternalInconsistencyException 
			reason:_cmd+@" : invalid view in template, must not be nil"];

	if([displayValue isKindOfClass:CPMenuItem])
	{
		if(![view isKindOfClass:CPPopUpButton])
			[CPException raise:CPInternalInconsistencyException 
				reason:_cmd+@" : invalid display value for criterion, does not match template view class"];
        [view selectItemWithTitle:[displayValue title]];
        return;
	}

	if([displayValue isKindOfClass:CPString])
	{
		if([view isKindOfClass:CPPopUpButton])
		{
	        [view selectItemWithTitle:displayValue];
	        return;
		}
	    
	    if([view respondsToSelector:@selector(setStringValue:)])
		{
	        [view setStringValue:displayValue];
	        return;
		}

	    if([view respondsToSelector:@selector(setObjectValue:)])
		{
	        [view setObjectValue:objectValue];
	        return;
		}
	}

	if([displayValue isKindOfClass:CPControl])
	{
		if([view isKindOfClass:CPPopUpButton]||![view isKindOfClass:CPControl])
			[CPException raise:CPInternalInconsistencyException 
				reason:_cmd+@" : invalid display value for criterion, does not match template view class"];
			
        if([displayValue respondsToSelector:@selector(color)])
        {
	        if(![view respondsToSelector:@selector(setColor:)])
				[CPException raise:CPInternalInconsistencyException 
					reason:_cmd+@" : invalid display value for criterion, does not match template view class"];
        	[view setColor:[displayValue color]];
	        return;
        }

        if([displayValue respondsToSelector:@selector(stringValue)])
        {
	        if(![view respondsToSelector:@selector(setStringValue:)])
				[CPException raise:CPInternalInconsistencyException 
					reason:_cmd+@" : invalid display value for criterion, does not match template view class"];
        	[view setStringValue:[displayValue stringValue]];
        	return;
        }
        
        if([displayValue respondsToSelector:@selector(objectValue)])
        {
	        if(![view respondsToSelector:@selector(setObjectValue:)])
				[CPException raise:CPInternalInconsistencyException 
					reason:_cmd+@" : invalid display value for criterion, does not match template view class"];
        	[view setObjectValue:[displayValue objectValue]];
        	return;
        }
	}
	
	[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : failed to set display value on criterion, classes do not match"];
}

#pragma mark CPRuleEditor overrides

-(void)setDelegate
{
}

-(CPArray)willInsertNewRowWithCriteria:(CPArray)criteria atIndex:(CPInteger)index
{
	var template=[self templateRefFromCriteria:criteria];
	if(template)
		return [template preProcessCriteria:criteria];
	return criteria;
}

-(void)didAddRow:(CPRuleEditorModelItem)row
{
	[self updateTemplateRefForRow:row];
}

-(void)willModifyRow:(CPRuleEditorModelItem)row
{
	var template=[self updateTemplateRefForRow:row];
	var criteria=[row criteria];
	if(!criteria||!template)
		return;
	[template preProcessCriteria:criteria];
}

-(id)criterionItemCopy:(id)item
{
	var template=[self mappedTemplateForObject:item];
	var copy=[item copy];
	[self mapObject:copy withTemplate:template];
	return copy;
}

#pragma mark Template mapping

-(CPPredicateEditorRowTemplate)updateTemplateRefForRow:(CPRuleEditorModelItem)row
{
	if(!row)
		return nil;
	var template=[self templateRefFromCriteria:[row criteria]];
	[row setData:template];	
	return template;
}

-(CPPredicateEditorRowTemplate)templateRefFromCriteria:(CPArray)criteria
{
	if(!criteria||![criteria count])
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : invalid criterion array, must not be empty"];
		
	var firstCriterion=[criteria objectAtIndex:0];
	var template=[self mappedTemplateForObject:[firstCriterion displayValue]];
	if(!template)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : orphan row, no template found"];

	return template;	
}

-(void)mapObject:(id)value withTemplate:(CPPredicateEditorRowTemplate)template
{
	[self mapObject:value withTemplate:template protect:NO];
}

-(void)mapObject:(id)value withTemplate:(CPPredicateEditorRowTemplate)template protect:(BOOL)protect
{
	if(!value||!template)
		return;

	value[":)"]=template;
}

-(CPPredicateEditorRowTemplate)mappedTemplateForObject:(id)value
{
	if(!value)
		return nil;
	return value[":)"];
}

@end

var CPPredicateTemplatesKey = @"CPPredicateTemplates";

@implementation CPPredicateEditor (CPCoding)

- (id)initWithCoder:(id)aCoder
{
    self=[super initWithCoder:aCoder];
    if (self != nil)
    {
        [self setRowTemplates:[aCoder decodeObjectForKey:CPPredicateTemplatesKey]];
    }

    return self;
}

- (void)encodeWithCoder:(id)aCoder
{
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:_rowTemplates forKey:CPPredicateTemplatesKey];
}

@end

/*! @endcond */
