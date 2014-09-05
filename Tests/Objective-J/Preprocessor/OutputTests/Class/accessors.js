var the_class=objj_allocateClassPair(Nil,"Class"),meta_class=the_class.isa;
objj_registerClassPair(the_class);
var the_class=objj_getClass("Class");
if(!the_class){
throw new SyntaxError("*** Could not find definition for class \"Class\"");
}
var meta_class=the_class.isa;
class_addIvars(the_class,[new objj_ivar("ivar")]);
class_addMethods(the_class,[new objj_method(sel_getUid("ivar"),function $Class__ivar(_1,_2){
return _1.ivar;
},["Type"]),new objj_method(sel_getUid("setIvar:"),function $Class__setIvar_(_3,_4,_5){
_3.ivar=_5;
},["void","Type"])]);