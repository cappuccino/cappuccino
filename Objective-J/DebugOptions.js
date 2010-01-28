
#define DEPENDENCY_LOGGING      1
#define STATIC_RESOURCE_LOGGING 1
#define EXECUTION_LOGGING       1

#if BROWSER
#define CPLog console.log
#else
#define CPLog print
#endif