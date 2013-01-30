/*
 * main.j
 * nib2cib
 *
 * Created by Francisco Tolmasky.
 * Copyright 2008, 280 North, Inc.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA
*/

@import "Nib2Cib.j"

var OS = require("os"),
    stream = require("narwhal/term").stream;


function main(args)
{
    checkUlimit();

    var nib2cib = [[Nib2Cib alloc] initWithArgs:args];

    [nib2cib run];
}

function checkUlimit()
{
    var minUlimit = 1024,
        p = OS.popen(["ulimit", "-n"]);

    if (p.wait() === 0)
    {
        var limit = p.stdout.read().split("\n")[0];

        if (Number(limit) < minUlimit)
        {
            stream.print("\0red(\0bold(WARNING:\0)\0) nib2cib may need to open more files than this terminal session currently allows (" + limit + "). Add the following line to your login configuration file (.bash_profile, .bashrc, etc.), start a new terminal session, then try again:\n");
            stream.print("ulimit -n " + minUlimit);
            OS.exit(1);
        }
    }
}
