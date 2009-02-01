/*
 * NSCustomResource.j
 * nib2cib
 *
 * Portions based on NSCustomResource.m (01/08/2009) in Cocotron (http://www.cocotron.org/)
 * Copyright (c) 2006-2007 Christopher J. W. Lloyd
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
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

@import <AppKit/_CPCibCustomResource.j>

importClass(javax.imageio.ImageIO);


@implementation _CPCibCustomResource (NSCoding)

- (id)NS_initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        _className = CP_NSMapClassName([aCoder decodeObjectForKey:@"NSClassName"]);
        _resourceName = [aCoder decodeObjectForKey:@"NSResourceName"];
        
        var size = CGSizeMakeZero();
        
        if (![aCoder resourcesFile])
        {
            CPLog.warn("***WARNING: Resources found in nib, but no resources path specified with -R option.");
            
            _properties = [CPDictionary dictionaryWithObject:CGSizeMakeZero() forKey:@"size"];
        }
        else
        {
            var resourceFile = [aCoder resourceFileForName:_resourceName];
            
            if (!resourceFile)
                CPLog.warn("***WARNING: Resource named " + _resourceName + " not found in supplied resources path.");
            else
            {
                var imageStream = ImageIO.createImageInputStream(resourceFile),
                    readers = ImageIO.getImageReaders(imageStream),
                    reader = null;
                
                if(readers.hasNext())
                    reader = readers.next();
                
                else
                {
                    imageStream.close();
                    //can't read image format... what do you want to do about it,
                    //throw an exception, return ?
                }
                
                reader.setInput(imageStream, true, true);
                
                // Now we know the size (yay!) 
                size = CGSizeMake(reader.getWidth(0), reader.getHeight(0));
                print(size.width + " " + size.height);
                reader.dispose();
                imageStream.close();
            }
        }
        
        _properties = [CPDictionary dictionaryWithObject:size forKey:@"size"];
    }
    
    return self;
}

@end

@implementation NSCustomResource : _CPCibCustomResource
{
}

- (id)initWithCoder:(CPCoder)aCoder
{
    return [self NS_initWithCoder:aCoder];
}

- (Class)classForKeyedArchiver
{
    return [_CPCibCustomResource class];
}

@end
