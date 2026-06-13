// AppController.j
// Manual test application for CPLanguageModelSession & CPSystemLanguageModel
// With custom SpeechBubbleBox drawing and editable System Prompt controls.
//

@import <AppKit/AppKit.j>
@import <Foundation/CPObject.j>
@import <Foundation/CPLanguageModel.j>

// --- SUBCLASS: SPEECH BUBBLE VIEW ---
@implementation SpeechBubbleBox : CPView
{
    BOOL    _isUser;
    CPColor _bubbleColor;
}

- (id)initWithFrame:(CGRect)aFrame isUser:(BOOL)isUser fillColor:(CPColor)aColor
{
    self = [super initWithFrame:aFrame];
    if (self) {
        _isUser = isUser;
        _bubbleColor = aColor;
        [self setAutoresizingMask:CPViewWidthSizable];
    }
    return self;
}

- (void)drawRect:(CGRect)aRect
{
    var context = [[CPGraphicsContext currentContext] graphicsPort];
    var bounds = [self bounds];
    var w = CGRectGetWidth(bounds);
    var h = CGRectGetHeight(bounds) - 10.0; // 10px spacing for the bottom triangle pointer
    var r = 6.0;   // Corner radius
    var th = 10.0; // Tail height

    // --- 1. FILL PATH ---
    CGContextBeginPath(context);
    
    // Top-left
    CGContextMoveToPoint(context, r, 0);
    
    // Top edge
    CGContextAddLineToPoint(context, w - r, 0);
    CGContextAddArcToPoint(context, w, 0, w, r, r);
    
    // Right edge
    CGContextAddLineToPoint(context, w, h - r);
    CGContextAddArcToPoint(context, w, h, w - r, h, r);
    
    // Bottom edge with triangular tail (RHS vs LHS)
    if (_isUser) {
        CGContextAddLineToPoint(context, w - 21, h);
        CGContextAddLineToPoint(context, w - 21, h + th);
        CGContextAddLineToPoint(context, w - 35, h);
        CGContextAddLineToPoint(context, r, h);
    } else {
        CGContextAddLineToPoint(context, 35, h);
        CGContextAddLineToPoint(context, 21, h + th);
        CGContextAddLineToPoint(context, 21, h);
        CGContextAddLineToPoint(context, r, h);
    }
    
    // Left edge
    CGContextAddArcToPoint(context, 0, h, 0, h - r, r);
    CGContextAddLineToPoint(context, 0, r);
    CGContextAddArcToPoint(context, 0, 0, r, 0, r);
    
    CGContextClosePath(context);
    
    // Fill path
    CGContextSetFillColor(context, _bubbleColor);
    CGContextFillPath(context);
    
    // --- 2. OUTLINE PATH ---
    CGContextBeginPath(context);
    CGContextMoveToPoint(context, r, 0);
    CGContextAddLineToPoint(context, w - r, 0);
    CGContextAddArcToPoint(context, w, 0, w, r, r);
    CGContextAddLineToPoint(context, w, h - r);
    CGContextAddArcToPoint(context, w, h, w - r, h, r);
    
    if (_isUser) {
        CGContextAddLineToPoint(context, w - 21, h);
        CGContextAddLineToPoint(context, w - 21, h + th);
        CGContextAddLineToPoint(context, w - 35, h);
        CGContextAddLineToPoint(context, r, h);
    } else {
        CGContextAddLineToPoint(context, 35, h);
        CGContextAddLineToPoint(context, 21, h + th);
        CGContextAddLineToPoint(context, 21, h);
        CGContextAddLineToPoint(context, r, h);
    }
    
    CGContextAddArcToPoint(context, 0, h, 0, h - r, r);
    CGContextAddLineToPoint(context, 0, r);
    CGContextAddArcToPoint(context, 0, 0, r, 0, r);
    CGContextClosePath(context);
    
    // Stroke outline
    CGContextSetStrokeColor(context, [CPColor colorWithWhite:0.8 alpha:1.0]);
    CGContextSetLineWidth(context, 1.0);
    CGContextStrokePath(context);
}

@end


