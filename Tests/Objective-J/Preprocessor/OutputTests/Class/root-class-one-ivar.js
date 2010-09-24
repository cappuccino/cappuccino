
var the_class = objj_allocateClassPair(Nil, "Class"),
    meta_class = the_class.isa;

class_addIvars(the_class,[new objj_ivar("ivar")]);

objj_registerClassPair(the_class);
