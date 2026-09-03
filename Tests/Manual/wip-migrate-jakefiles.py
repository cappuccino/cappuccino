#!/usr/bin/env python3
"""
Migrate Cappuccino integration-test Jakefiles under Tests/Manual from the
Narwhal-hosted format to the Node-hosted format.

Each Jakefile is updated in place: the leading file-metadata comment block
at the top of the file is left untouched, and everything after it is fully
replaced with the non-metadata content of JakefileNew (the template),
substituted with per-app values.

Six lines are copied from the legacy file, each tested for existence
independently -- any that aren't present fall back to the template's own
literal default:

    task.setProductName("capp-modernize");
    task.setIdentifier("com.yourcompany.cappModernize");
    task.setVersion("1.0");
    task.setAuthor("Your Company");
    task.setEmail("feedback @nospam@ yourcompany.com");
    task.setSummary("capp-modernize");

Nothing else is extracted -- sources/resources/index/info-plist paths,
compiler flags, OBJJ_INCLUDE_PATHS, app-size tracking, task list, etc. all
come from the template unchanged.

The internal `projectName` variable (used in the app(...) call and all
build-path joins) is not one of the six copied fields -- it's taken from
the containing directory name, since it must be unique per app and the
old file's app(...) call is not reliably a string literal.

This is a full technical-debt pass: every Jakefile under the given root
is updated, including ones already hand-updated to Node idioms. Before
any file is overwritten, the original is copied to JakefileBackup in the
same directory.

Some test application directories have no Jakefile at all. These are
detected by the presence of Info.plist or index.html with no sibling
Jakefile, and are reported and skipped rather than guessed at.

Usage:
    python3 migrate-jakefiles.py [--apply]

Default is a dry run: prints what would happen, writes nothing.
--apply performs the migration.
"""

import argparse
import re
import shutil
import sys
from pathlib import Path
from string import Template

HEADER_RE = re.compile(r'\A\s*/\*.*?\*/\s*', re.DOTALL)

FIELD_PATTERNS = {
    "product_name": r'task\.setProductName\(\s*"([^"]*)"\s*\)',
    "identifier": r'task\.setIdentifier\(\s*"([^"]*)"\s*\)',
    "version": r'task\.setVersion\(\s*"([^"]*)"\s*\)',
    "author": r'task\.setAuthor\(\s*"([^"]*)"\s*\)',
    "email": r'task\.setEmail\(\s*"([^"]*)"\s*\)',
    "summary": r'task\.setSummary\(\s*"([^"]*)"\s*\)',
}

# Literal defaults, taken verbatim from JakefileNew -- used only when the
# corresponding line is absent from the legacy file.
DEFAULTS = {
    "product_name": "capp-modernize",
    "identifier": "com.yourcompany.cappModernize",
    "version": "1.0",
    "author": "Your Company",
    "email": "feedback @nospam@ yourcompany.com",
    "summary": "capp-modernize",
}

