@import <Foundation/Foundation.j>

@import "Configuration.j"
@import "Generate.j"

var path = require("path");
var fs = require("fs");

function main(args) {
    var mainBundlePath = args.shift();

    if (args.length < 1) {
        return printUsage();
    }

    var count = args.length;

    for (var index = 0; index < count; ++index) {
        var argument = args[index];

        switch (argument) {
            case "version":
            case "--version":   return console.log(JSON.parse(fs.readFileSync('package.json', 'utf8')).version);

            case "-h":
            case "--help":      return printUsage();

            case "config":      return config.apply(this, args.slice(index + 1));

            case "gen":         return gen.apply(this, [mainBundlePath].concat(args.slice(index + 1)));

            default:            print("unknown command " + argument);
        }
    }
}

function printUsage() {
    print("capp [--version] COMMAND [OPTIONS] [ARGS]");
    print("    --version    Print version");
    print("    -h, --help   Print this help");
    print("");
    print("  gen [OPTIONS] PATH       Generate a new project at PATH from a predefined template");
    print("      -l                     Same as --symlink --build, symlinks $CAPP_BUILD Frameworks into your project");
    print("      -t, --template NAME    Specify the template name to use (see `capp gen --list-templates`)");
    print("      -f, --frameworks       Copy/symlink *only* the Frameworks directory to a new or existing project");
    print("      -F, --framework NAME   Additional framework to copy/symlink (default: Objective-J, Foundation, AppKit)");
    print("      -T, --theme NAME       Additional Theme to copy/symlink into Resource (default: nothing)");
    print("      --force                Overwrite Frameworks directory if it already exists");
    print("      --symlink              Symlink the source Frameworks directory to the project, don't copy");
    print("      --build                Copy/symlink the Frameworks directory files from your $CAPP_BUILD directory");
    print("      --noconfig             Use the default configuration when replacing template variables");
    print("");
    print("      Without -l or --build, frameworks from your narwhal installation are copied/symlinked");
    print("");
    print("  gen --list-templates     List the template names available for use with `capp gen -t/--template`");
    print("  gen --list-frameworks    List the framework names available for use with `capp gen -F/--framework`");
    print("");
    print("  config ...");
    print("      KEY VALUE       Set a value for a given key");
    print("      -l, --list      List all variables set in config file.");
    print("      --get KEY       Get the value for a given key");
    print("      --remove KEY    Remove the value for a given key");
}