// --- MAIN CONTROLLER ---
@implementation AppController : CPObject
{
    CPWindow            _mainWindow;
    CPScrollView        _chatScrollView;
    CPView              _chatDocumentView;
    CPTextField         _chatInputField;
    CPButton            _chatSendButton;
    CPButton            _settingsButton;
    CPCheckBox          _forceFallbackCheckbox;
    CPTextField         _statusLabel;
    CPTextView          _systemPromptTextView;
    
    CPWindow            _settingsWindow;
    CPPopUpButton       _servicePopUp;
    CPTextField         _endpointField;
    CPTextField         _modelField;
    CPTextField         _apiKeyField;
    
    CPLanguageModelSession _session;
    float               _currentChatY;
    id                  _currentStreamingTextView;
}

- (void)applicationDidFinishLaunching:(CPNotification)aNotification
{
    // Initialize default test settings in local user defaults
    var defaults = [CPUserDefaults standardUserDefaults];
    var defaultSettings = [CPDictionary dictionaryWithObjects:[
        @"ollama",
        @"http://localhost:11434/api/generate",
        @"gemma4:e4b",
        @""
    ] forKeys:[
        @"LLMTestServiceType",
        @"LLMTestEndpoint",
        @"LLMTestModel",
        @"LLMTestAPIKey"
    ]];
    [defaults registerDefaults:defaultSettings];

    // Read values to apply fallback routing to CPLanguageModelSession
    var activeService = [defaults objectForKey:@"LLMTestServiceType"],
        endpoint = [defaults objectForKey:@"LLMTestEndpoint"],
        model = [defaults objectForKey:@"LLMTestModel"],
        apiKey = [defaults objectForKey:@"LLMTestAPIKey"];

    [CPLanguageModelSession setFallbackServiceType:activeService
                                         endpoint:endpoint
                                            model:model
                                           apiKey:apiKey];

    // Main manual test window setup
    _mainWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0, 0, 800, 650)
                                              styleMask:CPTitledWindowMask | CPClosableWindowMask | CPMiniaturizableWindowMask | CPResizableWindowMask];
    [_mainWindow setTitle:@"CPLanguageModel Manual Test Tool"];
    [_mainWindow center];

    var contentView = [_mainWindow contentView];
    var bounds = [contentView bounds];

    // --- TOP CONTROL PANEL (Height 135px) ---
    var topBar = [[CPView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(bounds), 135)];
    [topBar setAutoresizingMask:CPViewWidthSizable | CPViewMaxYMargin];
    [topBar setBackgroundColor:[CPColor colorWithWhite:0.92 alpha:1.0]];
    [contentView addSubview:topBar];

    _statusLabel = [[CPTextField alloc] initWithFrame:CGRectMake(15, 12, 300, 20)];
    [_statusLabel setStringValue:@"Checking capability..."];
    [_statusLabel setFont:[CPFont systemFontOfSize:12.0]];
    [topBar addSubview:_statusLabel];

    _forceFallbackCheckbox = [[CPCheckBox alloc] initWithFrame:CGRectMake(330, 12, 140, 20)];
    [_forceFallbackCheckbox setTitle:@"Force Fallback"];
    [_forceFallbackCheckbox setTarget:self];
    [_forceFallbackCheckbox setAction:@selector(toggleForceFallback:)];
    [topBar addSubview:_forceFallbackCheckbox];

    _settingsButton = [[CPButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(bounds) - 210, 9, 90, 26)];
    [_settingsButton setTitle:@"Settings..."];
    [_settingsButton setAutoresizingMask:CPViewMinXMargin];
    [_settingsButton setTarget:self];
    [_settingsButton setAction:@selector(openSettingsSheet:)];
    [topBar addSubview:_settingsButton];

    var clearButton = [[CPButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(bounds) - 110, 9, 95, 26)];
    [clearButton setTitle:@"Clear Chat"];
    [clearButton setAutoresizingMask:CPViewMinXMargin];
    [clearButton setTarget:self];
    [clearButton setAction:@selector(clearChatAction:)];
    [topBar addSubview:clearButton];

    // System Prompt Header & Field [1]
    var promptLabel = [[CPTextField alloc] initWithFrame:CGRectMake(15, 42, 300, 18)];
    [promptLabel setStringValue:@"System Instructions (Persona):"];
    [promptLabel setFont:[CPFont boldSystemFontOfSize:11.0]];
    [promptLabel setTextColor:[CPColor darkGrayColor]];
    [topBar addSubview:promptLabel];

    var promptScroll = [[CPScrollView alloc] initWithFrame:CGRectMake(15, 62, CGRectGetWidth(bounds) - 30, 60)];
    [promptScroll setAutoresizingMask:CPViewWidthSizable];
    [promptScroll setAutohidesScrollers:YES];
    
    _systemPromptTextView = [[CPTextView alloc] initWithFrame:[promptScroll bounds]];
    [_systemPromptTextView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_systemPromptTextView setEditable:YES];
    [_systemPromptTextView setFont:[CPFont systemFontOfSize:11.0]];
    // Default instruction preset [1]
    [_systemPromptTextView setString:@"You are a helpful, concise testing assistant. You structure your explanations clearly using lists where appropriate."];
    
    [promptScroll setDocumentView:_systemPromptTextView];
    [topBar addSubview:promptScroll];

    // --- SCROLLING CHAT CONTAINER ---
    var scrollHeight = CGRectGetHeight(bounds) - 195;
    _chatScrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0, 135, CGRectGetWidth(bounds), scrollHeight)];
    [_chatScrollView setAutoresizingMask:CPViewWidthSizable | CPViewHeightSizable];
    [_chatScrollView setAutohidesScrollers:YES];
    [_chatScrollView setHasHorizontalScroller:NO];
    [_chatScrollView setBackgroundColor:[CPColor whiteColor]];

    _chatDocumentView = [[CPView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth([_chatScrollView bounds]), scrollHeight)];
    [_chatDocumentView setAutoresizingMask:CPViewWidthSizable];
    [_chatScrollView setDocumentView:_chatDocumentView];
    [contentView addSubview:_chatScrollView];

    // --- INPUT CONTAINER ---
    var bottomBarY = CGRectGetHeight(bounds) - 60;
    var bottomBar = [[CPView alloc] initWithFrame:CGRectMake(0, bottomBarY, CGRectGetWidth(bounds), 60)];
    [bottomBar setAutoresizingMask:CPViewWidthSizable | CPViewMinYMargin];
    [bottomBar setBackgroundColor:[CPColor colorWithWhite:0.95 alpha:1.0]];
    [contentView addSubview:bottomBar];

    _chatInputField = [[CPTextField alloc] initWithFrame:CGRectMake(15, 13, CGRectGetWidth(bounds) - 130, 34)];
    [_chatInputField setAutoresizingMask:CPViewWidthSizable];
    [_chatInputField setEditable:YES];
    [_chatInputField setBezeled:YES];
    [_chatInputField setPlaceholderString:@"Type a prompt and press Enter..."];
    [_chatInputField setTarget:self];
    [_chatInputField setAction:@selector(submitPromptAction:)];
    [bottomBar addSubview:_chatInputField];

    _chatSendButton = [[CPButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(bounds) - 105, 13, 90, 34)];
    [_chatSendButton setTitle:@"Send"];
    [_chatSendButton setAutoresizingMask:CPViewMinXMargin];
    [_chatSendButton setTarget:self];
    [_chatSendButton setAction:@selector(submitPromptAction:)];
    [bottomBar addSubview:_chatSendButton];

    [_mainWindow orderFront:self];

    [self checkModelSupport];
    [self resetSession];
}

