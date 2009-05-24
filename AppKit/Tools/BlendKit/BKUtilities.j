
@implementation BKThemeTemplate : CPObject
{
    CPString    _name;
    CPString    _description;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        _name = [aCoder decodeObjectForKey:@"BKThemeTemplateName"];
        _description = [aCoder decodeObjectForKey:@"BKThemeTemplateDescription"];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_name forKey:@"BKThemeTemplateName"];
    [aCoder encodeObject:_description forKey:@"BKThemeTemplateDescription"];
}

@end

@implementation BKThemeObjectTemplate : CPView
{
    CPString    _label;
    id          _themedObject;
}

- (id)initWithCoder:(CPCoder)aCoder
{
    self = [super init];
    
    if (self)
    {
        _label = [aCoder decodeObjectForKey:@"BKThemeObjectTemplateLabel"];
        _themedObject = [aCoder decodeObjectForKey:@"BKThemeObjectTemplateThemedObject"];
    }
    
    return self;
}

- (void)encodeWithCoder:(CPCoder)aCoder
{
    [aCoder encodeObject:_label forKey:@"BKThemeObjectTemplateLabel"];
    [aCoder encodeObject:_themedObject forKey:@"BKThemeObjectTemplateThemedObject"];
}

@end
