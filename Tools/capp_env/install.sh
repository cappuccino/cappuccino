#!/usr/bin/env bash

chmod +x capp_env

if [[ ! -d /usr/local/narwhal/bin ]]; then
    mkdir -p /usr/local/narwhal/bin
fi

cp capp_env /usr/local/narwhal/bin