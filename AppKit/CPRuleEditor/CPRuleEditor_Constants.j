/*
 * CPRuleEditor_Constants.j
 * AppKit
 *
 * Created by cacaodev.
 * Copyright 2011, cacaodev.
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

CPRuleEditorPredicateLeftExpression     = "CPRuleEditorPredicateLeftExpression";
CPRuleEditorPredicateRightExpression    = "CPRuleEditorPredicateRightExpression";
CPRuleEditorPredicateComparisonModifier = "CPRuleEditorPredicateComparisonModifier";
CPRuleEditorPredicateOptions            = "CPRuleEditorPredicateOptions";
CPRuleEditorPredicateOperatorType       = "CPRuleEditorPredicateOperatorType";
CPRuleEditorPredicateCustomSelector     = "CPRuleEditorPredicateCustomSelector";
CPRuleEditorPredicateCompoundType       = "CPRuleEditorPredicateCompoundType";

CPRuleEditorRowsDidChangeNotification   = "CPRuleEditorRowsDidChangeNotification";
CPRuleEditorRulesDidChangeNotification  = "CPRuleEditorRulesDidChangeNotification";

CPRuleEditorNestingModeSingle   = 0;        // Only a single row is allowed.  Plus/minus buttons will not be shown
CPRuleEditorNestingModeList     = 1;        // Allows a single list, with no nesting and no compound rows
CPRuleEditorNestingModeCompound = 2;        // Unlimited nesting and compound rows; this is the default
CPRuleEditorNestingModeSimple   = 3;        // One compound row at the top with subrows beneath it, and no further nesting allowed

CPRuleEditorRowTypeSimple       = 0;
CPRuleEditorRowTypeCompound     = 1;
