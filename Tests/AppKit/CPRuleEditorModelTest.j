@import <Foundation/Foundation.j>
@import <AppKit/CPRuleEditorModel.j>

@implementation CPRuleEditorModelTest : OJTestCase
{
}

-(CPRuleEditorModel)_setupListModel
{
/*
	0.Simple
	1.Simple
	2.Simple 
	3.Simple
	4.Simple 
*/
	var model=[[CPRuleEditorModel alloc] initWithNestingMode:CPRuleEditorNestingModeList];
	for(var i=0;i<5;i++)
		[model insertNewRowAtIndex:0 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:-1 criteria:nil];
	
	return model;
}

-(CPRuleEditorModel)_setupCompoundModel
{
/*
	0.Compound
		1.Simple
		2.Simple
		3.Compound 
			4.Simple 
			5.Simple
			6.Simple 
		7.Simple
		8.Simple 
		9.Simple 
*/
	var model=[[CPRuleEditorModel alloc] initWithNestingMode:CPRuleEditorNestingModeCompound];
	[model addNewRowOfType:CPRuleEditorRowTypeCompound criteria:nil];
	
	for(var i=0;i<5;i++)
		[model insertNewRowAtIndex:1 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:0 criteria:nil];
	
	[model insertNewRowAtIndex:3 ofType:CPRuleEditorRowTypeCompound withParentRowIndex:0 criteria:nil];

	for(var i=0;i<3;i++)
		[model insertNewRowAtIndex:4 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:3 criteria:nil];

	return model;
}

-(CPRuleEditorModel)_setupComplexCompoundModel
{
/*
	0.Compound
		1.Simple
		2.Simple
		3.Compound 
			4.Simple 
			5.Simple
			6.Simple 
		7.Simple
		8.Compound 
			9.Simple 
			10.Compound
				11.Simple
				12.Simple
				13.Simple
			14.Simple 
			15.Simple 
		16.Simple 
		17.Simple 
*/
	var model=[[CPRuleEditorModel alloc] initWithNestingMode:CPRuleEditorNestingModeCompound];
	[model addNewRowOfType:CPRuleEditorRowTypeCompound criteria:nil];

	for(var i=0;i<5;i++)
		[model insertNewRowAtIndex:1 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:0 criteria:nil];
	
	[model insertNewRowAtIndex:3 ofType:CPRuleEditorRowTypeCompound withParentRowIndex:0 criteria:nil];

	for(var i=0;i<3;i++)
		[model insertNewRowAtIndex:4 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:3 criteria:nil];
/*
	0.Compound
		1.Simple
		2.Simple
		3.Compound 
			4.Simple 
			5.Simple
			6.Simple 
		7.Simple
		8.Simple 
		9.Simple 
*/

	[model insertNewRowAtIndex:8 ofType:CPRuleEditorRowTypeCompound withParentRowIndex:0 criteria:nil];

	for(var i=0;i<3;i++)
		[model insertNewRowAtIndex:9 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:8 criteria:nil];
/*
	0.Compound
		1.Simple
		2.Simple
		3.Compound 
			4.Simple 
			5.Simple
			6.Simple 
		7.Simple
		8.Compound 
			9.Simple 
			10.Compound
				11.Simple 
				12.Simple
				13.Simple 
			14.Simple 
			15.Simple 
		16.Simple 
		17.Simple 
*/

	[model insertNewRowAtIndex:10 ofType:CPRuleEditorRowTypeCompound withParentRowIndex:8 criteria:nil];

	for(var i=0;i<3;i++)
		[model insertNewRowAtIndex:11 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:10 criteria:nil];

	return model;
}

-(void)test_initWithNestingMode_0
{
	var model=[[CPRuleEditorModel alloc] initWithNestingMode:CPRuleEditorNestingModeSingle];
	
	[self assertTrue:model!=nil];
	[self assertTrue:[model nestingMode]==CPRuleEditorNestingModeSingle];
	[self assertTrue:[model rootLess]];
}

-(void)test_initWithNestingMode_1
{
	var model=[[CPRuleEditorModel alloc] initWithNestingMode:CPRuleEditorNestingModeList];

	[self assertTrue:model!=nil];
	[self assertTrue:[model nestingMode]==CPRuleEditorNestingModeList];
	[self assertTrue:[model rootLess]];
}

-(void)test_initWithNestingMode_2
{
	var model=[[CPRuleEditorModel alloc] initWithNestingMode:CPRuleEditorNestingModeCompound];

	[self assertTrue:model!=nil];
	[self assertTrue:[model nestingMode]==CPRuleEditorNestingModeCompound];
	[self assertFalse:[model rootLess]];
}

-(void)test_initWithNestingMode_3
{
	var model=[[CPRuleEditorModel alloc] initWithNestingMode:CPRuleEditorNestingModeSimple];

	[self assertTrue:model!=nil];
	[self assertTrue:[model nestingMode]==CPRuleEditorNestingModeSimple];
	[self assertFalse:[model rootLess]];
}

