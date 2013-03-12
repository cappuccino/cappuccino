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
    a_longish_dir_name="$1"
    if [ -d "$a_longish_dir_name" ]; then
        echo "================================================================================"
        echo "There is an an existing Cappuccino installation at $a_longish_dir_name."
        echo "Should we remove it now?"
        echo "WARNING: the ENTIRE directory, $a_longish_dir_name, will be removed (i.e. "
        echo "'rm -rf $a_longish_dir_name'). Be sure this is correct. Custom modifications and "
        echo "installed packages WILL BE DELETED."
        if prompt "no"; then
            rm -rf "$a_longish_dir_name"
        fi
    fi
}

function ask_append_shell_config () {
    config_string="$1"

    shell_config_file=""

    if [[ "$SHELL" == *zsh* ]]; then
        if [ -f "$HOME/.zshrc" ]; then
            shell_config_file="$HOME/.zshrc"
        elif [ -f "$HOME/.profile" ]; then
            shell_config_file="$HOME/.profile"
        else
            touch "$HOME/.profile"
            shell_config_file="$HOME/.zshrc"
        fi
    elif [[ "$SHELL" == *bash* ]]; then
        if [ -f "$HOME/.bash_profile" ]; then
            shell_config_file="$HOME/.bash_profile"
        elif [ -f "$HOME/.bash_login" ]; then
            shell_config_file="$HOME/.bash_login"
        elif [ -f "$HOME/.bashrc" ]; then
            shell_config_file="$HOME/.bashrc"
        elif [ -f "$HOME/.profile" ]; then
            shell_config_file="$HOME/.profile"
        else
            touch "$HOME/.profile"
            shell_config_file="$HOME/.profile"
        fi
    else
        echo "    Could not automatically determine your shell. Looking for other configuration possibilities."
        # use order outlined by http://hayne.net/MacDev/Notes/unixFAQ.html#shellStartup
        if [ -f "$HOME/.bash_profile" ]; then
            shell_config_file="$HOME/.bash_profile"
        elif [ -f "$HOME/.bash_login" ]; then
            shell_config_file="$HOME/.bash_login"
        elif [ -f "$HOME/.bashrc" ]; then
            shell_config_file="$HOME/.bashrc"
        elif [ -f "$HOME/.zshrc" ]; then
            shell_config_file="$HOME/.zshrc"
        elif [ -f "$HOME/.profile" ]; then
            shell_config_file="$HOME/.profile"
        else
            touch "$HOME/.profile"
            shell_config_file="$HOME/.profile"
        fi
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
        echo "Error: problem running bootstrap.sh. Exiting."
        exit 1
    fi
}

function check_install_environment () {
    # make sure dependencies are installed and on the $PATH
    CAPP_BUILD_DEPS=(java unzip)

    for dep in ${CAPP_BUILD_DEPS[@]}; do
        which "$dep" &> /dev/null
        if [ ! "$?" = "0" ]; then
            echo "Error: $dep is required to bootstrap Cappuccino. Please install $dep and re-run bootstrap.sh."
            exit 1
        fi
    done

    # special case: check for curl or wget
    which curl &> /dev/null || which wget &> /dev/null
    if [ ! "$?" = "0" ]; then
        echo "Error: curl or wget are required to bootstrap Cappuccino. Please install one of them and re-run bootstrap.sh."
        exit 1
    fi

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
}

function check_build_environment () {
    CAPP_BUILD_DEPS=(gcc)

    for dep in ${CAPP_BUILD_DEPS[@]}; do
        which "$dep" &> /dev/null
        if [ ! "$?" = "0" ]; then
            echo "Error: $dep is required to build Cappuccino components. Please install $dep and re-run bootstrap.sh."
            exit 1
        fi
    done
}

check_install_environment

if [ -w "/usr/local" ]; then
    default_directory="/usr/local/narwhal"
else
    default_directory="$HOME/narwhal"
fi

install_directory=""
tmp_zip="/tmp/cappuccino.zip"

github_user="cappuccino"
github_ref="v0.9.7-alpha1"

noprompt=""
install_capp=""
install_method="zip"
verbosity=1

while [ $# -gt 0 ]; do
    case "$1" in
        --noprompt)     noprompt="yes";;
        --directory)    install_directory="$2"; shift;;
        --clone)        install_method="clone";;
        --clone-http)   install_method="clone --http";;
        --github-user)  github_user="$2"; shift;;
        --github-ref)   github_ref="$2"; shift;;
        -q|--quiet)     verbosity=$[verbosity - 1];;
        -v|--verbose)   verbosity=$[verbosity + 1];;
        *)              cat >&2 <<-EOT