# JakefileNew's non-metadata content, verbatim, with $-style placeholders
# for project_name (directory-derived) and the six copied fields.
BODY_TEMPLATE = Template('''const path = require("path");
const fs = require("fs");

var ENV = process.env,
    task = JAKE.task,
    FileList = JAKE.FileList,
    app = CAPPUCCINO.Jake.applicationtask.app,
    configuration = ENV["CONFIG"] || ENV["CONFIGURATION"] || ENV["c"] || "Debug",
    OS = require("os"),
    projectName = "$project_name",
    productName = "$product_name";

var buildDir = path.resolve(ENV["BUILD_PATH"] || ENV["CAPP_BUILD"] || "Build");

app (projectName, function(task)
{
    ENV["OBJJ_INCLUDE_PATHS"] = "Frameworks";

    if (configuration === "Debug")
        ENV["OBJJ_INCLUDE_PATHS"] = path.join(ENV["OBJJ_INCLUDE_PATHS"], configuration);

    task.setBuildIntermediatesPath(path.join(buildDir, projectName + ".build", configuration));
    task.setBuildPath(path.join(buildDir, configuration));

    task.setProductName(productName);
    task.setIdentifier("$identifier");
    task.setVersion("$version");
    task.setAuthor("$author");
    task.setEmail("$email");
    task.setSummary("$summary");
    task.setSources(new FileList("**/*.j").exclude(path.join("Build", "**")).exclude(path.join("Frameworks", "Source", "**")));
    task.setResources(new FileList("Resources/**"));
    task.setIndexFilePath("index.html");
    task.setInfoPlistPath("Info.plist");

    if (configuration === "Debug")
        task.setCompilerFlags("-DDEBUG -g -S --inline-msg-send");
    else
        task.setCompilerFlags("-O2");
});

task ("default", [projectName], function()
{
    printResults(configuration);
});

task ("build", ["default"], function()
{
    updateApplicationSize();
});

task ("debug", function()
{
    configuration = ENV["CONFIGURATION"] = "Debug";
    JAKE.subjake(["."], "build", ENV);
});

task ("release", function()
{
    configuration = ENV["CONFIGURATION"] = "Release";
    JAKE.subjake(["."], "build", ENV);
});

task ("run", ["debug"], function()
{
    OS.system(["open", path.join(buildDir, "Debug", productName, "index.html")]);
});

task ("run-release", ["release"], function()
{
    OS.system(["open", path.join(buildDir, "Release", productName, "index.html")]);
});

task ("deploy", ["release"], function()
{
    FILE.mkdirs(path.join(buildDir, "Deployment", productName));
    OS.system(["press", "-f", path.join(buildDir, "Release", productName), path.join(buildDir, "Deployment", productName)]);
    printResults("Deployment")
});

function printResults(configuration)
{
    console.log("----------------------------");
    console.log(configuration+" app built at path: " + path.join(buildDir, configuration, productName));
    console.log("----------------------------");
}

function updateApplicationSize()
{
    console.log("Calculating application file sizes...");

    var contents = fs.readFileSync(path.join(buildDir, configuration, productName, "Info.plist"), { encoding: "utf8" }),
        format = CFPropertyList.sniffedFormatOfString(contents),
        plist = CFPropertyList.propertyListFromString(contents),
        totalBytes = {executable:0, data:0, mhtml:0};

    // Get the size of all framework executables and sprite data
    var frameworksDir = "Frameworks";

    if (configuration === "Debug")
        frameworksDir = path.join(frameworksDir, "Debug");

    var frameworks = [];

    if (fs.existsSync(frameworksDir)) {
        frameworks = fs.readdirSync(frameworksDir);
    }

    frameworks.forEach(function(framework)
    {
        if (framework !== "Source")
            addBundleFileSizes(path.join(frameworksDir, framework), totalBytes);
    });

    // Read in the default theme name, and attempt to get its size
    var themeName = plist.valueForKey("CPDefaultTheme") || "Aristo2",
        themePath = nil;

    if (themeName === "Aristo" || themeName === "Aristo2")
        themePath = path.join(frameworksDir, "AppKit", "Resources", themeName + ".blend");
    else
        themePath = path.join("Frameworks", "Resources", themeName + ".blend");

    if (fs.existsSync(themePath) && fs.lstatSync(themePath).isDirectory())
        addBundleFileSizes(themePath, totalBytes);

    // Add sizes for the app
    addBundleFileSizes(path.join(buildDir, configuration, productName), totalBytes);

    console.log("Executables: " + totalBytes.executable + ", sprite data: " + totalBytes.data + ", total: " + (totalBytes.executable + totalBytes.data));

    var dict = new CFMutableDictionary();

    dict.setValueForKey("executable", totalBytes.executable);
    dict.setValueForKey("data", totalBytes.data);
    dict.setValueForKey("mhtml", totalBytes.mhtml);

    plist.setValueForKey("CPApplicationSize", dict);
    fs.writeFileSync(path.join(buildDir, configuration, productName, "Info.plist"), CFPropertyList.stringFromPropertyList(plist, format), { encoding: "utf8" });
}

function addBundleFileSizes(bundlePath, totalBytes)
{
    var bundleName = path.basename(bundlePath),
        environment = bundleName === "Foundation" ? "Objj" : "Browser",
        bundlePath = path.join(bundlePath, environment + ".environment");

    if (fs.existsSync(bundlePath) && fs.lstatSync(bundlePath).isDirectory())
    {
        var filename = bundleName + ".sj",
            filePath = path.join(bundlePath, filename);

        if (fs.existsSync(filePath)) {
            totalBytes.executable += fs.lstatSync(filePath).size;
        }

        filePath = path.join(bundlePath, "dataURLs.txt");

        if (fs.existsSync(filePath))
            totalBytes.data += fs.lstatSync(filePath).size;

        filePath = path.join(bundlePath, "MHTMLData.txt");

        if (fs.existsSync(filePath))
            totalBytes.mhtml += fs.lstatSync(filePath).size;

        filePath = path.join(bundlePath, "MHTMLPaths.txt");

        if (fs.existsSync(filePath))
            totalBytes.mhtml += fs.lstatSync(filePath).size;
    }
}
''')


def migrate_file(jakefile_path, apply_changes):
    text = jakefile_path.read_text()
    project_name = jakefile_path.parent.name

    header_match = HEADER_RE.match(text)
    header = header_match.group(0).rstrip("\n") if header_match else ""

    fields = {"project_name": project_name}
    for name, pattern in FIELD_PATTERNS.items():
        m = re.search(pattern, text)
        fields[name] = m.group(1) if m else DEFAULTS[name]

    body = BODY_TEMPLATE.substitute(fields)
    new_content = (header + "\n\n" if header else "") + body

    if apply_changes:
        backup_path = jakefile_path.with_name("JakefileBackup")
        if not backup_path.exists():
            shutil.copy2(jakefile_path, backup_path)
        jakefile_path.write_text(new_content)


def find_missing_jakefile_dirs(root, jakefile_dirs):
    """Directories that look like app roots (contain Info.plist or
    index.html) but have no Jakefile of their own."""
    candidates = set()
    for marker in ("Info.plist", "index.html"):
        for p in root.rglob(marker):
            if any(part in ("Frameworks", ".Frameworks") for part in p.parts):
                continue
            candidates.add(p.parent)
    return sorted(candidates - jakefile_dirs)


def main():
    parser = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("--apply", action="store_true", help="write changes (default is dry run)")
    args = parser.parse_args()

    root = Path(".")

    manual_jakefile = (root / "Jakefile").resolve()

    jakefiles = sorted(
        p for p in root.rglob("Jakefile")
        if not any(part in ("Frameworks", ".Frameworks") for part in p.parts)
        and p.resolve() != manual_jakefile
    )
    jakefile_dirs = {jf.parent for jf in jakefiles}
    missing_dirs = find_missing_jakefile_dirs(root, jakefile_dirs)

    if not jakefiles and not missing_dirs:
        sys.exit(f"no Jakefiles or app directories found under {root}")

    migrated_count = 0
    for jf in jakefiles:
        migrate_file(jf, args.apply)
        migrated_count += 1

    for d in missing_dirs:
        print(f"[       no Jakefile] {d}: skipped -- no Jakefile present")

    verb = "migrated" if args.apply else "would migrate"
    print()
    print(f"Summary: {migrated_count} {verb}, {len(missing_dirs)} no Jakefile")

    if not args.apply:
        print("\nDry run only -- re-run with --apply to write changes.")


if __name__ == "__main__":
    main()