-(void)test_allowNewRowInsertOfType_withParent_
{
// Single mode
	var model=[[CPRuleEditorModel alloc] initWithNestingMode:CPRuleEditorNestingModeSingle];
	[self assertTrue:[model allowNewRowInsertOfType:CPRuleEditorRowTypeSimple withParent:nil]];
	[self assertFalse:[model allowNewRowInsertOfType:CPRuleEditorRowTypeCompound withParent:nil]];

// List mode
	model=[[CPRuleEditorModel alloc] initWithNestingMode:CPRuleEditorNestingModeList];
	[self assertTrue:[model allowNewRowInsertOfType:CPRuleEditorRowTypeSimple withParent:nil]];
	[self assertFalse:[model allowNewRowInsertOfType:CPRuleEditorRowTypeCompound withParent:nil]];

// Simple mode
	model=[[CPRuleEditorModel alloc] initWithNestingMode:CPRuleEditorNestingModeSimple];
	[model addNewRowOfType:CPRuleEditorRowTypeCompound criteria:nil];
	[self assertTrue:[model allowNewRowInsertOfType:CPRuleEditorRowTypeSimple withParent:[model rowAtIndex:0]]];
	[self assertFalse:[model allowNewRowInsertOfType:CPRuleEditorRowTypeCompound withParent:[model rowAtIndex:0]]];

// Compound mode
	model=[[CPRuleEditorModel alloc] initWithNestingMode:CPRuleEditorNestingModeCompound];
	[model addNewRowOfType:CPRuleEditorRowTypeCompound criteria:nil];
	[self assertTrue:[model allowNewRowInsertOfType:CPRuleEditorRowTypeSimple withParent:[model rowAtIndex:0]]];
	[self assertTrue:[model allowNewRowInsertOfType:CPRuleEditorRowTypeCompound withParent:[model rowAtIndex:0]]];
}

-(void)test_addNewRowOfType_
{
// Single mode
	var model=[[CPRuleEditorModel alloc] initWithNestingMode:CPRuleEditorNestingModeSingle];

	var row=[model addNewRowOfType:CPRuleEditorRowTypeSimple criteria:nil];
	[self assertTrue:row!=nil message:@"Subtest 1.1 failed"];
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 1.2 failed"];
	[self assertTrue:[model flatRowsCount]==1 message:@"Subtest 1.3 failed"];
	
	row=[model addNewRowOfType:CPRuleEditorRowTypeSimple criteria:nil];
	[self assertTrue:row==nil message:@"Subtest 1.4 failed"];
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 1.5 failed"];
	[self assertTrue:[model flatRowsCount]==1 message:@"Subtest 1.6 failed"];

// List mode
	model=[[CPRuleEditorModel alloc] initWithNestingMode:CPRuleEditorNestingModeList];

	row=[model addNewRowOfType:CPRuleEditorRowTypeSimple criteria:nil];
	[self assertTrue:row!=nil message:@"Subtest 2.1 failed"];
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 2.2 failed"];
	[self assertTrue:[model flatRowsCount]==1 message:@"Subtest 2.3 failed"];
	
	row=[model addNewRowOfType:CPRuleEditorRowTypeCompound criteria:nil];
	[self assertTrue:row==nil message:@"Subtest 2.4 failed"];
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 2.5 failed"];
	[self assertTrue:[model flatRowsCount]==1 message:@"Subtest 2.6 failed"];

// Simple mode
	model=[[CPRuleEditorModel alloc] initWithNestingMode:CPRuleEditorNestingModeSimple];
	[model addNewRowOfType:CPRuleEditorRowTypeCompound criteria:nil];

	row=[model addNewRowOfType:CPRuleEditorRowTypeSimple criteria:nil];
	[self assertTrue:row==nil message:@"Subtest 3.1 failed"];
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 3.2 failed"];
	[self assertTrue:[model flatRowsCount]==1 message:@"Subtest 3.3 failed"];
	
	row=[model addNewRowOfType:CPRuleEditorRowTypeCompound criteria:nil];
	[self assertTrue:row==nil message:@"Subtest 3.4 failed"];
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 3.5 failed"];
	[self assertTrue:[model flatRowsCount]==1 message:@"Subtest 3.6 failed"];

// Compound mode
	model=[[CPRuleEditorModel alloc] initWithNestingMode:CPRuleEditorNestingModeCompound];
	[model addNewRowOfType:CPRuleEditorRowTypeCompound criteria:nil];

	row=[model addNewRowOfType:CPRuleEditorRowTypeSimple criteria:nil];
	[self assertTrue:row==nil message:@"Subtest 4.1 failed"];
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 4.2 failed"];
	[self assertTrue:[model flatRowsCount]==1 message:@"Subtest 4.3 failed"];

	row=[model addNewRowOfType:CPRuleEditorRowTypeCompound criteria:nil];
	[self assertTrue:row==nil message:@"Subtest 4.4 failed"];
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 4.5 failed"];
	[self assertTrue:[model flatRowsCount]==1 message:@"Subtest 4.6 failed"];
}

