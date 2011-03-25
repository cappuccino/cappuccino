This fixes issue #1190.

Motivation
==========

If you nib2cib the xib in this test application in the version of Cappuccino before this commit, about half the time or more, when you run the application it fails to load and the console shows the following error:

`TypeError: Result of expression '_subviews[index]' [null] is not an object.`

Solution
=========
The problem was caused by the fact that NSMatrix -initWithCoder was returning a completely new CPView object. Depending on the order of decoding of the object graph, this would lead to a situation where an object which referenced the NSMatrix would be left with a dangling reference. This also manifested in an attempt to archive the NSMatrix itself, which I could never figure out the reason for. Now I know why.

In any case, the solution was simple: make NSMatrix a subclass of CPView instead of CPObject, and after constructing it directly set its class via self.isa to CPView. Thus the original object is returned, but as a different class, and there is no problem with dangling references. As a bonus, the special check for attempted archiving of NSMatrix could be removed.