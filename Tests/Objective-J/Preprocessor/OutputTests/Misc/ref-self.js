{var the_class = objj_allocateClassPair(Nil, "TC"),
meta_class = the_class.isa;class_addIvars(the_class, [new objj_ivar("_control","id")]);objj_registerClassPair(the_class);
class_addMethods(the_class, [new objj_method(sel_getUid("a"), function $TC__a(self, _cmd)
{
    function(__input) { if (arguments.length) return self._control = __input; return self._control; };
}

,["id"])]);
}