-(void)test_rowAtIndex_indexOfRow_
{
/*
	0.Compound
		1.Simple
		2.Simple
		3.Compound 
			4.Simple 
			5.Simple
			6.Simple 
		7.Simple
		8.Compound 
			9.Simple 
			10.Compound
				11.Simple
				12.Simple
				13.Simple
			14.Simple 
			15.Simple 
		16.Simple 
		17.Simple 
*/
	var model=[self _setupComplexCompoundModel];
	
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 1.1 failed"];
	[self assertTrue:[model flatRowsCount]==18 message:@"Subtest 1.2 failed"];
	
	var row,index;
	for(var i=0;i<18;i++)
	{
		row=[model rowAtIndex:i];
		index=[model indexOfRow:row];
		[self assertTrue:(i==index) message:@"Subtest 1.3 failed"];
	}
}

-(void)test_immediateSubrowsIndexesOfRowAtIndex_
{
/*
	0.Compound
		1.Simple
		2.Simple
		3.Compound 
			4.Simple 
			5.Simple
			6.Simple 
		7.Simple
		8.Compound 
			9.Simple 
			10.Compound
				11.Simple
				12.Simple
				13.Simple
			14.Simple 
			15.Simple 
		16.Simple 
		17.Simple 
*/
	var model=[self _setupComplexCompoundModel];

	indexSet=[model immediateSubrowsIndexesOfRowAtIndex:0];
	expected=[[CPMutableIndexSet alloc] init];
	[expected addIndex:1];
	[expected addIndex:2];
	[expected addIndex:3];
	[expected addIndex:7];
	[expected addIndex:8];
	[expected addIndex:16];
	[expected addIndex:17];

	[self assertTrue:indexSet!=nil message:@"Subtest 1.1 failed"];
	[self assertTrue:[indexSet count]==7 message:@"Subtest 1.2 failed"];
	[self assertTrue:[indexSet isEqualToIndexSet:expected] message:@"Subtest 1.3 failed"];
	
	indexSet=[model immediateSubrowsIndexesOfRowAtIndex:1];
	[self assertTrue:indexSet==nil message:@"Subtest 2.1 failed"];
	
	indexSet=[model immediateSubrowsIndexesOfRowAtIndex:3];
	expected=[[CPMutableIndexSet alloc] init];
	[expected addIndex:4];
	[expected addIndex:5];
	[expected addIndex:6];
	[self assertTrue:indexSet!=nil message:@"Subtest 3.1 failed"];
	[self assertTrue:[indexSet count]==3 message:@"Subtest 3.2 failed"];
	[self assertTrue:[indexSet isEqualToIndexSet:expected] message:@"Subtest 3.3 failed"];

	indexSet=[model immediateSubrowsIndexesOfRowAtIndex:8];
	expected=[[CPMutableIndexSet alloc] init];
	[expected addIndex:9];
	[expected addIndex:10];
	[expected addIndex:14];
	[expected addIndex:15];
	[self assertTrue:indexSet!=nil message:@"Subtest 4.1 failed"];
	[self assertTrue:[indexSet count]==4 message:@"Subtest 4.2 failed"];
	[self assertTrue:[indexSet isEqualToIndexSet:expected] message:@"Subtest 4.3 failed"];

	indexSet=[model immediateSubrowsIndexesOfRowAtIndex:10];
	expected=[[CPMutableIndexSet alloc] init];
	[expected addIndex:11];
	[expected addIndex:12];
	[expected addIndex:13];
	[self assertTrue:indexSet!=nil message:@"Subtest 5.1 failed"];
	[self assertTrue:[indexSet count]==3 message:@"Subtest 5.2 failed"];
	[self assertTrue:[indexSet isEqualToIndexSet:expected] message:@"Subtest 5.3 failed"];
	
}

