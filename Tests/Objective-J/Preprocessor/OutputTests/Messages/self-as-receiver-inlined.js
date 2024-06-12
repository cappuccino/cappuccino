var the_class=objj_allocateClassPair(Nil,"MyClass"),meta_class=the_class.isa;
objj_registerClassPair(the_class);
class_addMethods(the_class,[new objj_method(sel_getUid("mySelector"),function $MyClass__mySelector(_1,_2){
(_1.isa.method_msgSend["init"]||_objj_forward)(_1,"init");
_1=nil;
(_1==null?_1:(_1.isa.method_msgSend["init"]||_objj_forward)(_1,"init"));
},["id"]),new objj_method(sel_getUid("mySelector2"),function $MyClass__mySelector2(self,_cmd){
(self.isa.method_msgSend["init"]||_objj_forward)(self,"init");
eval("self = null;");
(self==null?self:(self.isa.method_msgSend["init"]||_objj_forward)(self,"init"));
},["id"])]);