usage: ./bootstrap.sh [OPTIONS]

    --noprompt:             Don't prompt, use relatively safe defaults.
    --directory [DIR]:      Use a directory other than $default_directory.
    --clone:                Do "git clone git://" instead of downloading zips.
    --clone-http:           Do "git clone http://" instead of downloading zips.
    --github-user [USER]:   Github user (default: $github_user).
    --github-ref [REF]:     Use another git ref (default: $github_ref).
    -q | --quiet:           Output less logging.
    -v | --verbose:         Output more logging.
EOT
                        exit 1;;
    esac
    shift
done

github_project="$github_user-cappuccino-base"
github_path="$github_user/cappuccino-base"

# The purpose of bootstrap is to install Cappuccino.
install_cappuccino="yes"

if (( $verbosity > 0 )); then
    sed "s/\[\[ CAPPUCCINO_VERSION \]\]/$github_ref/" <<EOT

                   _______ ____  ___  __ __________(_)__  ___
                  / __/ _ \`/ _ \/ _ \/ // / __/ __/ / _ \/ _ \\
                  \__/\_,_/ .__/ .__/\_,_/\__/\__/_/_//_/\___/
                         /_/  /_/

                             Welcome to Cappuccino!

================================================================================

                                 Version [[ CAPPUCCINO_VERSION ]]


                         http://cappuccino-project.org
                    http://github.com/cappuccino/cappuccino
                       irc://irc.freenode.org#cappuccino

EOT
fi

echo "This script will install the Cappuccino environment for you. Continue?"

if ! prompt "yes"; then
    install_cappuccino="no"
    exit 0
fi

NARWHAL_ENGINE_SAVED="$NARWHAL_ENGINE"
unset NARWHAL_ENGINE
unset SEA
unset SEALVL

PATH_SAVED="$PATH"

if which "narwhal" > /dev/null; then
    narwhal_path="$(which narwhal)"
    # resolve symlinks
    while [ -h "$narwhal_path" ]; do
        dir=$(dirname -- "$narwhal_path")
        sym=$(readlink -- "$narwhal_path")
        narwhal_path="$(cd -- "$dir" && cd -- $(dirname -- "$sym") && pwd)/$(basename -- "$sym")"
    done

    # NARWHAL_HOME is the 2nd ancestor directory of this shell script
    dir="$(dirname -- "$(dirname -- "$narwhal_path")")"

    ask_remove_dir "$dir"
else
    ask_remove_dir "/usr/local/share/objj"
    ask_remove_dir "/usr/local/share/narwhal"
    ask_remove_dir "/usr/local/narwhal"
fi

if [ "$install_cappuccino" ]; then
    if [ ! "$install_directory" ]; then
        echo "================================================================================"
        echo "Enter an installation path, or hit enter/return to use \"$default_directory\":"
        if [ "$noprompt" ]; then
            input=""
        else
            read input
        fi
        if [ "$input" ] && [ ! "$input" = "yes" ]; then
            install_directory="`cd \`dirname "$input"\`; pwd`/`basename "$input"`"
        else
            install_directory="$default_directory"
        fi
    fi

    # absolutify
    install_directory="$(cd "$(dirname "$install_directory")" && echo "$(pwd)/$(basename "$install_directory")")"

    if [ ! -d "$(dirname "$install_directory")" ]; then
        echo "Error: parent directory of $install_directory does not exist."
        exit 1
    fi

    if [ -d "$install_directory" ]; then
        echo "================================================================================"
        echo "A directory already exists at $install_directory. Should we remove it now?"
        if prompt "no"; then
            rm -rf "$install_directory"
        else
            exit 1
        fi
    fi

    if [ "$(echo $install_method | cut -c-5)" = "clone" ]; then
        if [ "$(echo $install_method | cut -c7-)" = "--http" ]; then
            git_protocol="http"
        else
            git_protocol="git"
        fi
        git_repo="$git_protocol://github.com/$github_path.git"
        echo "Cloning Cappuccino base from \"$git_repo\"..."
        git clone "$git_repo" "$install_directory"
        (cd "$install_directory" && git checkout "origin/$github_ref")
    else
        zip_ball="http://github.com/$github_path/zipball/$github_ref"

        echo "Downloading Cappuccino base from \"$zip_ball\"..."
        curl_quiet_arg=""
        wget_quiet_arg=""
        if (( $verbosity < 1 )); then curl_quiet_arg="--silent"; wget_quiet_arg="--no-verbose"; fi
        $(which curl &> /dev/null && echo curl $curl_quiet_arg -L -o || echo wget $wget_quiet_arg --no-check-certificate -O) "$tmp_zip" "$zip_ball"
        check_and_exit

        echo "Installing Cappuccino base..."

        quiet_arg=""
        if (( $verbosity < 2 )); then quiet_arg="-q"; fi
        unzip $quiet_arg "$tmp_zip" -d "$install_directory"
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
    echo "Problem installing Cappuccino. Review any error messages above and try again."
    exit 1
