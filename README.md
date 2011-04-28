# xCodeCapp-Cocoa

xcodecapp-cocoa is a port from the original xcodecapp application. It works basically the same than this 
tools shipped with Cappuccino framework but have serveral advantages:
 
 * It uses the FSEventStream system to be notified when a file changes. So no useless looping
 * It consumes about no CPU when idle
 * It allows you to choose graphically the project you want to use
 * It will keep track of your already generated project helper
 * It supports .xcodecapp-ignore
 * It uses Growl to notify you when a conversion is done.

# License

All the code is distributed under AGPL v3.0 license. The parse.j comes from Cappuccino parser and uses the Cappuccino license.

# Author

Antoine Meradal <primalmotion@archipelproject.org>