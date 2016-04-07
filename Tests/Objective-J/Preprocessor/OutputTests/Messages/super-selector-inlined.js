var the_class=objj_allocateClassPair(Nil,"TheSuperClass"),meta_class=the_class.isa;
objj_registerClassPair(the_class);
var the_class=objj_allocateClassPair(Nil,"TheClass"),meta_class=the_class.isa;
objj_registerClassPair(the_class);
class_addMethods(the_class,[new objj_method(sel_getUid("xxxx:"),function $TheClass__xxxx_(_1,_2,_3){
(objj_getClass("TheClass").super_class.method_dtable["xxxx:"]||_objj_forward)(_1,"xxxx:",_3);
},["void","id"])]);