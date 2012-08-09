import sys, os
from mod_pbxproj import XcodeProject

XCODESUPPORTFOLDER = ".XcodeSupport"

def add_file(project, shadowGroup, sourceGroup, shadowPath, sourcePath, projectBaseURL):
    project.add_file(shadowPath, parent=shadowGroup)
    project.add_file(sourcePath, parent=sourceGroup)
    project.save()

def remove_file(project, shadowGroup, sourceGroup, shadowPath, sourcePath, projectBaseURL):
    project.remove_file("%s/%s" % (XCODESUPPORTFOLDER, os.path.basename(shadowPath)), parent=shadowGroup)
    project.remove_file(os.path.relpath(sourcePath, projectBaseURL), parent=sourceGroup)
    project.save()


if __name__ == '__main__':

    action              = sys.argv[1]
    PBXProjectFilePath  = sys.argv[2]
    shadowFilePath      = sys.argv[3]
    sourceFilePath      = sys.argv[4]
    projectBaseURL      = sys.argv[5]
    
    project = XcodeProject.Load(PBXProjectFilePath)
    
    shadowGroup = project.get_or_create_group('Shadows')
    sourceGroup = project.get_or_create_group('Sources')
    
    if "main.m" in shadowFilePath:
        sys.exit(0)
    
    files = project.get_files_by_os_path("%s/%s" % (XCODESUPPORTFOLDER, os.path.basename(shadowFilePath)))

    if action == "add" and len(files) == 0:
        add_file(project, shadowGroup, sourceGroup, shadowFilePath, sourceFilePath, projectBaseURL)

    elif action == "remove" and len(files) == 1:
        remove_file(project, shadowGroup, sourceGroup, shadowFilePath, sourceFilePath, projectBaseURL)
    
    

    
    

    




    