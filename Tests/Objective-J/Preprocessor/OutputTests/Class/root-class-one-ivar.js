
var the_class = objj_allocateClassPair(Nil, "TestClass"),
    meta_class = the_class.isa;

class_addIvars(the_class,[new objj_ivar("ivar","Type")]);

objj_registerClassPair(the_class);
