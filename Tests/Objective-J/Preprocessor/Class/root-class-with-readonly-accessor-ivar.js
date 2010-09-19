
var the_class = objj_allocateClassPair(Nil, "Class"),
    meta_class = the_class.isa;

class_addIvars(the_class,[new objj_ivar("array")]);
the_class.ivars[0].accessors = { "get" : "array" };

objj_registerClassPair(the_class);
class_addMethods(the_class,[new objj_method(sel_getUid("array"),function(_1,_2){
with(_1){
return array;
}
})]);
