#!/usr/bin/env bash

function processor_msg ()
{
    color=${2:-cyan}

    case "$color" in
        black           ) code="30";;
        red             ) code="31";;
        green           ) code="32";;
        yellow          ) code="33";;
        blue            ) code="34";;
        purple|magenta  ) code="35";;
        cyan            ) code="36";;
        white           ) code="37";;
        *               ) code="36";;
    esac

    echo -e "\033[${code}m$1\033[0m"
}

export -f processor_msg
