# -*- coding: utf-8 -*-
import os.path
import re
import sys
from mod_pbxproj import XcodeProject

XCODE_SUPPORT_FOLDER = ".XcodeSupport"
SLASH_REPLACEMENT  = u"∕"  # DIVISION SLASH  Unicode U+2215
STRING_RE = re.compile(ur"^\s*<string>(.*)</string>\s*$", re.MULTILINE)
FRAMEWORKS_RE = re.compile(ur"^(.+/Frameworks/(?:Debug|Source)/([^/]+))/.+$")
XCC_GENERAL_INCLUDE = u"xcc_general_include.h"


def update_general_include(project, projectBasePath, shadowGroup):
    xcc_general_include_path = os.path.join(projectBasePath, XCODE_SUPPORT_FOLDER, XCC_GENERAL_INCLUDE)
    content = u""

    for path in os.listdir(os.path.join(projectBasePath, XCODE_SUPPORT_FOLDER)):
        filename = unicode(os.path.basename(path))

        if filename.endswith(".h") and filename != XCC_GENERAL_INCLUDE:
            content += u'#include "{0}"\n'.format(filename)

    f = open(xcc_general_include_path, "w")
    f.write(content.encode("utf-8"))
    f.close()

    if len(project.get_files_by_os_path(os.path.join(XCODE_SUPPORT_FOLDER, XCC_GENERAL_INCLUDE))) == 0:
        project.add_file(xcc_general_include_path, parent=shadowGroup)

def file_with_path(path, projectPath, project):
    relPath = os.path.relpath(path, projectPath)

    for fileRef in [f for f in project.objects.values() if f.get("isa") == "PBXFileReference"]:
        filePath = path if fileRef.get("sourceTree") == "<absolute>" else relPath

        if fileRef.get("path") == filePath:
            return fileRef

    return None

def add_file(project, shadowGroup, sourceGroup, shadowHeaderPath, shadowImplementationPath, sourcePath, projectBasePath):
    # Shadow files are always project-relative
    if not file_with_path(shadowHeaderPath, projectBasePath, project):
        project.add_file(shadowHeaderPath, parent=shadowGroup, tree="SOURCE_ROOT", create_build_files=False)

    if not file_with_path(shadowImplementationPath, projectBasePath, project):
        project.add_file(shadowImplementationPath, parent=shadowGroup, tree="SOURCE_ROOT", create_build_files=False)

    # If the file is within the project directory, the file reference will be project-relative, otherwise absolute
    if sourcePath.startswith(projectBasePath):
        tree = "SOURCE_ROOT"
    else:
        tree = "<absolute>"

    if not file_with_path(sourcePath, projectBasePath, project):
        project.add_file(sourcePath, parent=sourceGroup, tree=tree, create_build_files=False)

def remove_file(project, shadowGroup, sourceGroup, shadowHeaderPath, shadowImplementationPath, sourcePath, projectBasePath):
    for path in (shadowHeaderPath, shadowImplementationPath, sourcePath):
        fileRef = file_with_path(path, projectBasePath, project)

        if fileRef:
            project.remove_file(fileRef)

def xml_converter(matchObj):
    return "<string>{0}</string>".format(matchObj.group(1).encode('ascii', 'xmlcharrefreplace'))

def convert_unicode_to_xml(path):
    """
        mod_pbxproj writes unicode data as utf-8, but since it's an xml plist
        all non-ascii characters should be converted to xml character references.
        So we do that as a post-processing phase.
        """
    with open(path, 'rb') as f:
        content = f.read().decode('utf-8')

    with open(path, "wb") as f:
        content = STRING_RE.sub(xml_converter, content)
        f.write(content)

def add_framework_resources(project, framework, resourcesPath):
    files = project.get_files_by_os_path(resourcesPath, tree="<absolute>")

    if not files:
        files = project.add_file(resourcesPath, parent=None, tree="<absolute>", create_build_files=False)

        if files:
            files[0]['name'] = framework + " Resources"

def save_project(project, pbxPath):
    project.save()
    convert_unicode_to_xml(pbxPath)


if __name__ == "__main__":

    action = sys.argv[1]

    if action in ("add", "remove"):
        projectBasePath = unicode(sys.argv[2])
        projectSourcePath = unicode(sys.argv[3])
        sourcePath = os.path.realpath(projectSourcePath)

        shadowBasePath = os.path.join(projectBasePath, XCODE_SUPPORT_FOLDER)
        shadowBaseName = os.path.splitext(sourcePath)[0].replace(u"/", SLASH_REPLACEMENT)
        shadowHeaderPath = os.path.join(shadowBasePath, shadowBaseName + ".h")
        shadowImplementationPath = os.path.join(shadowBasePath, shadowBaseName + ".m")
        projectName = os.path.basename(projectBasePath)
        pbxPath = os.path.join(projectBasePath, projectName + ".xcodeproj", "project.pbxproj")

        project = XcodeProject.Load(pbxPath)

        shadowGroup = project.get_or_create_group("Classes")
        sourceGroup = project.get_or_create_group("Sources")

        if action == "add":
            fileRef = file_with_path(shadowHeaderPath, projectBasePath, project)

            if not fileRef:
                update_general_include(project, projectBasePath, shadowGroup)
                add_file(project, shadowGroup, sourceGroup, shadowHeaderPath, shadowImplementationPath, sourcePath, projectBasePath)

            match = FRAMEWORKS_RE.match(projectSourcePath)

            if match:
                framework = match.group(2)
                resourcesPath = os.path.realpath(os.path.join(match.group(1), "Resources"))

                if os.path.isdir(resourcesPath):
                    add_framework_resources(project, framework, resourcesPath)

            save_project(project, pbxPath)

        elif action == "remove":
            update_general_include(project, projectBasePath, shadowGroup)
            remove_file(project, shadowGroup, sourceGroup, shadowHeaderPath, shadowImplementationPath, sourcePath, projectBasePath)
            save_project(project, pbxPath)
