var the_class=objj_allocateClassPair(Nil,"TestClass"),meta_class=the_class.isa;
objj_registerClassPair(the_class);
var the_class=objj_getClass("TestClass");
if(!the_class){
throw new SyntaxError("*** Could not find definition for class \"TestClass\"");
}
var meta_class=the_class.isa;
class_addIvars(the_class,[new objj_ivar("ivar","Type")]);
class_addMethods(the_class,[new objj_method(sel_getUid("ivar"),function $TestClass__ivar(_1,_2){
return _1.ivar;
},["Type"]),new objj_method(sel_getUid("setIvar:"),function $TestClass__setIvar_(_3,_4,_5){
_3.ivar=_5;
},["void","Type"])]);

