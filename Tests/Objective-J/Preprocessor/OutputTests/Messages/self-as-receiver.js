var the_class=objj_allocateClassPair(Nil,"MyClass"),meta_class=the_class.isa;
objj_registerClassPair(the_class);
class_addMethods(the_class,[new objj_method(sel_getUid("mySelector"),function $MyClass__mySelector(_1,_2){
_1.isa.objj_msgSend0(_1,"init");
_1=nil;
(_1==null?null:_1.isa.objj_msgSend0(_1,"init"));
},["id"]),new objj_method(sel_getUid("mySelector2"),function $MyClass__mySelector2(_3,_4){
_3.isa.objj_msgSend0(_3,"init");
eval("self = null;");
(_3==null?null:_3.isa.objj_msgSend0(_3,"init"));
},["id"])]);