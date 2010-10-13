#!/usr/bin/env bash

function prompt () {
    if [ "$noprompt" ] && [ "$#" = "1" ]; then
        if [ "$1" = "yes" ]; then
            echo "DEFAULT: yes"
            return 0
        else
            echo "DEFAULT: no"
            return 1
        fi
    fi

    while true; do
        echo "Enter \"yes\" or \"no\": "
        read response
        case $response
        in
            Y*) return 0 ;;
            y*) return 0 ;;
            N*) return 1 ;;
            n*) return 1 ;;
            *)
        esac
    done
}

function which () {
    echo "$PATH" | tr ":" "\n" | while read line; do [ -x "$line/$1" ] && echo "$line/$1" && return 0; done
}

function ask_remove_dir () {
    dir="$1"
    if [ -d "$dir" ]; then
        echo "================================================================================"
        echo "Found an existing Narwhal/Cappuccino installation, $dir. Remove it automatically now?"
        echo "WARNING: the ENTIRE directory, $dir, will be removed (i.e. 'rm -rf $dir')."
        echo "Be sure this is correct. Custom modifications and installed packages WILL BE DELETED."
        if prompt "no"; then
            rm -rf "$dir"
        fi
    fi
}

function ask_append_shell_config () {
    config_string="$1"

    shell_config_file=""
    # use order outlined by http://hayne.net/MacDev/Notes/unixFAQ.html#shellStartup
    if [ -f "$HOME/.bash_profile" ]; then
        shell_config_file="$HOME/.bash_profile"
    elif [ -f "$HOME/.bash_login" ]; then
        shell_config_file="$HOME/.bash_login"
    elif [ -f "$HOME/.profile" ]; then
        shell_config_file="$HOME/.profile"
    elif [ -f "$HOME/.bashrc" ]; then
        shell_config_file="$HOME/.bashrc"
    fi

    echo "    \"$config_string\" will be appended to \"$shell_config_file\"."
    if prompt "no"; then
        if [ "$shell_config_file" ]; then
            echo >> "$shell_config_file"
            echo "$config_string" >> "$shell_config_file"
            echo "Added to \"$shell_config_file\". Restart your shell or run \"source $shell_config_file\"."
            return 0
        else
            echo "Couldn't find a shell configuration file."
        fi
    fi
    return 1
}

function check_and_exit () {
    if [ ! "$?" = "0" ]; then
        echo "Error: problem running boostrap.sh. Exiting."
        exit 1
    fi
}

function check_build_environment () {
    # make sure user is running the Sun JVM or OpenJDK >= 6b18
    java_version=$(java -version 2>&1)
    echo $java_version | grep OpenJDK > /dev/null
    if [ "$?" = "0" ]; then # OpenJDK: make sure >= 6b18
        openjdk_version=$(echo $java_version | egrep -o '[0-9]b[0-9]+')
        if [ $(echo $openjdk_version | tr -d 'b') -lt 618 ]; then
            echo "Error: Narwhal is not compatible with your version of OpenJDK: $openjdk_version."
            echo "Please upgrade to OpenJDK >= 6b18 or switch to the Sun JVM. Then re-run bootstrap.sh."
            exit 1
        fi
    fi

    # make sure other dependencies are installed and on the $PATH
    OTHER_DEPS=(gcc unzip curl)

    for dep in ${OTHER_DEPS[@]}; do
        which "$dep" &> /dev/null
        if [ ! "$?" = "0" ]; then
            echo "Error: $dep is required to build Cappuccino. Please install $dep and re-run bootstrap.sh."
            exit 1
        fi
    done
}

check_build_environment

if [ -w "/usr/local" ]; then
    default_directory="/usr/local/narwhal"
else
    default_directory="$HOME/narwhal"
fi

install_directory=""
tmp_zip="/tmp/narwhal.zip"

github_user="280north"
github_ref="master"
tusk_install_command="install"

noprompt=""
install_capp=""

