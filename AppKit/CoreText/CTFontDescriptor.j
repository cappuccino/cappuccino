@typedef CTFontSymbolicTraits

kCTFontTraitItalic       = (1 << 0);
kCTFontTraitBold         = (1 << 1);
kCTFontTraitExpanded     = (1 << 5);
kCTFontTraitCondensed    = (1 << 6);
kCTFontTraitMonoSpace    = (1 << 10);
kCTFontTraitVertical     = (1 << 11);
kCTFontTraitUIOptimized  = (1 << 12);
kCTFontTraitColorGlyphs  = (1 << 13);
kCTFontTraitComposite    = (1 << 14);

kCTFontClassMaskShift    = 28;

kCTFontTraitClassMask    = (15 << kCTFontClassMaskShift);

kCTFontItalicTrait       = kCTFontTraitItalic,
kCTFontBoldTrait         = kCTFontTraitBold,
kCTFontExpandedTrait     = kCTFontTraitExpanded,
kCTFontCondensedTrait    = kCTFontTraitCondensed,
kCTFontMonoSpaceTrait    = kCTFontTraitMonoSpace,
kCTFontVerticalTrait     = kCTFontTraitVertical,
kCTFontUIOptimizedTrait  = kCTFontTraitUIOptimized,
kCTFontColorGlyphsTrait  = kCTFontTraitColorGlyphs,
kCTFontCompositeTrait    = kCTFontTraitComposite,
kCTFontClassMaskTrait    = kCTFontTraitClassMask
