@import <Foundation/Foundation.j>

@implementation CPNotificationCenterHelper : CPObject
{
}

+ (void)registeredNotificationsForObserver:(id)anObserver
{
    var defaultCenter = [CPNotificationCenter defaultCenter],
        names = [defaultCenter._namedRegistries keyEnumerator],
        notifications = [],
        name;

    while ((name = [names nextObject]) !== nil)
    {
        var notificationRegistry = [defaultCenter._namedRegistries objectForKey:name],
            objectObservers = notificationRegistry._objectObservers,
            keys = [objectObservers keyEnumerator],
            key;

        // Iterate through every set of observers
        while ((key = [keys nextObject]) !== nil)
        {
            var observers = [objectObservers objectForKey:key],
                observer = nil,
                observersEnumerator = [observers objectEnumerator];

            while ((observer = [observersEnumerator nextObject]) !== nil)
            {
                if ([observer observer] == anObserver)
                    [notifications addObject:name];
            }
        }
    }

    return notifications.sort();
}

@end
