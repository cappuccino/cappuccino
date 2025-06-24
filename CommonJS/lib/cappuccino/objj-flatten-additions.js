/**
 * objj-flatten-additions.js
 *
 * This file provides additions to the Objective-J runtime to allow tools like
 * 'flatten' and 'press' to run in a non-browser environment (like Node.js).
 *
 * Its primary function is to intercept CFHTTPRequest calls and satisfy them
 * from an in-memory cache, simulating network requests without actually
 * performing them. This is achieved by creating a MockXMLHttpRequest object.
 */

const URLCache = {};

// Store the original implementation before we patch it.
const CFHTTPRequest_open = CFHTTPRequest.prototype.open;

/**
 * Patch CFHTTPRequest.prototype.open to first check our in-memory cache.
 * If a request for a URL is found in the cache, we use the mock object
 * instead of making a real network request.
 */
CFHTTPRequest.prototype.open = function(method, url, async, user, password) {
    const cachedRequest = CFHTTPRequest._lookupCachedRequest(url);

    if (cachedRequest) {
        // If we found a cached response, use it as our "native" request object.
        this._nativeRequest = cachedRequest;

        // Use an arrow function to preserve the `this` context, referring to the CFHTTPRequest instance.
        this._nativeRequest.onreadystatechange = () => {
            ObjectiveJ.determineAndDispatchHTTPRequestEvents(this);
        };
    }

    // Call the original open method. If we didn't find a cached request,
    // this will proceed as normal. If we did, this call is mostly for
    // side-effects, as the onreadystatechange is now pointing to our mock.
    return CFHTTPRequest_open.apply(this, arguments);
};

/**
 * Adds a mock response to the in-memory cache.
 * @param {string|CFURL} aURL - The URL to cache the response for.
 * @param {number} status - The HTTP status code (e.g., 200).
 * @param {object} headers - A key-value object of response headers.
 * @param {string} body - The response body text.
 */
CFHTTPRequest._cacheRequest = function(aURL, status, headers, body) {
    URLCache[aURL] = new MockXMLHttpRequest(status, headers, body);
};

/**
 * Looks up a mock response in the in-memory cache.
 * @param {string|CFURL} aURL - The URL to look up.
 * @returns {MockXMLHttpRequest|undefined} The cached mock request, or undefined if not found.
 */
CFHTTPRequest._lookupCachedRequest = function(aURL) {
    return URLCache[aURL];
};

/**
 * A mock implementation of the browser's XMLHttpRequest object.
 * It's designed to simulate the lifecycle of an XHR request for use in a
 * non-browser environment.
 */
function MockXMLHttpRequest(status, headers, body) {
    this.readyState       = CFHTTPRequest.UninitializedState;
    this.status           = status || 200;
    this.statusText       = "";
    this.responseText     = body || "";
    this._responseHeaders = headers || {};
}

MockXMLHttpRequest.prototype.open = function(method, url, async, user, password) {
    this.readyState = CFHTTPRequest.LoadingState;
    this.async = async;
};

MockXMLHttpRequest.prototype.send = function(body) {
    const self = this;
    self.responseText = self.responseText.toString();

    function complete() {
        // Simulate the progression from Loaded to Complete state.
        for (self.readyState = CFHTTPRequest.LoadedState; self.readyState <= CFHTTPRequest.CompleteState; self.readyState++) {
            self.onreadystatechange();
        }
    }

    // Use Objective-J's scheduler to run the completion function, respecting the async flag.
    (self.async ? ObjectiveJ.Asynchronous(complete) : complete)();
};

// Define no-op stubs for the other XHR methods to prevent errors.
MockXMLHttpRequest.prototype.onreadystatechange    = function() {};
MockXMLHttpRequest.prototype.abort                 = function() {};
MockXMLHttpRequest.prototype.setRequestHeader      = function(header, value) {};
MockXMLHttpRequest.prototype.overrideMimeType      = function(mimetype) {};
MockXMLHttpRequest.prototype.getAllResponseHeaders = function() { return this._responseHeaders; };
MockXMLHttpRequest.prototype.getResponseHeader     = function(header) { return this._responseHeaders[header]; };