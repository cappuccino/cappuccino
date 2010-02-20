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

echo $shell_config_file
