
var the_class = objj_allocateClassPair(Nil, "Class"),
    meta_class = the_class.isa;

class_addIvars(the_class,[new objj_ivar("ivar"), new objj_ivar("array"), new objj_ivar("string"), new objj_ivar("integer")]);

objj_registerClassPair(the_class);
