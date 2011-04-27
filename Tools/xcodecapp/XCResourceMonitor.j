
@import <Foundation/CPObject.j>

var FILE = require("file"),
    FileList = require("jake").FileList;


@implementation XCResourceCollection : CPObject
{
    CPString        m_pattern;
    CPDictionary    m_mtimesForFilePaths;
    
    CPMutableArray  m_addedFilePaths    @accessors(readonly, getter=addedFilePaths);
    CPMutableArray  m_removedFilePaths  @accessors(readonly, getter=removedFilePaths);
    CPMutableArray  m_editedFilePaths   @accessors(readonly, getter=editedFilePaths);
}

- (id)initWithPattern:(CPString)aPattern
{
    self = [super init];

    if (self)
        m_pattern = aPattern;

    return self;
}

- (void)update
{
    m_addedFilePaths = [];
    m_removedFilePaths = [];
    m_editedFilePaths = [];

    // FIXME: There must be a better way to do this.
    var subProjects = new FileList(FILE.join(FILE.dirname(FILE.dirname(m_pattern)), "*/**/Jakefile")),
        paths = new FileList(m_pattern);

    subProjects.forEach(function(aPath)
    {
        paths.exclude(FILE.join(FILE.dirname(aPath), "**", "*"));
    });

    paths.exclude(FILE.join("Build", "**", "*"));

    var mtimesForFilePaths = [CPMutableDictionary new];

    paths.forEach(function(aPath)
    {
        var time = [m_mtimesForFilePaths objectForKey:aPath],
            current = FILE.mtime(aPath);

        if (time === nil)
            [m_addedFilePaths addObject:aPath];

        else if (current > time)
            [m_editedFilePaths addObject:aPath];

        [mtimesForFilePaths setObject:current forKey:aPath];
    });

    var filePath = nil,
        filePaths = [m_mtimesForFilePaths keyEnumerator];

    while (filePath = [filePaths nextObject])
        if ([mtimesForFilePaths objectForKey:filePath] === nil)
            [m_removedFilePaths addObject:filePath];

    m_mtimesForFilePaths = mtimesForFilePaths;
}

@end
