/**
 * cappuccino.js (Modernized for Node.js)
 *
 * This module provides versioning information by reading and parsing the
 * project's package.json file. It has been updated to use the standard
 * Node.js 'fs' and 'path' modules, removing the dependency on Narwhal.
 */

const fs = require('fs');
const path = require('path');

// Cache the parsed package.json to avoid reading the file multiple times.
let pkg = null;

function getPackage() {
    if (!pkg) {
        // In Node.js, `__filename` gives the full path to the current module file.
        // We assume package.json is located two directories above this file.
        const packageJsonPath = path.join(path.dirname(__filename), '..', '..', 'package.json');

        try {
            const fileContents = fs.readFileSync(packageJsonPath, 'utf8');
            pkg = JSON.parse(fileContents);
        } catch (error) {
            console.error(`Failed to read or parse package.json at: ${packageJsonPath}`);
            console.error(error);
            // Return a default structure to prevent further crashes.
            pkg = {
                "version": "0.0.0",
                "cappuccino-revision": "unknown",
                "cappuccino-timestamp": new Date().toISOString()
            };
        }
    }
    return pkg;
}

exports.version = function() {
    return getPackage()["version"];
};

exports.revision = function() {
    return getPackage()["cappuccino-revision"];
};

exports.timestamp = function() {
    // Ensure the result is always a Date object.
    return new Date(getPackage()["cappuccino-timestamp"]);
};

/**
 * Generates a full version string, e.g., "cappuccino 1.0.0 (2023-10-27 abc123)".
 * This implementation uses modern JavaScript template literals and string padding,
 * removing the need for a separate 'printf' module.
 */
exports.fullVersionString = function() {
    const ts = exports.timestamp();
    const year = ts.getUTCFullYear();

    // Use .padStart() to ensure two-digit month and day, replacing sprintf's '%02d'.
    const month = (ts.getUTCMonth() + 1).toString().padStart(2, '0');
    const day = ts.getUTCDate().toString().padStart(2, '0');
    const rev = exports.revision().slice(0, 6);

    // Use a template literal for clean and readable string formatting.
    return `cappuccino ${exports.version()} (${year}-${month}-${day} ${rev})`;
};