-(void)test_insertNewRowAtIndex_ofType_withParentRowIndex
{
	var count,row,indexSet,root;
	var subTestIdx=0;

	var model=[[CPRuleEditorModel alloc] initWithNestingMode:CPRuleEditorNestingModeCompound];
	[model addNewRowOfType:CPRuleEditorRowTypeCompound criteria:nil];
/*
	0.Compound
*/

	row=[model insertNewRowAtIndex:0 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:0 criteria:nil];
/*
	0.Compound
*/

	[self assertTrue:row==nil message:@"Subtest 1 failed"];  
	row=[model insertNewRowAtIndex:1 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:0 criteria:nil];
/*
	0.Compound
		1.Simple <-
*/
	[self assertTrue:row!=nil message:@"Subtest 2.1 failed"];
	[self assertTrue:[row parent]!=nil message:@"Subtest 2.2 failed"];
	[self assertTrue:[row depth]==1 message:@"Subtest 2.3 failed"]; 

/*
	0.Compound
		1.Simple <-
		2.Simple
*/
	row=[model insertNewRowAtIndex:1 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:0 criteria:nil];
	[self assertTrue:row!=nil message:@"Subtest 3 failed"];

/*
	0.Compound
		1.Simple
		2.Simple <-
		3.Simple 
*/
	row=[model insertNewRowAtIndex:2 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:0 criteria:nil];
	[self assertTrue:row!=nil message:@"Subtest 4 failed"];

/*
	0.Compound
		1.Simple
		2.Simple
		3.Simple
		4.Simple <-
*/
	row=[model insertNewRowAtIndex:4 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:0 criteria:nil];
	[self assertTrue:row!=nil message:@"Subtest 5 failed"];

/*
	0.Compound
		1.Simple
		2.Simple
		3.Simple <-
		4.Simple
		5.Simple 
*/
	row=[model insertNewRowAtIndex:3 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:0 criteria:nil];
	[self assertTrue:row!=nil message:@"Subtest 6 failed"];

/*
	0.Compound
		1.Simple
		2.Simple
		3.Compound <-
		4.Simple
		5.Simple 
		6.Simple 
*/
	var compoundRow=[model insertNewRowAtIndex:3 ofType:CPRuleEditorRowTypeCompound withParentRowIndex:0 criteria:nil];
	[self assertTrue:compoundRow!=nil message:@"Subtest 7 failed"];

/*
	0.Compound
		1.Simple
		2.Simple
		3.Compound 
			4.Simple <-
		5.Simple
		6.Simple 
		7.Simple 
*/
	row=[model insertNewRowAtIndex:4 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:3 criteria:nil];
	[self assertTrue:row!=nil message:@"Subtest 8.1 failed"];
	[self assertTrue:[row depth]==2 message:@"Subtest 8.2 failed"];

	row=[model insertNewRowAtIndex:6 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:3 criteria:nil];
	[self assertTrue:row==nil message:@"Subtest 9 failed"]; 

	row=[model insertNewRowAtIndex:3 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:3 criteria:nil];
	[self assertTrue:row==nil message:@"Subtest 10 failed"]; 

	row=[model insertNewRowAtIndex:2 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:3 criteria:nil];
	[self assertTrue:row==nil message:@"Subtest 11 failed"]; 

/*
	0.Compound
		1.Simple
		2.Simple
		3.Compound 
			4.Simple <-
			5.Simple 
		6.Simple
		7.Simple 
		8.Simple 
*/
	row=[model insertNewRowAtIndex:4 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:3 criteria:nil];
	[self assertTrue:row!=nil message:@"Subtest 12 failed"];

/*
	0.Compound
		1.Simple
		2.Simple
		3.Compound 
			4.Simple 
			5.Simple <-
			6.Simple 
		7.Simple
		8.Simple 
		9.Simple 
*/
	row=[model insertNewRowAtIndex:5 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:3 criteria:nil];
	[self assertTrue:row!=nil message:@"Subtest 13 failed"];

/*
	check model
*/
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 14.1 failed"];
	[self assertTrue:[model flatRowsCount]==10 message:@"Subtest 14.2 failed"];
	
	root=[model rowAtIndex:0];
	count=[root subrowsCount];
	
	for(var i=0;i<count;i++)
	{
		row=[root childAtIndex:i];
		if(i==2)
		{
			[self assertTrue:[row rowType]==CPRuleEditorRowTypeCompound];
			
			var subrow;
			var jcount=[row subrowsCount];
			[self assertTrue:jcount==3];
			for(var j=0;j<jcount;j++)
			{
				subrow=[row childAtIndex:j];
				[self assertTrue:[subrow rowType]==CPRuleEditorRowTypeSimple message:@"Subtest 14.4 failed"];
				[self assertTrue:[subrow parent]==row message:@"Subtest 14.5 failed"];
				[self assertTrue:[subrow depth]==2 message:@"Subtest 14.6 failed"];
			}
			continue;
		}
		[self assertTrue:[row rowType]==CPRuleEditorRowTypeSimple message:@"Subtest 14.7 failed"];
		[self assertTrue:[row parent]==root message:@"Subtest 14.8 failed"];
		[self assertTrue:[row depth]==1 message:@"Subtest 14.9 failed"];
	}
}

- (void)test_removeRowAtIndex_includeSubrows_yes
{
	var count,row,indexSet,root;
/*
	0.Compound
		1.Simple
		2.Simple
		3.Compound 
			4.Simple 
			5.Simple
			6.Simple 
		7.Simple
		8.Simple 
		9.Simple 
*/

	var model=[self _setupCompoundModel];
	root=[model rowAtIndex:0];

	[self assertTrue:[model rowsCount]==1 message:@"Subtest 1.1 failed"];
	[self assertTrue:[model flatRowsCount]==10 message:@"Subtest 1.2 failed"];

	[model removeRowAtIndex:0 includeSubrows:YES]; //root not removable

	[self assertTrue:[model rowsCount]==1 message:@"Subtest 2.1 failed"];
	[self assertTrue:[model flatRowsCount]==10 message:@"Subtest 2.2 failed"];
	
/*
	0.Compound
		1.Simple
		2.Simple <-
		3.Compound 
			4.Simple 
			5.Simple
			6.Simple 
		7.Simple
		8.Simple 
		9.Simple 
*/
	[model removeRowAtIndex:2 includeSubrows:YES];
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 3.1 failed"];
	[self assertTrue:[model flatRowsCount]==9 message:@"Subtest 3.2 failed"];

/*
	0.Compound
		1.Simple
		2.Compound 
			3.Simple 
			4.Simple <--
			5.Simple 
		6.Simple
		7.Simple 
		8.Simple 
*/
	[model removeRowAtIndex:4 includeSubrows:YES];
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 4.1 failed"];
	[self assertTrue:[model flatRowsCount]==8 message:@"Subtest 4.2 failed"];

/*
	0.Compound
		1.Simple
		2.Compound <--
			3.Simple 
			4.Simple 
		5.Simple
		6.Simple 
		7.Simple 
*/
	[model removeRowAtIndex:2 includeSubrows:YES];
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 5.1 failed"];
	[self assertTrue:[model flatRowsCount]==5 message:@"Subtest 5.2 failed"];

/*
	0.Compound
		1.Simple
		2.Simple
		3.Simple 
		4.Simple 
*/

	count=[root subrowsCount];
	for(var i=0;i<count;i++)
	{
		row=[root childAtIndex:i];
		[self assertTrue:[row rowType]==CPRuleEditorRowTypeSimple message:@"Subtest 6.2 failed"];
		[self assertTrue:[row parent]==root message:@"Subtest 6.3 failed"];
		[self assertTrue:[row depth]==1 message:@"Subtest 6.4 failed"];
	}
}

