# -*- coding: utf-8 -*-
import os.path
import re
import sys
from mod_pbxproj import XcodeProject

XCODESUPPORTFOLDER = ".XcodeSupport"
SLASH_REPLACEMENT  = u"∕"  # DIVISION SLASH  Unicode U+2215
STRING_RE = re.compile(ur"^\s*<string>(.*)</string>\s*$", re.MULTILINE)
FRAMEWORKS_RE = re.compile(ur"^(.+/Frameworks/Debug/([^/]+))/.+$")


def update_general_include(project, projectBasePath):
    xcc_general_include_file = os.path.join(projectBasePath, XCODESUPPORTFOLDER, u"xcc_general_include.h")
    content = u""

    for file in os.listdir(os.path.join(projectBasePath, XCODESUPPORTFOLDER)):
        if file.endswith(".h"):
            content += u'#include "{0}"\n'.format(os.path.basename(unicode(file)))

    f = open(xcc_general_include_file, "w")
    f.write(content.encode("utf-8"))
    f.close()

    if len(project.get_files_by_os_path(os.path.join(XCODESUPPORTFOLDER, os.path.basename(xcc_general_include_file)))) == 0:
        project.add_file(xcc_general_include_file, parent=shadowGroup)

def add_file(project, shadowGroup, sourceGroup, shadowHeaderPath, shadowImplementationFilePath, sourcePath, projectBasePath):
    project.add_file(shadowHeaderPath, parent=shadowGroup)
    project.add_file(shadowImplementationFilePath, parent=shadowGroup)

    if sourcePath in project.get_files_by_os_path(os.path.relpath(sourcePath, projectBasePath)):
        return

    project.add_file(sourcePath, parent=sourceGroup)

def remove_file(project, shadowGroup, sourceGroup, shadowHeaderPath, shadowImplementationFilePath, sourcePath, projectBasePath):
    project.remove_file(os.path.join(XCODESUPPORTFOLDER, os.path.basename(shadowHeaderPath)), parent=shadowGroup)
    project.remove_file(os.path.join(XCODESUPPORTFOLDER, os.path.basename(shadowImplementationFilePath)), parent=shadowGroup)
    project.remove_file(os.path.relpath(sourcePath, projectBasePath), parent=sourceGroup)

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

def add_framework_resources(project, resourcesPath):
    realPath = os.path.realpath(resourcesPath)
    files = project.get_files_by_os_path(realPath, tree="<absolute>")

    if not files:
        files = project.add_file(realPath, parent=None, tree="<absolute>", create_build_files=False)

        if files:
            framework = os.path.basename(os.path.dirname(resourcesPath))
            files[0]['name'] = framework + " Resources"


if __name__ == "__main__":

    action = sys.argv[1]

    if action in ("add", "remove"):
        projectBasePath = unicode(sys.argv[2])
        projectSourcePath = unicode(sys.argv[3])
        sourcePath = os.path.realpath(projectSourcePath)

        shadowBasePath = os.path.join(projectBasePath, ".XcodeSupport")
        shadowBasename = os.path.splitext(sourcePath)[0].replace(u"/", SLASH_REPLACEMENT)
        shadowHeaderPath = os.path.join(shadowBasePath, shadowBasename + ".h")
        shadowImplementationPath = os.path.join(shadowBasePath, shadowBasename + ".m")
        projectName = os.path.basename(projectBasePath)
        pbxPath = os.path.join(projectBasePath, projectName + ".xcodeproj", "project.pbxproj")

        project = XcodeProject.Load(pbxPath)

        shadowGroup = project.get_or_create_group("Classes")
        sourceGroup = project.get_or_create_group("Sources")

        files = project.get_files_by_os_path(os.path.join(XCODESUPPORTFOLDER, os.path.basename(shadowHeaderPath)))

        if action == "add":
            if len(files) == 0:
                update_general_include(project, projectBasePath)
                add_file(project, shadowGroup, sourceGroup, shadowHeaderPath, shadowImplementationPath, sourcePath, projectBasePath)

            match = FRAMEWORKS_RE.match(projectSourcePath)

            if match:
                framework = match.group(2)
                resourcesPath = os.path.join(match.group(1), "Resources")

                if os.path.isdir(resourcesPath):
                    add_framework_resources(project, resourcesPath)

            project.save()
            convert_unicode_to_xml(pbxPath)

        elif action == "remove" and len(files) == 1:
            update_general_include(project, projectBasePath)
            remove_file(project, shadowGroup, sourceGroup, shadowHeaderPath, shadowImplementationPath, sourcePath, projectBasePath)
            project.save()
