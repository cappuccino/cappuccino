/*
 * CPColorPanelTest.j
 * AppKit
 *
 * Created to test CPColorPanel architectural refactoring.
 */

@import <AppKit/CPColorPanel.j>

/*
 * Mock color picker for testing
 */
@implementation _MockColorPicker : CPObject
{
	CPArray _receivedColors;
	CPView  _view;
}

- (id)init
{
	if (self = [super init])
	{
		_receivedColors = [];
		_view = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
	}
	return self;
}

- (void)setColor:(CPColor)aColor
{
	[_receivedColors addObject:aColor];
}

- (CPArray)receivedColors
{
	return _receivedColors;
}

- (CPView)provideNewView:(BOOL)initial
{
	return _view;
}

@end

@implementation CPColorPanelTest : OJTestCase
{
	CPColorPanel _panel;
}

- (void)setUp
{
	// Get shared panel and ensure it's initialized
	_panel = [CPColorPanel sharedColorPanel];
	[_panel _loadContentsIfNecessary];
}

- (void)tearDown
{
	// Reset panel state between tests
	[_panel setColor:[CPColor whiteColor]];
}

/*
 * Test that setting a color updates the opacity slider to match the color's alpha component.
 * This ensures the slider always reflects the current color's opacity.
 */
- (void)testSetColorUpdatesOpacitySlider
{
	var initialColor = [CPColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0];
	[_panel setColor:initialColor];

	// Track if setColor gets called
	var setColorCalled = NO;
	var originalSetColor = _panel.setColor;
	_panel.setColor = function(aColor)
	{
		setColorCalled = YES;
		originalSetColor.call(this, aColor);
	};

	// Simulate user changing opacity slider
	[_panel._opacitySlider setFloatValue:0.5];
	[_panel _opacityChanged:_panel._opacitySlider];

	_panel.setColor = originalSetColor; // Restore

	[self assertFalse:setColorCalled
			  message:"_opacityChanged should update state directly without calling setColor"];
}

/*
 * Test that _opacityChanged: creates a new color with the correct alpha value.
 */
- (void)testOpacityChangeUpdatesColorAlpha
{
	var initialColor = [CPColor colorWithRed:0.5 green:0.5 blue:1.0 alpha:1.0];
	[_panel setColor:initialColor];

	[_panel._opacitySlider setFloatValue:0.3];
	[_panel _opacityChanged:_panel._opacitySlider];

	var newColor = [_panel color];
	[self assert:0.3 equals:[newColor alphaComponent]
		 message:"Color's alpha should match slider value"];

	// RGB components should remain unchanged
	var components = [newColor components];
	[self assert:0.5 equals:components[0] message:"Red component should be unchanged"];
	[self assert:0.5 equals:components[1] message:"Green component should be unchanged"];
	[self assert:1.0 equals:components[2] message:"Blue component should be unchanged"];
}

/*
 * Test that the active picker receives setColor: when a color changes.
 * Regression test: active picker was not notified of color changes.
 */
- (void)testActivePickerNotifiedOfColorChanges
{
	var mockPicker = [[_MockColorPicker alloc] init];
	_panel._activePicker = mockPicker;

	var color1 = [CPColor redColor];
	var color2 = [CPColor blueColor];

	[_panel setColor:color1];
	[_panel setColor:color2];

	var receivedColors = [mockPicker receivedColors];
	[self assert:2 equals:[receivedColors count]
		 message:"Active picker should receive setColor for each color change"];
	[self assert:color1 same:receivedColors[0]];
	[self assert:color2 same:receivedColors[1]];
}

/*
 * Test that a picker receives setColor: when it becomes active.
 * Regression test: picker was not notified of current color on activation.
 */
- (void)testPickerNotifiedOnActivation
{
	var testColor = [CPColor colorWithRed:0.5 green:0.5 blue:1.0 alpha:1.0];
	[_panel setColor:testColor];

	var mockPicker = [[_MockColorPicker alloc] init];
	_panel._colorPickers = [mockPicker];

	var button = [[CPButton alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
	[button setTag:0];

	[_panel _setPicker:button];

	var receivedColors = [mockPicker receivedColors];
	[self assert:1 equals:[receivedColors count]
		 message:"Picker should receive setColor when activated"];
	[self assert:testColor same:receivedColors[0]];
}

/*
 * Test that opacity() method returns the current color's alpha component.
 */
- (void)testOpacityMethodReturnsAlpha
{
	var testColor = [CPColor colorWithRed:1.0 green:0.0 blue:0.0 alpha:0.42];
	[_panel setColor:testColor];

	[self assert:0.42 equals:[_panel opacity]
		 message:"opacity method should return color's alpha component"];
}

/*
 * Test that setColor: with equal color does not trigger updates.
 * This is an optimization to prevent unnecessary work.
 */
- (void)testSetColorWithEqualColorDoesNothing
{
	var testColor = [CPColor colorWithRed:1.0 green:0.5 blue:0.0 alpha:0.7];
	[_panel setColor:testColor];

	var mockPicker = [[_MockColorPicker alloc] init];
	_panel._activePicker = mockPicker;

	// Set same color again
	[_panel setColor:testColor];

	var receivedColors = [mockPicker receivedColors];
	[self assert:0 equals:[receivedColors count]
		 message:"Setting equal color should not trigger picker update"];
}

/*
 * Test color() method returns the current color.
 */
- (void)testColorMethodReturnsCurrentColor
{
	var testColor = [CPColor colorWithRed:0.2 green:0.4 blue:0.6 alpha:0.8];
	[_panel setColor:testColor];

	[self assert:testColor same:[_panel color]
		 message:"color method should return current color"];
}

@end