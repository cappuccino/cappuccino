# -*- coding: utf-8 -*-
import os.path
import re
import sys
from mod_pbxproj import XcodeProject


class PBXModifier (object):

    XCODE_SUPPORT_FOLDER = u".XcodeSupport"
    SLASH_REPLACEMENT  = u"∕"  # DIVISION SLASH  Unicode U+2215
    FRAMEWORKS_RE = re.compile(ur"^(.+/Frameworks/(?:Debug|Source)/([^/]+))/.+$")
    XCC_GENERAL_INCLUDE = u"xcc_general_include.h"

    def __init__(self, projectRootPath=None):
        self.projectRootPath = projectRootPath
        projectName = os.path.basename(projectRootPath)
        self.pbxPath = os.path.join(projectRootPath, projectName + u".xcodeproj", u"project.pbxproj")
        self.project = XcodeProject.Load(self.pbxPath)

        self._shadowGroup = None
        self._sourceGroup = None
        self._frameworksGroup = None

    @property
    def frameworksGroup(self):
        if self._frameworksGroup is None:
            self._frameworksGroup = self.project.get_or_create_group(u"Frameworks", parent=self.sourceGroup)

        return self._frameworksGroup

    @property
    def shadowGroup(self):
        if self._shadowGroup is None:
            self._shadowGroup = self.project.get_or_create_group(u"Cocoa Classes")

        return self._shadowGroup

    @property
    def sourceGroup(self):
        if self._sourceGroup is None:
            self._sourceGroup = self.project.get_or_create_group(u"Cappuccino Source")

        return self._sourceGroup

    def update_general_include(self):
        xcc_general_include_path = os.path.join(self.projectRootPath, self.XCODE_SUPPORT_FOLDER, self.XCC_GENERAL_INCLUDE)
        content = u""

        for path in os.listdir(os.path.join(self.projectRootPath, self.XCODE_SUPPORT_FOLDER)):
            filename = unicode(os.path.basename(path))

            if filename.endswith(".h") and filename != self.XCC_GENERAL_INCLUDE:
                content += u'#include "{0}"\n'.format(filename)

        f = open(xcc_general_include_path, "w")
        f.write(content.encode("utf-8"))
        f.close()

        if len(self.project.get_files_by_os_path(os.path.join(self.XCODE_SUPPORT_FOLDER, self.XCC_GENERAL_INCLUDE))) == 0:
            self.project.add_file(xcc_general_include_path, parent=self.shadowGroup)

    def file_with_path(self, projectSourcePath):
        relativePath = os.path.relpath(projectSourcePath, self.projectRootPath)

        for fileRef in [f for f in self.project.objects.values() if f.get("isa") == "PBXFileReference"]:
            filePath = projectSourcePath if fileRef.get("sourceTree") == "<absolute>" else relativePath

            if fileRef.get("path") == filePath:
                return fileRef

        return None

    def group_with_name(self, name):
        groups = self.project.get_groups_by_name(name)

        return groups[0] if len(groups) == 1 else None

    def add_file(self, projectSourcePath, shadowHeaderPath, shadowImplementationPath):
        resolvedPath = os.path.realpath(projectSourcePath)

        # Shadow files are always project-relative
        if not self.file_with_path(shadowHeaderPath):
            self.project.add_file(shadowHeaderPath, parent=self.shadowGroup, tree="SOURCE_ROOT", create_build_files=False)

        if not self.file_with_path(shadowImplementationPath):
            self.project.add_file(shadowImplementationPath, parent=self.shadowGroup, tree="SOURCE_ROOT", create_build_files=False)

        # If the file is within the project directory, the file reference will be project-relative, otherwise absolute
        if resolvedPath.startswith(self.projectRootPath):
            tree = "SOURCE_ROOT"
        else:
            tree = "<absolute>"

        if not self.file_with_path(resolvedPath):
            relativePath = os.path.relpath(projectSourcePath, self.projectRootPath)

            if relativePath.startswith(u"Frameworks/"):
                parent = self.frameworksGroup
            else:
                parent = self.sourceGroup

            self.project.add_file(resolvedPath, parent=parent, tree=tree, create_build_files=False)

    def remove_file(self, projectSourcePath, shadowHeaderPath, shadowImplementationPath):
        resolvedPath = os.path.realpath(projectSourcePath)

        for path in (shadowHeaderPath, shadowImplementationPath, resolvedPath):
            fileRef = self.file_with_path(path)

            if fileRef:
                self.project.remove_file(fileRef)

    def add_framework_resources(self, framework, resourcesPath):
        files = self.project.get_files_by_os_path(resourcesPath, tree="<absolute>")

        if not files:
            files = self.project.add_file(resourcesPath, parent=None, tree="<absolute>", create_build_files=False)

            if files:
                files[0]['name'] = framework + u" Resources"

    def compare_file_ids(self, id1, id2):
        # A few special cases:
        # - Frameworks group always goes last
        # - XCC_GENERAL_INCLUDE always goes after another file
        # - Frameworks/* file always goes after a non-Frameworks file
        obj1 = self.project.get_obj(id1)
        name1 = obj1.get("name", obj1.get("path"))

        obj2 = self.project.get_obj(id2)
        name2 = obj2.get("name", obj2.get("path"))

        # Note: the "∕" in "Frameworks∕" is actually Unicode DIVISION_SLASH, not SOLIDUS (forward slash)
        if name1 == u"Frameworks" and obj1.get("isa") == u"PBXGroup":
            return 1
        elif name2 == u"Frameworks" and obj2.get("isa") == u"PBXGroup":
            return -1
        elif name1 == self.XCC_GENERAL_INCLUDE and obj2.get("isa") == u"PBXFileReference":
            return 1
        elif name2 == self.XCC_GENERAL_INCLUDE and obj1.get("isa") == u"PBXFileReference":
            return -1
        elif name1.startswith(u"Frameworks∕") and not name2.startswith(u"Frameworks∕"):
            return 1
        elif name2.startswith(u"Frameworks∕") and not name1.startswith(u"Frameworks∕"):
            return -1

        return cmp(name1.lower(), name2.lower())

    def compare_resource_folder_ids(self, id1, id2):
        folder1 = self.project.get_obj(id1)
        name1 = folder1.get("name", folder1.get("path"))

        folder2 = self.project.get_obj(id2)
        name2 = folder2.get("name", folder2.get("path"))

        if name1 == u"Resources":
            return -1
        elif name2 == u"Resources":
            return 1

        return cmp(name1.lower(), name2.lower())

    def sort_project(self):
        # Sort the files alphabetically in our groups.
        for group in (self.sourceGroup, self.shadowGroup, self._frameworksGroup):
            if group is None:
                continue

            group.get("children").data.sort(cmp=self.compare_file_ids)

        # Move resource folders to the top, Resources at the very top
        root_ids = self.project.root_group.get("children").data
        folder_ids = []

        for id in root_ids:
            item = self.project.get_obj(id)
            name = item.get("name", item.get("path"))

            if name.endswith(u"Resources") and item.get("lastKnownFileType") == "folder":
                folder_ids.append(id)

        folder_ids.sort(cmp=self.compare_resource_folder_ids, reverse=True)

        for id in folder_ids:
            index = root_ids.index(id)
            del root_ids[index]
            root_ids.insert(0, id)

    def save_project(self):
        if self.project.modified:
            self.project.backup(backup_name=self.project.pbxproj_path + ".backup")
            self.sort_project()
            self.project.saveFormat3_2()

    def update_project_with_source(self, action, projectSourcePath):
        relativePath = os.path.relpath(projectSourcePath, self.projectRootPath)

        shadowBasePath = os.path.join(projectRootPath, self.XCODE_SUPPORT_FOLDER)
        shadowBaseName = os.path.splitext(relativePath)[0].replace(u"/", self.SLASH_REPLACEMENT)
        shadowHeaderPath = os.path.join(shadowBasePath, shadowBaseName + ".h")
        shadowImplementationPath = os.path.join(shadowBasePath, shadowBaseName + ".m")

        if action == "add":
            fileRef = self.file_with_path(shadowHeaderPath)

            if not fileRef:
                self.update_general_include()
                self.add_file(projectSourcePath, shadowHeaderPath, shadowImplementationPath)

            match = self.FRAMEWORKS_RE.match(projectSourcePath)

            if match:
                framework = match.group(2)
                resourcesPath = os.path.realpath(os.path.join(match.group(1), u"Resources"))

                if os.path.isdir(resourcesPath):
                    self.add_framework_resources(framework, resourcesPath)

        elif action == "remove":
            self.update_general_include()
            self.remove_file(projectSourcePath, shadowHeaderPath, shadowImplementationPath)


#
# Possible ways to call this script:
#
# "add" projectRootPath file
# "remove" projectRootPath file
# "update" projectRootPath action file... [action file...]
#
# File paths are full project paths, no resolved symlinks.
# action is "add" or "remove".
#
if __name__ == "__main__":

    action = sys.argv[1]
    projectRootPath = unicode(sys.argv[2])
    modifier = PBXModifier(projectRootPath)

    if action in ("add", "remove"):
        projectSourcePath = unicode(sys.argv[3])
        modifier.update_project_with_source(action, projectSourcePath)

    elif action == "update":
        # When the action is "update", it is followed by "add" or "remove", followed by 1+ paths
        args = sys.argv[3:]
        action = unicode(args.pop(0))
        
        while len(args):
            arg = unicode(args.pop(0))
            
            if arg in ("add", "remove"):
                action = arg
                continue
            else:
                modifier.update_project_with_source(action, arg)
    
    modifier.save_project()