- (void)test_setCanRemoveAllRows
{
/*
	0.Simple
	1.Simple
	2.Simple 
	3.Simple
	4.Simple 
*/
	var model=[self _setupListModel];

	[self assertTrue:[model rowsCount]==5 message:@"Subtest 1.1 failed"];
	[self assertTrue:[model flatRowsCount]==5 message:@"Subtest 1.2 failed"];
	
	[model setCanRemoveAllRows:NO];
	for(var i=0;i<5;i++)
		[model removeRowAtIndex:0 includeSubrows:YES];

	[self assertTrue:[model flatRowsCount]==1 message:@"Subtest 1.3 failed"];

	model=[self _setupListModel];

	[model setCanRemoveAllRows:YES];
	for(var i=0;i<5;i++)
		[model removeRowAtIndex:0 includeSubrows:YES];

	[self assertTrue:[model flatRowsCount]==0 message:@"Subtest 2.1 failed"];
	[self assertTrue:[model rowsCount]==0 message:@"Subtest 2.2 failed"];

/*
	0.Compound
		1.Simple
		2.Simple
		3.Compound 
			4.Simple 
			5.Simple
			6.Simple 
		7.Simple
		8.Simple 
		9.Simple 
*/

	model=[self _setupCompoundModel];
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 3.1 failed"];
	[self assertTrue:[model flatRowsCount]==10 message:@"Subtest 3.2 failed"];

	[model setCanRemoveAllRows:NO];
	[model removeRowAtIndex:0 includeSubrows:YES];

	[self assertTrue:[model rowsCount]==1 message:@"Subtest 3.3 failed"];
	[self assertTrue:[model flatRowsCount]==10 message:@"Subtest 3.4 failed"];

	[model setCanRemoveAllRows:YES];
	[model removeRowAtIndex:0 includeSubrows:YES];

	[self assertTrue:[model rowsCount]==0 message:@"Subtest 3.5 failed"];
	[self assertTrue:[model flatRowsCount]==0 message:@"Subtest 3.6 failed"];
}

- (void)test_removeRowAtIndex_includeSubrows_no
{
	var count,row,indexSet,root;
/*
	0.Compound
		1.Simple
		2.Simple
		3.Compound 
			4.Simple 
			5.Simple
			6.Simple 
		7.Simple
		8.Simple 
		9.Simple 
*/

	var model=[self _setupCompoundModel];
	root=[model rowAtIndex:0];

	[model removeRowAtIndex:0 includeSubrows:NO]; //root not removable

	[self assertTrue:[model rowsCount]==1 message:@"Subtest 1.1 failed"];
	[self assertTrue:[model flatRowsCount]==10 message:@"Subtest 1.2 failed"];
	
/*
	0.Compound
		1.Simple
		2.Simple <-
		3.Compound 
			4.Simple 
			5.Simple
			6.Simple 
		7.Simple
		8.Simple 
		9.Simple 
*/
	[model removeRowAtIndex:2 includeSubrows:NO];
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 2.1 failed"];
	[self assertTrue:[model flatRowsCount]==9 message:@"Subtest 2.2 failed"];

/*
	0.Compound
		1.Simple
		2.Compound 
			3.Simple 
			4.Simple <--
			5.Simple 
		6.Simple
		7.Simple 
		8.Simple 
*/
	[model removeRowAtIndex:4 includeSubrows:NO];
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 3.1 failed"];
	[self assertTrue:[model flatRowsCount]==8 message:@"Subtest 3.2 failed"];

/*
	0.Compound
		1.Simple
		2.Compound <--
			3.Simple 
			4.Simple 
		5.Simple
		6.Simple 
		7.Simple 
*/
	[model removeRowAtIndex:2 includeSubrows:NO];
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 4.1 failed"];
	[self assertTrue:[model flatRowsCount]==7 message:@"Subtest 4.2 failed"];

/*
	0.Compound
		1.Simple
		2.Simple 
		3.Simple 
		4.Simple
		5.Simple 
		6.Simple 
*/
	count=[root subrowsCount];
	[self assertTrue:count==6 message:@"Subtest 5.1 failed"];
	
	for(var i=0;i<count;i++)
	{
		row=[root childAtIndex:i];
		[self assertTrue:[row rowType]==CPRuleEditorRowTypeSimple message:@"Subtest 5.2 failed"];
		[self assertTrue:[row parent]==root message:@"Subtest 5.3 failed"];
		[self assertTrue:[row depth]==1 message:@"Subtest 5.4 failed"];
	}
}

