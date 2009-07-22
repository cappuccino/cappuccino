
@import <Foundation/CPKeyedUnarchiver.j>


@implementation Nib2CibKeyedUnarchiver : CPKeyedUnarchiver
{
    File    resourcesFile;
}

- (id)initForReadingWithData:(CPData)data resourcesFile:(File)aResourcesFile
{
    self = [super initForReadingWithData:data];
    
    if (self)
        resourcesFile = aResourcesFile;
    
    return self;
}

- (File)resourcesFile
{
    return resourcesFile;
}

- (File)resourceFileForName:(CPString)aName
{
    var moreFiles = [resourcesFile.listFiles()];

    do
    {
        var files = moreFiles.shift(),
            index = 0,
            count = files.length;
        
        for (; index < count; ++index)
        {
            var file = files[index].getCanonicalFile(),
                name = String(file.getName());
                
            if (name === aName)
                return file;
            
            if (file.isDirectory())
                moreFiles.push(file.listFiles());
        }
    }
    while (moreFiles.length > 0)
    
    return NULL;
}

@end
