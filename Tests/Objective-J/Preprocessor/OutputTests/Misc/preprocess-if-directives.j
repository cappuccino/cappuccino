#define xxxx 3
#ifndef carlberg
  var name = "Martin"
  #if xxxx == 3
    var verb = "Was";
    #ifdef yyyy
      var action = "Home";
    #else
      #if zzzzz
        var action = "Away";
      #else
        var action = "Here"
      #endif
    #endif
  #else
    var verb = "is";
  #endif
#else
  var name = "Alexander";
#endif

#define f(x) x > 3

if (f(4)) var a = 3;
