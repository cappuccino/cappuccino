#!/usr/bin/env python

import os
import commands
import re

PATH = os.path.abspath(os.path.join(os.path.dirname(__file__)))


def get_tests_cases():
    ret = []
    for filename in os.listdir("TestCases"):
        ret.append("TestCases/%s" % filename)
    return ret
    # return ["TestCases/2.j"]

def get_expected_output(test_case):
    f = open(test_case)
    content = f.readlines();
    f.close()

    status = int(content[0].replace("// Expected output: ", ""))

    recording = False
    output = []

    for line in content:
        if "END_EXPECTED" in line:
            recording = False
            break;

        if "START_EXPECTED" in line:
            recording = True
            continue

        if recording:
            output.append(line)

    output = "".join(output);
    output = output.replace("[__PATH__]", "%s/%s" % (PATH, test_case))
    output = cleanup_output(output)

    return (status, output)


def get_actual_output(test_case):
    status, output = commands.getstatusoutput("objj %s" % test_case)
    output = cleanup_output(output)
    return (status, output)


def cleanup_output(output):
    if not output:
        return ""
    output = output.replace(" ", "")
    output = output.replace("\n", "")
    output = output.replace("[0m", "")
    return re.sub('[^\s!-~]', '', output)


if __name__ == "__main__":

    for test in get_tests_cases():

        expected_status, expected_output = get_expected_output(test)
        actual_status, actual_output = get_actual_output(test)

        print "########################################"
        print "Testing %s" % test
        errored = False
        if expected_status != actual_status:
            errored = True
            print "    Error in %s: Status code is different: expected %d, actual %d" % (test, expected_status, actual_status)

        if expected_output != actual_output:
            errored = True
            print "    Error in %s. Outputs are different" % test
            print "    EXPECTED: %s" % expected_output
            print "    ACTUAL:   %s" % actual_output

        if not errored:
            print "    OK"
