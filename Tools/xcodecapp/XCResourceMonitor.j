
@import <Foundation/CPObject.j>

var FILE = require("file"),
    FileList = require("jake").FileList;


@implementation XCResourceCollection : CPObject
{
    CPString        m_pattern;
    CPString        m_ignorePattern;
    CPDictionary    m_mtimesForFilePaths;

    CPMutableArray  m_addedFilePaths    @accessors(readonly, getter=addedFilePaths);
    CPMutableArray  m_removedFilePaths  @accessors(readonly, getter=removedFilePaths);
    CPMutableArray  m_editedFilePaths   @accessors(readonly, getter=editedFilePaths);
}

- (id)initWithPattern:(CPString)aPattern ignore:(CPArray)someIgnorePatterns
{
    self = [super init];

    if (self)
    {
        m_pattern = aPattern;
        m_ignorePattern = new FileList();

        someIgnorePatterns.forEach(function(anIgnorePattern)
        {
            var ignorePaths = new FileList(FILE.join(FILE.dirname(FILE.dirname(anIgnorePattern))));
            m_ignorePattern.include(ignorePaths);
        });
    }

    return self;
}

- (void)update
{
    m_addedFilePaths = [];
    m_removedFilePaths = [];
    m_editedFilePaths = [];


    var paths = new FileList(m_pattern),
        mtimesForFilePaths = [CPMutableDictionary new];

    // FIXME: I guess this can be greatly optimized,
    // but I'm not at ease with CommonJS.
    m_ignorePattern.forEach(function(aPath)
    {
        if (aPath != "")
        {
            var p = FILE.join(FILE.cwd(), aPath, "*/**");
            paths.exclude(p);
        }
    });

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
