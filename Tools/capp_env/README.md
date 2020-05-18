# capp_env

`capp_env` is a simple virtual environment tool for Cappuccino.


## Usage

To create a virtual environment:

    capp_env -p /path/to/the/env

This will create

    /path/to/the/env
        /bin
        /build
        /sources # if you want to put your sources here, but it is optional
        /narwhal

It will download the latest `cappuccino_base`, put it in `narwhal` and will create an `activate` file in `/path/to/the/env/bin`

Then you can activate this environment by doing:

    source /path/to/the/env/bin/activate

your current `PATH` will be updated to look for `jake` and `capp` and all the tools from `/path/to/the/env/narwhal/bin`, and will set `CAPP_BUILD` to be `/path/to/the/env/build`.

From now on, you can clone the Cappuccino sources, (in `sources` for instance) and do

    jake install

If you install the Cappuccino source while in an virtual env, all the tools will use the debug version that you just built (for instance, `nib2cib` will be used from `/path/to/the/env/build/Debug/CommonJS/cappuccino/bin/nib2cib`)


## Deactivate

Just close the current terminal, or run

    capp_env_deactivate


## TODOs

    - let a chance to select the current cappuccino base version to download
    - find a way to make XcodeCapp to use these environements