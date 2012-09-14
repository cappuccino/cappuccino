import sys, os
from mod_pbxproj import XcodeProject

XCODESUPPORTFOLDER = ".XcodeSupport"

def update_general_include(project, projectBaseURL):
    xcc_general_include_file = "%s/%s/xcc_general_include.h" % (projectBaseURL, XCODESUPPORTFOLDER)
    content = ""

    for file in os.listdir("%s/%s" % (projectBaseURL, XCODESUPPORTFOLDER)):
        if file.endswith(".h"):
            content += "#include \"%s\"\n" % file

    f = open(xcc_general_include_file, "w")
    f.write(content)
    f.close()

    if len(project.get_files_by_os_path("%s/%s" % (XCODESUPPORTFOLDER, os.path.basename(xcc_general_include_file)))) == 0:
        project.add_file(xcc_general_include_file, parent=shadowGroup)


def add_file(project, shadowGroup, sourceGroup, shadowHeaderPath, shadowImplementationFilePath, sourcePath, projectBaseURL):
    project.add_file(shadowHeaderPath, parent=shadowGroup)
    project.add_file(shadowImplementationFilePath, parent=shadowGroup)
    project.add_file(sourcePath, parent=sourceGroup)

def remove_file(project, shadowGroup, sourceGroup, shadowHeaderPath, shadowImplementationFilePath, sourcePath, projectBaseURL):
    project.remove_file("%s/%s" % (XCODESUPPORTFOLDER, os.path.basename(shadowHeaderPath)), parent=shadowGroup)
    project.remove_file("%s/%s" % (XCODESUPPORTFOLDER, os.path.basename(shadowImplementationFilePath)), parent=shadowGroup)
    project.remove_file(os.path.relpath(sourcePath, projectBaseURL), parent=sourceGroup)


if __name__ == '__main__':

    action                          = sys.argv[1]
    PBXProjectFilePath              = sys.argv[2]
    shadowHeaderFilePath            = sys.argv[3]
    shadowImplementationFilePath    = sys.argv[4]
    sourceFilePath                  = sys.argv[5]
    projectBaseURL                  = sys.argv[6]

    project = XcodeProject.Load(PBXProjectFilePath)

    shadowGroup = project.get_or_create_group('Classes')
    sourceGroup = project.get_or_create_group('Sources')

    if "main.j" in sourceFilePath:
        sys.exit(0)

    files = project.get_files_by_os_path("%s/%s" % (XCODESUPPORTFOLDER, os.path.basename(shadowHeaderFilePath)))

    if action == "add" and len(files) == 0:
        update_general_include(project, projectBaseURL)
        add_file(project, shadowGroup, sourceGroup, shadowHeaderFilePath, shadowImplementationFilePath, sourceFilePath, projectBaseURL)
        project.save()

    elif action == "remove" and len(files) == 1:
        update_general_include(project, projectBaseURL)
        remove_file(project, shadowGroup, sourceGroup, shadowHeaderFilePath, shadowImplementationFilePath, sourceFilePath, projectBaseURL)
        project.save()