-(void)test_removeRowsAtIndexes_includeSubrows_yes_0
{
	var count,row,indexSet,root;
/*
	0.Compound
		1.Simple
		2.Simple
		3.Compound 
			4.Simple 
			5.Simple
			6.Simple 
		7.Simple
		8.Simple 
		9.Simple 
*/

	var model=[self _setupCompoundModel];
	root=[model rowAtIndex:0];
/*
	0.Compound
		1.Simple <--
		2.Simple
		3.Compound 
			4.Simple 
			5.Simple <--
			6.Simple 
		7.Simple
		8.Simple <--
		9.Simple 
*/
	indexSet=[[CPMutableIndexSet alloc] init];
	[indexSet addIndex:1];
	[indexSet addIndex:5];
	[indexSet addIndex:8];
	
	[model removeRowsAtIndexes:indexSet includeSubrows:YES];
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 1.1 failed"];
	[self assertTrue:[model flatRowsCount]==7 message:@"Subtest 1.2 failed"];

	row=[model rowAtIndex:2];
	[self assertTrue:[row rowType]==CPRuleEditorRowTypeCompound message:@"Subtest 1.3 failed"];
	[self assertTrue:[row subrowsCount]==2 message:@"Subtest 1.4 failed"];

/*
	0.Compound
		1.Simple
		2.Compound <--
			3.Simple 
			4.Simple <--
		5.Simple
		6.Simple 
*/
	indexSet=[[CPMutableIndexSet alloc] init];
	[indexSet addIndex:2];
	[indexSet addIndex:4];
	
	[model removeRowsAtIndexes:indexSet includeSubrows:YES];

/*
	0.Compound
		1.Simple
		2.Simple
		3.Simple 
*/

	[self assertTrue:[model rowsCount]==1 message:@"Subtest 2.1 failed"];
	[self assertTrue:[model flatRowsCount]==4 message:@"Subtest 2.2 failed"];
	
	root=[model rowAtIndex:0];
	count=[root subrowsCount];
	for(var i=0;i<count;i++)
	{
		row=[root childAtIndex:i];
		[self assertTrue:[row rowType]==CPRuleEditorRowTypeSimple message:@"Subtest 2.3 failed"];
		[self assertTrue:[row parent]==root message:@"Subtest 2.4 failed"];
		[self assertTrue:[row depth]==1 message:@"Subtest 2.5 failed"];
	}
}

