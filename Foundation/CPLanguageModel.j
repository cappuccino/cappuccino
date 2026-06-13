/*
 * CPLanguageModel.j
 * Foundation
 *
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
 */

@import "CPObject.j"
@import "CPString.j"
@import "CPError.j"
@import "CPDictionary.j"
@import "CPBundle.j"
@import "CPUserDefaults.j"

// File-scoped fallback configuration parameters
var CPLanguageModelSessionFallbackServiceType            = @"ollama",
    CPLanguageModelSessionFallbackEndpoint               = @"http://localhost:11434/api/generate",
    CPLanguageModelSessionFallbackModel                  = @"gemma4:e4b",
    CPLanguageModelSessionFallbackAPIKey                 = @"",
    CPLanguageModelSessionFallbackAPIKeyUserDefaultKey   = @"",
    CPLanguageModelSessionEndorsesFallback               = NO;


/*!
    @ingroup foundation
    @class CPSystemLanguageModel

    CPSystemLanguageModel provides a standard query interface to inspect the 
    availability of client-side, on-device large language models (such as Gemma Nano on Chrome) 
    in the active web browser runtime.
*/
@implementation CPSystemLanguageModel : CPObject

var sharedInstance = nil;

/*!
    Returns the singleton system language model monitor.
    @return the default CPSystemLanguageModel instance
*/
+ (id)defaultModel
{

    if (!sharedInstance)
        sharedInstance = [[CPSystemLanguageModel alloc] init];

    return sharedInstance;
}

/*!
    Asynchronously queries the active browser environment to determine if on-device
    language models are supported and readily available to execute prompts.
    @param completionHandler a callback block executed with a boolean parameter (supported)
*/
- (void)supportsLocaleWithCompletionHandler:(Function)completionHandler
{
    if (typeof window === "undefined" || !completionHandler)
    {
        if (completionHandler)
            completionHandler(NO);

        return;
    }

    (async function() {
        var supported = false;

        try {
            if (window.ai && window.ai.languageModel) {
                // Pass language options to align with the creation options
                var options = {
                    expectedInputs: [{ type: "text", languages: ["en"] }],
                    expectedOutputs: [{ type: "text", languages: ["en"] }]
                };

                if (typeof window.ai.languageModel.availability === 'function') {
                    var avail = await window.ai.languageModel.availability(options);
                    supported = (avail === "readily" || avail === "available" || avail === "after-download");
                } else if (typeof window.ai.languageModel.capabilities === 'function') {
                    var caps = await window.ai.languageModel.capabilities(options);
                    supported = (caps.available === "readily" || caps.available === "after-download");
                } else {
                    supported = true;
                }
            }
            else if (window.LanguageModel) {
                supported = true;
            }
        } catch (e) {
            supported = false;
        }

        completionHandler(supported);
    })();
}

@end


/*!
    @ingroup foundation
    @class CPLanguageModelSession

    CPLanguageModelSession manages an active session with a local on-device 
    language model. If the active browser does not support on-device models, the session 
    gracefully and transparently falls back to configured remote server endpoints.

    @discussion
    CPLanguageModelSession handles text generation prompts. If on-device AI
    (like Gemini Nano) is supported by the browser, it is utilized directly. 
    Otherwise, or if CPLanguageModelSessionEndorsesFallback is configured to YES,
    the session automatically falls back to configured network-based providers 
    (such as local Ollama, Groq, or OpenRouter).

    Fallback configurations can be populated globally using the application's Info.plist 
    via the following keys:
    <pre>
    CPEndorseLanguageModelFallback - YES to bypass on-device models and force fallback
    CPDefaultLanguageModelService - "ollama" | "groq" | "gemini" | "openrouter"
    CPDefaultLanguageModelEndpoint - API Endpoint (e.g. Ollama URL)
    CPDefaultLanguageModelModel - Model name string
    CPDefaultLanguageModelAPIKeyUserDefaultKey - CPUserDefaults key containing the actual API token
    CPDefaultLanguageModelAPIKey - Authentication token string (Unsecure direct fallback)
    </pre>
*/
@implementation CPLanguageModelSession : CPObject
{
    id       _chromeSession       @accessors(property=chromeSession);
    CPString _instructions        @accessors(property=instructions);
    CPString _fallbackServiceType @accessors(property=fallbackServiceType);
    CPString _fallbackEndpoint    @accessors(property=fallbackEndpoint);
    CPString _fallbackModel       @accessors(property=fallbackModel);
    CPString _fallbackAPIKey      @accessors(property=fallbackAPIKey);
}

