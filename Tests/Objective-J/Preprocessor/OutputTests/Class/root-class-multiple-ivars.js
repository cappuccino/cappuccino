var the_class = objj_allocateClassPair(Nil, "TestClass"),
    meta_class = the_class.isa;

class_addIvars(the_class,[new objj_ivar("ivar","Type"), new objj_ivar("array","CPArray"), new objj_ivar("string","CPString"), new objj_ivar("integer","int")]);

objj_registerClassPair(the_class);
