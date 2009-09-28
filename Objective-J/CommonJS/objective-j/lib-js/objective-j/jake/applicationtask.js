
BundleTask = require("objective-j/jake/bundletask").BundleTask;

function ApplicationTask(aName)
{
    BundleTask.apply(this, arguments);
}

ApplicationTask.__proto__ = BundleTask;
ApplicationTask.prototype.__proto__ = BundleTask.prototype;

ApplicationTask.prototype.packageType = function()
{
    return "APPL";
}

exports.ApplicationTask = ApplicationTask;

exports.app = function(aName, aFunction)
{
    // No .apply necessary because the parameters aren't variable.
    return ApplicationTask.defineTask(aName, aFunction);
}

/*
if type == Bundle::Type::Application and index_file

                index_file_path = File.join(build_path, File.basename(index_file))

                file_d index_file_path => [index_file] do |t|
                    cp(index_file, t.name)
                end

                enhance([index_file_path])

                frameworks_path = File.join(build_path, 'Frameworks')

                file_d frameworks_path do
                    IO.popen("capp gen -f " + build_path) do |capp|
                        capp.sync = true

                        while str = capp.gets
                            puts str
                        end
                    end
                    rake abort if ($? != 0)
                end

                enhance([frameworks_path])
            end

*/