/*!
    Initializes fallback defaults and "Endorsement" flags from the application's Info.plist.
*/
+ (void)initialize
{
    if (self === [CPLanguageModelSession class])
    {
        var bundle = [CPBundle mainBundle];
        
        CPLanguageModelSessionEndorsesFallback             = !![bundle objectForInfoDictionaryKey:@"CPEndorseLanguageModelFallback"];
        CPLanguageModelSessionFallbackServiceType          = [bundle objectForInfoDictionaryKey:@"CPDefaultLanguageModelService"] || @"ollama";
        CPLanguageModelSessionFallbackEndpoint             = [bundle objectForInfoDictionaryKey:@"CPDefaultLanguageModelEndpoint"] || @"http://localhost:11434/api/generate";
        CPLanguageModelSessionFallbackModel                = [bundle objectForInfoDictionaryKey:@"CPDefaultLanguageModelModel"] || @"gemma4:e4b";
        CPLanguageModelSessionFallbackAPIKey               = [bundle objectForInfoDictionaryKey:@"CPDefaultLanguageModelAPIKey"] || @"";
        CPLanguageModelSessionFallbackAPIKeyUserDefaultKey = [bundle objectForInfoDictionaryKey:@"CPDefaultLanguageModelAPIKeyUserDefaultKey"] || @"";
    }
}

/*!
    Configures whether the session should bypass native browser AI models and force fallback network routing.
    @param shouldEndorse YES to bypass native AI; NO to prioritize native AI if available
*/
+ (void)setEndorsesFallback:(BOOL)shouldEndorse
{
    CPLanguageModelSessionEndorsesFallback = shouldEndorse;
}

/*!
    Indicates if the session bypasses native browser AI models.
    @return YES if forced fallback is active; NO otherwise
*/
+ (BOOL)endorsesFallback
{
    return CPLanguageModelSessionEndorsesFallback;
}

/*!
    Configures fallback details dynamically, overriding any defaults loaded from Info.plist.
    @param serviceType the service type (e.g. @"ollama", @"groq", @"gemini", @"openrouter")
    @param endpoint the network target URL
    @param model the model identifier
    @param apiKey the API key string
*/
+ (void)setFallbackServiceType:(CPString)serviceType endpoint:(CPString)endpoint model:(CPString)model apiKey:(CPString)apiKey
{
    CPLanguageModelSessionFallbackServiceType = serviceType;
    CPLanguageModelSessionFallbackEndpoint = endpoint;
    CPLanguageModelSessionFallbackModel = model;
    CPLanguageModelSessionFallbackAPIKey = apiKey;
}

/*!
    Configures the CPUserDefaults key used to dynamically look up the API key.
    @param keyName the user defaults key name containing the actual credentials
*/
+ (void)setFallbackAPIKeyUserDefaultKey:(CPString)keyName
{
    CPLanguageModelSessionFallbackAPIKeyUserDefaultKey = keyName;
}

/*!
    Gets the CPUserDefaults key name used to dynamically look up the API key.
    @return the user defaults key name
*/
+ (CPString)fallbackAPIKeyUserDefaultKey
{
    return CPLanguageModelSessionFallbackAPIKeyUserDefaultKey;
}

/*!
    Initializes a language model session with specific system instructions.
    @param instructions the system instructions or context prompt
    @return the initialized session
*/
- (id)initWithInstructions:(CPString)instructions
{
    self = [super init];

    if (self)
    {
        _instructions = instructions;
        _chromeSession = nil;
        _fallbackServiceType = nil;
        _fallbackEndpoint = nil;
        _fallbackModel = nil;
        _fallbackAPIKey = nil;
    }

    return self;
}

