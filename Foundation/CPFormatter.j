/*
 * CPFormatter.j
 * Foundation
 *
 * Created by Randall Luecke
 * Copyright 2010, RCLConcepts, LLC.
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

/*!
    @class CPFormatter
    @ingroup foundation
    @brief CPFormatter is an abstract class that declares an interface for objects that create, interpret,
           and validate the textual representation of cell contents. The Foundation framework provides two
           concrete subclasses of CPFormatter to generate these objects: CPNumberFormatter and CPDateFormatter.

           CPFormatter is intended for subclassing. A custom formatter can restrict the input and enhance the
           display of data in novel ways. For example, you could have a custom formatter that ensures that serial
           numbers entered by a user conform to predefined formats. Before you decide to create a custom formatter,
           make sure that you cannot configure the public subclasses CPDateFormatter and CPNumberFormatter to satisfy your requirements.
*/

@import "CPException.j"
@import "CPObject.j"

@implementation CPFormatter : CPObject

/*!
    The default implementation of this method raises an exception.

    When implementing a subclass, return the CPString object that textually represents
    the view's object for display and if editingStringForObjectValue: is unimplemented for editing.
    First test the passed-in object to see if it's of the correct class. If it isn't, return nil;
    but if it is of the right class, return a properly formatted and, if necessary, localized string.
    (See the specification of the CPString class for formatting and localizing details.)

    @param anObject The object for which a textual representation is returned
    @return CPSting a formatted string
*/
- (CPString)stringForObjectValue:(id)anObject
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
    return nil;
}

/*- (CPAttributedString)attributedStringForObjectValue:(id)anObject withDefaultAttributes:(CPDictionary)attributes
{

}*/

/*!
    The default implementation of this method invokes stringForObjectValue:.

    When implementing a subclass, override this method only when the string that users see and the string
    that they edit are different. In your implementation, return an CPString object that is used for editing,
    following the logic recommended for implementing stringForObjectValue:. As an example, you would implement
    this method if you want the dollar signs in displayed strings removed for editing.

    @param anObject the object for which to return an editing string
    @return CPString object that is used for editing the textual representation of an object
*/
- (CPString)editingStringForObjectValue:(id)anObject
{
    return [self stringForObjectValue:anObject];
}

/*!
    The default implementation of this method raises an exception.

    When implementing a subclass, return by reference the object anObject after creating it from aString.
    Return \c YES if the conversion is successful. If you return \c NO, also return by reference (in anError)
    a localized user-presentable CPString object that explains the reason why the conversion failed; the delegate
    (if any) of the CPControl object can then respond to the failure in
    control:didFailToFormatString:errorDescription:. However, if anError is nil, the sender is not interested in
    the error description, and you should not attempt to assign one.

    @param anObject if conversion is successful, upon return contains the object created from the string
    @param aString the string to parse.
    @param anError if non-nil, if there is an error during the conversion, upon return contains an CPString object that describes the problem.
    @return BOOL \c YES if the conversion from the string to a view content object was successful, otherwise \c NO.
*/
- (BOOL)getObjectValue:(idRef)anObject forString:(CPString)aString errorDescription:(CPStringRef)anError
{
    _CPRaiseInvalidAbstractInvocation(self, _cmd);
    return NO;
}

/*!
    Returns a Boolean value that indicates whether a partial string is valid.

    This method is invoked each time the user presses a key while the cell has the keyboard focus it lets you verify and
    edit the cell text as the user types it.

    In a subclass implementation, evaluate aPartialString according to the context, edit the text if necessary, and return
    by reference any edited string in aNewString. Return \c YES if aPartialString is acceptable and \c NO if aPartialString is unacceptable.
    If you return \c NO and aNewString is nil, the control displays aPartialString minus the last character typed. If you return \c NO, you can
    also return by reference a CPString object (in anError) that explains the reason why the validation failed; the delegate (if any)
    of the CPControl can then respond to the failure in control:didFailToValidatePartialString:errorDescription:.
    The selection range will always be set to the end of the text if replacement occurs.

    This method is a compatibility method. If a subclass overrides this method and does not override
    isPartialStringValid:proposedSelectedRange:originalString:originalSelectedRange:errorDescription:, this method will be called as before
    (isPartialStringValid:proposedSelectedRange:originalString:originalSelectedRange:errorDescription: just calls this one by default).

    @param aPartialString the text currently in the view.
    @param aNewString if aPartialString needs to be modified, upon return contains the replacement string.
    @param anError if non-nil, if validation fails contains a CPString object that describes the problem.
    @return \c YES if aPartialString is an acceptable value, otherwise \c NO.
*/
- (BOOL)isPartialStringValid:(CPString)aPartialString newEditingString:(CPStringRef)aNewString errorDescription:(CPStringRef)anError
{
    @deref(aPartialString) = nil;

    if (anError)
        @deref(anError) = nil;

    return YES;
}

/*!
    This method should be implemented in subclasses that want to validate user changes to a string in a field, where the user changes are
    not necessarily at the end of the string, and preserve the selection (or set a different one, such as selecting the erroneous part of
    the string the user has typed).

    In a subclass implementation, evaluate aPartialStringRef according to the context. Return \c YES if aPartialStringRef is acceptable and \c NO if aPartialStringRef
    is unacceptable. Assign a new string by reference to aPartialStringRef and a new range by reference to aProposedSelectedRangeRef and return \c NO if you want to replace the string and
    change the selection range. If you return \c NO, you can also return by reference a CPString object (in anError) that explains the reason why the
    validation failed; the delegate (if any) of the CPControl can then respond to the failure in
    control:didFailToValidatePartialString:errorDescription:.

    @param aPartialStringRef The new string to validate.
    @param aProposedSelectedRangeRef The selection range that will be used if the string is accepted or replaced.
    @param originalString The original string, before the proposed change.
    @param originalSelectedRange The selection range over which the change is to take place.
    @param anError If non-nil, if validation fails contains an CPString object that describes the problem.
    @return \c YES if aPartialStringRef is acceptable, otherwise \c NO.

*/
- (BOOL)isPartialStringValid:(CPStringRef)aPartialStringRef proposedSelectedRange:(CPRangeRef)aProposedSelectedRangeRef originalString:(CPString)originalString originalSelectedRange:(CPRange)originalSelectedRange errorDescription:(CPStringRef)anError
{
    var newString = nil,
        valid = [self isPartialStringValid:aPartialStringRef newEditingString:@ref(newString) errorDescription:anError];

    if (!valid)
    {
        @deref(aPartialStringRef) = newString;

        // If a new string is passed back, the selection is always put at the end
        if (newString !== nil)
            @deref(aProposedSelectedRangeRef) = CPMakeRange(newString.length, 0);
    }

    return valid;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self init];
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
}

@end
