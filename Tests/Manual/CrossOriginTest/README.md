This test checks the withCredentials CORS functionality with Cappuccino.

Running the test:

You will need to start two HTTP Servers; one on localhost:8000, and one on localhost:8001. 

The first:

`$> python -m SimpleHTTPServer`  // starts it on 8000

In another terminal window:

`$> python cors-server.py` // starts another on 8001

Visit http://localhost:8000 in your web browser. There are two buttons and a checkbox.

One button will issue a native XMLHTTPRequest. The other will issue a CPURLConnection request. The checkbox will control whether the withCredentials option is set on both types of requests.

With the checkbox checked, you should press either of the buttons. In the terminal with the 'cors-server.py' script running you will see output that should match the following:

```
INFO:root:CORS: With Credentials
127.0.0.1 - - [05/Dec/2014 18:44:48] "GET /resp.json HTTP/1.1" 200 -
```

If you uncheck the checkbox, you should see the following:

```
INFO:root:CORS: No Credentials
127.0.0.1 - - [05/Dec/2014 18:44:56] "GET /resp.json HTTP/1.1" 200 -
```

This error message is controlled by the presence of the 'Cookies' header.

NOTE: The cors-server.py will set a cookie for you (mycookie=cappuccino!), but only after the first request. If you don't have a cookie set for localhost, the server message will show 'No Credentials' on the first request since the Cookie header is not set. Subsequent requests will behave correctly.

The browser console will also provide some status information about the request and response.

# A note about IE<sup>**</sup>

As best I can tell, IE behaves differently than all other browsers. I have tested this in Chrome and Firefox on Mac & Windows, Safari on Mac, IE11 on Windows. In this test, unchecking the 'With Credentials' will tell the browser to not send a cookie to the server if the server and client are not on the same host. However, in IE, it will pass the cookie along if the server and host are on the same top domain, but not necessarily the same host. The corollary of this is that if the two servers are on different domains, the `withCredentials` setting in IE does absolutely nothing.

To get it to work, you must instruct your users to adjust their cookie privacy settings and allow third-party cookies. This seemed to work for me, but dynamically adjusting the `withCredentials` parameter did nothing with this on -- IE always sent the cookies if it was configured to do so.

<sup>*</sup> What, you expected IE to actually work like the rest of the world?