/*!
    Initializes a language model session with specific system instructions and an explicit programmatic API key.
    @param instructions the system instructions or context prompt
    @param apiKey the fallback API key to use specifically for this session
    @return the initialized session
*/
- (id)initWithInstructions:(CPString)instructions apiKey:(CPString)apiKey
{
    self = [self initWithInstructions:instructions];

    if (self)
    {
        _fallbackAPIKey = apiKey;
    }

    return self;
}

/*!
    Initializes a language model session with instructions and explicit fallback settings.
    @param instructions the system instructions or context prompt
    @param options dictionary containing custom fallback configuration (e.g. @{ @"serviceType": ..., @"apiKey": ... })
    @return the initialized session
*/
- (id)initWithInstructions:(CPString)instructions fallbackOptions:(CPDictionary)options
{
    self = [self initWithInstructions:instructions];

    if (self)
    {
        if (options)
        {
            _fallbackServiceType = [options objectForKey:@"serviceType"];
            _fallbackEndpoint    = [options objectForKey:@"endpoint"];
            _fallbackModel       = [options objectForKey:@"model"];
            _fallbackAPIKey      = [options objectForKey:@"apiKey"];
        }
    }

    return self;
}

/*!
    Sends a query prompt to the language model session.
    @param prompt the query text to analyze
    @param completionHandler a callback receiving the response string or a CPError instance
*/
- (void)respondToPrompt:(CPString)prompt options:(id)options completionHandler:(Function)completionHandler
{
    // If the developer forced fallback, bypass native browser execution
    if (CPLanguageModelSessionEndorsesFallback)
    {
        [self _executeRemoteFallbackWithPrompt:prompt options:options completionHandler:completionHandler];
        return;
    }

    if (_chromeSession)
    {
        [self _executePrompt:prompt options:options completionHandler:completionHandler];
        return;
    }

    var selfRef = self,
        instructions = [self instructions];

    [CPLanguageModelSession _getChromeFactoryWithCompletionHandler:function(factory, error) {
        if (error) {
            [selfRef _executeRemoteFallbackWithPrompt:prompt options:options completionHandler:completionHandler];
            return;
        }

        // Add the required expected input and output parameters
        var sessionOptions = {
            expectedInputs: [{ type: "text", languages: ["en"] }],
            expectedOutputs: [{ type: "text", languages: ["en"] }]
        };
        if (instructions) {
            sessionOptions.systemPrompt = instructions;
        }

        factory.create(sessionOptions).then(function(session) {
            [selfRef setChromeSession:session];
            [selfRef _executePrompt:prompt options:options completionHandler:completionHandler];
        }).catch(function(err) {
            [selfRef _executeRemoteFallbackWithPrompt:prompt options:options completionHandler:completionHandler];
        });
    }];
}

/*!
    Sends a query prompt and streams the response chunk-by-chunk for live UI rendering.
    @param prompt the query text to analyze
    @param chunkHandler a callback block executed as text increments are received
    @param completionHandler a final callback block executed when generation completes
*/
- (void)respondToPrompt:(CPString)prompt
        onChunkReceived:(Function)chunkHandler
              completed:(Function)completionHandler
{
    if (CPLanguageModelSessionEndorsesFallback)
    {
        [self _executeRemoteFallbackWithPrompt:prompt options:nil completionHandler:function(res, err) {
            if (!err && chunkHandler)
                chunkHandler(res);
            completionHandler(res, err);
            [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode]; // pump run loop to force GUI update

        }];
        return;
    }

    if (_chromeSession)
    {
        [self _executePromptStreaming:prompt onChunkReceived:chunkHandler completed:completionHandler];
        return;
    }

    var selfRef = self,
        instructions = [self instructions];

    [CPLanguageModelSession _getChromeFactoryWithCompletionHandler:function(factory, error) {
        if (error) {
            [selfRef _executeRemoteFallbackWithPrompt:prompt options:nil completionHandler:function(res, err) {
                if (!err && chunkHandler)
                    chunkHandler(res);
                completionHandler(res, err);
            }];
            return;
        }

        // Add the required expected input and output parameters
        var options = {
            expectedInputs: [{ type: "text", languages: ["en"] }],
            expectedOutputs: [{ type: "text", languages: ["en"] }]
        };
        if (instructions) {
            options.systemPrompt = instructions;
        }

        factory.create(options).then(function(session) {
            [selfRef setChromeSession:session];
            [selfRef _executePromptStreaming:prompt onChunkReceived:chunkHandler completed:completionHandler];
        }).catch(function(err) {
            [selfRef _executeRemoteFallbackWithPrompt:prompt options:nil completionHandler:function(res, err) {
                if (!err && chunkHandler)
                    chunkHandler(res);
                completionHandler(res, err);
            }];
        });
    }];
}

