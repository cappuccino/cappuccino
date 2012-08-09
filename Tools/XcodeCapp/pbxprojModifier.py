import sys, os
from mod_pbxproj import XcodeProject


def add_file(PBXProjectFilePath, path):

    project = XcodeProject.Load(PBXProjectFilePath)
    shadowGroup = project.get_or_create_group('Shadows')

    files = project.get_files_by_os_path("XcodeSupport/%s" % os.path.basename(path))
    
    if "main.m" in path:
        sys.exit(0)
    
    if len(files) == 0:
        project.add_file(path, parent=shadowGroup)
        project.save()

def remove_file(PBXProjectFilePath, path):
    
    project = XcodeProject.Load(PBXProjectFilePath)
    shadowGroup = project.get_or_create_group('Shadows')
    
    files = project.get_files_by_os_path("XcodeSupport/%s" % os.path.basename(path))
    
    if "main.m" in path:
        sys.exit(0)
    
    if len(files) == 1:
        project.remove_file("XcodeSupport/%s" % os.path.basename(path), parent=shadowGroup)
        project.save()


if __name__ == '__main__':

    action              = sys.argv[1]
    PBXProjectFilePath  = sys.argv[2]
    currentFilePath     = sys.argv[3]
    
    if action == "add":
        add_file(PBXProjectFilePath, currentFilePath)
    elif action == "remove":
        remove_file(PBXProjectFilePath, currentFilePath)
    
    
    

    
    

    




    