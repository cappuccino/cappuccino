#!/usr/bin/env bash

function prompt () {
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
        echo "WARNING: custom modifications and installed packages in this installation WILL BE DELETED."
        if prompt; then
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
    if prompt; then
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

if [ "--clone" = "$1" ]; then
    tusk_install_command="clone"
    git_clone=1
else
    tusk_install_command="install"
fi

github_project="280north-narwhal"
github_path=$(echo "$github_project" | tr '-' '/')
install_directory="/usr/local/narwhal"
tmp_zip="/tmp/narwhal.zip"

unset NARWHAL_ENGINE

PATH_SAVED="$PATH"

ask_remove_dir "/usr/local/share/objj"
ask_remove_dir "/usr/local/share/narwhal"
ask_remove_dir "/usr/local/narwhal"
if which "narwhal" > /dev/null; then
    dir=$(dirname -- $(dirname -- $(which "narwhal")))
    ask_remove_dir "$dir"
fi

install_narwhal=""
if which "narwhal" > /dev/null; then
    dir=$(dirname -- $(dirname -- $(which "narwhal")))
    echo "Using Narwhal installation at \"$dir\". Is this correct?"
    if ! prompt; then
        echo "================================================================================"
        echo "Narwhal JavaScript platform is required. Install it automatically now?"
        if prompt; then
            install_narwhal="yes"
        fi
    fi
else
    echo "================================================================================"
    echo "Narwhal JavaScript platform is required. Install it automatically now?"
    if prompt; then
        install_narwhal="yes"
    fi
fi

if [ "$install_narwhal" ]; then
    echo "================================================================================"
    echo "To use the default location, \"$install_directory\", just hit enter/return, or enter another path:"
    read input
    if [ "$input" ]; then
        install_directory="`cd \`dirname $input\`; pwd`/`basename $input`"
    fi

    if [ -d "$install_directory" ]; then
        echo "================================================================================"
        echo "Directory exists at $install_directory. Delete it?"
        if prompt; then
            rm -rf "$install_directory"
        fi
    fi

    if [ "$git_clone" ]; then
        git_repo="git://github.com/$github_path.git"
        echo "Cloning Narwhal from \"$git_repo\"..."
        git clone "$git_repo" "$install_directory"
    else
        zip_ball="http://github.com/$github_path/zipball/master"

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

install_directory=$(dirname $(dirname $(which narwhal)))

echo "================================================================================"
echo "Using Narwhal installation at \"$install_directory\". Is this correct?"
if ! prompt; then
    exit 1
fi

echo "Installing necessary packages..."

if ! tusk update; then
    echo "Error: unable to update tusk catalog. Check that you have sufficient permissions."
    exit 1
fi

tusk $tusk_install_command browserjs jake

if [ `uname` = "Darwin" ]; then
    echo "================================================================================"
    echo "Would you like to install the JavaScriptCore engine for Narwhal?"
    echo "This is optional but will make building and running Objective-J much faster."
    if prompt; then
        tusk $tusk_install_command narwhal-jsc

        if ! (cd "$install_directory/packages/narwhal-jsc" && make webkit); then
            echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            echo "WARNING: building narwhal-jsc failed. Hit enter to continue."
            echo "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
            read
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
        if prompt; then
            rm -rf "$CAPP_BUILD"
        fi
    fi
else
    echo "================================================================================"
    echo "Before building Cappuccino we recommend you set the \$CAPP_BUILD environment variable to a path where you wish to build Cappuccino."
    echo "NOTE: If you have previously set \$CAPP_BUILD and built Cappuccino you may want to delete the directory before rebuilding."
fi

echo "================================================================================"
echo "Bootstrapping of Narwhal and other required tools is complete. You can now build Cappuccino."
echo "NOTE: any changes made to the shell configuration files won't take place until you restart the shell."