/*!
    Closes the session and releases associated memory resources on-device.
*/
- (void)destroy
{
    if (_chromeSession && typeof _chromeSession.destroy === "function")
    {
        _chromeSession.destroy();
        _chromeSession = nil;
    }
}


// MARK: - Private Helper Methods

+ (void)_getChromeFactoryWithCompletionHandler:(Function)completionHandler
{
    if (typeof window === "undefined")
    {
        var cpError = [CPError errorWithDomain:@"CPLanguageModelErrorDomain" code:-1 userInfo:[CPDictionary dictionaryWithObject:@"Execution environment is not a browser window." forKey:CPLocalizedDescriptionKey]];
        completionHandler(nil, cpError);
        return;
    }

    if (window.ai && window.ai.languageModel)
        completionHandler(window.ai.languageModel, nil);
    else if (window.LanguageModel)
        completionHandler(window.LanguageModel, nil);
    else
        completionHandler(nil, [CPError errorWithDomain:@"CPLanguageModelErrorDomain" code:0 userInfo:nil]);
}

- (void)_executePrompt:(CPString)prompt options:(id)options completionHandler:(Function)completionHandler
{
    var promptPromise = options ? _chromeSession.prompt(prompt, options) : _chromeSession.prompt(prompt);

    promptPromise.then(function(result) {
        completionHandler(result, nil);
    }).catch(function(err) {
        var cpError = [CPError errorWithDomain:@"CPLanguageModelErrorDomain" 
                                          code:2 
                                      userInfo:[CPDictionary dictionaryWithObject:err.message forKey:CPLocalizedDescriptionKey]];
        completionHandler(nil, cpError);
    });
}

- (CPString)_resolvedFallbackServiceType
{
    return _fallbackServiceType || CPLanguageModelSessionFallbackServiceType;
}

- (CPString)_resolvedFallbackEndpoint
{
    return _fallbackEndpoint || CPLanguageModelSessionFallbackEndpoint;
}

- (CPString)_resolvedFallbackModel
{
    return _fallbackModel || CPLanguageModelSessionFallbackModel;
}

- (CPString)_resolvedFallbackAPIKey
{
    // 1. Session instance explicit key has highest priority
    if (_fallbackAPIKey)
        return _fallbackAPIKey;

    // 2. Class fallback API key set programmatically takes second priority
    if (CPLanguageModelSessionFallbackAPIKey)
        return CPLanguageModelSessionFallbackAPIKey;

    // 3. Dynamic lookup from standard user defaults takes final priority
    if (CPLanguageModelSessionFallbackAPIKeyUserDefaultKey)
    {
        var defaults = [CPUserDefaults standardUserDefaults],
            apiKey = [defaults objectForKey:CPLanguageModelSessionFallbackAPIKeyUserDefaultKey];
        if (apiKey)
            return apiKey;
    }

    return @"";
}

