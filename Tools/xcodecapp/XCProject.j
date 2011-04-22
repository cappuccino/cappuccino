
@import <Foundation/CPObject.j>
@import <Foundation/CPString.j>
@import <Foundation/CPDictionary.j>

@import "XCResourceMonitor.j"

var FILE = require("file"),
    OS = require("os");


@implementation XCProject : CPObject
{
    CFURL               m_URL;

    XCResourceMonitor   m_sourceResourceMonitor;
    XCResourceMonitor   m_nibResourceMonitor;

    CFURL               m_xCodeProjectURL;
    CFURL               m_xCodeProjectFileURL;
    CFURL               m_xCodeSupportSourcesURL;
}

- (id)initWithPath:(CPString)aPath ignoreFilePath:(CPString)anIgnoreFilePath  shouldOpenProject:(BOOL)shouldOpen
{
    self = [super init];

    if (self)
    {
        m_URL = new CFURL(aPath);

        var ignorePatterns = [],
            ignoreFilePath = anIgnoreFilePath || FILE.join(m_URL, ".xcodecapp-ignore");

        if (FILE.exists(ignoreFilePath))
            ignorePatterns = FILE.read(ignoreFilePath).split("\n");

        [self prepare_xCodeProject];

        m_sourceResourceMonitor = [[XCResourceCollection alloc] initWithPattern:FILE.join(m_URL, "/**/*.j") ignore:ignorePatterns];
        m_nibResourceMonitor = [[XCResourceCollection alloc] initWithPattern:FILE.join(m_URL, "/**/*.[nx]ib") ignore:ignorePatterns];

        if (shouldOpen)
            [self launch];
    }

    return self;
}

- (CPString)projectName
{
    return m_URL.lastPathComponent();
}

- (CFURL)xCodeProjectTemplateURL
{
    var CAPP_HOME = require("narwhal/packages").catalog["cappuccino"].directory;

    return new CFURL(FILE.join(CAPP_HOME, "lib", "xcodecapp", "Resources", "xCodeSupport.xcodeproj"));
}

- (CFURL)xCodeProjectParserURL
{
    var CAPP_HOME = require("narwhal/packages").catalog["cappuccino"].directory;

    return new CFURL(FILE.join(CAPP_HOME, "lib", "xcodecapp", "Resources", "FIXME_parser.j"));
}

- (void)launch
{
    OS.system("open " + m_xCodeProjectFileURL);
}

- (void)prepare_xCodeProject
{
    m_xCodeProjectURL = new CFURL(".xCodeSupport", m_URL.asDirectoryPathURL());

    if (FILE.exists(m_xCodeProjectURL))
        FILE.rmtree(m_xCodeProjectURL);

    FILE.mkdir(m_xCodeProjectURL);

    var projectName = [self projectName],
        xCodeProjectTemplateURL = [self xCodeProjectTemplateURL];

    m_xCodeProjectFileURL = new CFURL(projectName + ".xcodeproj", m_xCodeProjectURL.asDirectoryPathURL());

    FILE.copyTree(xCodeProjectTemplateURL, m_xCodeProjectFileURL.absoluteURL());

    var pbxprojURL = new CFURL("project.pbxproj", m_xCodeProjectFileURL.asDirectoryPathURL()),
        pbxproj = FILE.read(pbxprojURL, { charset:"UTF-8" });

    pbxproj = pbxproj.replace(/\$\{CappuccinoProjectName\}/g, projectName);
    pbxproj = pbxproj.replace(/\$\{CappuccinoProjectRelativePath\}/g, FILE.join("..", "..", projectName));

    FILE.write(pbxprojURL, pbxproj, { charset:"UTF-8" });

    m_xCodeSupportSourcesURL = new CFURL("Sources", m_xCodeProjectURL.asDirectoryPathURL());

    FILE.mkdir(m_xCodeSupportSourcesURL);
}

- (void)update
{
    [self updateSourceFiles];
    [self updateNibFiles];
}

- (CPURL)shadowURLForSourceURL:(CPURL)aSourceURL
{
    var flattenedPath = (aSourceURL + "").replace(new RegExp("\/", "g"), "_"),
        extension = FILE.extension(flattenedPath),
        basename = flattenedPath.substr(0, flattenedPath.length - extension.length) + ".h";

    return new CFURL(basename, m_xCodeSupportSourcesURL.asDirectoryPathURL());
}

- (void)updateSourceFiles
{
    // Require the new parser for this.
    [m_sourceResourceMonitor update];

    [m_sourceResourceMonitor addedFilePaths].forEach(function(aFilePath)
    {
        print("Added " + aFilePath);
        OS.system("objj " + [self xCodeProjectParserURL] + " " + aFilePath + " " + [self shadowURLForSourceURL:aFilePath]);
    });

    [m_sourceResourceMonitor editedFilePaths].forEach(function(aFilePath)
    {
        print("Edited " + aFilePath);
        OS.system("objj " + [self xCodeProjectParserURL] + " " + aFilePath + " " + [self shadowURLForSourceURL:aFilePath]);
    });

    [m_sourceResourceMonitor removedFilePaths].forEach(function(aFilePath)
    {
        print("Removed " + aFilePath);
        FILE.remove([self shadowURLForSourceURL:aFilePath]);
    });
}

- (void)updateNibFiles
{
    [m_nibResourceMonitor update];

    [m_nibResourceMonitor addedFilePaths].forEach(function(aFilePath)
    {
        print("Added " + aFilePath);
        OS.system("nib2cib " + aFilePath);
        print("Conversion for " + aFilePath + ": done.");
    });

    [m_nibResourceMonitor editedFilePaths].forEach(function(aFilePath)
    {
        print("Edited " + aFilePath);
        OS.system("nib2cib " + aFilePath);
        print("Conversion for " + aFilePath + ": done.");
    });

    [m_nibResourceMonitor removedFilePaths].forEach(function(aFilePath)
    {
        // delete?
        print("Removed " + aFilePath);
        // OS.system("nib2cib " + aFilePath);
    });
}

@end