while [ $# -gt 0 ]; do
    case "$1" in
        --noprompt)     noprompt="yes";;
        --directory)    install_directory="$2"; shift;;
        --clone)        tusk_install_command="clone";;
        --github-user)  github_user="$2"; shift;;
        --github-ref)   github_ref="$2"; shift;;
        --install-capp) install_capp="yes";;
        *)              cat >&2 <<-EOT
usage: ./bootstrap.sh [OPTIONS]

    --noprompt:             Don't prompt, use relatively safe defaults.
    --directory [DIR]:      Use a directory other than /usr/local/narwhal.
    --clone:                Do "git clone" instead of downloading zips.
    --github-user [USER]:   Use another github user (default: 280north).
    --github-ref [REF]:     Use another git ref (default: master).
    --install-capp:         Install "objective-j" and "cappuccino" packages.
EOT
                        exit 1;;
    esac
    shift
done

github_project="$github_user-narwhal"
github_path=$(echo "$github_project" | tr '-' '/')

unset NARWHAL_ENGINE
unset SEA
unset SEALVL

PATH_SAVED="$PATH"

ask_remove_dir "/usr/local/share/objj"
ask_remove_dir "/usr/local/share/narwhal"
ask_remove_dir "/usr/local/narwhal"
if which "narwhal" > /dev/null; then
    narwhal_path=$(which "narwhal")
    # resolve symlinks
    while [ -h "$narwhal_path" ]; do
        dir=$(dirname -- "$narwhal_path")
        sym=$(readlink -- "$narwhal_path")
        narwhal_path=$(cd -- "$dir" && cd -- $(dirname -- "$sym") && pwd)/$(basename -- "$sym")
    done

    # NARWHAL_HOME is the 2nd ancestor directory of this shell script
    dir=$(dirname -- "$(dirname -- "$narwhal_path")")

    ask_remove_dir "$dir"
fi

install_narwhal=""
if which "narwhal" > /dev/null; then
    dir=$(dirname -- "$(dirname -- $(which "narwhal"))")
    echo "Using Narwhal installation at \"$dir\". Is this correct?"
    if ! prompt "no"; then
        echo "================================================================================"
        echo "Narwhal JavaScript platform is required. Install it automatically now?"
        if prompt "yes"; then
            install_narwhal="yes"
        fi
    fi
else
    echo "================================================================================"
    echo "Narwhal JavaScript platform is required. Install it automatically now?"
    if prompt "yes"; then
        install_narwhal="yes"
    fi
fi

