function printUsage(command)
{
    var usage = "usage: steam COMMAND [ARGS]\n\n"+
"The most commonly used steam commands are:\n"+
"\tbuild    Build a project\n"+
"\tcreate   Create a new project\n\n"+
"See 'steam help COMMAND' for more information on a specific command.";

    switch (command)
    {
        case  "--help":
        case undefined: java.lang.System.out.println(usage);
                        break;
            
        case  "create": java.lang.System.out.println("Creates a new Cappuccino project.\n\nusage: steam create PROJECT_NAME [-l]\n\n"+
                            "\t-l  Link Frameworks to $STEAM_BUILD/Release, instead of installing default Frameworks");
                        break;
        
        default:        java.lang.System.out.println("steam: '" + command + "' is not a steam command. See 'steam --help'.");
    }
    java.lang.System.exit(1);
}