fi

install_directory="$(dirname -- "$(dirname -- "$(which narwhal)")")"

#echo "================================================================================"
#echo "Using the Cappuccino base installation at \"$install_directory\". Is this correct?"
#if ! prompt "yes"; then
#    exit 1
#fi

if [ `uname` = "Darwin" ]; then
    echo "================================================================================"
    echo "Would you like to build the JavaScriptCore engine? This is optional but will "
    echo "make building and running Cappuccino and Objective-J much faster."
    if prompt "yes"; then
        check_build_environment

        # The narwhal-jsc package is already installed within the base kit.

        # This autoreconf command improves compatibility with MacPorts, but only works with autoconf 2.65+.
        needed_autoconf_major=2
        needed_autoconf_minor=65
        if $(autoconf --version | head -1 | python -c "import sys, re; major, minor=re.search(r'(\d+)\.(\d+)', sys.stdin.read()).groups(); sys.exit((int(major) < $needed_autoconf_major or int(minor) < $needed_autoconf_minor) and 1)"); then
            # Don't bother checking the return code of this operation. Even if it fails, it's still
            # worthwhile to continue and attempt the full build.
            (cd "$install_directory/packages/narwhal-jsc/deps/libedit-20100424-3.0" && autoreconf -if)
        fi

        if ! (cd "$install_directory/packages/narwhal-jsc/" && make webkit); then
            rm -rf "$install_directory/packages/narwhal-jsc"
            echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            echo "WARNING: building narwhal-jsc failed. Hit enter to continue."
            echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            # read
        elif ! [ "$NARWHAL_ENGINE_SAVED" = "jsc" ]; then
            echo "================================================================================"
            echo "Rhino is currently the default JavaScript engine. Should we change the default to JavaScriptCore"
            echo "for you? This can by overridden by setting the NARWHAL_ENGINE environment variable "
            echo "to \"jsc\" or \"rhino\"."
            ask_append_shell_config "export NARWHAL_ENGINE=jsc"
        fi
    fi
fi

export PATH="$PATH_SAVED"
if ! which "narwhal" > /dev/null; then
    echo "================================================================================"
    echo "Cappuccino's \"bin\" directory must be in your PATH environment variable."
    echo "Should we do this for you?"

    export_path_string="export PATH=\"$install_directory/bin:\$PATH\""

    if ! ask_append_shell_config "$export_path_string"; then
        echo "Add \"$install_directory/bin\" to your PATH environment variable in your shell "
        echo "configuration file (e.x. .profile, .bashrc, .bash_profile)."
        echo "For example:"
        echo "    $export_path_string"
    fi
fi

if [ "$CAPP_BUILD" ]; then
    if [ -d "$CAPP_BUILD" ]; then
        echo "================================================================================"
        echo "A \$CAPP_BUILD directory already exists at \"$CAPP_BUILD\". The previous "
        echo "build may be incompatible. Should we remove it now?"
        if prompt "no"; then
            rm -rf "$CAPP_BUILD"
        fi
    fi
else
    echo "================================================================================"
    echo "Before building Cappuccino we recommend you set the \$CAPP_BUILD environment "
    echo "variable to a path where you wish to build Cappuccino. This can be automatically"
    echo "set to the default value of \"$PWD/Build\", or you can set \$CAPP_BUILD yourself."
    ask_append_shell_config "export CAPP_BUILD=\"$PWD/Build\""
fi

if [ `uname` = "Darwin" ]; then
    xcode_path=`xcode-select -print-path 2>/dev/null`
    if ! [ "$xcode_path" ] || ! [ -d "$xcode_path" ]; then
        echo "================================================================================"
        echo "WARNING: Your Xcode path seems to be incorrect. This may prevent the nib2cib and"
        echo "XcodeCapp utilities from working. Fix your Xcode installation using the"
        echo "xcode-select utility."
        echo "For example:"
        echo "    sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer"
    fi
fi

echo "================================================================================"
echo "Bootstrapping of Cappuccino and other required tools is complete."
echo "NOTE: any changes made to the shell configuration files won't take place until "
echo "you restart the shell."
