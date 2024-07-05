#!/usr/bin/env bash

chmod +x capp_lint

cp capp_lint /usr/local/bin

if [[ ! -d /usr/local/share/man/man1 ]]; then
    mkdir -p /usr/local/share/man/man1
fi

cp capp_lint.1 /usr/local/share/man/man1