-(void)test_removeRowsAtIndexes_includeSubrows_yes_1
{
	var count,row,indexSet,root;
/*
	0.Compound
		1.Simple
		2.Simple
		3.Compound 
			4.Simple 
			5.Simple
			6.Simple 
		7.Simple
		8.Simple 
		9.Simple 
*/

	var model=[self _setupCompoundModel];
	root=[model rowAtIndex:0];

	[model insertNewRowAtIndex:5 ofType:CPRuleEditorRowTypeCompound withParentRowIndex:3 criteria:nil];
	[model insertNewRowAtIndex:6 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:5 criteria:nil];
	[model insertNewRowAtIndex:6 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:5 criteria:nil];
	[model insertNewRowAtIndex:6 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:5 criteria:nil];

/*
	0.Compound
		1.Simple
		2.Simple <--
		3.Compound 
			4.Simple 
			5.Compound
				6.Simple
				7.Simple <--
				8.Simple
			9.Simple
			10.Simple 
		11.Simple
		12.Simple <-- 
		13.Simple 
*/
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 3.1 failed"];
	[self assertTrue:[model flatRowsCount]==14 message:@"Subtest 3.2 failed"];

	indexSet=[[CPMutableIndexSet alloc] init];
	[indexSet addIndex:2];
	[indexSet addIndex:7];
	[indexSet addIndex:12];
	
	[model removeRowsAtIndexes:indexSet includeSubrows:YES];

/*
	0.Compound
		1.Simple
		2.Compound 
			3.Simple 
			4.Compound
				5.Simple
				6.Simple
			7.Simple
			8.Simple 
		9.Simple
		10.Simple 
*/
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 4.1 failed"];
	[self assertTrue:[model flatRowsCount]==11 message:@"Subtest 4.2 failed"];
	
	row=[root childAtIndex:1];
	[self assertTrue:[row rowType]==CPRuleEditorRowTypeCompound message:@"Subtest 4.3 failed"];
	[self assertTrue:[row parent]==root message:@"Subtest 4.4 failed"];
	[self assertTrue:[row depth]==1 message:@"Subtest 4.5 failed"];
	[self assertTrue:[row subrowsCount]==4 message:@"Subtest 4.6 failed"];

	var subrow=[row childAtIndex:1];
	[self assertTrue:[subrow rowType]==CPRuleEditorRowTypeCompound message:@"Subtest 4.7 failed"];
	[self assertTrue:[subrow parent]==row message:@"Subtest 4.8 failed"];
	[self assertTrue:[subrow depth]==2 message:@"Subtest 4.9 failed"];
	[self assertTrue:[subrow subrowsCount]==2 message:@"Subtest 4.10 failed"];

/*
	0.Compound
		1.Simple <--
		2.Compound 
			3.Simple 
			4.Compound <--
				5.Simple
				6.Simple
			7.Simple
			8.Simple 
		9.Simple
		10.Simple 
*/

	indexSet=[[CPMutableIndexSet alloc] init];
	[indexSet addIndex:1];
	[indexSet addIndex:4];
	
	[model removeRowsAtIndexes:indexSet includeSubrows:YES];

/*
	0.Compound
		1.Compound 
			2.Simple 
			3.Simple
			4.Simple 
		5.Simple
		6.Simple 
*/

	[self assertTrue:[model rowsCount]==1 message:@"Subtest 5.1 failed"];
	[self assertTrue:[model flatRowsCount]==7 message:@"Subtest 5.2 failed"];
	
	row=[root childAtIndex:0];
	[self assertTrue:[row rowType]==CPRuleEditorRowTypeCompound message:@"Subtest 5.3 failed"];
	[self assertTrue:[row parent]==root message:@"Subtest 5.4 failed"];
	[self assertTrue:[row depth]==1 message:@"Subtest 5.5 failed"];
	[self assertTrue:[row subrowsCount]==3  message:@"Subtest 5.6 failed"];

/*
	0.Compound
		1.Compound <--
			2.Simple 
			3.Simple <--
			4.Simple 
		5.Simple
		6.Simple <--
*/
	indexSet=[[CPMutableIndexSet alloc] init];
	[indexSet addIndex:1];
	[indexSet addIndex:3];
	[indexSet addIndex:6];
	
	[model removeRowsAtIndexes:indexSet includeSubrows:YES];

/*
	0.Compound
		1.Simple
*/
	
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 6.1 failed"];
	[self assertTrue:[model flatRowsCount]==2 message:@"Subtest 6.2 failed"];
	
	row=[root childAtIndex:0];
	[self assertTrue:[row rowType]==CPRuleEditorRowTypeSimple message:@"Subtest 6.3 failed"];
	[self assertTrue:[row parent]==root message:@"Subtest 6.4 failed"];
	[self assertTrue:[row depth]==1 message:@"Subtest 6.5 failed"];
	[self assertTrue:[row subrowsCount]==0 message:@"Subtest 6.6 failed"];
	
}

-(void)test_removeRowsAtIndexes_includeSubrows_no_0
{
	var count,row,indexSet,root;
/*
	0.Compound
		1.Simple
		2.Simple
		3.Compound 
			4.Simple 
			5.Simple
			6.Simple 
		7.Simple
		8.Simple 
		9.Simple 
*/
	var model=[self _setupCompoundModel];
	root=[model rowAtIndex:0];
/*
	0.Compound
		1.Simple <--
		2.Simple
		3.Compound 
			4.Simple 
			5.Simple <--
			6.Simple 
		7.Simple
		8.Simple <--
		9.Simple 
*/
	indexSet=[[CPMutableIndexSet alloc] init];
	[indexSet addIndex:1];
	[indexSet addIndex:5];
	[indexSet addIndex:8];
	
	[model removeRowsAtIndexes:indexSet includeSubrows:NO];
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 1.1 failed"];
	[self assertTrue:[model flatRowsCount]==7 message:@"Subtest 1.2 failed"];

	row=[root childAtIndex:1];
	[self assertTrue:[row rowType]==CPRuleEditorRowTypeCompound message:@"Subtest 1.3 failed"];
	[self assertTrue:[row subrowsCount]==2 message:@"Subtest 1.4 failed"];

/*
	0.Compound
		1.Simple
		2.Compound <--
			3.Simple 
			4.Simple <--
		5.Simple
		6.Simple 
*/
	indexSet=[[CPMutableIndexSet alloc] init];
	[indexSet addIndex:2];
	[indexSet addIndex:4];
	
	[model removeRowsAtIndexes:indexSet includeSubrows:NO];

/*
	0.Compound
		1.Simple
		2.Simple
		3.Simple 
		4.Simple 
*/

	[self assertTrue:[model rowsCount]==1 message:@"Subtest 2.1 failed"];
	[self assertTrue:[model flatRowsCount]==5 message:@"Subtest 2.2 failed"];
	
	count=[root subrowsCount];
	for(var i=0;i<count;i++)
	{
		row=[root childAtIndex:i];
		[self assertTrue:[row rowType]==CPRuleEditorRowTypeSimple  message:@"Subtest 2.3 failed"];
		[self assertTrue:[row parent]==root message:@"Subtest 2.4 failed"];
		[self assertTrue:[row depth]==1 message:@"Subtest 2.5 failed"];
	}
}

