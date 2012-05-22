/*
 * CPRuleEditorRowView.j
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
 
@import <Foundation/CPObject.j>
@import <AppKit/CPView.j>
@import <AppKit/CPButton.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPMenu.j>
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPButton.j>
@import "CPRuleEditorCriterion.j"
@import "CPRuleEditorPopUpButton.j"
@import "CPRuleEditorActionButton.j"


var GRADIENT_NORMAL;
var GRADIENT_HIGHLIGHTED;

IE_FILTER = "progid:DXImageTransform.Microsoft.gradient(startColorstr='#fcfcfc', endColorstr='#dfdfdf')";

CPRuleEditorRowViewRightMargin=10;
CPRuleEditorRowViewLeftMargin=10;
CPRuleEditorRowViewVerticalMargin=4;
CPRuleEditorRowViewButtonHeight=14;
CPRuleEditorRowViewButtonSpacing=6;
CPRuleEditorRowViewCriterionHeight=18;
CPRuleEditorRowViewPopUpHeight=14;
CPRuleEditorRowViewCriterionSpacing=10;
CPRuleEditorRowViewDragIndicatorHeight=3;

CPRuleEditorViewAltKeyDown = @"CPRuleEditorViewAltKeyDown";
CPRuleEditorViewAltKeyUp = @"CPRuleEditorViewAltKeyUp";

@implementation CPRuleEditorRowView : CPView
{
	CPView 					_contentView @accessors(readonly,property=contentView);
	CPView 					_subrowsView @accessors(readonly,property=subrowsView);
	id 						_delegate @accessors(property=delegate);
	CPRuleEditorModelItem 	_item @accessors(property=item);
	BOOL 					_selected @accessors(property=selected);
	int 					_nestingMode @accessors(property=nestingMode);
	CPButton 				_addButton @accessors(readonly,property=addButton);
	CPButton 				_removeButton @accessors(readonly,property=removeButton);
	BOOL 					_editable @accessors(property=editable);
	CGFloat					_rowHeight @accessors(property=rowHeight);
	BOOL 					_showDragIndicator @accessors(property=showDragIndicator);
	CPImage                 _alternateAddButtonImage; 
	CPNotificationCenter	_notificationCenter;
	CPImage 				_alternateAddButtonImage=nil;
	
	BOOL 					_frozenActions;
	BOOL 					_updating;
}

#pragma mark Theming

+ (id)themeAttributes
{
	return [CPRuleEditor themeAttributes];
}

+ (void)initialize
{
    if (CPBrowserIsEngine(CPWebKitBrowserEngine))
    {
        GRADIENT_NORMAL = "-webkit-gradient(linear, left top, left bottom, from(rgb(252, 252, 252)), to(rgb(223, 223, 223)))";
        GRADIENT_HIGHLIGHTED = "-webkit-gradient(linear, left top, left bottom, from(rgb(223, 223, 223)), to(rgb(252, 252, 252)))";
    }
    else if (CPBrowserIsEngine(CPGeckoBrowserEngine))
    {
        GRADIENT_NORMAL = "-moz-linear-gradient(top,  rgb(252, 252, 252),  rgb(223, 223, 223))";
        GRADIENT_HIGHLIGHTED = "-moz-linear-gradient(top,  rgb(223, 223, 223),  rgb(252, 252, 252))";
    }
}

#pragma mark Constructors

-(id)initWithFrame:(CGRect)frame
{
    self=[super initWithFrame:frame];
    if(!self)
    	return nil;

	[self setThemeClass:"rule-editor"];    
	[self setAutoresizingMask:CPViewWidthSizable];
	
	_selected=NO;
	_delegate=nil;
	_item=nil;
	_nestingMode=CPRuleEditorRowTypeSimple;
	_editable=YES;
	_rowHeight=frame.size.height;
	_updating=NO;
	_frozenActions=NO;

//TODO Use theme image
	
	_alternateAddButtonImage=[[CPImage alloc] initWithContentsOfFile:[[CPBundle bundleForClass:[CPRuleEditor class]] pathForResource:@"CPRuleEditor/rule-editor-add-compound.png"] ];
	
	[self createCriteriaView];
	[self createSubrowsView];
	[self createButtons];
	
    return self;
}

#pragma mark Building the view

-(void)createButtons
{
	_addButton=[self createButtonWithAction:@selector(addClicked:) image:[self valueForThemeAttribute:@"add-image"] atPosition:0];
	_removeButton=[self createButtonWithAction:@selector(removeClicked:) image:[self valueForThemeAttribute:@"remove-image"] atPosition:1];
	
	[self addSubview:_addButton];
	[self addSubview:_removeButton];
}

-(CPButton)createButtonWithAction:(SEL)action image:(CPImage)image atPosition:(CPInteger)position
{
	var frame=[self frame];
	var deltaX=-position*(CPRuleEditorRowViewButtonHeight+CPRuleEditorRowViewButtonSpacing);
    var buttonFrame = CGRectMake(
    	frame.size.width-CPRuleEditorRowViewButtonHeight-CPRuleEditorRowViewRightMargin+deltaX,
    	(_rowHeight-CPRuleEditorRowViewButtonHeight)/2,
    	CPRuleEditorRowViewButtonHeight,
    	CPRuleEditorRowViewButtonHeight);

    var button=[[CPRuleEditorActionButton alloc] initWithFrame:buttonFrame];
    
    [button setImage:image];
    [button setAction:action];
    [button setTarget:self];
    [button setAutoresizingMask:CPViewMinXMargin];
    
    return button;
}

-(void)createCriteriaView
{
	_contentView=[[CPView alloc] initWithFrame:[self bounds]];
    [_contentView setAutoresizingMask:CPViewWidthSizable];
	[self addSubview:_contentView];
}

-(void)createSubrowsView
{
	var bounds=[self bounds];
	var rect=CGRectMake(0,bounds.size.height,bounds.size.width,0);
	_subrowsView=[[CPView alloc] initWithFrame:rect];
    [_subrowsView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
	[self addSubview:_subrowsView];
}

#pragma mark Properties


-(void)setItem:(CPRuleEditorModelItem)item
{	
	[self resetCriteria];
	
	_item=item;
	
	var criteria=[item criteria];
	
	var criterion;
	var previousCriterion;
	var displayValue;
	var view;
	
	var count=[criteria count];
	if(count==0)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : Empty CPRuleEditorCriterion"];

	_frozenActions=YES;
	
	for(var i=0;i<count;i++)
	{
		criterion=criteria[i];
		if(![criterion isKindOfClass:CPRuleEditorCriterion]||![criterion isValid])
			[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : Invalid CPRuleEditorCriterion"];

		displayValue=[criterion displayValue];
		if([criterion isStandaloneView])
		{
			previousCriterion=[self addViewForCriterion:criterion withValue:displayValue atIndex:i afterCriterionView:previousCriterion];
			continue;
		}
		
		previousCriterion=[self addMenuForCriterion:criterion withValue:displayValue atIndex:i afterCriterionView:previousCriterion];
	}	
	
	_frozenActions=NO;
}

-(void)setNestingMode:(CPInteger)nestingMode
{
	if(nestingMode==_nestingMode)
		return;
		
	_nestingMode=nestingMode;

	var subviews=[_subrowsView subviews];
	
	var subview;
	var view;
	var count=[subviews count];
	
	for(var i=0;i<count;i++)	
	{
		subview=subviews[i];
		if(![subview isKindOfClass:CPRuleEditorRowView])
			continue;
		view=[subview setNestingMode:nestingMode];
		if(view)
			return view;
	}
}

-(void)setDelegate:(id)delegate
{
	if(delegate==_delegate)
		return;
		
	var subviews=[_subrowsView subviews];
	
	var subview;
	var view;
	var count=[subviews count];
	
	for(var i=0;i<count;i++)	
	{
		subview=subviews[i];
		if(![subview isKindOfClass:CPRuleEditorRowView])
			continue;
		[subview setDelegate:delegate];
	}

    var notificationCenter=[CPNotificationCenter defaultCenter];

    if(_delegate)
    {
		[notificationCenter removeObserver:self name:CPRuleEditorViewAltKeyDown object:_delegate];
		[notificationCenter removeObserver:self name:CPRuleEditorViewAltKeyUp object:_delegate];
    }
    
	_delegate=delegate;
    
    if(_delegate&&[_delegate nestingMode]==CPRuleEditorNestingModeCompound)
    {
		[notificationCenter addObserver:self selector:@selector(altKeyDown:) name:CPRuleEditorViewAltKeyDown object:_delegate];
		[notificationCenter addObserver:self selector:@selector(altKeyUp:) name:CPRuleEditorViewAltKeyUp object:_delegate];
		
		if([[CPApp currentEvent] modifierFlags] & CPAlternateKeyMask)
			[self altKeyDown:nil];
    }
}

-(void)setSelected:(BOOL)selected
{
	if(selected==_selected)
		return;
	
	_selected=selected;
	
	if(_selected)
		[self setThemeState:CPThemeStateSelectedDataView];
	else
		[self unsetThemeState:CPThemeStateSelectedDataView];
}

-(void)setEditable:(BOOL)editable
{
	if(_editable==editable)
		return;

	_editable=editable;
	
	[_addButton setHidden:!_editable];
	[_removeButton setHidden:!_editable];

	var subviews;
	var subview;

	subviews=[_contentView subviews];
	var count=[subviews count];
	for(var i=0;i<count;i++)	
	{
		subview=subviews[i];
		if([subview respondsToSelector:@selector(setEnabled:)])
			[subview setEnabled:_editable];
		if([subview respondsToSelector:@selector(setEditable:)])
			[subview setEditable:_editable];
	}

	subviews=[_subrowsView subviews];

	count=[subviews count];
	for(var i=0;i<count;i++)	
	{
		subview=subviews[i];
		if(![subview isKindOfClass:CPRuleEditorRowView])
			continue;
		[subview setEditable:_editable];
	}
}

-(void)setRowHeight:(CGFloat)rowHeight
{
	if(_rowHeight==rowHeight)
		return;

	_rowHeight=Math.max(rowHeight,CPRuleEditorRowViewMinHeight);

	var subview;
	var subviews=[_subrowsView subviews];
	var count=[subviews count];
	for(var i=0;i<count;i++)	
	{
		subview=subviews[i];
		if(![subview isKindOfClass:CPRuleEditorRowView])
			continue;
		[subview setRowHeight:_rowHeight];
	}
}

-(BOOL)isLast
{
	if(!_item)
		return NO;

	var parent=[_item parent];
	if(!parent)
		return [_item subrows]==0;

	return [parent indexOfChild:_item]==([parent subrowsCount]-1);
}

-(void)setShowDragIndicator:(BOOL)show
{
	if(_showDragIndicator==show)
		return;
	_showDragIndicator=show;
	[self setNeedsDisplay:YES];
}

#pragma mark Criteria management

-(void)resetCriteria
{
	var subviews=[_contentView subviews];
	var count=[subviews count];
	for(var i=count-1;i>=0;i--)	
		[subviews[i] removeFromSuperview];
}

-(CPInteger)indexOfCriterion:(id)aCriterion
{
	if([aCriterion isKindOfClass:CPMenuItem])
		return [self indexOfMenuItemCriterion:aCriterion];

	var view;
	var subviews=[_contentView subviews];
	var count=[subviews count];
	for(var i=0;i<count;i++)
		if([subviews objectAtIndex:i]===aCriterion)
			return i;
	
	return CPNotFound;
}

-(CPInteger)indexOfMenuItemCriterion:(CPMenuItem)item
{
	var view;
	var subviews=[_contentView subviews];
	var count=[subviews count];
	for(var i=0;i<count;i++)
	{
		view=[subviews objectAtIndex:i];
		if(![view isKindOfClass:CPPopUpButton])
			continue;
		if([[view menu] indexOfItem:item]!=CPNotFound)
			return i;
	}
	
	return CPNotFound;
}

-(void)addCriterionView:(CPView)criterion afterCriterionView:(CPView)previousCriterion
{
	var frame=[self frame];
	var previousCriterionFrame=previousCriterion?[previousCriterion frame]:nil;
	var xOrigin=previousCriterion?
		previousCriterionFrame.origin.x+previousCriterionFrame.size.width+CPRuleEditorRowViewCriterionSpacing
		:CPRuleEditorRowViewLeftMargin;
	
	if([criterion isKindOfClass:CPTextField])
		[criterion setSmallSize];
		
	var height=[criterion isKindOfClass:CPPopUpButton]?CPRuleEditorRowViewPopUpHeight:CPRuleEditorRowViewCriterionHeight;
    var criterionFrame=[criterion frame]; 
    criterionFrame=CGRectMake(
    	xOrigin,
    	(_rowHeight-height)/2,
    	criterionFrame.size.width,
    	height);
    
    [criterion setFrame:criterionFrame];
    [_contentView addSubview:criterion];
}

-(void)bindCriterionViewItem:(id)item
{
	if(!item)
		return;
	
	if([item isKindOfClass:CPMenuItem])
	{
		[item setTarget:self];
		[item setAction:@selector(criterionChanged:)];
		return;
	}

	if([item isKindOfClass:CPTextField])
	{
	    [[CPNotificationCenter defaultCenter] addObserver:self selector:@selector(criterionChangedNotification:) name:CPControlTextDidEndEditingNotification object:item];
	    return;
	}

	if(![item isKindOfClass:CPControl])
		return;

	if([item respondsToSelector:@selector(objectValue)])
	    [item addObserver:self forKeyPath:@"objectValue" options:CPKeyValueObservingOptionNew | CPKeyValueObservingOptionOld context:nil];
	if([item respondsToSelector:@selector(stringValue)])
	    [item addObserver:self forKeyPath:@"stringValue" options:CPKeyValueObservingOptionNew | CPKeyValueObservingOptionOld context:nil];
	if([item respondsToSelector:@selector(color)])
	    [item addObserver:self forKeyPath:@"color" options:CPKeyValueObservingOptionNew | CPKeyValueObservingOptionOld context:nil];
}

- (void)observeValueForKeyPath:(CPString)aKeyPath ofObject:(id)anObject change:(CPDictionary)changes context:(id)aContext
{
	[self criterionChanged:anObject];
}

-(CPView)addViewForCriterion:(CPRuleEditorCriterion)criterion withValue:(id)value atIndex:(CPInteger)index afterCriterionView:(CPRuleEditorCriterion)previousCriterion
{
	if(![criterion isStandaloneView])
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : Invalid CPRuleEditorCriterion"];
	
	var view;
	
	if([value isKindOfClass:CPView])
	{
		view=[_delegate criterionItemCopy:value];
		[view setHidden:[criterion hidden]];
		[self addCriterionView:view afterCriterionView:previousCriterion];
		[self bindCriterionViewItem:view];
		return view;
	}

	view=[_delegate criterionItemCopy:[criterion standaloneView]];
	
	if(!value)
	{
		[view setHidden:[criterion hidden]];
		[self addCriterionView:view afterCriterionView:previousCriterion];
		[self bindCriterionViewItem:view];
		return view;
	}

	if([value isKindOfClass:CPString])
	{
		if([view respondsToSelector:@selector(setStringValue:)])
			[view setStringValue:value];
		else
		if([view respondsToSelector:@selector(setObjectValue:)])
			[view setObjectValue:value];

		[view setHidden:[criterion hidden]];
		[self addCriterionView:view afterCriterionView:previousCriterion];
		[self bindCriterionViewItem:view];
		return view;
	}

	if([criterion respondsToSelector:@selector(setObjectValue:)])
		[criterion setObjectValue:value];
	
	[view setHidden:[criterion hidden]];
	[self addCriterionView:view afterCriterionView:previousCriterion];
	[self bindCriterionViewItem:view];
	return view;
}

-(CPView)addMenuForCriterion:(CPRuleEditorCriterion)criterion withValue:(id)value atIndex:(CPInteger)index afterCriterionView:(CPRuleEditorCriterion)previousCriterion
{
	if(![criterion isMenu])
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : Invalid CPRuleEditorCriterion"];
	
	var menuItems=[CPArray arrayWithArray:[criterion items]];
	var menuCount=[menuItems count];
	
	if(menuCount==1)
	{
		return [self addStaticTextForCriterion:criterion afterCriterionView:previousCriterion];
	}
	
	var menuItem;
	var selectedIndex=CPNotFound;
	var selectedTitle=nil;

	if(value)
	{
		if([value isKindOfClass:CPNumber])
			selectedIndex=[value intValue];
		else if([value isKindOfClass:CPString])
			selectedTitle=value;
		else if(!isNaN(value))
			selectedIndex=[value intValue];
		else if([value isKindOfClass:CPMenuItem])
			selectedTitle=[value title];
		else if([value respondsToSelector:@selector(description)])
			selectedTitle=[value description];
	}
	
	for(var i=0;i<menuCount;i++)
	{
		menuItem=menuItems[i];
		if(!menuItem)
		{
			menuItems[i]=[CPMenuItem separatorItem];
			continue;
		}

		if([menuItem isKindOfClass:CPString])
		{
			if([menuItem length]==0)
			{
				menuItems[i]=[CPMenuItem separatorItem];
				continue;
			}
			
			menuItems[i]=[[CPMenuItem alloc] initWithTitle:menuItem action:@selector(criterionChanged:) keyEquivalent:@""];
			[self bindCriterionViewItem:menuItems[i]];
			
			continue;
		}

		menuItem=[_delegate criterionItemCopy:menuItem];
		[menuItem setState:CPOffState];
		
		if([menuItem menu])
			[[menuItem menu] removeItem:menuItem];
		
		menuItems[i]=menuItem;
	
		[self bindCriterionViewItem:menuItems[i]];
	}
	
	var selectedItem=nil;
	
	if(selectedIndex!=CPNotFound&&selectedIndex<[menuItems count])
	{
		selectedItem=[menuItems objectAtIndex:selectedIndex];
	}
	else
	if(selectedTitle)
	{
		var idx=[menuItems indexOfObjectPassingTest:function(obj,index){
			return [obj title]==selectedTitle;
		}];
		if(idx!=CPNotFound)
			selectedItem=menuItems[idx];
	}
	else
	{
		var idx=selectedItem=[menuItems indexOfObjectPassingTest:function(obj,index){
			return ![obj isSeparatorItem];
		}];
		if(idx!=CPNotFound)
			selectedItem=menuItems[idx];
	}
	
	if(!selectedItem)
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : Invalid CPRuleEditorCriterion"];
	
	var title=[selectedItem title];
    var font=[self valueForThemeAttribute:@"font"];
    var width=[title sizeWithFont:font].width+25;
    var frame=CGRectMake(0,0,width+((width%25)?25:0),CPRuleEditorRowViewButtonHeight);

    var popup=[[CPRuleEditorPopUpButton alloc] initWithFrame:frame];
    [popup setValue:font forThemeAttribute:@"font"];
    [popup setValue:CGSizeMake(0.0, CPRuleEditorRowViewCriterionHeight) forThemeAttribute:@"min-size"];

    for(var i=0;i<menuCount;i++)
    {
    	menuItem=[menuItems objectAtIndex:i];
    	if(![menuItem isSeparatorItem])
    	{
    		title=[menuItem title];
	    	[menuItem setTitle:[self localizedString:title]];
    	}
        [popup addItem:menuItem];
    }

    [popup selectItemWithTitle:[selectedItem title]];
	[popup setHidden:[criterion hidden]];
	
	[self addCriterionView:popup afterCriterionView:previousCriterion];

    return popup;
}

-(CPView)addStaticTextForCriterion:(CPRuleEditorCriterion)criterion afterCriterionView:(CPRuleEditorCriterion)previousCriterion
{
	if(![criterion isMenu])
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : Invalid CPRuleEditorCriterion"];
	
	var menuItems=[CPArray arrayWithArray:[criterion items]];
	
	var menuItem;
	
	menuItem=menuItems[0];
	if(!menuItem||([menuItem isKindOfClass:CPString]&&[menuItem length]==0))
		[CPException raise:CPInternalInconsistencyException reason:_cmd+@" : Invalid CPRuleEditorCriterion"];

	var text;

	if([menuItem isKindOfClass:CPMenuItem])	
		text=[menuItem title];
	else
		text=menuItem;
	
	var frame=CGRectMake(0,0,100,_rowHeight);
    var textField=[[CPTextField alloc] initWithFrame:frame];
    [textField setStaticWithFont:[self valueForThemeAttribute:@"font"]];
    [textField setStringValue:[self localizedString:text]];
    [textField sizeToFit];
	
	[self addCriterionView:textField afterCriterionView:previousCriterion];

    return textField;
}

-(void)removeFromSuperview
{
	if([self superview])
	{
		[[CPNotificationCenter defaultCenter] removeObserver:self];
	}
	[super removeFromSuperview];
}

#pragma mark Layout

-(void)addRowView:(CPRuleEditorRowView)aView
{
	[_subrowsView addSubview:aView];
}

-(void)removeRowView:(CPRuleEditorRowView)aView
{
	[aView removeFromSuperview];		
}

-(void)addRowView:(CPRuleEditorRowView)rowView positioned:(CPInteger)position relativeTo:(CPView)aView
{
	[_subrowsView addSubview:rowView positioned:position relativeTo:aView];
}

-(void)_layoutSubviews
{
	var subrows=[_subrowsView subviews];
	var count=[subrows count];

	var view;
	var rect;
	var deltaY=0;
	for(var i=0;i<count;i++)
	{
		view=subrows[i];
		if(![view isKindOfClass:CPRuleEditorRowView])
			continue;
			
		[view _layoutSubviews];
			
		rect=[view frame];
		rect.origin.y=deltaY;
		[view setFrame:rect];
		
		deltaY+=rect.size.height;

		[view setFrame:rect];
	}

	var indicatorHeight=_showDragIndicator?CPRuleEditorRowViewDragIndicatorHeight:0;

	rect=[_subrowsView frame];
	rect.origin.y=_rowHeight+indicatorHeight;
	rect.size.height=deltaY;
	[_subrowsView setFrame:rect];

    rect=[_addButton frame];
    rect.origin.y=((_rowHeight-CPRuleEditorRowViewButtonHeight)/2)-1;
    [_addButton setFrame:rect];
    [_addButton setHidden:(!_editable||(_delegate&&[_delegate nestingMode]==CPRuleEditorNestingModeSingle))];

    rect=[_removeButton frame];
    rect.origin.y=((_rowHeight-CPRuleEditorRowViewButtonHeight)/2)-1;
    [_removeButton setFrame:rect];
    [_removeButton setHidden:(!_editable||(_delegate&&(![_delegate isRowRemoveable:_item]||[_delegate nestingMode]==CPRuleEditorNestingModeSingle)))];

	subviews=[_contentView subviews];
	count=[subviews count];

	for(var i=0;i<count;i++)
	{
		view=subviews[i];
		rect=[view frame];
		rect.origin.y=[view isKindOfClass:CPButton]?((_rowHeight-rect.size.height)/2)-1:((_rowHeight-rect.size.height)/2);
		[view setFrame:rect];
	}
	
	var size=[_contentView frameSize];
	size.height=_rowHeight;
	[_contentView setFrameSize:size];

	size=[self frameSize];
	size.height=deltaY+_rowHeight+indicatorHeight;
	[self setFrameSize:size];
}

#pragma mark Finding subviews


-(CPRuleEditorRowView)rowViewWithItem:(CPRuleEditorModelItem)item
{
	if(_item==item)
		return self;
		
	var subviews=[_subrowsView subviews];
	
	var subview;
	var view;
	var count=[subviews count];
	
	for(var i=0;i<count;i++)	
	{
		subview=subviews[i];
		if(![subview isKindOfClass:CPRuleEditorRowView])
			continue;
		view=[subview rowViewWithItem:item];
		if(view)
			return view;
	}
	return nil;
}

#pragma mark Drawing


- (void)drawBordersInContext:(CGContext)context verticalOffset:(float)vOffset width:(float)width
{
    var frame=[self frame];
    
	CGContextSaveGState(context);
    
    CGContextBeginPath(context);
    CGContextMoveToPoint(context,0,frame.origin.y+vOffset+0.5);
    CGContextAddLineToPoint(context,width,frame.origin.y+vOffset+0.5);
    CGContextClosePath(context);
    CGContextSetStrokeColor(context,[CPColor whiteColor]);
    CGContextSetLineWidth(1);
    CGContextStrokePath(context);
    
    var indicatorHeight=_showDragIndicator?CPRuleEditorRowViewDragIndicatorHeight:0;
    if(indicatorHeight)
    {
	    indent=[_item rowType]==CPRuleEditorRowTypeSimple?CPRuleEditorRowViewIndent*[_item depth]:CPRuleEditorRowViewIndent*([_item depth]+1);

	    CGContextBeginPath(context);
	    CGContextMoveToPoint(context,indent,vOffset+frame.origin.y+_rowHeight+(indicatorHeight/2)+-0.5);
	    CGContextAddLineToPoint(context,width,vOffset+frame.origin.y+_rowHeight+(indicatorHeight/2)-0.5);
	    CGContextSetLineWidth(CPRuleEditorRowViewDragIndicatorHeight);
	    CGContextClosePath(context);
	    CGContextSetStrokeColor(context,[CPColor grayColor]);
	    CGContextStrokePath(context);
    }

    CGContextBeginPath(context);
    CGContextMoveToPoint(context,0,vOffset+frame.origin.y+_rowHeight+indicatorHeight+-0.5);
    CGContextAddLineToPoint(context,width,vOffset+frame.origin.y+_rowHeight+indicatorHeight-0.5);
    CGContextSetLineWidth(1);
    CGContextClosePath(context);
    CGContextSetStrokeColor(context,[self valueForThemeAttribute:@"slice-bottom-border-color"]);
    CGContextStrokePath(context);

	CGContextRestoreGState(context);

	var subrows=[_subrowsView subviews];
	var count=[subrows count];
	
	var subrow;
	vOffset+=frame.origin.y+_rowHeight+indicatorHeight;
	for(var i=0;i<count;i++)	
	{
		subrow=subrows[i];
		if(![subrow isKindOfClass:CPRuleEditorRowView])
			continue;
		[subrow drawBordersInContext:context verticalOffset:vOffset width:width];
	}
}

#pragma mark Actions

-(void)addClicked:(id)sender
{
	[[self window] makeFirstResponder:self];

	if(	_frozenActions
		||!_delegate
		||!sender
		||![_delegate respondsToSelector:@selector(insertNewRowOfType:afterRow:)]
		)
		return;
	
	var altKeyPressed=[[CPApp currentEvent] modifierFlags] & CPAlternateKeyMask;
	var rowType=(altKeyPressed&&_delegate&&[_delegate nestingMode]==CPRuleEditorNestingModeCompound)?CPRuleEditorRowTypeCompound:CPRuleEditorRowTypeSimple;

	[_delegate insertNewRowOfType:rowType afterRow:_item];
}

-(void)removeClicked:(id)sender
{
	[[self window] makeFirstResponder:self];

	if(	_frozenActions
		||!_delegate
		||!sender
		||![_delegate respondsToSelector:@selector(removeRow:)]
		)
		return;
		
	[_delegate removeRow:_item];
}

-(void)criterionChangedNotification:(CPNotification)notification
{
	if(!notification)
		return;
		
	var sender=[notification object];
	if(!sender)
		return;
		
	[self criterionChanged:sender];
}

-(void)criterionChanged:(id)sender
{
	if(_updating)
		return;

	_updating=YES;

	[[self window] makeFirstResponder:self];

	_updating=NO;

	if(	_frozenActions
		||!_delegate
		||!sender
		||![_delegate respondsToSelector:@selector(valueChanged:criterionIndex:valueIndex:inRow:)]
		)
		return;
	
	var value=nil;
	var criterionIndex=CPNotFound;
	var valueIndex=0;
		
	if([sender isKindOfClass:CPMenuItem])
	{
		valueIndex=[[sender menu] indexOfItem:sender];
		value=sender;
		criterionIndex=[self indexOfCriterion:sender];
	}
	else
	{
		value=sender;
		criterionIndex=[self indexOfCriterion:sender];
	}
	
	if(criterionIndex==CPNotFound)
		return;

	[_delegate valueChanged:value criterionIndex:criterionIndex valueIndex:valueIndex inRow:_item];
}

#pragma mark Delegating

-(CPString)localizedString:(CPString)str
{
	if(_delegate&&[_delegate respondsToSelector:@selector(localizedString:)])
		return [_delegate localizedString:str];
	return str;
}

#pragma mark Drag & Drop

- (CPView)hitTest:(CPPoint)aPoint
{
	var res=[super hitTest:aPoint];
	if(res==_contentView)
		return self;
	return res;
}

- (CPView)viewAtPoint:(CPPoint)aPoint
{
	var point=[self convertPoint:aPoint fromView:nil];
	var rect=[_contentView frame];

	if(CPRectContainsPoint(rect,point))
		return self;
	
	var view;
	var subview;
	var subviews=[_subrowsView subviews];
	var count=[subviews count];
	
	for(var i=0;i<count;i++)	
	{
		subview=subviews[i];
		if(![subview isKindOfClass:CPRuleEditorRowView])
			continue;

		view=[subview viewAtPoint:aPoint];
		if(view)
			return view;
	}

	return nil;
}

-(BOOL)hasSubrow:(CPRuleEditorRowView)rowView
{
	if(!rowView||rowView==self)
		return NO;

	var view;
	var subview;
	var subviews=[_subrowsView subviews];
	var count=[subviews count];
	
	for(var i=0;i<count;i++)	
	{
		subview=subviews[i];
		if(![subview isKindOfClass:CPRuleEditorRowView])
			continue;
			
		if(subview==rowView)
			return YES;
			
		if([subview hasSubrow:rowView])
			return YES;
	}
	
	return NO;
}

- (BOOL)isOpaque
{
    return YES;
}

- (void)mouseDragged:(CPEvent)event
{
	if(!_editable)
		return;
    var pasteboard=[CPPasteboard pasteboardWithName: CPDragPboard];
    [pasteboard declareTypes:[CPArray arrayWithObjects: CPRuleEditorItemPBoardType, nil] owner: self];

    var dragView=[[CPView alloc] initWithFrame:[self frame]];

    var html = self._DOMElement.innerHTML;
    dragView._DOMElement.innerHTML = [html copy];

    [dragView setAlphaValue:0.7];
    [dragView setBackgroundColor:[CPColor whiteColor]];

    [self dragView:dragView
                at:CPPointMake(0,0)
            offset:CPPointMake(0,0)
             event:event
        pasteboard:pasteboard
            source:self
         slideBack:YES];
}

#pragma mark Keyboard hook

-(BOOL)acceptsFirstResponder
{
    return YES;
}

- (BOOL)resignFirstResponder
{
    return [super resignFirstResponder];
}

-(void)flagsChanged:(CPEvent)anEvent
{
	[super flagsChanged:anEvent];
    if(_delegate&&[_delegate nestingMode]==CPRuleEditorNestingModeCompound)
	{
		if([anEvent modifierFlags]&CPAlternateKeyMask)
		{
			[[CPNotificationCenter defaultCenter] postNotificationName:CPRuleEditorViewAltKeyDown object:_delegate userInfo:nil];
		}
		else
		{
			[[CPNotificationCenter defaultCenter] postNotificationName:CPRuleEditorViewAltKeyUp object:_delegate userInfo:nil];
		}
	}
}

-(void)altKeyDown:(CPNotification)notification
{
//TODO Use theme image
    [_addButton setImage:_alternateAddButtonImage];
    [_addButton setNeedsDisplay:YES];
}

-(void)altKeyUp:(CPNotification)notification
{
    [_addButton setImage:[self valueForThemeAttribute:@"add-image"]];
    [_addButton setNeedsDisplay:YES];
}

@end

@implementation CPTextField(CPRuleEditorRowView)

-(void)setSmallSize
{
	[self setValue:[CPFont systemFontOfSize:11.0] forThemeAttribute:@"font" inState:CPThemeStateBezeled];
	[self setValue:CGInsetMake(3.0, 7.0, 0.0, 8.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBezeled];
	[self setValue:CGInsetMake(2.0, 6.0, 0.0, 8.0) forThemeAttribute:@"content-inset" inState:CPThemeStateBezeled | CPThemeStateEditing];
	[self setValue:CGInsetMake(0.0, 4.0, 0.0, 4.0) forThemeAttribute:@"bezel-inset" inState:CPThemeStateBezeled];
	[self setValue:CGInsetMake(-2.0, 0.0, -2.0, 0.0) forThemeAttribute:@"bezel-inset" inState:CPThemeStateBezeled | CPThemeStateEditing];
}

-(void)setStaticWithFont:(CPFont)font
{
	[self setBordered:NO];
	[self setEditable:NO];
	[self setDrawsBackground:NO];
    [self setValue:font forThemeAttribute:@"font"];

	if(![self stringValue])
		[self setStringValue:@" "];
	[self sizeToFit];
	[self setValue:CGInsetMake((([self frame].size.height-[font size])/2)+1, 0.0, 0.0, 0.0) forThemeAttribute:@"content-inset" inState:CPThemeStateNormal];
}

@end


