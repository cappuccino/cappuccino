/*
 * jake.js
 * Objective-J
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

var FILE = require("file");

var BUNDLE_TASK = require("objective-j/jake/bundletask");

exports.BundleTask = BUNDLE_TASK.BundleTask;
exports.bundle = BUNDLE_TASK.bundle;

var FRAMEWORK_TASK = require("objective-j/jake/frameworktask");

exports.FrameworkTask = FRAMEWORK_TASK.FrameworkTask;
exports.framework = FRAMEWORK_TASK.framework;

var APPLICATION_TASK = require("objective-j/jake/applicationtask");

exports.ApplicationTask = APPLICATION_TASK.ApplicationTask;
exports.app = APPLICATION_TASK.app;