-(void)test_removeRowsAtIndexes_includeSubrows_no_1
{
	var count,row,indexSet,root;

	var model=[self _setupCompoundModel];
	root=[model rowAtIndex:0];

/*
	0.Compound
		1.Simple
		2.Simple
		3.Compound 
			4.Simple 
			5.Simple
			6.Simple 
		7.Simple
		8.Simple 
		9.Simple 
*/
	[model insertNewRowAtIndex:5 ofType:CPRuleEditorRowTypeCompound withParentRowIndex:3 criteria:nil];
	[model insertNewRowAtIndex:6 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:5 criteria:nil];
	[model insertNewRowAtIndex:6 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:5 criteria:nil];
	[model insertNewRowAtIndex:6 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:5 criteria:nil];

	[self assertTrue:[model rowsCount]==1 message:@"Subtest 3.1 failed"];
	[self assertTrue:[model flatRowsCount]==14 message:@"Subtest 3.2 failed"];

/*
	0.Compound
		1.Simple <--
		2.Simple 
		3.Compound <--
			4.Simple 
			5.Compound <--
				6.Simple
				7.Simple <--
				8.Simple
			9.Simple
			10.Simple 
		11.Simple
		12.Simple <-- 
		13.Simple 
*/
	indexSet=[[CPMutableIndexSet alloc] init];
	[indexSet addIndex:1];
	[indexSet addIndex:3];
	[indexSet addIndex:5];
	[indexSet addIndex:7];
	[indexSet addIndex:12];
	
	[model removeRowsAtIndexes:indexSet includeSubrows:NO];

/*
	0.Compound
		1.Simple 
		2.Simple 
		3.Simple
		4.Simple
		5.Simple
		6.Simple 
		7.Simple
		8.Simple 
*/

	[self assertTrue:[model rowsCount]==1 message:@"Subtest 4.1 failed"];
	[self assertTrue:[model flatRowsCount]==9 message:@"Subtest 4.2 failed"];
	
	count=[root subrowsCount];
	for(var i=0;i<count;i++)
	{
		row=[root childAtIndex:i];
		[self assertTrue:[row rowType]==CPRuleEditorRowTypeSimple message:@"Subtest 4.3 failed"];
		[self assertTrue:[row parent]==root message:@"Subtest 4.4 failed"];
		[self assertTrue:[row depth]==1 message:@"Subtest 4.5 failed"];
	}
}
	
-(void)test_removeRowsAtIndexes_includeSubrows_no_2
{
	var count,row,indexSet,root;
/*
	0.Compound
		1.Simple
		2.Simple
		3.Compound 
			4.Simple 
			5.Simple
			6.Simple 
		7.Simple
		8.Simple 
		9.Simple 
*/
	var model=[self _setupCompoundModel];
	root=[model rowAtIndex:0];

/*
	0.Compound
		1.Simple
		2.Simple
		3.Compound 
			4.Simple 
			5.Simple
			6.Simple 
		7.Simple
		8.Simple 
		9.Simple 
*/
	[model insertNewRowAtIndex:5 ofType:CPRuleEditorRowTypeCompound withParentRowIndex:3 criteria:nil];
	[model insertNewRowAtIndex:6 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:5 criteria:nil];
	[model insertNewRowAtIndex:6 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:5 criteria:nil];
	[model insertNewRowAtIndex:6 ofType:CPRuleEditorRowTypeSimple withParentRowIndex:5 criteria:nil];

	[self assertTrue:[model rowsCount]==1  message:@"Subtest 5.1 failed"];
	[self assertTrue:[model flatRowsCount]==14 message:@"Subtest 5.2 failed"];

/*
	0.Compound
		1.Simple <--
		2.Simple <--
		3.Compound 
			4.Simple 
			5.Compound <--
				6.Simple
				7.Simple 
				8.Simple
			9.Simple
			10.Simple 
		11.Simple <--
		12.Simple  
		13.Simple <--
*/
	indexSet=[[CPMutableIndexSet alloc] init];
	[indexSet addIndex:1];
	[indexSet addIndex:2];
	[indexSet addIndex:5];
	[indexSet addIndex:11];
	[indexSet addIndex:13];
	
	[model removeRowsAtIndexes:indexSet includeSubrows:NO];

/*
	0.Compound
		1.Compound 
			2.Simple 
			3.Simple
			4.Simple 
			5.Simple
			6.Simple
			7.Simple 
		8.Simple 
*/
	[self assertTrue:[model rowsCount]==1 message:@"Subtest 6.1 failed"];
	[self assertTrue:[model flatRowsCount]==9 message:@"Subtest 6.2 failed"];
	
	var subrow=[root childAtIndex:0];
	count=[subrow subrowsCount];
	for(var i=0;i<count;i++)
	{
		row=[subrow childAtIndex:i];
		[self assertTrue:[row rowType]==CPRuleEditorRowTypeSimple message:@"Subtest 6.3 failed"];
		[self assertTrue:[row parent]==subrow message:@"Subtest 6.4 failed"];
		[self assertTrue:[row depth]==2 message:@"Subtest 6.5 failed"];
	}

}

@end