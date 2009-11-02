#!/bin/sh

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

function path_instructions () {
    echo "Add \"$INSTALL_DIRECTORY/bin\" to your PATH environment variable in your shell configuration file (e.x. .profile, .bashrc, .bash_profile)."
    echo "For example:"
    echo "    export PATH=$INSTALL_DIRECTORY/bin:\$PATH"
}

TEMPZIP="/tmp/narwhal.zip"
INSTALL_DIRECTORY="/usr/local/narwhal"

ORIGINAL_PATH="$PATH"

if ! which -s "narwhal"; then
    echo "Narwhal JavaScript platform is required. Install it into \"$INSTALL_DIRECTORY\"?"
    if prompt; then
        echo "Downloading Narwhal..."
        curl -L -o "$TEMPZIP" "http://github.com/tlrobinson/narwhal/zipball/master"
        echo "Installing Narwhal..."
        unzip "$TEMPZIP" -d "$INSTALL_DIRECTORY"
        rm "$TEMPZIP"
        
        mv $INSTALL_DIRECTORY/tlrobinson-narwhal-*/* $INSTALL_DIRECTORY/.
        rm -rf $INSTALL_DIRECTORY/tlrobinson-narwhal-*
        
        if ! which -s "narwhal"; then
            export PATH="$INSTALL_DIRECTORY/bin:$PATH"
        fi
    else
        echo "Narwhal required, aborting installation. To install Narwhal manually follow the instructions at http://narwhaljs.org/"
        exit 1
    fi
fi

if ! which -s "narwhal"; then
    echo "Error: problem installing Narwhal"
    exit 1
fi

echo "Installing Objective-J and Cappuccino tools..."
tusk install objj

if [ `uname` = "Darwin" ]; then
    echo "Would you like to install the JavaScriptCore engine for Narwhal? This is optional but will make building and running Objective-J much faster."
    if prompt; then
        tusk install narwhal-jsc
        pushd "$INSTALL_DIRECTORY/packages/narwhal-jsc"
        make webkit
        popd
    fi
fi

export PATH="$ORIGINAL_PATH"
if ! which -s "narwhal"; then
    
    SHELL_CONFIG=""
    if [ -f "$HOME/.bashrc" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        SHELL_CONFIG="$HOME/.bash_profile"
    elif [ -f "$HOME/.profile" ]; then
        SHELL_CONFIG="$HOME/.profile"
    elif [ -f "$HOME/.bash_login" ]; then
        SHELL_CONFIG="$HOME/.bash_login"
    fi

    EXPORT_PATH_STRING="\nexport PATH=\"$INSTALL_DIRECTORY/bin:\$PATH\""

    echo "You must add Narwhal's \"bin\" directory to your PATH environment variable. Do this automatically now?"
    echo "\"$EXPORT_PATH_STRING\" will be appended to \"$SHELL_CONFIG\"."
    if prompt; then
        if [ "$SHELL_CONFIG" ]; then
            echo "$EXPORT_PATH_STRING" >> "$SHELL_CONFIG"
            echo "Added to \"$SHELL_CONFIG\". Restart your shell or run \"source $SHELL_CONFIG\"."
        else
            echo "Couldn't find a shell configuration file."
            path_instructions
        fi
    else
        path_instructions
    fi
fi
