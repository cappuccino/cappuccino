
#define DEPENDENCY_LOGGING      0
#define EXECUTION_LOGGING       0

#if BROWSER
#define CPLog console.log
#else
#define CPLog print
#endif