- (void)checkModelSupport
{
    var systemModel = [CPSystemLanguageModel defaultModel];
    [_statusLabel setStringValue:@"Checking capability..."];
    
    var selfRef = self;
    [systemModel supportsLocaleWithCompletionHandler:function(supported) {
        if (supported) {
            [selfRef._statusLabel setStringValue:@"On-Device LLM: Supported"];
        } else {
            [selfRef._statusLabel setStringValue:@"On-Device LLM: Not available. Using fallback."];
        }
    }];
}

- (void)toggleForceFallback:(id)sender
{
    var force = [sender state] === CPOnState;
    [CPLanguageModelSession setEndorsesFallback:force];
    [_statusLabel setStringValue:(force ? @"Fallback forced programmatically." : @"Prioritizing on-device model.")];
}

- (void)clearChatAction:(id)sender
{
    [self resetSession];
}

- (void)resetSession
{
    _currentChatY = 15;
    _currentStreamingTextView = nil;
    
    if (_session) {
        [_session destroy];
    }
    
    // Read the custom instructions from the text field upon starting a fresh session [1]
    var instructions = [_systemPromptTextView string] || @"";
    _session = [[CPLanguageModelSession alloc] initWithInstructions:instructions];
    
    [[_chatDocumentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    [_chatDocumentView setFrameSize:CGSizeMake(CGRectGetWidth([_chatScrollView bounds]), CGRectGetHeight([_chatScrollView bounds]))];
    
    [self appendMessage:@"Session initialized.\n\nEnter a query below to begin." isUser:NO];
}

// Append a formatted message using SpeechBubbleBox and sizeToFit calculation
- (void)appendMessage:(CPString)text isUser:(BOOL)isUser
{
    var docWidth = CGRectGetWidth([_chatScrollView bounds]) - 50;
    
    var textView = [[CPTextView alloc] initWithFrame:CGRectMake(15, 10, docWidth - 30, 20)];
    [textView insertText:text];
    [textView setTextColor:[CPColor blackColor]];
    [textView setFont:[CPFont systemFontOfSize:11.0]];
    [textView setEditable:YES];
    [textView setRichText:NO];
    [textView setBackgroundColor:[CPColor clearColor]];
    [textView setAutoresizingMask:CPViewWidthSizable];
    
    [textView sizeToFit];
    var textHeight = CGRectGetHeight([textView frame]);
    
    var cardHeight = textHeight + 20; // 10px spacing top/bottom
    var bubbleHeight = cardHeight + 10; // Extra 10px spacing for the bottom triangle pointer [1]
    
    var fillColor = isUser ? [CPColor colorWithRed:0.90 green:0.93 blue:1.0 alpha:1.0] : [CPColor colorWithWhite:0.96 alpha:1.0];
    var cardBox = [[SpeechBubbleBox alloc] initWithFrame:CGRectMake(15, _currentChatY, docWidth, bubbleHeight) 
                                                  isUser:isUser 
                                               fillColor:fillColor];
    
    [cardBox addSubview:textView];
    [_chatDocumentView addSubview:cardBox];
    
    if (!isUser) {
        _currentStreamingTextView = textView;
    }
    
    _currentChatY += bubbleHeight + 15; // 15px gap between consecutive messages
    [_chatDocumentView setFrameSize:CGSizeMake(CGRectGetWidth([_chatScrollView bounds]), _currentChatY + 20)];
    
    var boundsHeight = CGRectGetHeight([_chatScrollView bounds]);
    if (_currentChatY > boundsHeight) {
        [[_chatScrollView contentView] scrollToPoint:CGPointMake(0, _currentChatY - boundsHeight + 40)];
    }
}

// Updates the placeholder message with the final generated response
- (void)updateMessage:(CPString)newText
{
    if (!_currentStreamingTextView)
        return;

    [_currentStreamingTextView setString:newText];

    var textHeight = CGRectGetHeight([_currentStreamingTextView frame]);
    var cardHeight = textHeight + 20;
    var bubbleHeight = cardHeight + 10;

    var container = [_currentStreamingTextView superview]; // Resolves the SpeechBubbleBox
    var oldBubbleHeight = CGRectGetHeight([container frame]);

    [container setFrameSize:CGSizeMake(CGRectGetWidth([container frame]), bubbleHeight)];
    [_currentStreamingTextView setFrameSize:CGSizeMake(CGRectGetWidth([_currentStreamingTextView frame]), textHeight)];
    [container setNeedsDisplay:YES];
    [_currentStreamingTextView setNeedsDisplay:YES];

    var diffHeight = bubbleHeight - oldBubbleHeight;
    _currentChatY += diffHeight;

    [_chatDocumentView setFrameSize:CGSizeMake(CGRectGetWidth([_chatScrollView bounds]), _currentChatY + 20)];

    var boundsHeight = CGRectGetHeight([_chatScrollView bounds]);
    if (_currentChatY > boundsHeight) {
        [[_chatScrollView contentView] scrollToPoint:CGPointMake(0, _currentChatY - boundsHeight + 40)];
    }
}

- (void)submitPromptAction:(id)sender
{
    var prompt = [_chatInputField stringValue];
    if (!prompt || [prompt stringByTrimmingWhitespace] === @"") {
        return;
    }

    [_chatInputField setStringValue:@""];
    [_chatInputField setEnabled:NO];
    [_chatSendButton setEnabled:NO];

    [self appendMessage:prompt isUser:YES];
    [self appendMessage:@"Generating response..." isUser:NO];

    var selfRef = self;

    [_session respondToPrompt:prompt
                      options:nil
            completionHandler:function(finalText, error) {
        [selfRef._chatInputField setEnabled:YES];
        [selfRef._chatInputField becomeFirstResponder];
        [selfRef._chatSendButton setEnabled:YES];

        if (error) {
            [selfRef updateMessage:@"Error: " + [error localizedDescription]];
        } else {
            debugger
            [selfRef updateMessage:finalText];
        }
    }];
}

// --- CONFIGURATION POPUP SHEETS ---

- (void)openSettingsSheet:(id)sender
{
    if (!_settingsWindow)
    {
        _settingsWindow = [[CPWindow alloc] initWithContentRect:CGRectMake(0, 0, 420, 260)
                                                      styleMask:CPTitledWindowMask | CPClosableWindowMask];
        [_settingsWindow setTitle:@"Fallback Settings"];
        
        var sheetContentView = [_settingsWindow contentView];
        var sheetBounds = [sheetContentView bounds];

        var serviceLabel = [[CPTextField alloc] initWithFrame:CGRectMake(15, 25, 110, 20)];
        [serviceLabel setStringValue:@"Service Type:"];
        [serviceLabel setFont:[CPFont systemFontOfSize:12.0]];
        [serviceLabel setAlignment:CPRightTextAlignment];
        [sheetContentView addSubview:serviceLabel];

        _servicePopUp = [[CPPopUpButton alloc] initWithFrame:CGRectMake(135, 22, 180, 26) pullsDown:NO];
        [_servicePopUp addItemWithTitle:@"Ollama (Local)"];
        [[_servicePopUp lastItem] setRepresentedObject:@"ollama"];
        [_servicePopUp addItemWithTitle:@"Groq API"];
        [[_servicePopUp lastItem] setRepresentedObject:@"groq"];
        [_servicePopUp addItemWithTitle:@"Google Gemini"];
        [[_servicePopUp lastItem] setRepresentedObject:@"gemini"];
        [_servicePopUp addItemWithTitle:@"OpenRouter"];
        [[_servicePopUp lastItem] setRepresentedObject:@"openrouter"];
        [_servicePopUp setTarget:self];
        [_servicePopUp setAction:@selector(serviceTypeDidChange:)];
        [sheetContentView addSubview:_servicePopUp];

        var endpointLabel = [[CPTextField alloc] initWithFrame:CGRectMake(15, 65, 110, 20)];
        [endpointLabel setStringValue:@"Endpoint URL:"];
        [endpointLabel setFont:[CPFont systemFontOfSize:12.0]];
        [endpointLabel setAlignment:CPRightTextAlignment];
        [sheetContentView addSubview:endpointLabel];

        _endpointField = [[CPTextField alloc] initWithFrame:CGRectMake(135, 62, CGRectGetWidth(sheetBounds) - 155, 24)];
        [_endpointField setEditable:YES];
        [_endpointField setBezeled:YES];
        [_endpointField setFont:[CPFont systemFontOfSize:12.0]];
        [sheetContentView addSubview:_endpointField];

        var modelLabel = [[CPTextField alloc] initWithFrame:CGRectMake(15, 105, 110, 20)];
        [modelLabel setStringValue:@"Model Name:"];
        [modelLabel setFont:[CPFont systemFontOfSize:12.0]];
        [modelLabel setAlignment:CPRightTextAlignment];
        [sheetContentView addSubview:modelLabel];

        _modelField = [[CPTextField alloc] initWithFrame:CGRectMake(135, 102, CGRectGetWidth(sheetBounds) - 155, 24)];
        [_modelField setEditable:YES];
        [_modelField setBezeled:YES];
        [_modelField setFont:[CPFont systemFontOfSize:12.0]];
        [sheetContentView addSubview:_modelField];

        var apiKeyLabel = [[CPTextField alloc] initWithFrame:CGRectMake(15, 145, 110, 20)];
        [apiKeyLabel setStringValue:@"API Key:"];
        [apiKeyLabel setFont:[CPFont systemFontOfSize:12.0]];
        [apiKeyLabel setAlignment:CPRightTextAlignment];
        [sheetContentView addSubview:apiKeyLabel];

        _apiKeyField = [[CPTextField alloc] initWithFrame:CGRectMake(135, 142, CGRectGetWidth(sheetBounds) - 155, 24)];
        [_apiKeyField setEditable:YES];
        [_apiKeyField setBezeled:YES];
        [_apiKeyField setSecure:YES];
        [_apiKeyField setFont:[CPFont systemFontOfSize:12.0]];
        [sheetContentView addSubview:_apiKeyField];

        var btnY = CGRectGetHeight(sheetBounds) - 45;

        var cancelBtn = [[CPButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(sheetBounds) - 205, btnY, 90, 26)];
        [cancelBtn setTitle:@"Cancel"];
        [cancelBtn setTarget:self];
        [cancelBtn setAction:@selector(closeSettingsSheet:)];
        [sheetContentView addSubview:cancelBtn];

        var saveBtn = [[CPButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(sheetBounds) - 105, btnY, 90, 26)];
        [saveBtn setTitle:@"Save"];
        [saveBtn setTarget:self];
        [saveBtn setAction:@selector(saveSettings:)];
        [sheetContentView addSubview:saveBtn];
    }

    var defaults = [CPUserDefaults standardUserDefaults];
    var activeService = [defaults objectForKey:@"LLMTestServiceType"] || @"ollama";

    if (activeService === @"ollama") [_servicePopUp selectItemAtIndex:0];
    else if (activeService === @"groq") [_servicePopUp selectItemAtIndex:1];
    else if (activeService === @"gemini") [_servicePopUp selectItemAtIndex:2];
    else if (activeService === @"openrouter") [_servicePopUp selectItemAtIndex:3];

    [_endpointField setStringValue:[defaults objectForKey:@"LLMTestEndpoint"] || @"http://localhost:11434/api/generate"];
    [_modelField setStringValue:[defaults objectForKey:@"LLMTestModel"] || @"gemma4:e4b"];
    [_apiKeyField setStringValue:[defaults objectForKey:@"LLMTestAPIKey"] || @""];

    [self updateFieldsForService:activeService];

    [CPApp beginSheet:_settingsWindow
        modalForWindow:_mainWindow
         modalDelegate:self
        didEndSelector:nil
           contextInfo:nil];
}

- (void)updateFieldsForService:(CPString)serviceType
{
    if (serviceType === @"ollama") {
        [_endpointField setEnabled:YES];
        [_apiKeyField setEnabled:NO];
        [_apiKeyField setPlaceholderString:@"Not required"];
    } else {
        [_endpointField setEnabled:NO];
        [_endpointField setPlaceholderString:@"Default platform endpoint used"];
        [_apiKeyField setEnabled:YES];
        [_apiKeyField setPlaceholderString:@"API Token values"];
    }
}

- (void)serviceTypeDidChange:(id)sender
{
    var newService = [[_servicePopUp selectedItem] representedObject];
    [self updateFieldsForService:newService];
}

- (void)closeSettingsSheet:(id)sender
{
    [CPApp endSheet:_settingsWindow];
    [_settingsWindow orderOut:self];
}

- (void)saveSettings:(id)sender
{
    var defaults = [CPUserDefaults standardUserDefaults];
    var activeService = [[_servicePopUp selectedItem] representedObject] || @"ollama";
    var endpoint = [_endpointField stringValue];
    var model = [_modelField stringValue];
    var apiKey = [_apiKeyField stringValue];

    [defaults setObject:activeService forKey:@"LLMTestServiceType"];
    [defaults setObject:endpoint forKey:@"LLMTestEndpoint"];
    [defaults setObject:model forKey:@"LLMTestModel"];
    [defaults setObject:apiKey forKey:@"LLMTestAPIKey"];

    [CPLanguageModelSession setFallbackServiceType:activeService
                                         endpoint:endpoint
                                            model:model
                                           apiKey:apiKey];

    [self closeSettingsSheet:sender];
    [_statusLabel setStringValue:@"Fallback settings updated."];
}

@end