- (void)_executeRemoteFallbackWithPrompt:(CPString)prompt options:(id)options completionHandler:(Function)completionHandler
{
    var systemPrompt = [self instructions],
        serviceType = [self _resolvedFallbackServiceType],
        endpoint = [self _resolvedFallbackEndpoint],
        model = [self _resolvedFallbackModel],
        apiKey = [self _resolvedFallbackAPIKey];

    var reqUrl = @"",
        headers = { "Content-Type": "application/json" },
        payload = {};

    if (serviceType === @"groq")
    {
        reqUrl = "https://api.groq.com/openai/v1/chat/completions";
        headers["Authorization"] = "Bearer " + apiKey;
        payload = {
            "model": model,
            "messages": [
                { "role": "system", "content": systemPrompt },
                { "role": "user", "content": prompt }
            ],
            "temperature": 0
        };
    }
    else if (serviceType === @"gemini")
    {
        reqUrl = "https://generativelanguage.googleapis.com/v1beta/models/" + model + ":generateContent?key=" + apiKey;
        payload = {
            "contents": [
                { "parts": [{ "text": systemPrompt + "\n\n" + prompt }] }
            ],
            "generationConfig": { "temperature": 0 }
        };
    }
    else if (serviceType === @"openrouter")
    {
        reqUrl = "https://openrouter.ai/api/v1/chat/completions";
        headers["Authorization"] = "Bearer " + apiKey;
        payload = {
            "model": model,
            "messages": [
                { "role": "system", "content": systemPrompt },
                { "role": "user", "content": prompt }
            ],
            "temperature": 0
        };
    }
    else
    {
        reqUrl = endpoint || "http://localhost:11434/api/generate";
        payload = {
            "model": model,
            "prompt": systemPrompt + "\n\n" + prompt,
            "stream": false,
            "options": { "temperature": 0 }
        };
    }

    fetch(reqUrl, {
        method: 'POST',
        headers: headers,
        body: JSON.stringify(payload)
    })
    .then(function(response) {
        if (!response.ok) {
            throw new Error("HTTP error! Status: " + response.status);
        }
        return response.json();
    })
    .then(function(data) {
        var responseText = "";

        if (serviceType === "groq" || serviceType === "openrouter") {
            responseText = (data.choices && data.choices[0] && data.choices[0].message) ? data.choices[0].message.content : "";
        } else if (serviceType === "gemini") {
            responseText = (data.candidates && data.candidates[0] && data.candidates[0].content && data.candidates[0].content.parts) ? data.candidates[0].content.parts[0].text : "";
        } else {
            responseText = data.response || "";
        }

        completionHandler(responseText, nil);
    })
    .catch(function(err) {
        var cpError = [CPError errorWithDomain:@"CPLanguageModelErrorDomain" 
                                          code:4 
                                      userInfo:[CPDictionary dictionaryWithObject:err.message forKey:CPLocalizedDescriptionKey]];
        completionHandler(nil, cpError);
    });
}

- (void)_executePromptStreaming:(CPString)prompt
                onChunkReceived:(Function)chunkHandler
                      completed:(Function)completionHandler
{
    var stream;

    try {
        stream = _chromeSession.promptStreaming(prompt);
    } catch (err) {
        var cpError = [CPError errorWithDomain:@"CPLanguageModelErrorDomain" 
                                              code:3 
                                          userInfo:[CPDictionary dictionaryWithObject:err.message forKey:CPLocalizedDescriptionKey]];
        completionHandler(nil, cpError);
        return;
    }

    (async function() {
        var lastChunk = "";

        try {
            for await (const chunk of stream) {
                lastChunk = chunk;
                if (chunkHandler) {
                    chunkHandler(chunk);
                }
            }
            if (completionHandler)
            {
                completionHandler(lastChunk, nil);
                [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode]; // pump run loop to force GUI update

            }
        } catch (err) {
            if (completionHandler) {
                var cpError = [CPError errorWithDomain:@"CPLanguageModelErrorDomain" 
                                                  code:2 
                                              userInfo:[CPDictionary dictionaryWithObject:err.message forKey:CPLocalizedDescriptionKey]];
                completionHandler(nil, cpError);
                [[CPRunLoop currentRunLoop] limitDateForMode:CPDefaultRunLoopMode]; // pump run loop to force GUI update
            }
        }
    })();
}

@end