if [ "$install_narwhal" ]; then
    if [ ! "$install_directory" ]; then
        echo "================================================================================"
        echo "To use the default location, \"$default_directory\", just hit enter/return, or enter another path:"
        if [ "$noprompt" ]; then
            input=""
        else
            read input
        fi
        if [ "$input" ]; then
            install_directory="`cd \`dirname "$input"\`; pwd`/`basename "$input"`"
        else
            install_directory="$default_directory"
        fi
    fi

    # absolutify
    install_directory="$(cd "$(dirname "$install_directory")" && echo "$(pwd)/$(basename "$install_directory")")"

    if [ ! -d "$(dirname "$install_directory")" ]; then
        echo "Error: parent directory of $install_directory does not exist"
        exit 1
    fi

    if [ -d "$install_directory" ]; then
        echo "================================================================================"
        echo "Directory exists at $install_directory. Delete it?"
        if prompt "no"; then
            rm -rf "$install_directory"
        else
            exit 1
        fi
    fi

    if [ "$tusk_install_command" = "clone" ]; then
        git_repo="git://github.com/$github_path.git"
        echo "Cloning Narwhal from \"$git_repo\"..."
        git clone "$git_repo" "$install_directory"
        (cd "$install_directory" && git checkout "origin/$github_ref")
    else
        zip_ball="http://github.com/$github_path/zipball/$github_ref"

        echo "Downloading Narwhal from \"$zip_ball\"..."
        curl -L -o "$tmp_zip" "$zip_ball"
        check_and_exit

        echo "Installing Narwhal..."
        unzip "$tmp_zip" -d "$install_directory"
        check_and_exit
        rm "$tmp_zip"
        check_and_exit

        mv "$install_directory/$github_project-"*/* "$install_directory/."
        check_and_exit
        rm -rf "$install_directory/$github_project-"*
        check_and_exit
    fi

    export PATH="$install_directory/bin:$PATH"
fi

if ! which "narwhal" > /dev/null; then
    echo "Problem installing Narwhal. To install Narwhal manually follow the instructions at http://narwhaljs.org/"
    exit 1
fi

install_directory=$(dirname -- "$(dirname -- "$(which narwhal)")")

echo "================================================================================"
echo "Using Narwhal installation at \"$install_directory\". Is this correct?"
if ! prompt "yes"; then
    exit 1
fi

# echo "================================================================================"
# echo "Would you like to install the pre-built Objective-J and Cappuccino packages?"
# echo "If you intend to build Cappuccino yourself this is not neccessary."
# if [ ! "$install_capp" ] && prompt; then
#     install_capp="yes"
# fi
extra_packages=""
if [ "$install_capp" ]; then
    extra_packages="objective-j cappuccino"
fi

echo "Installing necessary packages..."

if ! tusk update; then
    echo "Error: unable to update tusk catalog. Check that you have sufficient permissions."
    exit 1
fi

tusk $tusk_install_command browserjs jake shrinksafe $extra_packages

if [ `uname` = "Darwin" ]; then
    echo "================================================================================"
    echo "Would you like to install the JavaScriptCore engine for Narwhal?"
    echo "This is optional but will make building and running Objective-J much faster."
    if prompt "yes"; then
        tusk $tusk_install_command narwhal-jsc

        if ! (cd "$install_directory/packages/narwhal-jsc" && make webkit); then
            rm -rf "$install_directory/packages/narwhal-jsc"
            echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            echo "WARNING: building narwhal-jsc failed. Hit enter to continue."
            echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            # read
        elif ! [ "$NARWHAL_ENGINE" = "jsc" ]; then
            echo "================================================================================"
            echo "Rhino is the default Narwhal engine, should we change the default to JavaScriptCore for you?"
            echo "This can by overridden by setting the NARWHAL_ENGINE environment variable to \"jsc\" or \"rhino\"."
            ask_append_shell_config "export NARWHAL_ENGINE=jsc"
        fi
    fi
fi

export PATH="$PATH_SAVED"
if ! which "narwhal" > /dev/null; then
    echo "================================================================================"
    echo "You must add Narwhal's \"bin\" directory to your PATH environment variable. Do this automatically now?"

    export_path_string="export PATH=\"$install_directory/bin:\$PATH\""

    if ! ask_append_shell_config "$export_path_string"; then
        echo "Add \"$install_directory/bin\" to your PATH environment variable in your shell configuration file (e.x. .profile, .bashrc, .bash_profile)."
        echo "For example:"
        echo "    $export_path_string"
    fi
fi

if [ "$CAPP_BUILD" ]; then
    if [ -d "$CAPP_BUILD" ]; then
        echo "================================================================================"
        echo "An existing \$CAPP_BUILD directory at \"$CAPP_BUILD\" exists. The previous build may be incompatible. Remove it automatically now?"
        if prompt "no"; then
            rm -rf "$CAPP_BUILD"
        fi
    fi
else
    echo "================================================================================"
    echo "Before building Cappuccino we recommend you set the \$CAPP_BUILD environment variable to a path where you wish to build Cappuccino."
    echo "NOTE: If you have previously set \$CAPP_BUILD and built Cappuccino you may want to delete the directory before rebuilding."
fi

echo "================================================================================"
echo "Bootstrapping of Narwhal and other required tools is complete."
echo "NOTE: any changes made to the shell configuration files won't take place until you restart the shell."
