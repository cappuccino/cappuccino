/*
 * ThemeDescriptors.j
 * AppKit
 *
 * Created by Didier Korthoudt
 * Copyright 2018 <didier.korthoudt@uliege.be>
 * HUD design copyright 2026 <daboe01@gmail.com>
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

@import <Foundation/CPObject.j>
@import <Foundation/CPGeometry.j>
@import <AppKit/CPApplication.j>
@import <AppKit/CPBrowser.j>
@import <AppKit/CPButton.j>
@import <AppKit/CPButtonBar.j>
@import <AppKit/CPCheckBox.j>
@import <AppKit/CPComboBox.j>
@import <AppKit/CPColorWell.j>
@import <AppKit/CPDatePicker.j>
@import <AppKit/CPLevelIndicator.j>
@import <AppKit/CPPopUpButton.j>
@import <AppKit/CPProgressIndicator.j>
@import <AppKit/CPRadio.j>
@import <AppKit/CPRuleEditor.j>
@import <AppKit/CPScroller.j>
@import <AppKit/CPScrollView.j>
@import <AppKit/CPSegmentedControl.j>
@import <AppKit/CPSlider.j>
@import <AppKit/CPSplitView.j>
@import <AppKit/CPStepper.j>
@import <AppKit/CPTableHeaderView.j>
@import <AppKit/CPTabView.j>
@import <AppKit/CPSearchField.j>
@import <AppKit/CPTextField.j>
@import <AppKit/CPTokenField.j>
@import <AppKit/CPWindow.j>
@import <AppKit/CPAlert.j>
@import <AppKit/_CPToolTip.j>
@import <AppKit/CPPopover.j>
@import <AppKit/CPColor.j>
@import <AppKit/CPFont.j>
@import <AppKit/CPImage.j>

@import "Aristo3Colors.j"

var A3ColorActiveText   = [A3CPColorActiveText cssString],
    A3ColorInactiveText = [A3CPColorInactiveText cssString],
    A3ColorWhite        = [[CPColor whiteColor] cssString],
    A3ColorBlack        = [[CPColor blackColor] cssString];

// SVGs
    var svgArrowDown    = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB3aWR0aD0iNjQiIGhlaWdodD0iNjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cGF0aCBkPSJNNyAxMEwxMiAxNUwxNyAxMEg3WiIgZmlsbD0iIzQ1NDU0NSIvPgo8L3N2Zz4=')",
    svgArrowUp      = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB3aWR0aD0iNjQiIGhlaWdodD0iNjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cGF0aCBkPSJNMTIgOUwxNyAxNEg3TDEyIDlaIiBmaWxsPSIjNDU0NTQ1Ii8+Cjwvc3ZnPg==')",
    svgSingleArrow  = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB3aWR0aD0iNjQiIGhlaWdodD0iNjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cGF0aCBkPSJNOCAxMEwxMiAxNEwxNiAxMCIgc3Ryb2tlPSIjMDA3QkZGIiBzdHJva2Utd2lkdGg9IjEuNSIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIi8+Cjwvc3ZnPg==')",
    svgDoubleArrow  = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB3aWR0aD0iNjQiIGhlaWdodD0iNjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cGF0aCBkPSJNNCAxMEw4IDZMMTIgMTAiIHN0cm9rZT0iIzAwN0JGRiIgc3Ryb2tlLXdpZHRoPSIxLjUiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIgc3Ryb2tlLWxpbmVqb2luPSJyb3VuZCIvPgogIDxwYXRoIGQ9Ik00IDE0TDggMThMMTIgMTQiIHN0cm9rZT0iIzAwN0JGRiIgc3Ryb2tlLXdpZHRoPSIxLjUiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIgc3Ryb2tlLWxpbmVqb2luPSJyb3VuZCIvPgo8L3N2Zz4=')",
    svgDoubleArrow2  = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB3aWR0aD0iNjQiIGhlaWdodD0iNjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KICA8cGF0aCBkPSJNNCA2TDggMTBMMTIgNiIgc3Ryb2tlPSIjMDA3QkZGIiBzdHJva2Utd2lkdGg9IjEuNSIgc3Ryb2tlLWxpbmVjYXA9InJvdW5kIiBzdHJva2UtbGluZWpvaW49InJvdW5kIi8+CiAgPHBhdGggZD0iTTQgMTRMMTIgMTQiIHN0cm9rZT0iIzAwN0JGRiIgc3Ryb2tlLXdpZHRoPSIxLjUiIHN0cm9rZS1saW5lY2FwPSJyb3VuZCIgc3Ryb2tlLWxpbmVqb2luPSJyb3VuZCIvPgo8L3N2Zz4=')",
    svgCheckmark    = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMiAxMiI+PHBhdGggZD0iTTQgMTBMMCA2TDIgNEw0IDhMMTAgMkwxMiA0TDQgMTBaIi8+PC9zdmc+')",
    svgDash         = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMiAxMiI+PHJlY3QgeT0iNSIgd2lkdGg9IjEyIiBoZWlnaHQ9IjIiLz48L3N2Zz4=')",
    svgRadioDot     = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMiAxMiI+PGNpcmNsZSBjeD0iNiIgY3k9IjYiIHI9IjMiLz48L3N2Zz4=')",
    svgMagnifier    = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA1MDAgNTAwIj48ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSgwLC01NTIuMzYyMTYpIj48ZyB0cmFuc2Zvcm09InRyYW5zbGF0ZSwtNC4zNjA5NzkzLC03LjY3MDQ3ODUpIj48cGF0aCBkPSJNIDIzMi44Mzk1Miw2MTQuOTY3MDIgQSAxNTQuMDQ4MTYsMTU0LjA0Nzk0IDAgMCAwIDc4Ljc5MTUzLDc2OS4wMTM4MiAxNTQuMDQ4MTYsMTU0LjA0Nzk0IDAgMCAwIDIzMi44Mzk1Miw5MjMuMDYxODQgMTU0LjA0ODE2LDE1NC4wNDc5NCAwIDAgMCAzODYuODg3NTEsNzY5LjAxMzgyIDE1NC4wNDgxNiwxNTQuMDQ3OTQgMCAwIDAgMjMyLjgzOTUyLDYxNC45NjcwMiBaIG0gMCwyNi43NzYxMyBBIDEyOS45NTgzMiwxMjcuMjcwNyAwIDAgMSAzNjIuNzk4MzIsNzY5LjAxMzgyIDEyOS45NTgzMiwxMjcuMjcwNyAwIDAgMSAyMzIuODM5NTIsODk2LjI4NDQ5IDEyOS45NTgzMiwxMjcuMjcwNyAwIDAgMSAxMDIuODgxOTQsNzY5LjAxMzgyIDEyOS45NTgzMiwxMjcuMjcwNyAwIDAgMSAyMzIuODM5NTIsNjQxLjc0MzE1IFoiIGZpbGw9IiMyYjAwMDAiIC8+PHJlY3Qgcnk9IjE4LjA4MzQyIiByeD0iMzMuMjQ5NDQzIiB0cmFuc2Zvcm09Im1hdHJpeCgwLjY1MzE2NzY4LDAuNzU3MjEzMywtMC42MDY4OTA1MSwwLjc5NDc4NTQ1LDAsMCkiIHk9IjMxOS41NTQzMiIgeD0iNzk0Ljg3NzUiIGhlaWdodD0iMzYuMTY2ODQiIHdpZHRoPSIxNzMuMDI2NzUiIGZpbGw9IiMyYjAwMDAiIC8+PC9nPjwvZz48L3N2Zz4=')",
    svgCancel = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAzNzUgMzc1Ij48cGF0aCBmaWxsPSIjMzMzMzMzIiBkPSJNMTg3LjUgMi41YTE4NSAxODUgMCAwIDAtMTg1IDE4NSAxODUgMTg1IDAgMCAwIDE4NSAxODUgMTg1IDE4NSAxODUgMCAwIDE4NS0xODUgMTg1IDE4NSAwIDAgMC0xODUtMTg1em0tODUuOSA3OC45YTIwLjIgMjAuMiAwIDAgMSAxNC41IDYuMWw3MS40IDcxLjQgNzEuNC03MS40YTIwLjIgMjAuMiAwIDAgMSAxMy45LTYuMSAyMC4yIDIwLjIgMCAwIDEgMTQuNyAzNC43bC03MS40IDcxLjQgNzEuNCA3MS40YTIwLjIgMjAuMiAwIDEgMS0yOC42IDI4LjZsLTcxLjQtNzEuNC03MS40IDcxLjRhMjAuMiAyMC4yIDAgMSAxLTI4LjYtMjguNmw3MS40LTcxLjQtNzEuNC03MS40YTIwLjIgMjAuMiAwIDAgMSAxNC4xLTM0Ljd6Ii8+PC9zdmc+')";
    svgArrowRight   = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMCAxMCI+PHBhdGggZD0iTTIgMUw4IDVMMiA5WiIvPjwvc3ZnPg==')",
    svgPlus         = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxNiAxNiI+PHBhdGggZD0iTTggM3YxMG0tNS01aDEwIiBzdHJva2Utd2lkdGg9IjIiIHN0cm9rZT0iY3VycmVudENvbG9yIiBmaWxsPSJub25lIi8+PC9zdmc+')",
    svgMinus        = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxNiAxNiI+PHBhdGggZD0iTTMgOGgxMCIgc3Ryb2tlLXdpZHRoPSIyIiBzdHJva2U9ImN1cnJlbnRDb2xvciIgZmlsbD0ibm9uZSIvPjwvc3ZnPg==')",
    svgGear         = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA1MTIgNTEyIj48cGF0aCBkPSJNNDE2LjM0OSAyNTYuMDQ2Yy0uMDAxLTIxLjAxMyAxMy4xNDMtMzguOTQ4IDMxLjY1MS00Ni4wNjJhMTk2LjMwMiAxOTYuMzAyIDAgMCAwLTIzLjY2NC01Ny4xMzkgNDkuNDIzIDQ5LjQyMyAwIDAgMS0yMC4wODIgNC4yNTRjLTEyLjYyMSAwLTI1LjIzOC00LjgxMS0zNC44NzEtMTQuNDQyLTE0Ljg2My0xNC44NjMtMTguMjQ4LTM2Ljg0Ni0xMC4xOC01NC45N0ExOTYuMjc0IDE5Ni4yNzQgMCAwIDAgMzAyLjA3NCA2NEMyOTQuOTcxIDgyLjUyOSAyNzcuMDI3IDk1LjY5IDI1NiA5NS42OWMtMjEuMDI1IDAtMzguOTY5LTEzLjE2MS00Ni4wNzMtMzEuNjlhMTk2LjI0MyAxOTYuMjQzIDAgMCAwLTU3LjEyOCAyMy42ODhjOC4wNjggMTguMTIyIDQuNjgzIDQwLjEwNC0xMC4xODEgNTQuOTctOS42MzEgOS42MzEtMjIuMjUgMTQuNDQzLTM0Ljg3MSAxNC40NDNhNDkuNDI5IDQ5LjQyOSAwIDAgMS0yMC4wODMtNC4yNTVBMTk2LjI3MyAxOTYuMjczIDAgMCAwIDY0IDIwOS45ODRjMTguNTA5IDcuMTEyIDMxLjY1MiAyNS4wNDkgMzEuNjUyIDQ2LjA2MiAwIDIxLjAwOC0xMy4xMzIgMzguOTM2LTMxLjYzIDQ2LjA1NGExOTYuMzE4IDE5Ni4zMTggMCAwIDAgMjMuNjkyIDU3LjEyOCA0OS40MjggNDkuNDI4IDAgMCAxIDIwLjAzMi00LjIzMmMxMi42MjIgMCAyNS4yMzkgNC44MTIgMzQuODcxIDE0LjQ0MyAxNC44NDEgMTQuODQxIDE4LjIzOSAzNi43ODEgMTAuMjE1IDU0Ljg4OWExOTYuMjU3IDE5Ni4yNTcgMCAwIDAgNTcuMTMgMjMuNjczYzcuMTI4LTE4LjQ3OSAyNS4wNDYtMzEuNTk2IDQ2LjAzOC0zMS41OTYgMjAuOTkyIDAgMzguOTEgMTMuMTE1IDQ2LjAzNyAzMS41OTZhMTk2LjIzNCAxOTYuMjM0IDAgMCAwIDU3LjEzMi0yMy42NzVjLTguMDIzLTE4LjEwNi00LjYyNi00MC4wNDYgMTAuMjE2LTU0Ljg4NyA5LjYyOS05LjYzMiAyMi4yNDgtMTQuNDQ0IDM0Ljg2OC0xNC40NDQgNi44MzYgMCAxMy42NyAxLjQxMSAyMC4wMzMgNC4yMzNhMTk2LjMxOCAxOTYuMzE4IDAgMCAwIDIzLjY5Mi01Ny4xMjhjLTE4LjQ5OC03LjExOS0zMS42MjktMjUuMDQ4LTMxLjYyOS00Ni4wNTR6TTI1Ni45IDMzNS45Yy00NC4zIDAtODAtMzUuOS04MC04MCAwLTQ0LjEwMSAzNS43LTgwIDgwLTgwIDQ0LjI5OSAwIDgwIDM1Ljg5OSA4MCA4MCAwIDQ0LjEtMzUuNzAxIDgwLTgwIDgweiIvPjwvc3ZnPg==')",
    svgGear2        = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyAKICB3aWR0aD0iMS4zZW0iIAogIGhlaWdodD0iMWVtIiAKICB2aWV3Qm94PSIwIDAgMTM1MCAxMDI0IiAKICB2ZXJzaW9uPSIxLjEiIAogIHhtbG5zPSJodHRwOi8vd3d3LnczLm9yZy8yMDAwL3N2ZyIKPgogIDxwYXRoIAogICAgZmlsbD0ibm9uZSIgCiAgICBzdHJva2U9ImN1cnJlbnRDb2xvciIgCiAgICBzdHJva2Utd2lkdGg9IjUwIiAKICAgIHN0cm9rZS1saW5lam9pbj0icm91bmQiIAogICAgZD0iTTgzMi42OTggNTEyLjA5MmMtMC4wMDItNDIuMDI2IDI2LjI4Ni03Ny44OTYgNjMuMzAyLTkyLjEyNC05Ljc3NC00MC45MzItMjUuOTE0LTc5LjQtNDcuMzI4LTExNC4yNzgtMTIuNzUgNS42NzItMjYuNDYgOC41MDgtNDAuMTY0IDguNTA4LTI1LjI0MiAwLTUwLjQ3Ni05LjYyMi02OS43NDItMjguODg0LTI5LjcyNi0yOS43MjYtMzYuNDk2LTczLjY5Mi0yMC4zNi0xMDkuOTRDNjgzLjUzNiAxNTMuOTQ2IDY0NS4wOCAxMzcuNzkgNjA0LjE0OCAxMjggNTg5Ljk0MiAxNjUuMDU4IDU1NC4wNTQgMTkxLjM4IDUxMiAxOTEuMzhjLTQyLjA1IDAtNzcuOTM4LTI2LjMyMi05Mi4xNDYtNjMuMzgtNDAuOTMyIDkuNzktNzkuMzg2IDI1Ljk0Ni0xMTQuMjU2IDQ3LjM3NiAxNi4xMzYgMzYuMjQ0IDkuMzY2IDgwLjIwOC0yMC4zNjIgMTA5Ljk0LTE5LjI2MiAxOS4yNjItNDQuNSAyOC44ODYtNjkuNzQyIDI4Ljg4Ni0xMy43MDggMC0yNy40MTItMi44MzgtNDAuMTY2LTguNTFDMTUzLjkxNiAzNDAuNTY4IDEzNy43NzIgMzc5LjAzNCAxMjggNDE5Ljk2OGMzNy4wMTggMTQuMjI0IDYzLjMwNCA1MC4wOTggNjMuMzA0IDkyLjEyNCAwIDQyLjAxNi0yNi4yNjQgNzcuODcyLTYzLjI2IDkyLjEwOCA5Ljc5NiA0MC45MzIgMjUuOTUyIDc5LjM4NCA0Ny4zODQgMTE0LjI1NiAxMi43MjItNS42NDIgMjYuMzk2LTguNDY0IDQwLjA2NC04LjQ2NCAyNS4yNDQgMCA1MC40NzggOS42MjQgNjkuNzQyIDI4Ljg4NiAyOS42ODIgMjkuNjgyIDM2LjQ3OCA3My41NjIgMjAuNDMgMTA5Ljc3OCAzNC44NzYgMjEuNDIgNzMuMzI4IDM3LjU2NiAxMTQuMjYgNDcuMzQ2IDE0LjI1Ni0zNi45NTggNTAuMDkyLTYzLjE5MiA5Mi4wNzYtNjMuMTkyIDQxLjk4NCAwIDc3LjgyIDI2LjIzIDkyLjA3NCA2My4xOTIgNDAuOTM2LTkuNzggNzkuMzg2LTI1LjkyOCAxMTQuMjY0LTQ3LjM1LTE2LjA0Ni0zNi4yMTItOS4yNTItODAuMDkyIDIwLjQzMi0xMDkuNzc0IDE5LjI1OC0xOS4yNjQgNDQuNDk2LTI4Ljg4OCA2OS43MzYtMjguODg4IDEzLjY3MiAwIDI3LjM0IDIuODIyIDQwLjA2NiA4LjQ2NiAyMS40MzItMzQuODcyIDM3LjU4OC03My4zMjQgNDcuMzg0LTExNC4yNTZDODU4Ljk2IDU4OS45NjIgODMyLjY5OCA1NTQuMTA0IDgzMi42OTggNTEyLjA5MnpNNTEzLjggNjcxLjhjLTg4LjYgMC0xNjAtNzEuOC0xNjAtMTYwIDAtODguMjAyIDcxLjQtMTYwIDE2MC0xNjAgODguNTk4IDAgMTYwIDcxLjc5OCAxNjAgMTYwQzY3My44IDYwMCA2MDIuMzk4IDY3MS44IDUxMy44IDY3MS44eiIgCiAgLz4KPC9zdmc+')",
    svgAlertIconWarning = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB3aWR0aD0iNjRweCIgaGVpZ2h0PSI2NHB4IiB2aWV3Qm94PSIwIDAgMTAwIDEwMCIgdmVyc2lvbj0iMS4xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogICAgPGNpcmNsZSBjeD0iNTAiIGN5PSI1MCIgcj0iNDgiIGZpbGw9IiMyOTcxQjciPjwvY2lyY2xlPgogICA8ZyBmaWxsPSIjRkZGRkZGIj4KICAgICAgICA8cGF0aCBkPSJNNDQsMjIgTDU2LDIyIEw1Myw1OCBMNDcsNTggWiI+PC9wYXRoPgogICAgICAgIDxjaXJjbGUgY3g9IjUwIiBjeT0iNzQiIHI9IjYuNSI+PC9jaXJjbGU+CiAgICA8L2c+Cjwvc3ZnPg==')",
    svgAlertIconError = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB3aWR0aD0iNjRweCIgaGVpZ2h0PSI2NHB4IiB2aWV3Qm94PSIwIDAgMTAwIDEwMCIgdmVyc2lvbj0iMS4xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogICAgPHBhdGggZmlsbD0iI0QwMDIxQiIgZD0iTTI5LjUsNC41IEw3MC41LDQuNSBMOTUuNSwyOS41IEw5NS41LDcwLjUgTDcwLjUsOTUuNSBMMjkuNSw5NS41IEw0LjUsNzAuNSBMNC41LDI5LjUgWiI+PC9wYXRoPgogICAgPGcgZmlsbD0iI0ZGRkZGRiI+CiAgICAgICAgPHBhdGggZD0iTTQ2LDI0IEw1NCwyNCBMNTIsNTggTDQ4LDU4IFoiPjwvcGF0aD4KICAgICAgICA8Y2lyY2xlIGN4PSI1MCIgY3k9Ijc0IiByPSI1Ij48L2NpcmNsZT4KICAgIDwvZz4KPC9zdmc+')",
    svgAlertIconHelp = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB3aWR0aD0iNjRweCIgaGVpZ2h0PSI2NHB4IiB2aWV3Qm94PSIwIDAgMTAwIDEwMCIgdmVyc2lvbj0iMS4xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogICAgPGNpcmNsZSBjeD0iNTAiIGN5PSI1MCIgcj0iNDgiIGZpbGw9IiMyOTcxQjciPjwvY2lyY2xlPgogICAgPGcgZmlsbD0iI0ZGRkZGRiI+CiAgICAgICAgPHBhdGggZD0iTTM1LDM1IEExNSwxNSAwIDAsMSA2NSwzNSBDNjUsNDUgNTYsNDggNTYsNTggTDQ0LDU4IEM0NCw0NiA1Myw0NCA1MywzNSBBMywzIDAgMCwwIDQ3LDM1IEgzNSBaIj48L3BhdGg+CiAgICAgICAgPGNpcmNsZSBjeD0iNTAiIGN5PSI3NCIgcj0iNi41Ij48L2NpcmNsZT4KICAgIDwvZz4KPC9zdmc+')",
    svgAlertIconInformation = "url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB3aWR0aD0iNjRweCIgaGVpZ2h0PSI2NHB4IiB2aWV3Qm94PSIwIDAgMTAwIDEwMCIgdmVyc2lvbj0iMS4xIiB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciPgogICAgPGNpcmNsZSBjeD0iNTAiIGN5PSI1MCIgcj0iNDgiIGZpbGw9IiMyOTcxQjciPjwvY2lyY2xlPgogICAgPGcgZmlsbD0iI0ZGRkZGRiI+CiAgICAgICAgPGNpcmNsZSBjeD0iNTAiIGN5PSIyNiIgcj0iNi41Ij48L2NpcmNsZT4KICAgICAgICA8cGF0aCBkPSJNNDQsNDAgTDU2LDQwIEw1Niw3OCBMNDQsNzggWiI+PC9wYXRoPgogICAgPC9nPgo8L3N2Zz4=')";

// Global State Variables
var themedButtonValues                      = nil,
    themedTextFieldValues                   = nil,
    themedRoundedTextFieldValues            = nil,
    themedVerticalScrollerValues            = nil,
    themedHorizontalScrollerValues          = nil,
    themedSegmentedControlValues            = nil,
    themedHorizontalSliderValues            = nil,
    themedVerticalSliderValues              = nil,
    themedCircularSliderValues              = nil,
    themedAlertValues                       = nil,
    themedWindowViewValues                  = nil,
    themedProgressIndicator                 = nil,
    themedIndeterminateProgressIndicator    = nil,
    themedCheckBoxValues                    = nil,
    themedRadioButtonValues                 = nil,

// Text Colors
    regularTextColor                = [CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:1.0],
    regularTextShadowColor          = [CPColor colorWithCalibratedWhite:1.0 alpha:0.2],
    regularDisabledTextColor        = [CPColor colorWithCalibratedWhite:79.0 / 255.0 alpha:0.6],
    regularDisabledTextShadowColor  = [CPColor colorWithCalibratedWhite:240.0 / 255.0 alpha:0.6],

    defaultTextColor                = [CPColor whiteColor],
    defaultTextShadowColor          = [CPColor colorWithCalibratedWhite:0.0 alpha:0.3],
    defaultDisabledTextColor        = regularDisabledTextColor,
    defaultDisabledTextShadowColor  = regularDisabledTextShadowColor,

    placeholderColor                = regularDisabledTextColor;

@implementation Aristo3ThemeDescriptor : BKThemeDescriptor

+ (CPString)themeName
{
    return @"Aristo3";
}

+ (CPArray)themeShowcaseExcludes
{
    return [
            "themedAlert",
            "themedMenuView",
            "themedMenuItemStandardView",
            "themedMenuItemMenuBarView",
            "themedToolbarView",
            "themedBorderlessBridgeWindowView",
            "themedWindowView",
            "themedBrowser",
            "themedRuleEditor",
            "themedTableDataView",
            "themedCornerview",
            "themedTokenFieldTokenCloseButton",
            "themedColor",
            "themedView",
            "themedFont"
            ];
}

+ (CPView)themedView
{
    var view = [[CPView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)],
        dynamicSet = @{
                       @"A3CPColorActiveText":             A3CPColorActiveText,
                       @"A3CPColorInactiveText":           A3CPColorInactiveText,
                       @"A3CPColorDefaultText":            A3CPColorDefaultText,
                       @"A3CPColorActiveBorder":           A3CPColorActiveBorder,
                       @"A3ColorActiveBorder":             A3ColorActiveBorder,
                       @"A3CPColorInactiveBorder":         A3CPColorInactiveBorder,
                       @"A3ColorInactiveBorder":           A3ColorInactiveBorder,
                       @"A3ColorInactiveDarkBorder":       A3ColorInactiveDarkBorder,
                       @"A3ColorBorderLight":              A3ColorBorderLight,
                       @"A3ColorBorderMedium":             A3ColorBorderMedium,
                       @"A3ColorBorderDark":               A3ColorBorderDark,
                       @"A3ColorBorderBlue":               A3ColorBorderBlue,
                       @"A3CPColorBorderBlue":             A3CPColorBorderBlue,
                       @"A3ColorBorderBlueLight":          A3ColorBorderBlueLight,
                       @"A3ColorBorderBlueHighlighted":    A3ColorBorderBlueHighlighted,
                       @"A3ColorBackground":               A3ColorBackground,
                       @"A3ColorBackgroundInactive":       A3ColorBackgroundInactive,
                       @"A3ColorBackgroundHighlighted":    A3ColorBackgroundHighlighted,
                       @"A3ColorBackgroundWhite":          A3ColorBackgroundWhite,
                       @"A3ColorBackgroundDark":           A3ColorBackgroundDark,
                       @"A3ColorBorderRed":                A3ColorBorderRed,
                       @"A3ColorBorderRedLight":           A3ColorBorderRedLight,
                       @"A3ColorBorderRedHighlighted":     A3ColorBorderRedHighlighted,
                       @"A3ColorWindowHeadActive":         A3ColorWindowHeadActive,
                       @"A3ColorWindowHeadInactive":       A3ColorWindowHeadInactive,
                       @"A3ColorWindowButtonClose":        A3ColorWindowButtonClose,
                       @"A3ColorWindowButtonCloseDark":    A3ColorWindowButtonCloseDark,
                       @"A3ColorWindowButtonCloseLight":   A3ColorWindowButtonCloseLight,
                       @"A3ColorWindowButtonMin":          A3ColorWindowButtonMin,
                       @"A3ColorWindowButtonMinDark":      A3ColorWindowButtonMinDark,
                       @"A3ColorWindowButtonMinLight":     A3ColorWindowButtonMinLight,
                       @"A3ColorWindowButtonZoom":         A3ColorWindowButtonZoom,
                       @"A3ColorWindowButtonZoomDark":     A3ColorWindowButtonZoomDark,
                       @"A3ColorWindowButtonZoomLight":    A3ColorWindowButtonZoomLight,
                       @"A3ColorWindowBorder":             A3ColorWindowBorder,
                       @"A3ColorMenuLightBackground":      A3ColorMenuLightBackground,
                       @"A3ColorMenuBackground":           A3ColorMenuBackground,
                       @"A3ColorMenuCheckmark":            A3ColorMenuCheckmark,
                       @"A3ColorMenuBorder":               A3ColorMenuBorder,
                       @"A3ColorTextfieldActiveBorder":    A3ColorTextfieldActiveBorder,
                       @"A3ColorTextfieldInactiveBorder":  A3ColorTextfieldInactiveBorder,
                       @"A3CPColorTableAlternateRow":      A3CPColorTableAlternateRow,
                       @"A3CPColorTableDivider":           A3CPColorTableDivider,
                       @"A3ColorTableHeaderSeparator":     A3ColorTableHeaderSeparator,
                       @"A3ColorScrollerDark":             A3ColorScrollerDark
                       };

    [self registerThemeValues:[
                               [@"css-based", YES],
                               [@"dynamic-set", dynamicSet]
                               ]
                      forView:view];

    return view;
}

+ (CPFont)themedFont
{
    var font = [CPFont systemFontOfSize:12];

    [self registerThemeValues:[
                               [@"system-font-face", @"-apple-system, BlinkMacSystemFont, sans-serif"],
                               [@"system-font-size-regular", 13],
                               [@"system-font-size-small", 11],
                               [@"system-font-size-mini", 9]
                              ]
                      forObject:font];

    return font;
}

+ (CPColor)themedColor
{
    var color = [CPColor redColor],
    themedColorValues =
    [
     [@"alternate-selected-control-color",        [[CPColor alloc] _initWithRGBA:[0.22, 0.46, 0.84, 1.0]]],
     [@"secondary-selected-control-color",        [[CPColor alloc] _initWithRGBA:[0.83, 0.83, 0.83, 1.0]]],
     [@"selected-text-background-color",          [CPColor colorWithHexString:"99CCFF"]],
     [@"selected-text-inactive-background-color", [CPColor colorWithHexString:"CCCCCC"]]
    ];

    [self registerThemeValues:themedColorValues forObject:color];

    return color;
}

+ (CPButton)makeButton
{
    return [[CPButton alloc] initWithFrame:CGRectMake(0, 0, 100, 21)];
}

+ (CPButton)button
{
    var button = [self makeButton],

    // IB Style : Push (CPButtonStateBezelStyleRounded) - Bordered
    buttonCssColor = [CPColor colorWithCSSDictionary:@{
                                                       @"background-color": A3ColorBackgroundWhite,
                                                       @"border-color": A3ColorActiveBorder,
                                                       @"border-style": @"solid",
                                                       @"border-width": @"1px",
                                                       @"border-radius": @"3px",
                                                       @"box-sizing": @"border-box"
                                                       }],

    disabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorLightBackground,
                                                               @"border-color": A3ColorBackgroundBlack14,
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"border-radius": @"3px",
                                                               @"box-sizing": @"border-box"
                                                               }],

    highlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"background-color": A3ColorBorderBlueHighlighted,
                                                                  @"border-color": A3ColorBorderBlueHighlighted,
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"1px",
                                                                  @"border-radius": @"3px",
                                                                  @"box-sizing": @"border-box"
                                                                  }],

    selectedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorBorderBlue,
                                                               @"border-color": A3ColorBorderBlueHighlighted,
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"border-radius": @"3px",
                                                               @"box-sizing": @"border-box"
                                                               }],

    defaultButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                              @"background-color": @"A3ColorBorderBlue",
                                                              @"border-color": @"A3ColorBorderBlue",
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px",
                                                              @"border-radius": @"3px",
                                                              @"box-sizing": @"border-box"
                                                              }],

    defaultHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                         @"background-color": A3ColorBorderBlueHighlighted,
                                                                         @"border-color": A3ColorBorderBlueHighlighted,
                                                                         @"border-style": @"solid",
                                                                         @"border-width": @"1px",
                                                                         @"border-radius": @"3px",
                                                                         @"box-sizing": @"border-box"
                                                                         }],

    // IB Style : Square (CPShadowlessSquareBezelStyle) - Bordered
    squareButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorSquareButtonBackground,
                                                             @"border-color": A3ColorActiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"0px",
                                                             @"box-sizing": @"border-box"
                                                             }],

    squareDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                     @"background-color": A3ColorLightBackground,
                                                                     @"border-color": A3ColorInactiveBorder,
                                                                     @"border-style": @"solid",
                                                                     @"border-width": @"1px",
                                                                     @"border-radius": @"0px",
                                                                     @"box-sizing": @"border-box"
                                                                     }],

    squareHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                        @"background-color": A3ColorButtonBackgroundHighlighted,
                                                                        @"border-color": A3ColorActiveBorder,
                                                                        @"border-style": @"solid",
                                                                        @"border-width": @"1px",
                                                                        @"border-radius": @"0px",
                                                                        @"box-sizing": @"border-box"
                                                                        }],

    // IB Style : Gradient (CPSmallSquareBezelStyle) - Bordered
    gradientButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorSquareButtonBackground,
                                                               @"border-color": A3ColorActiveBorder,
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"border-radius": @"0px",
                                                               @"box-sizing": @"border-box"
                                                               }],

    gradientDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                       @"background-color": A3ColorBackground50,
                                                                       @"border-color": A3ColorInactiveBorder,
                                                                       @"border-style": @"solid",
                                                                       @"border-width": @"1px",
                                                                       @"border-radius": @"0px",
                                                                       @"box-sizing": @"border-box"
                                                                       }],

    gradientHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                          @"background-color": A3ColorButtonBackgroundHighlighted,
                                                                          @"border-color": A3ColorActiveBorder,
                                                                          @"border-style": @"solid",
                                                                          @"border-width": @"1px",
                                                                          @"border-radius": @"0px",
                                                                          @"box-sizing": @"border-box"
                                                                          }],

    // IB Style : Textured rounded (CPButtonStateBezelStyleTexturedRounded) - Bordered
    trButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                         @"background-color": A3ColorBackgroundWhite,
                                                         @"border-color": A3ColorActiveBorder,
                                                         @"border-style": @"solid",
                                                         @"border-width": @"1px",
                                                         @"border-radius": @"3px",
                                                         @"box-sizing": @"border-box"
                                                         }],

    trDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorLightBackground,
                                                                 @"border-color": A3ColorBackgroundBlack14,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"border-radius": @"3px",
                                                                 @"box-sizing": @"border-box"
                                                                 }],

    trHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": A3ColorBackgroundHighlighted,
                                                                    @"border-color": A3ColorActiveBorder,
                                                                    @"border-style": @"solid",
                                                                    @"border-width": @"1px",
                                                                    @"border-radius": @"3px",
                                                                    @"box-sizing": @"border-box"
                                                                    }],

    // IB Style : Round rect (CPButtonStateBezelStyleRoundRect) - Bordered
    rrButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                         @"background-color": A3ColorTransparent,
                                                         @"border-color": A3ColorActiveBorder,
                                                         @"border-style": @"solid",
                                                         @"border-width": @"1px",
                                                         @"border-radius": @"5px",
                                                         @"box-sizing": @"border-box"
                                                         }],

    rrDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorTransparent,
                                                                 @"border-color": A3ColorInactiveBorder,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"border-radius": @"5px",
                                                                 @"box-sizing": @"border-box"
                                                                 }],

    rrHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": A3ColorBackgroundDark35,
                                                                    @"border-color": A3ColorActiveBorder,
                                                                    @"border-style": @"solid",
                                                                    @"border-width": @"1px",
                                                                    @"border-radius": @"5px",
                                                                    @"box-sizing": @"border-box"
                                                                    }],

    // IB Style : Recessed (CPButtonStateBezelStyleRecessed) - Bordered
    recessedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorTransparent,
                                                               @"border-style": @"none",
                                                               @"border-radius": @"5px",
                                                               @"box-sizing": @"border-box"
                                                               }],

    recessedDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                       @"background-color": A3ColorTransparent,
                                                                       @"border-style": @"none",
                                                                       @"border-radius": @"5px",
                                                                       @"box-sizing": @"border-box"
                                                                       }],

    recessedHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                          @"background-color": A3ColorBackgroundBlack50,
                                                                          @"border-style": @"none",
                                                                          @"border-radius": @"5px",
                                                                          @"box-sizing": @"border-box"
                                                                          }],

    recessedHoveredButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                      @"background-color": A3ColorBackgroundBlack20,
                                                                      @"border-style": @"none",
                                                                      @"border-radius": @"5px",
                                                                      @"box-sizing": @"border-box"
                                                                      }],

    recessedSelectedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                       @"background-color": A3ColorBackgroundBlack35,
                                                                       @"border-style": @"none",
                                                                       @"border-radius": @"5px",
                                                                       @"box-sizing": @"border-box"
                                                                       }],

    // IB Style : Inline (CPButtonStateBezelStyleInline) - Bordered
    inlineButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorBackgroundBlack20,
                                                             @"border-style": @"none",
                                                             @"border-radius": @"8px",
                                                             @"box-sizing": @"border-box"
                                                             }],

    inlineDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                     @"background-color": A3ColorButtonBackgroundHighlighted50,
                                                                     @"border-style": @"none",
                                                                     @"border-radius": @"8px",
                                                                     @"box-sizing": @"border-box"
                                                                     }],

    inlineHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                        @"background-color": A3ColorBackgroundBlack50,
                                                                        @"border-style": @"none",
                                                                        @"border-radius": @"8px",
                                                                        @"box-sizing": @"border-box"
                                                                        }],

    // IB Style : Bevel (CPButtonStateBezelStyleRegularSquare) - Bordered
    bevelButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": A3ColorBackgroundWhite,
                                                            @"border-color": A3ColorActiveBorder,
                                                            @"border-style": @"solid",
                                                            @"border-width": @"1px",
                                                            @"border-radius": @"3px",
                                                            @"box-sizing": @"border-box"
                                                            }],

    bevelDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": A3ColorLightBackground,
                                                                    @"border-color": A3ColorBackgroundBlack14,
                                                                    @"border-style": @"solid",
                                                                    @"border-width": @"1px",
                                                                    @"border-radius": @"3px",
                                                                    @"box-sizing": @"border-box"
                                                                    }],

    bevelHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                       @"background-color": A3ColorBackground,
                                                                       @"border-color": A3ColorActiveBorder,
                                                                       @"border-style": @"solid",
                                                                       @"border-width": @"1px",
                                                                       @"border-radius": @"3px",
                                                                       @"box-sizing": @"border-box"
                                                                       }],

    // IB Style : Textured (CPButtonStateBezelStyleTextured) - Bordered
    texturedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorBackground90,
                                                               @"border-color": A3ColorActiveBorder,
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"border-radius": @"3px",
                                                               @"box-sizing": @"border-box"
                                                               }],

    texturedDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                       @"background-color": A3ColorBackground50, 
                                                                       @"border-color": A3ColorBackgroundBlack14,
                                                                       @"border-style": @"solid",
                                                                       @"border-width": @"1px",
                                                                       @"border-radius": @"3px",
                                                                       @"box-sizing": @"border-box"
                                                                       }],

    texturedHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                          @"background-color": A3ColorButtonBackgroundHighlighted80,
                                                                          @"border-color": A3ColorActiveBorder,
                                                                          @"border-style": @"solid",
                                                                          @"border-width": @"1px",
                                                                          @"border-radius": @"3px",
                                                                          @"box-sizing": @"border-box"
                                                                          }],

    // All styles - unbordered

    unborderedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorTransparent,
                                                                 @"box-sizing": @"border-box"
                                                                 }],

    unborderedHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                            @"background-color": A3ColorBackground,
                                                                            @"box-sizing": @"border-box"
                                                                            }],

    // Disclosure triangle (SVG based)

    disclosureImage = [CPImage imageWithCSSDictionary:@{
                                                        @"box-sizing": @"border-box",
                                                        @"background-color": A3ColorDisclosure,
                                                        "-webkit-mask-image": svgArrowRight,
                                                        "mask-image": svgArrowRight,
                                                        "-webkit-mask-size": "contain",
                                                        "mask-size": "contain",
                                                        "-webkit-mask-repeat": "no-repeat",
                                                        "mask-repeat": "no-repeat",
                                                        "-webkit-mask-position": "center",
                                                        "mask-position": "center",
                                                        @"transform": @"rotate(0deg)",
                                                        @"transition-duration": @"0.35s",
                                                        @"transition-property": @"transform"
                                                        }
                                                 size:CGSizeMake(10, 10)],

    disclosureDisabledImage = [CPImage imageWithCSSDictionary:@{
                                                                @"box-sizing": @"border-box",
                                                                @"background-color": A3ColorDisclosureDisabled,
                                                                "-webkit-mask-image": svgArrowRight,
                                                                "mask-image": svgArrowRight,
                                                                "-webkit-mask-size": "contain",
                                                                "mask-size": "contain",
                                                                "-webkit-mask-repeat": "no-repeat",
                                                                "mask-repeat": "no-repeat",
                                                                "-webkit-mask-position": "center",
                                                                "mask-position": "center"
                                                                }
                                                         size:CGSizeMake(10, 10)],

    disclosureHighlightedImage = [CPImage imageWithCSSDictionary:@{
                                                                   @"box-sizing": @"border-box",
                                                                   @"background-color": A3ColorDisclosurePushed,
                                                                   "-webkit-mask-image": svgArrowRight,
                                                                   "mask-image": svgArrowRight,
                                                                   "-webkit-mask-size": "contain",
                                                                   "mask-size": "contain",
                                                                   "-webkit-mask-repeat": "no-repeat",
                                                                   "mask-repeat": "no-repeat",
                                                                   "-webkit-mask-position": "center",
                                                                   "mask-position": "center"
                                                                   }
                                                            size:CGSizeMake(10, 10)],

    disclosureDownImage = [CPImage imageWithCSSDictionary:@{
                                                            @"box-sizing": @"border-box",
                                                            @"background-color": A3ColorDisclosure,
                                                            "-webkit-mask-image": svgArrowDown,
                                                            "mask-image": svgArrowDown,
                                                            "-webkit-mask-size": "contain",
                                                            "mask-size": "contain",
                                                            "-webkit-mask-repeat": "no-repeat",
                                                            "mask-repeat": "no-repeat",
                                                            "-webkit-mask-position": "center",
                                                            "mask-position": "center",
                                                            @"transform": @"rotate(0deg)", // SVG is already down
                                                            @"transition-duration": @"0.35s",
                                                            @"transition-property": @"transform"
                                                            }
                                                     size:CGSizeMake(10, 10)],

    disclosureDisabledDownImage = [CPImage imageWithCSSDictionary:@{
                                                                    @"box-sizing": @"border-box",
                                                                    @"background-color": A3ColorDisclosureDisabled,
                                                                    "-webkit-mask-image": svgArrowDown,
                                                                    "mask-image": svgArrowDown,
                                                                    "-webkit-mask-size": "contain",
                                                                    "mask-size": "contain",
                                                                    "-webkit-mask-repeat": "no-repeat",
                                                                    "mask-repeat": "no-repeat",
                                                                    "-webkit-mask-position": "center",
                                                                    "mask-position": "center"
                                                                    }
                                                             size:CGSizeMake(10, 10)],

    disclosureHighlightedDownImage = [CPImage imageWithCSSDictionary:@{
                                                                       @"box-sizing": @"border-box",
                                                                       @"background-color": A3ColorDisclosurePushed,
                                                                       "-webkit-mask-image": svgArrowDown,
                                                                       "mask-image": svgArrowDown,
                                                                       "-webkit-mask-size": "contain",
                                                                       "mask-size": "contain",
                                                                       "-webkit-mask-repeat": "no-repeat",
                                                                       "mask-repeat": "no-repeat",
                                                                       "-webkit-mask-position": "center",
                                                                       "mask-position": "center"
                                                                       }
                                                                size:CGSizeMake(10, 10)],

    // Disclosure rounded

    disclosureRoundedCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"background-color": A3ColorBackgroundWhite,
                                                                  @"border-color": A3ColorActiveBorder,
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"1px",
                                                                  @"border-radius": @"5px",
                                                                  @"box-sizing": @"border-box"
                                                                  }],

    disclosureRoundedDisabledCssColor = [CPColor colorWithCSSDictionary:@{
                                                                          @"background-color": A3ColorBackgroundInactive,
                                                                          @"border-color": A3ColorInactiveBorder,
                                                                          @"border-style": @"solid",
                                                                          @"border-width": @"1px",
                                                                          @"border-radius": @"5px",
                                                                          @"box-sizing": @"border-box"
                                                                          }],

    disclosureRoundedHighlightedCssColor = [CPColor colorWithCSSDictionary:@{
                                                                             @"background-color": A3ColorBackgroundInactive,
                                                                             @"border-color": A3ColorActiveBorder,
                                                                             @"border-style": @"solid",
                                                                             @"border-width": @"1px",
                                                                             @"border-radius": @"5px",
                                                                             @"box-sizing": @"border-box"
                                                                             }],

    disclosureOffImage = [CPImage imageWithCSSDictionary:@{
                                                           "-webkit-mask-image": svgArrowRight,
                                                           "mask-image": svgArrowRight,
                                                           "background-color": A3ColorActiveText,
                                                           "-webkit-mask-size": "contain",
                                                           "mask-size": "contain",
                                                           "-webkit-mask-repeat": "no-repeat",
                                                           "mask-repeat": "no-repeat",
                                                           "-webkit-mask-position": "center",
                                                           "mask-position": "center",
                                                           @"transform": "rotate(0deg)"
                                                           }
                                        beforeDictionary:nil
                                         afterDictionary:nil
                                                    size:CGSizeMake(7, 4)],

    disclosureOnImage = [CPImage imageWithCSSDictionary:@{
                                                          "-webkit-mask-image": svgArrowDown,
                                                          "mask-image": svgArrowDown,
                                                          "background-color": A3ColorActiveText,
                                                          "-webkit-mask-size": "contain",
                                                          "mask-size": "contain",
                                                          "-webkit-mask-repeat": "no-repeat",
                                                          "mask-repeat": "no-repeat",
                                                          "-webkit-mask-position": "center",
                                                          "mask-position": "center"
                                                          }
                                       beforeDictionary:nil
                                        afterDictionary:nil
                                                   size:CGSizeMake(7, 4)],
    // --- HUD SPECIFIC STYLES ---
    hudButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": @"rgba(0, 0, 0, 0.25)",
                                                            @"border-color": @"rgba(255, 255, 255, 0.25)",
                                                            @"border-style": @"solid",
                                                            @"border-width": @"1px",
                                                            @"border-radius": @"10px", // Capsule shape for HUD buttons
                                                            @"box-sizing": @"border-box",
                                                            @"box-shadow": @"0 1px 0 rgba(255,255,255,0.1) inset"
                                                        }],

    hudHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                        @"background-color": @"rgba(0, 0, 0, 0.5)",
                                                                        @"border-color": @"rgba(255, 255, 255, 0.4)",
                                                                        @"border-style": @"solid",
                                                                        @"border-width": @"1px",
                                                                        @"border-radius": @"10px",
                                                                        @"box-sizing": @"border-box"
                                                                    }],

    hudDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": @"rgba(0, 0, 0, 0.1)",
                                                                    @"border-color": @"rgba(255, 255, 255, 0.1)",
                                                                    @"border-style": @"solid",
                                                                    @"border-width": @"1px",
                                                                    @"border-radius": @"10px",
                                                                    @"box-sizing": @"border-box"
                                                                }];

    // Global
    themedButtonValues =
    [
     [@"direct-nib2cib-adjustment",     YES], // Don't let nib2cib "play" with buttons
     [@"invert-image",                  NO],  // By default, don't invert the image (works only with material icon images)
     [@"invert-image-on-push",          NO],  // By default, don't invert the image when the button is pushed (works only with material icon images)
     [@"line-break-mode",               CPLineBreakByTruncatingTail],
     [@"vertical-alignment",            CPCenterVerticalTextAlignment],

     [@"text-color",                    @"A3CPColorActiveText"], // FIXME: test is here also
     [@"text-color",                    A3CPColorInactiveText,                  CPThemeStateDisabled],

     [@"text-color",                    A3CPColorDefaultText,                   [CPThemeStateBordered, CPThemeStateDefault, CPThemeStateKeyWindow]],
     [@"text-color",                    A3CPColorActiveText,                    [CPThemeStateBordered, CPThemeStateDefault]],

     [@"text-color",                    A3CPColorDefaultText,                   CPThemeStateDefault],
     [@"text-color",                    A3CPColorInactiveText,                  [CPThemeStateDefault,  CPThemeStateDisabled]],

     [@"text-color",                    A3CPColorDefaultText,                   [CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"text-color",                    A3CPColorActiveText,                    [CPThemeStateBordered, CPThemeStateSelected]],
     [@"text-color",                    A3CPColorDefaultText,                   [CPThemeStateBordered, CPThemeStateHighlighted, CPThemeStateSelected]],


     // Unbordered

     [@"bezel-color",                   unborderedButtonCssColor],
     [@"bezel-color",                   unborderedButtonCssColor,               [CPThemeStateDisabled]],
     [@"bezel-color",                   unborderedHighlightedButtonCssColor,    [CPThemeStateHighlighted]],

     // Push unbordered

     [@"image-color",                   A3CPColorBlack50,                       CPButtonStateBezelStyleRounded],
     [@"image-color",                   A3CPColorBlack85,                       [CPButtonStateBezelStyleRounded, CPThemeStateHighlighted]],
     [@"image-color",                   A3CPColorBlack25,                       [CPButtonStateBezelStyleRounded, CPThemeStateDisabled]],
     [@"image-offset",                  1.0,                                    CPButtonStateBezelStyleRounded],

     // Recessed unbordered

     [@"bezel-color",                   unborderedHighlightedButtonCssColor,    [CPButtonStateBezelStyleRecessed]],
     [@"bezel-color",                   unborderedHighlightedButtonCssColor,    [CPButtonStateBezelStyleRecessed, CPThemeStateDisabled]],
     [@"bezel-color",                   unborderedHighlightedButtonCssColor,    [CPButtonStateBezelStyleRecessed, CPThemeStateHighlighted]],

     // Square unbordered

     [@"image-color",                   A3CPColorBlack50,                       CPButtonStateBezelStyleShadowlessSquare],
     [@"image-color",                   A3CPColorBlack85,                       [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateHighlighted]],
     [@"image-color",                   A3CPColorBlack25,                       [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateDisabled]],
     [@"image-offset",                  1.0,                                    CPButtonStateBezelStyleShadowlessSquare],

     // Gradient unbordered

     [@"image-color",                   A3CPColorBlack50,                       CPButtonStateBezelStyleSmallSquare],
     [@"image-color",                   A3CPColorBlack85,                       [CPButtonStateBezelStyleSmallSquare, CPThemeStateHighlighted]],
     [@"image-color",                   A3CPColorBlack25,                       [CPButtonStateBezelStyleSmallSquare, CPThemeStateDisabled]],
     [@"image-offset",                  1.0,                                    CPButtonStateBezelStyleSmallSquare],
     [@"nib2cib-adjustment-frame",      CGRectMake(1.0, 1.0, 0.0, 0.0),         CPButtonStateBezelStyleSmallSquare],

     // IB Style : Push (CPButtonStateBezelStyleRounded) - Bordered
     [@"bezel-color",                   buttonCssColor,                         [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"bezel-color",                   disabledButtonCssColor,                 [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                   highlightedButtonCssColor,              [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color",                   highlightedButtonCssColor,              [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateHighlighted, CPThemeStateSelected]],
     [@"bezel-color",                   selectedButtonCssColor,                 [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateSelected]],

     [@"bezel-color",                   defaultButtonCssColor,                  [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDefault, CPThemeStateKeyWindow]],
     [@"bezel-color",                   defaultHighlightedButtonCssColor,       [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDefault, CPThemeStateHighlighted]],

     [@"text-color",                    A3CPColorActiveText,                    [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"text-color",                    A3CPColorActiveTextHighlighted,         [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"text-color",                    A3CPColorInactiveText,                  [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"text-color",                    A3CPColorActiveTextHighlighted,         [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDefault, CPThemeStateKeyWindow]],
     [@"text-color",                    A3CPColorActiveTextHighlighted,         [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDefault, CPThemeStateHighlighted]],
     [@"text-color",                    A3CPColorInactiveText,                  [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDefault, CPThemeStateDisabled]],

     // Without this, unbordered image color values would be used
     [@"image-color",                   @"FollowTextColor",                     [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(-1.0, 6.0, 1.0, 5.0),       [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"image-offset",                  1.0,                                    [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",      CGRectMake(2.0,  0.0, -12.0, 0.0),      [CPButtonStateBezelStyleRounded, CPThemeStateBordered]], // Height is fixed by min/max -size
     [@"nib2cib-adjustment-frame",      CGRectMake(3.0,  0.0, -13.0, 0.0),      [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDefault]],
     [@"min-size",                      CGSizeMake(0.0, 22.0),                  [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(-1.0, 22.0),                 [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(0.0, 5.0, 1.0, 4.0),        [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"image-offset",                  1.0,                                    [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",      CGRectMake(5.0, -3.0, -10.0, 0.0),      [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeSmall]], // Height is fixed by min/max -size
     [@"min-size",                      CGSizeMake(0.0, 18.0),                  [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"max-size",                      CGSizeMake(-1.0, 18.0),                 [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeSmall]],

     [@"content-inset",                 CGInsetMake(1.0, 8.0, 1.0, 7.0),        [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"image-offset",                  1.0,                                    [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",      CGRectMake(1.0, -3.0, -2.0, 0.0),       [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeMini]], // Height is fixed by min/max -size
     [@"min-size",                      CGSizeMake(0.0, 15.0),                  [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"max-size",                      CGSizeMake(-1.0, 15.0),                 [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     
     [@"content-inset",                 CGInsetMake(1.0, 6.0, 1.0, 5.0),        [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeLarge]],
     [@"image-offset",                  1.0,                                    [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeLarge]],
     [@"nib2cib-adjustment-frame",      CGRectMake(5.0, 5.0, -10.0, 0.0),      [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeLarge]], // Height is fixed by min/max -size
     [@"min-size",                      CGSizeMake(0.0, 30.0),                  [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeLarge]],
     [@"max-size",                      CGSizeMake(-1.0, 30.0),                 [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateControlSizeLarge]],

     // IB Style : Square (CPShadowlessSquareBezelStyle) - Bordered
     [@"bezel-color",                   squareButtonCssColor,                   [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered]],
     [@"bezel-color",                   squareDisabledButtonCssColor,           [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                   squareHighlightedButtonCssColor,        [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"text-color",                    A3CPColorActiveText,                    [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"image-color",                   A3CPColorBlack85,                       [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered]],
     [@"image-color",                   A3CPColorBlack85,                       [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"image-color",                   A3CPColorBlack25,                       [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"image-offset",                  2.0,                                    [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(1.0, 2.0, 2.0, 2.0),       [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, 0.0, 0.0),         [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered]],
     [@"min-size",                      CGSizeMake(0.0, 0.0),                  [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(-1.0, -1.0),                 [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(2.0, 2.0, 2.0, 2.0),       [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, 0.0, 0.0),         [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"min-size",                      CGSizeMake(0.0, 0.0),                  [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"max-size",                      CGSizeMake(-1.0, -1.0),                 [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],

     [@"content-inset",                 CGInsetMake(2.0, 2.0, 2.0, 2.0),       [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, 0.0, 0.0),         [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"min-size",                      CGSizeMake(0.0, 0.0),                  [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"max-size",                      CGSizeMake(-1.0, -1.0),                 [CPButtonStateBezelStyleShadowlessSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],

     // IB Style : Gradient (CPSmallSquareBezelStyle) - Bordered
     [@"bezel-color",                   gradientButtonCssColor,                 [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered]],
     [@"bezel-color",                   gradientDisabledButtonCssColor,         [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                   gradientHighlightedButtonCssColor,      [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"text-color",                    A3CPColorActiveText,                    [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"image-color",                   A3CPColorBlack85,                       [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered]],
     [@"image-color",                   A3CPColorBlack85,                       [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"image-color",                   A3CPColorBlack25,                       [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"image-offset",                  2.0,                                    [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(0.0, 2.0, 2.0, 2.0),       [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -1.0, 0.0, -2.0),       [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered]],
     [@"min-size",                      CGSizeMake(0.0, 0.0),                  [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(-1.0, -1.0),                 [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(2.0, 2.0, 2.0, 2.0),       [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -1.0, 0.0, -2.0),       [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"min-size",                      CGSizeMake(0.0, 0.0),                  [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"max-size",                      CGSizeMake(-1.0, -1.0),                 [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],

     [@"content-inset",                 CGInsetMake(2.0, 2.0, 2.0, 2.0),       [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -1.0, 0.0, -2.0),       [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"min-size",                      CGSizeMake(0.0, 0.0),                  [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"max-size",                      CGSizeMake(-1.0, -1.0),                 [CPButtonStateBezelStyleSmallSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],

     // --- FORCE DARK TEXT FOR DEFAULT STATE ---
     // This overrides the global rule that turns text white for "Default" (Return key) buttons
     [@"text-color",                    A3CPColorActiveText,                    [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateDefault]],
     [@"text-color",                    A3CPColorActiveText,                    [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateDefault, CPThemeStateKeyWindow]],

     // IB Style : Textured rounded (CPButtonStateBezelStyleTexturedRounded) - Bordered
     [@"bezel-color",                   trButtonCssColor,                       [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered]],
     [@"bezel-color",                   trDisabledButtonCssColor,               [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                   trHighlightedButtonCssColor,            [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"text-color",                    A3CPColorActiveText65,                  [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered]],
     [@"text-color",                    A3CPColorActiveText,                    [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"text-color",                    A3CPColorInactiveText,                  [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateDisabled]],

     [@"content-inset",                 CGInsetMake(0.0, 7.0, 1.0, 7.0),       [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -3.0, 0.0, -3.0),       [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered]],
     [@"min-size",                      CGSizeMake(0.0, 22.0),                  [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(-1.0, 22.0),                 [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(1.0, 7.0, 1.0, 7.0),       [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 4.0, 0.0, -1.0),       [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"min-size",                      CGSizeMake(0.0, 18.0),                  [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"max-size",                      CGSizeMake(-1.0, 18.0),                 [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateControlSizeSmall]],

     [@"content-inset",                 CGInsetMake(1.0, 5.0, 1.0, 5.0),       [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 4.0, 0.0, -1.0),       [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"min-size",                      CGSizeMake(0.0, 15.0),                  [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"max-size",                      CGSizeMake(-1.0, 15.0),                 [CPButtonStateBezelStyleTexturedRounded, CPThemeStateBordered, CPThemeStateControlSizeMini]],

     // IB Style : Round rect (CPButtonStateBezelStyleRoundRect) - Bordered
     [@"bezel-color",                   rrButtonCssColor,                       [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered]],
     [@"bezel-color",                   rrDisabledButtonCssColor,               [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                   rrHighlightedButtonCssColor,            [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"text-color",                    A3CPColorActiveText,                    [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"content-inset",                 CGInsetMake(1.0, 7.0, 1.0, 7.0),        [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -3.0, 0.0, -1.0),       [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered]],
     [@"min-size",                      CGSizeMake(0.0, 18.0),                  [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(-1.0, 18.0),                 [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(1.0, 7.0, 1.0, 7.0),       [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, 0.0, -1.0),       [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"min-size",                      CGSizeMake(0.0, 16.0),                  [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"max-size",                      CGSizeMake(-1.0, 16.0),                 [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateControlSizeSmall]],

     [@"content-inset",                 CGInsetMake(1.0, 7.0, 1.0, 7.0),       [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -5.0, 0.0, -3.0),       [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"min-size",                      CGSizeMake(0.0, 14.0),                  [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"max-size",                      CGSizeMake(-1.0, 14.0),                 [CPButtonStateBezelStyleRoundRect, CPThemeStateBordered, CPThemeStateControlSizeMini]],

     // IB Style : Recessed (CPButtonStateBezelStyleRecessed) - Bordered
     [@"bezel-color",                   recessedButtonCssColor,                 [CPButtonStateBezelStyleRecessed, CPThemeStateBordered]],
     [@"bezel-color",                   recessedDisabledButtonCssColor,         [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                   recessedDisabledButtonCssColor,         [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateDisabled, CPThemeStateHovered]],
     [@"bezel-color",                   recessedHighlightedButtonCssColor,      [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color",                   recessedHoveredButtonCssColor,          [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateHovered]],
     [@"bezel-color",                   recessedSelectedButtonCssColor,         [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateSelected]],
     [@"bezel-color",                   recessedDisabledButtonCssColor,         [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateSelected, CPThemeStateDisabled]],
     [@"bezel-color",                   recessedDisabledButtonCssColor,         [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateSelected, CPThemeStateDisabled, CPThemeStateHovered]],
     [@"bezel-color",                   recessedHighlightedButtonCssColor,      [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateSelected, CPThemeStateHighlighted]],
     [@"bezel-color",                   recessedHoveredButtonCssColor,          [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateSelected, CPThemeStateHovered]],

     [@"text-color",                    A3CPColorActiveText65,                  [CPButtonStateBezelStyleRecessed, CPThemeStateBordered]],
     [@"text-color",                    A3CPColorDefaultText,                   [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"text-color",                    A3CPColorDefaultText,                   [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateHovered]],
     [@"text-color",                    A3CPColorDefaultText,                   [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateSelected]],
     [@"text-color",                    A3CPColorInactiveText,                  [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"text-color",                    A3CPColorInactiveWhiteText,             [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateDisabled, CPThemeStateSelected]],
     [@"text-color",                    A3CPColorInactiveWhiteText,             [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateDisabled, CPThemeStateHighlighted]],

     [@"content-inset",                 CGInsetMake(1.0, 6.0, 1.0, 4.0),        [CPButtonStateBezelStyleRecessed, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, 0.0, -1.0),       [CPButtonStateBezelStyleRecessed, CPThemeStateBordered]],
     [@"min-size",                      CGSizeMake(0.0, 18.0),                  [CPButtonStateBezelStyleRecessed, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(-1.0, 18.0),                 [CPButtonStateBezelStyleRecessed, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(1.0, 6.0, 1.0, 4.0),        [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, 0.0, -1.0),       [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"min-size",                      CGSizeMake(0.0, 16.0),                  [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"max-size",                      CGSizeMake(-1.0, 16.0),                 [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateControlSizeSmall]],

     [@"content-inset",                 CGInsetMake(1.0, 6.0, 1.0, 4.0),        [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -5.0, 0.0, -3.0),       [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"min-size",                      CGSizeMake(0.0, 14.0),                  [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"max-size",                      CGSizeMake(-1.0, 14.0),                 [CPButtonStateBezelStyleRecessed, CPThemeStateBordered, CPThemeStateControlSizeMini]],

     // IB Style : Inline (CPButtonStateBezelStyleInline) - Bordered
     [@"bezel-color",                   inlineButtonCssColor,                   [CPButtonStateBezelStyleInline, CPThemeStateBordered]],
     [@"bezel-color",                   inlineDisabledButtonCssColor,           [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                   inlineHighlightedButtonCssColor,        [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"text-color",                    A3CPColorDefaultText,                   [CPButtonStateBezelStyleInline, CPThemeStateBordered]],
     [@"text-color",                    A3CPColorInactiveText,                  [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"text-color",                    A3CPColorDefaultText,                   [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"content-inset",                 CGInsetMake(1.0, 2.0, 1.0, 2.0),        [CPButtonStateBezelStyleInline, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, 0.0, -1.0),       [CPButtonStateBezelStyleInline, CPThemeStateBordered]],
     [@"min-size",                      CGSizeMake(0.0, 16.0),                  [CPButtonStateBezelStyleInline, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(-1.0, 16.0),                 [CPButtonStateBezelStyleInline, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(1.0, 2.0, 1.0, 2.0),        [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, 0.0, -1.0),       [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"min-size",                      CGSizeMake(0.0, 16.0),                  [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"max-size",                      CGSizeMake(-1.0, 16.0),                 [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateControlSizeSmall]],

     [@"content-inset",                 CGInsetMake(1.0, 2.0, 1.0, 2.0),        [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, 0.0, -1.0),       [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"min-size",                      CGSizeMake(0.0, 16.0),                  [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"max-size",                      CGSizeMake(-1.0, 16.0),                 [CPButtonStateBezelStyleInline, CPThemeStateBordered, CPThemeStateControlSizeMini]],

     // IB Style : Bevel (CPButtonStateBezelStyleRegularSquare) - Bordered
     [@"bezel-color",                   bevelButtonCssColor,                    [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered]],
     [@"bezel-color",                   bevelDisabledButtonCssColor,            [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                   bevelHighlightedButtonCssColor,         [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"text-color",                    A3CPColorActiveText,                    [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"content-inset",                 CGInsetMake(-3.0, 8.0, 0.0, 6.0),       [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",      CGRectMake(2.0, -8.0, -4.0, -5.0),      [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered]],
     [@"min-size",                      CGSizeMake(0.0, 21.0),                  [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(-1.0, 21.0),                 [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(-3.0, 8.0, 0.0, 6.0),       [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",      CGRectMake(2.0, -8.0, -4.0, -5.0),      [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"min-size",                      CGSizeMake(0.0, 21.0),                  [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"max-size",                      CGSizeMake(-1.0, 21.0),                 [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateControlSizeSmall]],

     [@"content-inset",                 CGInsetMake(-3.0, 8.0, 0.0, 6.0),       [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",      CGRectMake(2.0, -8.0, -4.0, -5.0),      [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"min-size",                      CGSizeMake(0.0, 21.0),                  [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"max-size",                      CGSizeMake(-1.0, 21.0),                 [CPButtonStateBezelStyleRegularSquare, CPThemeStateBordered, CPThemeStateControlSizeMini]],

     // IB Style : Textured (CPButtonStateBezelStyleTextured) - Bordered
     [@"bezel-color",                   texturedButtonCssColor,                 [CPButtonStateBezelStyleTextured, CPThemeStateBordered]],
     [@"bezel-color",                   texturedDisabledButtonCssColor,         [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                   texturedHighlightedButtonCssColor,      [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"text-color",                    A3CPColorActiveText,                    [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"content-inset",                 CGInsetMake(-1.0, 8.0, 0.0, 6.0),       [CPButtonStateBezelStyleTextured, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -5.0, 0.0, -3.0),       [CPButtonStateBezelStyleTextured, CPThemeStateBordered]],
     [@"min-size",                      CGSizeMake(0.0, 20.0),                  [CPButtonStateBezelStyleTextured, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(-1.0, 20.0),                 [CPButtonStateBezelStyleTextured, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(1.0, 8.0, 0.0, 6.0),       [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, 0.0, -1.0),       [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"min-size",                      CGSizeMake(0.0, 18.0),                  [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"max-size",                      CGSizeMake(-1.0, 18.0),                 [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateControlSizeSmall]],

     [@"content-inset",                 CGInsetMake(0.0, 8.0, 0.0, 6.0),       [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, 0.0, -1.0),       [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"min-size",                      CGSizeMake(0.0, 15.0),                  [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"max-size",                      CGSizeMake(-1.0, 15.0),                 [CPButtonStateBezelStyleTextured, CPThemeStateBordered, CPThemeStateControlSizeMini]],

     [@"bezel-color",                   unborderedButtonCssColor,               [CPButtonStateBezelStyleDisclosure]],
     [@"bezel-color",                   unborderedButtonCssColor,               [CPButtonStateBezelStyleDisclosure, CPThemeStateHighlighted]],
     [@"bezel-color",                   unborderedButtonCssColor,               [CPButtonStateBezelStyleDisclosure, CPThemeStateSelected]],
     [@"bezel-color",                   unborderedButtonCssColor,               [CPButtonStateBezelStyleDisclosure, CPThemeStateSelected, CPThemeStateHighlighted]],

     // IB Style : Disclosure triangle (CPButtonStateBezelStyleDisclosure) - Bordered
     [@"image",                         disclosureImage,                        [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered]],
     [@"image",                         disclosureDisabledImage,                [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"image",                         disclosureHighlightedImage,             [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"image",                         disclosureDownImage,                    [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered, CPThemeStateSelected]],
     [@"image",                         disclosureHighlightedDownImage,         [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered, CPThemeStateSelected, CPThemeStateHighlighted]],
     [@"image",                         disclosureDisabledDownImage,            [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered, CPThemeStateSelected, CPThemeStateDisabled]],

     [@"image-offset",                  0.0,                                    [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered]],
     [@"image-position",                CPImageOnly,                            [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(0.0, 0.0, 0.0, 2.0),        [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",      CGRectMake(3.0, -3.0, 0.0, 0.0),        [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered]],
     [@"min-size",                      CGSizeMake(13.0, 13.0),                 [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(13.0, 13.0),                 [CPButtonStateBezelStyleDisclosure, CPThemeStateBordered]],

     // IB Style : Disclosure rounded (CPButtonStateBezelStyleRoundedDisclosure) - Bordered
     [@"bezel-color",                   disclosureRoundedCssColor,              [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered]],
     [@"bezel-color",                   disclosureRoundedDisabledCssColor,      [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                   disclosureRoundedHighlightedCssColor,   [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"image",                         disclosureOffImage,                     [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered]],
     [@"image",                         disclosureOnImage,                      [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateSelected]],

     [@"image-offset",                  0.0,                                    [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered]],
     [@"image-position",                CPImageOnly,                            [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(1.0, 0.0, 0.0, 0.0),        [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered]],
     [@"content-inset",                 CGInsetMake(0.0, 0.0, 0.0, 0.0),        [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateSelected]],

     [@"nib2cib-adjustment-frame",      CGRectMake(4.0, -8.0, -8.0, -5.0),      [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered]],
     [@"min-size",                      CGSizeMake(21.0, 21.0),                 [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered]],
     [@"max-size",                      CGSizeMake(21.0, 21.0),                 [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered]],

     [@"content-inset",                 CGInsetMake(0.0, 0.0, 0.0, 0.0),        [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"nib2cib-adjustment-frame",      CGRectMake(3.0, -8.0, -6.0, -5.0),      [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"min-size",                      CGSizeMake(19.0, 18.0),                 [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateControlSizeSmall]],
     [@"max-size",                      CGSizeMake(19.0, 18.0),                 [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateControlSizeSmall]],

     [@"content-inset",                 CGInsetMake(0.0, 0.0, 0.0, 0.0),        [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, -2.0, -1.0),      [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"min-size",                      CGSizeMake(15.0, 15.0),                 [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateControlSizeMini]],
     [@"max-size",                      CGSizeMake(15.0, 15.0),                 [CPButtonStateBezelStyleRoundedDisclosure, CPThemeStateBordered, CPThemeStateControlSizeMini]],


     [@"min-size",       CGSizeMake(0.0, 20.0),                          CPThemeStateControlSizeSmall],
     [@"max-size",       CGSizeMake(-1.0, 20.0),                         CPThemeStateControlSizeSmall],
     [@"min-size",       CGSizeMake(0.0, 16.0),                          CPThemeStateControlSizeMini],
     [@"max-size",       CGSizeMake(-1.0, 16.0),                         CPThemeStateControlSizeMini],

     [@"image-offset",   CPButtonImageOffset],

// --- HUD MAPPINGS ---
     
     // 1. Force Text Color White
     [@"text-color",    [CPColor whiteColor],                   CPThemeStateHUD],
     [@"text-color",    [CPColor colorWithWhite:1 alpha:0.4],   [CPThemeStateHUD, CPThemeStateDisabled]],
     
     // Ensure white text persists even when button thinks it is Default or Highlighted in HUD
     [@"text-color",    [CPColor whiteColor],                   [CPButtonStateBezelStyleRounded, CPThemeStateHUD]],
     [@"text-color",    [CPColor whiteColor],                   [CPButtonStateBezelStyleRounded, CPThemeStateHUD, CPThemeStateDefault]],
     [@"text-color",    [CPColor whiteColor],                   [CPButtonStateBezelStyleRounded, CPThemeStateHUD, CPThemeStateHighlighted]],

     // Force white text for Bordered + Highlighted states in HUD to override standard theme specificity
     [@"text-color",    [CPColor whiteColor],                   [CPButtonStateBezelStyleRounded, CPThemeStateHUD, CPThemeStateBordered]],
     [@"text-color",    [CPColor whiteColor],                   [CPButtonStateBezelStyleRounded, CPThemeStateHUD, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"text-color",    [CPColor whiteColor],                   [CPButtonStateBezelStyleRounded, CPThemeStateHUD, CPThemeStateBordered, CPThemeStateSelected]],
     
     // High specificity rule for Disabled HUD buttons to prevent them from looking enabled (white)
     [@"text-color",    [CPColor colorWithWhite:1 alpha:0.4],   [CPButtonStateBezelStyleRounded, CPThemeStateHUD, CPThemeStateBordered, CPThemeStateDisabled]],

     [@"text-color",    [CPColor whiteColor],                   [CPButtonStateBezelStyleSmallSquare, CPThemeStateHUD]],
     [@"text-color",    [CPColor whiteColor],                   [CPButtonStateBezelStyleSmallSquare, CPThemeStateHUD, CPThemeStateHighlighted]],

     // 2. Rounded Bezel Style (Standard Push Button)
     [@"bezel-color",   hudButtonCssColor,                      [CPButtonStateBezelStyleRounded, CPThemeStateHUD, CPThemeStateBordered]],
     [@"bezel-color",   hudButtonCssColor,                      [CPButtonStateBezelStyleRounded, CPThemeStateHUD, CPThemeStateBordered, CPThemeStateDefault]],
     [@"bezel-color",   hudHighlightedButtonCssColor,           [CPButtonStateBezelStyleRounded, CPThemeStateHUD, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color",   hudDisabledButtonCssColor,              [CPButtonStateBezelStyleRounded, CPThemeStateHUD, CPThemeStateBordered, CPThemeStateDisabled]],
     
     // 3. Small Square Bezel Style (Secondary Alert Buttons)
     [@"bezel-color",   hudButtonCssColor,                      [CPButtonStateBezelStyleSmallSquare, CPThemeStateHUD, CPThemeStateBordered]],
     [@"bezel-color",   hudHighlightedButtonCssColor,           [CPButtonStateBezelStyleSmallSquare, CPThemeStateHUD, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color",   hudDisabledButtonCssColor,              [CPButtonStateBezelStyleSmallSquare, CPThemeStateHUD, CPThemeStateBordered, CPThemeStateDisabled]],

     // 4. Textured Rounded
     [@"bezel-color",   hudButtonCssColor,                      [CPButtonStateBezelStyleTexturedRounded, CPThemeStateHUD, CPThemeStateBordered]],
     [@"bezel-color",   hudHighlightedButtonCssColor,           [CPButtonStateBezelStyleTexturedRounded, CPThemeStateHUD, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color",   hudDisabledButtonCssColor,              [CPButtonStateBezelStyleTexturedRounded, CPThemeStateHUD, CPThemeStateBordered, CPThemeStateDisabled]],

     // 5. Round Rect (This is the default style in CPButton.j)
     [@"bezel-color",   hudButtonCssColor,                      [CPButtonStateBezelStyleRoundRect, CPThemeStateHUD, CPThemeStateBordered]],
     [@"bezel-color",   hudHighlightedButtonCssColor,           [CPButtonStateBezelStyleRoundRect, CPThemeStateHUD, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color",   hudDisabledButtonCssColor,              [CPButtonStateBezelStyleRoundRect, CPThemeStateHUD, CPThemeStateBordered, CPThemeStateDisabled]],

     // Adjust Layout for HUD
     // Rounded
     [@"min-size",      CGSizeMake(0.0, 18.0),                  [CPButtonStateBezelStyleRounded, CPThemeStateHUD]],
     [@"content-inset", CGInsetMake(0.0, 10.0, 1.0, 10.0),      [CPButtonStateBezelStyleRounded, CPThemeStateHUD]],

     [@"text-color",    [CPColor whiteColor],                   [CPButtonStateBezelStyleRounded, CPThemeStateHUD, CPThemeStateBordered, CPThemeStateDefault, CPThemeStateHighlighted]],
     [@"text-color",    [CPColor whiteColor],                   [CPButtonStateBezelStyleRounded, CPThemeStateHUD, CPThemeStateBordered, CPThemeStateKeyWindow, CPThemeStateHighlighted]],
     [@"text-color",    [CPColor whiteColor],                   [CPButtonStateBezelStyleRoundRect, CPThemeStateHUD, CPThemeStateBordered, CPThemeStateDefault, CPThemeStateHighlighted]],
     [@"text-color",    [CPColor whiteColor],                   [CPButtonStateBezelStyleRoundRect, CPThemeStateHUD, CPThemeStateBordered, CPThemeStateKeyWindow, CPThemeStateHighlighted]],

     // Small Square
     [@"min-size",      CGSizeMake(0.0, 18.0),                  [CPButtonStateBezelStyleSmallSquare, CPThemeStateHUD]],
     [@"content-inset", CGInsetMake(0.0, 10.0, 1.0, 10.0),      [CPButtonStateBezelStyleSmallSquare, CPThemeStateHUD]]
    ];

    [self registerThemeValues:themedButtonValues forView:button];

    return button;
}

+ (CPButton)themedStandardButton
{
    var button = [self button];

    [button setTitle:@"Cancel"];

    return button;
}

#pragma mark -

+ (CPPopUpButton)themedPopUpButton
{
    var button = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 21.0) pullsDown:NO],

    // Helper for Consistent Arrow Styling
    arrowCSS = function(color, rightOffset, boxSize) {
        var size = boxSize || "25px",
            offset = rightOffset || "-8px",
            marginTop = -(parseInt(size) / 2.0);

        return @{
            @"content": @"''",
            @"position": @"absolute",
            @"top": @"50%",
            @"right": offset,
            @"width": size,
            @"height": size,
            @"margin-top": marginTop + "px",

            "-webkit-mask-image": svgDoubleArrow,
            "mask-image": svgDoubleArrow,
            "-webkit-mask-size": "contain",
            "mask-size": "contain",
            "-webkit-mask-repeat": "no-repeat",
            "mask-repeat": "no-repeat",
            "-webkit-mask-position": "center",
            "mask-position": "center",
            
            @"background-color": color
        };
    },
    
    // Helper for Separator Styling (ensures consistency across states)
    separatorCSS = function(rightOffset) {
        return @{
            @"background-color": @"rgb(225,225,225)",
            @"bottom": @"3px",
            @"content": @"''",
            @"position": @"absolute",
            @"right": rightOffset || @"17px",
            @"top": @"3px",
            @"width": @"1px"
        };
    },

    // ==========================================================
    // REGULAR SIZE DEFINITIONS
    // ==========================================================
    
    buttonCssColor = [CPColor colorWithCSSDictionary:@{
                                                       @"background-color": A3ColorBackgroundWhite,
                                                       @"border-color": A3ColorActiveBorder,
                                                       @"border-style": @"solid",
                                                       @"border-width": @"1px",
                                                       @"border-radius": @"3px",
                                                       @"box-sizing": @"border-box"
                                                       }
                                    beforeDictionary:separatorCSS(@"17px")
                                     afterDictionary:arrowCSS(A3ColorBorderBlue, "-8px", "25px")],

    notKeyButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorBackgroundWhite,
                                                             @"border-color": A3ColorActiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"3px",
                                                             @"box-sizing": @"border-box"
                                                             }
                                          beforeDictionary:separatorCSS(@"17px")
                                           afterDictionary:arrowCSS(A3ColorInactiveText, "-8px", "25px")],

    disabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorBackgroundInactive,
                                                               @"border-color": A3ColorInactiveBorder,
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"border-radius": @"3px",
                                                               @"box-sizing": @"border-box"
                                                               }
                                            beforeDictionary:nil 
                                             afterDictionary:arrowCSS(A3ColorInactiveText, "-8px", "25px")],

    highlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"border-color": A3ColorBorderDark,
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"1px",
                                                                  @"border-radius": @"3px",
                                                                  @"box-sizing": @"border-box",
                                                                  @"background-color": A3ColorBackgroundHighlighted
                                                                  }
                                               beforeDictionary:separatorCSS(@"17px")
                                                afterDictionary:arrowCSS(A3ColorBorderBlue, "-8px", "25px")],

    // ==========================================================
    // SMALL SIZE DEFINITIONS
    // ==========================================================

    smallButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                       @"background-color": A3ColorBackgroundWhite,
                                                       @"border-color": A3ColorActiveBorder,
                                                       @"border-style": @"solid",
                                                       @"border-width": @"1px",
                                                       @"border-radius": @"3px",
                                                       @"box-sizing": @"border-box"
                                                       }
                                    beforeDictionary:separatorCSS(@"15px")
                                     afterDictionary:arrowCSS(A3ColorBorderBlue, "-8px", "23px")],

    smallNotKeyButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorBackgroundWhite,
                                                             @"border-color": A3ColorActiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"3px",
                                                             @"box-sizing": @"border-box"
                                                             }
                                          beforeDictionary:separatorCSS(@"15px")
                                           afterDictionary:arrowCSS(A3ColorInactiveText, "-8px", "23px")],

    smallDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorBackgroundInactive,
                                                               @"border-color": A3ColorInactiveBorder,
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"border-radius": @"3px",
                                                               @"box-sizing": @"border-box"
                                                               }
                                            beforeDictionary:nil
                                             afterDictionary:arrowCSS(A3ColorInactiveText, "-8px", "23px")],

    smallHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"border-color": A3ColorBorderDark,
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"1px",
                                                                  @"border-radius": @"3px",
                                                                  @"box-sizing": @"border-box",
                                                                  @"background-color": A3ColorBackgroundHighlighted
                                                                  }
                                                 beforeDictionary:separatorCSS(@"15px")
                                                  afterDictionary:arrowCSS(A3ColorBorderBlue, "-8px", "23px")],

    // ==========================================================
    // MINI SIZE DEFINITIONS
    // ==========================================================

    miniButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                       @"background-color": A3ColorBackgroundWhite,
                                                       @"border-color": A3ColorActiveBorder,
                                                       @"border-style": @"solid",
                                                       @"border-width": @"1px",
                                                       @"border-radius": @"3px",
                                                       @"box-sizing": @"border-box"
                                                       }
                                    beforeDictionary:separatorCSS(@"13px")
                                     afterDictionary:arrowCSS(A3ColorBorderBlue, "-7px", "20px")],

    miniNotKeyButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorBackgroundWhite,
                                                             @"border-color": A3ColorActiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"3px",
                                                             @"box-sizing": @"border-box"
                                                             }
                                          beforeDictionary:separatorCSS(@"13px")
                                           afterDictionary:arrowCSS(A3ColorInactiveText, "-7px", "20px")],

    miniDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorBackgroundInactive,
                                                               @"border-color": A3ColorInactiveBorder,
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"border-radius": @"3px",
                                                               @"box-sizing": @"border-box"
                                                               }
                                            beforeDictionary:nil
                                             afterDictionary:arrowCSS(A3ColorInactiveText, "-7px", "20px")],

    miniHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"border-color": A3ColorBorderDark,
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"1px",
                                                                  @"border-radius": @"3px",
                                                                  @"box-sizing": @"border-box",
                                                                  @"background-color": A3ColorBackgroundHighlighted
                                                                  }
                                                 beforeDictionary:separatorCSS(@"13px")
                                                  afterDictionary:arrowCSS(A3ColorBorderBlue, "-7px", "20px")],
    // HUD Arrow Helper (White arrows)
    hudArrowCSS = function(color) {
        return arrowCSS(color, "-8px", "25px");
    },
    
    hudButtonCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0, 0, 0, 0.25)",
        @"border-color": @"rgba(255, 255, 255, 0.25)",
        @"border-style": @"solid",
        @"border-width": @"1px",
        @"border-radius": @"3px",
        @"box-sizing": @"border-box",
        @"box-shadow": @"0 1px 0 rgba(255,255,255,0.1) inset"
    } beforeDictionary:nil afterDictionary:hudArrowCSS(@"#ffffff")],

    hudHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0, 0, 0, 0.5)",
        @"border-color": @"rgba(255, 255, 255, 0.5)",
        @"border-style": @"solid",
        @"border-width": @"1px",
        @"border-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:hudArrowCSS(@"#ffffff")],

    // NEW: Disabled HUD state with gray background and dimmed arrow
    hudDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0, 0, 0, 0.1)",
        @"border-color": @"rgba(255, 255, 255, 0.1)",
        @"border-style": @"solid",
        @"border-width": @"1px",
        @"border-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:hudArrowCSS(@"rgba(255,255,255,0.3)")],


    // ==========================================================
    // REGISTRATION
    // ==========================================================
    
    themeValues =
    [
     [@"direct-nib2cib-adjustment",  YES],
     [@"text-color",                 A3CPColorActiveText],
     [@"text-color",                 A3CPColorInactiveText,                     [CPThemeStateDisabled]],
     [@"menu-offset",               CGSizeMake(-2, 1)],

     // Regular size
     [@"bezel-color",                buttonCssColor,                            [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateKeyWindow]],
     [@"bezel-color",                notKeyButtonCssColor,                      [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"bezel-color",                highlightedButtonCssColor,                 [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color",                disabledButtonCssColor,                    [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",                disabledButtonCssColor,                    [CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     
     [@"content-inset",              CGInsetMake(0.0, 19.0, 1.0, 9.0),          [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],

     // We must include CPThemeStateBordered here to override CPButton's definition
     [@"min-size",                   CGSizeMake(32.0, 22.0),                    [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"max-size",                   CGSizeMake(-1.0, 22.0),                    [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",   CGRectMake(2.0, -8.0, -5.0, -4.5),         [CPButtonStateBezelStyleRounded, CPThemeStateBordered]],

     // Small size
     [@"bezel-color",                smallButtonCssColor,                       [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateKeyWindow]],
     [@"bezel-color",                smallNotKeyButtonCssColor,                 [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered]],
     [@"bezel-color",                smallHighlightedButtonCssColor,            [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color",                smallDisabledButtonCssColor,               [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDisabled]],
     
     [@"content-inset",              CGInsetMake(1.0, 17.0, 1.00, 8.0),         [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered]],
     
     // FIX: We must include CPThemeStateBordered here to override CPButton's definition
     [@"min-size",                   CGSizeMake(38.0, 19.0),                    [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered]],
     [@"max-size",                   CGSizeMake(-1.0, 19.0),                    [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",   CGRectMake(3.0, -7.0, -6.0, -4.0),         [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered]],

     // Mini size
     [@"bezel-color",                miniButtonCssColor,                        [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateKeyWindow]],
     [@"bezel-color",                miniNotKeyButtonCssColor,                  [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered]],
     [@"bezel-color",                miniHighlightedButtonCssColor,             [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color",                miniDisabledButtonCssColor,                [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateDisabled]],
     
     [@"content-inset",              CGInsetMake(1.0, 15.0, 1.0, 10.0),         [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered]],
     
     // FIX: We must include CPThemeStateBordered here to override CPButton's definition
     [@"min-size",                   CGSizeMake(32.0, 15.0),                    [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered]],
     [@"max-size",                   CGSizeMake(-1.0, 15.0),                    [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered]],
     [@"nib2cib-adjustment-frame",   CGRectMake(1.0, -0.0, -3.0, -0.0),         [CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered]],

     // Flat styles
     [@"bezel-color",                buttonCssColor,                          [CPButtonStateBezelStyleRegularSquare, CPThemeStateKeyWindow]],
     [@"bezel-color",                buttonCssColor,                          [CPButtonStateBezelStyleRegularSquare]],
     [@"bezel-color",                highlightedButtonCssColor,               [CPButtonStateBezelStyleRegularSquare, CPThemeStateHighlighted]],
     [@"bezel-color",                disabledButtonCssColor,                  [CPButtonStateBezelStyleRegularSquare, CPThemeStateDisabled]],

     [@"content-inset",              CGInsetMake(2.0, 10, 1.0, 10.0),         [CPButtonStateBezelStyleRegularSquare]],
     [@"min-size",                   CGSizeMake(32.0, 21.0),                  [CPButtonStateBezelStyleRegularSquare]],
     [@"max-size",                   CGSizeMake(-1.0, 21.0),                  [CPButtonStateBezelStyleRegularSquare]],
     [@"nib2cib-adjustment-frame",   CGRectMake(0.0, -0.0, -0.0, -0.0),       [CPButtonStateBezelStyleRegularSquare]],

     // --- HUD MAPPINGS ---
     // 1. Text Colors
     [@"text-color",    [CPColor whiteColor],                                 CPThemeStateHUD],
     [@"text-color",    [CPColor colorWithWhite:1 alpha:0.4],                 [CPThemeStateHUD, CPThemeStateDisabled]],

     // 2. Bezel Colors
     [@"bezel-color",   hudButtonCssColor,          [CPButtonStateBezelStyleRounded, CPThemeStateHUD]],
     
     [@"bezel-color",   hudDisabledButtonCssColor,  [CPButtonStateBezelStyleRounded, CPThemeStateDisabled, CPThemeStateBordered, CPThemeStateHUD]],
     
     [@"bezel-color",   hudButtonCssColor,          [CPButtonStateBezelStyleRounded, CPThemeStateHUD, CPThemeStateKeyWindow]],
     [@"bezel-color",   hudHighlightedButtonCssColor, [CPButtonStateBezelStyleRounded, CPThemeStateHUD, CPThemeStateHighlighted]]
    ];

    [self registerThemeValues:themeValues forView:button];

    [button setTitle:@"Pop Up"];
    [button addItemWithTitle:@"item"];

    return button;
}

+ (CPPopUpButton)themedPullDownMenu
{
    var button = [[CPPopUpButton alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 21.0) pullsDown:YES],

    // Helper for Consistent Arrow Styling (reusing logic from PopUpButton)
    arrowCSS = function(color, rightOffset, boxSize) {
        var size = boxSize || "25px",
            offset = rightOffset || "-8px",
            marginTop = -(parseInt(size) / 2.0);

        return @{
            @"content": @"''",
            @"position": @"absolute",
            @"top": @"50%",
            @"right": offset,
            @"width": size,
            @"height": size,
            @"margin-top": marginTop + "px",

            "-webkit-mask-image": svgSingleArrow,
            "mask-image": svgSingleArrow, // FIX: Ensure consistent mask image
            "-webkit-mask-size": "contain",
            "mask-size": "contain",
            "-webkit-mask-repeat": "no-repeat",
            "mask-repeat": "no-repeat",
            "-webkit-mask-position": "center",
            "mask-position": "center",
            
            @"background-color": color
        };
    },
    hudArrowCSS = function(color) {
        return @{
            @"content": @"''",
            @"position": @"absolute",
            @"top": @"50%",
            @"right": @"-8px",
            @"width": @"25px",
            @"height": @"25px",
            @"margin-top": @"-12.5px",
            "-webkit-mask-image": svgSingleArrow, // Use Single Arrow for Pull Down
            "mask-image": svgSingleArrow,
            "-webkit-mask-size": "contain",
            "mask-size": "contain",
            "-webkit-mask-repeat": "no-repeat",
            "mask-repeat": "no-repeat",
            "-webkit-mask-position": "center",
            "mask-position": "center",
            @"background-color": color
        };
    },

    hudButtonCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0, 0, 0, 0.25)",
        @"border-color": @"rgba(255, 255, 255, 0.25)",
        @"border-style": @"solid",
        @"border-width": @"1px",
        @"border-radius": @"3px",
        @"box-sizing": @"border-box",
        @"box-shadow": @"0 1px 0 rgba(255,255,255,0.1) inset"
    } beforeDictionary:nil afterDictionary:hudArrowCSS(@"#ffffff")],

    hudHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0, 0, 0, 0.5)",
        @"border-color": @"rgba(255, 255, 255, 0.5)",
        @"border-style": @"solid",
        @"border-width": @"1px",
        @"border-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:hudArrowCSS(@"#ffffff")],

    // ==========================================================
    // REGULAR SIZE DEFINITIONS
    // ==========================================================

    buttonCssColor = [CPColor colorWithCSSDictionary:@{
                                                       @"background-color": A3ColorBackgroundWhite,
                                                       @"border-color": A3ColorActiveBorder,
                                                       @"border-style": @"solid",
                                                       @"border-width": @"1px",
                                                       @"border-radius": @"3px",
                                                       @"box-sizing": @"border-box"
                                                       }
                                    beforeDictionary:@{
                                                       @"background-color": @"rgb(225,225,225)",
                                                       @"bottom": @"3px",
                                                       @"content": @"''",
                                                       @"position": @"absolute",
                                                       @"right": @"17px",
                                                       @"top": @"3px",
                                                       @"width": @"1px"
                                                       }
                                     // FIX: Use A3ColorBorderBlue
                                     afterDictionary:arrowCSS(A3ColorBorderBlue, "-4px", "25px")],

    notKeyButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorBackgroundWhite,
                                                             @"border-color": A3ColorActiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"3px",
                                                             @"box-sizing": @"border-box"
                                                             }
                                          beforeDictionary:@{
                                                             @"background-color": @"rgb(225,225,225)",
                                                             @"bottom": @"3px",
                                                             @"content": @"''",
                                                             @"position": @"absolute",
                                                             @"right": @"17px",
                                                             @"top": @"3px",
                                                             @"width": @"1px"
                                                             }
                                           afterDictionary:arrowCSS(A3ColorInactiveText, "-4px", "25px")],

    disabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorBackgroundInactive,
                                                               @"border-color": A3ColorInactiveBorder,
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"border-radius": @"3px",
                                                               @"box-sizing": @"border-box"
                                                               }
                                            beforeDictionary:nil
                                             afterDictionary:arrowCSS(A3ColorInactiveText, "-4px", "25px")],

    highlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"border-color": A3ColorBorderDark,
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"1px",
                                                                  @"border-radius": @"3px",
                                                                  @"box-sizing": @"border-box",
                                                                  @"background-color": A3ColorBackgroundInactive
                                                                  }
                                               beforeDictionary:@{
                                                                  @"background-color": @"rgb(225,225,225)",
                                                                  @"bottom": @"3px",
                                                                  @"content": @"''",
                                                                  @"position": @"absolute",
                                                                  @"right": @"17px",
                                                                  @"top": @"3px",
                                                                  @"width": @"1px"
                                                                  }
                                                // FIX: Use A3ColorBorderBlue
                                                afterDictionary:arrowCSS(A3ColorBorderBlue, "-4px", "25px")],

    // ==========================================================
    // SMALL SIZE DEFINITIONS
    // ==========================================================

    smallButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": A3ColorBackgroundWhite,
                                                            @"border-color": A3ColorActiveBorder,
                                                            @"border-style": @"solid",
                                                            @"border-width": @"1px",
                                                            @"border-radius": @"3px",
                                                            @"box-sizing": @"border-box"
                                                            }
                                         beforeDictionary:@{
                                                            @"background-color": @"rgb(225,225,225)",
                                                            @"bottom": @"3px",
                                                            @"content": @"''",
                                                            @"position": @"absolute",
                                                            @"right": @"15px", // Adjusted
                                                            @"top": @"3px",
                                                            @"width": @"1px"
                                                            }
                                          afterDictionary:arrowCSS(A3ColorBorderBlue, "-4px", "23px")],

    smallNotKeyButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"background-color": A3ColorBackgroundWhite,
                                                                  @"border-color": A3ColorActiveBorder,
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"1px",
                                                                  @"border-radius": @"3px",
                                                                  @"box-sizing": @"border-box"
                                                                  }
                                               beforeDictionary:@{
                                                                  @"background-color": @"rgb(225,225,225)",
                                                                  @"bottom": @"3px",
                                                                  @"content": @"''",
                                                                  @"position": @"absolute",
                                                                  @"right": @"15px", // Adjusted
                                                                  @"top": @"3px",
                                                                  @"width": @"1px"
                                                                  }
                                                afterDictionary:arrowCSS(A3ColorInactiveText, "-4px", "23px")],

    smallDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": A3ColorBackgroundInactive,
                                                                    @"border-color": A3ColorInactiveBorder,
                                                                    @"border-style": @"solid",
                                                                    @"border-width": @"1px",
                                                                    @"border-radius": @"3px",
                                                                    @"box-sizing": @"border-box"
                                                                    }
                                                 beforeDictionary:nil
                                                  afterDictionary:arrowCSS(A3ColorInactiveText, "-4px", "23px")],

    smallHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                       @"border-color": A3ColorBorderDark,
                                                                       @"border-style": @"solid",
                                                                       @"border-width": @"1px",
                                                                       @"border-radius": @"3px",
                                                                       @"box-sizing": @"border-box",
                                                                       @"background-color": A3ColorBackgroundInactive
                                                                       }
                                                    beforeDictionary:@{
                                                                       @"background-color": @"rgb(225,225,225)",
                                                                       @"bottom": @"3px",
                                                                       @"content": @"''",
                                                                       @"position": @"absolute",
                                                                       @"right": @"15px",
                                                                       @"top": @"3px",
                                                                       @"width": @"1px"
                                                                       }
                                                     afterDictionary:arrowCSS(A3ColorBorderBlue, "-4px", "23px")],

    // ==========================================================
    // MINI SIZE DEFINITIONS
    // ==========================================================

    miniButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                           @"background-color": A3ColorBackgroundWhite,
                                                           @"border-color": A3ColorActiveBorder,
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"border-radius": @"3px",
                                                           @"box-sizing": @"border-box"
                                                           }
                                        beforeDictionary:@{
                                                           @"background-color": @"rgb(225,225,225)",
                                                           @"bottom": @"2px",
                                                           @"content": @"''",
                                                           @"position": @"absolute",
                                                           @"right": @"13px", // Adjusted
                                                           @"top": @"2px",
                                                           @"width": @"1px"
                                                           }
                                         // FIX: Use A3ColorBorderBlue
                                         afterDictionary:arrowCSS(A3ColorBorderBlue, "-3px", "20px")],

    miniNotKeyButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorBackgroundWhite,
                                                                 @"border-color": A3ColorActiveBorder,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"border-radius": @"3px",
                                                                 @"box-sizing": @"border-box"
                                                                 }
                                              beforeDictionary:@{
                                                                 @"background-color": @"rgb(225,225,225)",
                                                                 @"bottom": @"2px",
                                                                 @"content": @"''",
                                                                 @"position": @"absolute",
                                                                 @"right": @"13px", // Adjusted
                                                                 @"top": @"2px",
                                                                 @"width": @"1px"
                                                                 }
                                               afterDictionary:arrowCSS(A3ColorInactiveText, "-3px", "20px")],

    miniDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                   @"background-color": A3ColorBackgroundInactive,
                                                                   @"border-color": A3ColorInactiveBorder,
                                                                   @"border-style": @"solid",
                                                                   @"border-width": @"1px",
                                                                   @"border-radius": @"3px",
                                                                   @"box-sizing": @"border-box"
                                                                   }
                                                beforeDictionary:nil
                                                 afterDictionary:arrowCSS(A3ColorInactiveText, "-3px", "20px")],

    miniHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                      @"border-color": A3ColorBorderDark,
                                                                      @"border-style": @"solid",
                                                                      @"border-width": @"1px",
                                                                      @"border-radius": @"3px",
                                                                      @"box-sizing": @"border-box",
                                                                      @"background-color": A3ColorBackgroundInactive
                                                                      }
                                                   beforeDictionary:@{
                                                                      @"background-color": @"rgb(225,225,225)",
                                                                      @"bottom": @"2px",
                                                                      @"content": @"''",
                                                                      @"position": @"absolute",
                                                                      @"right": @"13px", // Adjusted
                                                                      @"top": @"2px",
                                                                      @"width": @"1px"
                                                                      }
                                                    // FIX: Use A3ColorBorderBlue
                                                    afterDictionary:arrowCSS(A3ColorBorderBlue, "-3px", "20px")],

    // ==========================================================
    // UNBORDERED BUTTONS
    // ==========================================================

    nbButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                         @"background-color": A3ColorTransparent,
                                                         @"border-color": A3ColorTransparent,
                                                         @"border-style": @"solid",
                                                         @"border-width": @"1px",
                                                         @"border-radius": @"3px",
                                                         @"box-sizing": @"border-box"
                                                         }
                                      beforeDictionary:nil
                                       afterDictionary:arrowCSS(A3ColorInactiveText, "-8px", "25px")],

    nbDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorTransparent,
                                                                 @"border-color": A3ColorTransparent,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"border-radius": @"3px",
                                                                 @"box-sizing": @"border-box"
                                                                 }
                                              beforeDictionary:nil
                                               afterDictionary:arrowCSS(A3ColorInactiveText, "-8px", "25px")],

    nbHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": A3ColorTransparent,
                                                                    @"border-color": A3ColorTransparent,
                                                                    @"border-style": @"solid",
                                                                    @"border-width": @"1px",
                                                                    @"border-radius": @"3px",
                                                                    @"box-sizing": @"border-box"
                                                                    }
                                                 beforeDictionary:nil
                                                  afterDictionary:arrowCSS(A3ColorActiveText, "-8px", "25px")],
                                                  
    // Small NB
    smallNbButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                              @"background-color": A3ColorTransparent,
                                                              @"border-color": A3ColorTransparent,
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px",
                                                              @"border-radius": @"3px",
                                                              @"box-sizing": @"border-box"
                                                              }
                                           beforeDictionary:nil
                                            afterDictionary:arrowCSS(A3ColorInactiveText, "-6px", "23px")],

    smallNbDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                      @"background-color": A3ColorTransparent,
                                                                      @"border-color": A3ColorTransparent,
                                                                      @"border-style": @"solid",
                                                                      @"border-width": @"1px",
                                                                      @"border-radius": @"3px",
                                                                      @"box-sizing": @"border-box"
                                                                      }
                                                   beforeDictionary:nil
                                                    afterDictionary:arrowCSS(A3ColorInactiveText, "-6px", "23px")],

    smallNbHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                         @"background-color": A3ColorTransparent,
                                                                         @"border-color": A3ColorTransparent,
                                                                         @"border-style": @"solid",
                                                                         @"border-width": @"1px",
                                                                         @"border-radius": @"3px",
                                                                         @"box-sizing": @"border-box"
                                                                         }
                                                      beforeDictionary:nil
                                                       afterDictionary:arrowCSS(A3ColorActiveText, "-6px", "23px")],
    
    // Mini NB
    miniNbButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorTransparent,
                                                             @"border-color": A3ColorTransparent,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"3px",
                                                             @"box-sizing": @"border-box"
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:arrowCSS(A3ColorInactiveText, "-4px", "20px")],

    miniNbDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                     @"background-color": A3ColorTransparent,
                                                                     @"border-color": A3ColorTransparent,
                                                                     @"border-style": @"solid",
                                                                     @"border-width": @"1px",
                                                                     @"border-radius": @"3px",
                                                                     @"box-sizing": @"border-box"
                                                                     }
                                                  beforeDictionary:nil
                                                   afterDictionary:arrowCSS(A3ColorInactiveText, "-4px", "20px")],

    miniNbHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                        @"background-color": A3ColorTransparent,
                                                                        @"border-color": A3ColorTransparent,
                                                                        @"border-style": @"solid",
                                                                        @"border-width": @"1px",
                                                                        @"border-radius": @"3px",
                                                                        @"box-sizing": @"border-box"
                                                                        }
                                                     beforeDictionary:nil
                                                      afterDictionary:arrowCSS(A3ColorActiveText, "-4px", "20px")],

    themeValues =
    [
     [@"direct-nib2cib-adjustment", YES,                                    CPPopUpButtonStatePullsDown],
     [@"menu-offset",               CGSizeMake(0, -1),                      CPPopUpButtonStatePullsDown],
     [@"text-color",                A3CPColorActiveText,                    CPPopUpButtonStatePullsDown],
     [@"text-color",                A3CPColorInactiveText,                  [CPPopUpButtonStatePullsDown, CPThemeStateDisabled]],

     // Bordered, IB style "Push" (CPRoundedBezelStyle)

     // Regular size
     [@"bezel-color",               buttonCssColor,                         [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateKeyWindow]],
     [@"bezel-color",               notKeyButtonCssColor,                   [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"bezel-color",               highlightedButtonCssColor,              [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateKeyWindow, CPThemeStateHighlighted]],
     [@"bezel-color",               disabledButtonCssColor,                 [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",               disabledButtonCssColor,                 [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateBordered, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"nib2cib-adjustment-frame",  CGRectMake(3.0, -8.0, -6.0, -5.0),      [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"content-inset",             CGInsetMake(3.0, 19.0, 1.0, 6.0),       [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateBordered]],
     [@"min-size",                  CGSizeMake(32.0, 21.0),                 [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateBordered]],

     // Small size
     [@"bezel-color",               smallButtonCssColor,                    [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateKeyWindow]],
     [@"bezel-color",               smallNotKeyButtonCssColor,              [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered]],
     [@"bezel-color",               smallHighlightedButtonCssColor,         [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateKeyWindow, CPThemeStateHighlighted]],
     [@"bezel-color",               smallDisabledButtonCssColor,            [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",               smallDisabledButtonCssColor,            [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"nib2cib-adjustment-frame",  CGRectMake(3.0, -7.0, -6.0, -4.0),      [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered]],
     [@"content-inset",             CGInsetMake(1.0, 17.0, 1.0, 8.0),       [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered]],
     [@"min-size",                  CGSizeMake(38.0, 20.0),                 [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeSmall, CPThemeStateBordered]],

     // Mini size
     [@"bezel-color",               miniButtonCssColor,                     [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateKeyWindow]],
     [@"bezel-color",               miniNotKeyButtonCssColor,               [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered]],
     [@"bezel-color",               miniHighlightedButtonCssColor,          [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateKeyWindow, CPThemeStateHighlighted]],
     [@"bezel-color",               miniDisabledButtonCssColor,             [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color",               miniDisabledButtonCssColor,             [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"nib2cib-adjustment-frame",  CGRectMake(0.0, -0.0, -1.0, -0.0),      [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered]],
     [@"content-inset",             CGInsetMake(1.0, 15.0, 1.0, 10.0),      [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered]],
     [@"min-size",                  CGSizeMake(32.0, 15.0),                 [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateControlSizeMini, CPThemeStateBordered]],

     // Not bordered, IB style "Bevel" (CPRegularSquareBezelStyle)

     // Regular size
     [@"bezel-color",               nbButtonCssColor,                       [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateKeyWindow]],
     [@"bezel-color",               nbButtonCssColor,                       [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare]],
     [@"bezel-color",               nbHighlightedButtonCssColor,            [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateKeyWindow, CPThemeStateHighlighted]],
     [@"bezel-color",               nbDisabledButtonCssColor,               [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateDisabled]],
     [@"bezel-color",               nbDisabledButtonCssColor,               [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"nib2cib-adjustment-frame",  CGRectMake(1.0, 1.0, 0.0, 0.0),         [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare]],
     [@"content-inset",             CGInsetMake(2.0, 11, 1.0, 10.0),          [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare]],
     [@"min-size",                  CGSizeMake(32.0, 21.0),                 [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare]],

     // Small size
     [@"bezel-color",               smallNbButtonCssColor,                  [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall, CPThemeStateKeyWindow]],
     [@"bezel-color",               smallNbButtonCssColor,                  [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall]],
     [@"bezel-color",               smallNbHighlightedButtonCssColor,       [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall, CPThemeStateKeyWindow, CPThemeStateHighlighted]],
     [@"bezel-color",               smallNbDisabledButtonCssColor,          [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
     [@"bezel-color",               smallNbDisabledButtonCssColor,          [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"nib2cib-adjustment-frame",  CGRectMake(1.0, 0.0, 0.0, 0.0),         [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall]],
     [@"content-inset",             CGInsetMake(1.0, 11, 1.0, 9.0),          [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall]],
     [@"min-size",                  CGSizeMake(38.0, 20.0),                 [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeSmall]],

     // Mini size
     [@"bezel-color",               miniNbButtonCssColor,                   [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini, CPThemeStateKeyWindow]],
     [@"bezel-color",               miniNbButtonCssColor,                   [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini]],
     [@"bezel-color",               miniNbHighlightedButtonCssColor,        [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini, CPThemeStateKeyWindow, CPThemeStateHighlighted]],
     [@"bezel-color",               miniNbDisabledButtonCssColor,           [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini, CPThemeStateDisabled]],
     [@"bezel-color",               miniNbDisabledButtonCssColor,           [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"nib2cib-adjustment-frame",  CGRectMake(1.0, 1.0, 0.0, 0.0),         [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini]],
     [@"content-inset",             CGInsetMake(1.0, 11, 1.0, 8.0),          [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini]],
     [@"min-size",                  CGSizeMake(32.0, 16.0),                 [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateControlSizeMini]],

     // Register HUD states
     [@"text-color",    [CPColor whiteColor],       [CPPopUpButtonStatePullsDown, CPThemeStateHUD]],
     
     [@"bezel-color",   hudButtonCssColor,          [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateHUD]],
     [@"bezel-color",   hudButtonCssColor,          [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateHUD, CPThemeStateKeyWindow]],
     [@"bezel-color",   hudHighlightedButtonCssColor, [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRounded, CPThemeStateHUD, CPThemeStateHighlighted]]
    ];

    [self registerThemeValues:themeValues forView:button];

    [button setTitle:@"Pull Down"];
    [button addItemWithTitle:@"item"];

    return button;
}

#pragma mark -

+ (CPScrollView)themedScrollView
{
    var scrollView = [[CPScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)],
        
        bottomCornerColor = [CPColor colorWithCSSDictionary:@{
                                                              @"background-color": A3ColorScrollerBackground
                                                              }],
        
        // --- ADD THIS: HUD Corner Color ---
        hudBottomCornerColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": @"rgba(0, 0, 0, 0.25)",
                                                                 @"border-left": @"1px solid rgba(255, 255, 255, 0.2)",
                                                                 @"border-top": @"1px solid rgba(255, 255, 255, 0.2)"
                                                                 }],
        // ----------------------------------

    // Standard White Theme
    bezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                      @"background-color": A3ColorBackgroundWhite,
                                                      @"border-color": A3ColorTextfieldActiveBorder,
                                                      @"border-style": @"solid",
                                                      @"border-width": @"1px",
                                                      @"border-radius": @"0px",
                                                      @"box-sizing": @"border-box",
                                                      @"transition-duration": @"0.35s, 0.35s",
                                                      @"transition-property": @"box-shadow, border"
                                                      }],

    bezelFocusedCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorBackgroundWhite,
                                                             @"border-color": A3ColorBorderBlue,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"0px",
                                                             @"box-sizing": @"border-box",
                                                             @"box-shadow": @"0px 0px 2px 0px rgb(59,127,202)",
                                                             @"transition-duration": @"0.35s, 0.35s",
                                                             @"transition-property": @"box-shadow, border"
                                                             }],

    // --- HUD STYLES ---
    // Transparent background with a subtle light border
    hudBezelCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"transparent", 
        @"border-color": @"rgba(255, 255, 255, 0.2)",
        @"border-style": @"solid",
        @"border-width": @"1px",
        @"border-radius": @"0px",
        @"box-sizing": @"border-box"
    }],

    // HUD Focused: Slightly lighter background glow, white border
    hudBezelFocusedCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(255, 255, 255, 0.05)",
        @"border-color": @"#ffffff",
        @"border-style": @"solid",
        @"border-width": @"1px",
        @"border-radius": @"0px",
        @"box-sizing": @"border-box",
        @"box-shadow": @"0 0 3px rgba(255,255,255,0.3)"
    }],

    themedScrollViewValues =
    [
     // --- Standard States ---
     [@"background-color-no-border",        bezelCssColor],
     [@"background-color-no-border",        bezelFocusedCssColor,       [CPThemeStateFirstResponder, CPThemeStateKeyWindow]],
     [@"background-color-line-border",      bezelCssColor],
     [@"background-color-line-border",      bezelFocusedCssColor,       [CPThemeStateFirstResponder, CPThemeStateKeyWindow]],
     [@"background-color-bezel-border",     bezelCssColor],
     [@"background-color-bezel-border",     bezelFocusedCssColor,       [CPThemeStateFirstResponder, CPThemeStateKeyWindow]],
     [@"background-color-groove-border",    bezelCssColor],
     [@"background-color-groove-border",    bezelFocusedCssColor,       [CPThemeStateFirstResponder, CPThemeStateKeyWindow]],

     [@"content-inset-no-border",       CGInsetMakeZero()],
     [@"content-inset-line-border",     CGInsetMake(0,2,2,0)],
     [@"content-inset-bezel-border",    CGInsetMake(0,2,2,0)],
     [@"content-inset-groove-border",   CGInsetMake(0,2,2,0)],
     
     [@"bottom-corner-color", bottomCornerColor],
     [@"bottom-corner-color", hudBottomCornerColor, CPThemeStateHUD],


     // --- HUD OVERRIDES ---
     // We map all border types to the HUD style. 
     // Crucially, we override the FirstResponder+KeyWindow combination to prevent the white focused style from appearing.
     
     // 1. Base HUD State
     [@"background-color-no-border",    hudBezelCssColor,       CPThemeStateHUD],
     [@"background-color-line-border",  hudBezelCssColor,       CPThemeStateHUD],
     [@"background-color-bezel-border", hudBezelCssColor,       CPThemeStateHUD],
     
     // 2. HUD + Focused (Active)
     [@"background-color-no-border",    hudBezelFocusedCssColor, [CPThemeStateHUD, CPThemeStateFirstResponder]],
     [@"background-color-line-border",  hudBezelFocusedCssColor, [CPThemeStateHUD, CPThemeStateFirstResponder]],
     [@"background-color-bezel-border", hudBezelFocusedCssColor, [CPThemeStateHUD, CPThemeStateFirstResponder]],
     
     // 3. HUD + Focused + Key Window (Highest Specificity - overrides standard focused state)
     [@"background-color-no-border",    hudBezelFocusedCssColor, [CPThemeStateHUD, CPThemeStateFirstResponder, CPThemeStateKeyWindow]],
     [@"background-color-line-border",  hudBezelFocusedCssColor, [CPThemeStateHUD, CPThemeStateFirstResponder, CPThemeStateKeyWindow]],
     [@"background-color-bezel-border", hudBezelFocusedCssColor, [CPThemeStateHUD, CPThemeStateFirstResponder, CPThemeStateKeyWindow]]
    ];

    [self registerThemeValues:themedScrollViewValues forView:scrollView];

    [scrollView setAutohidesScrollers:YES];
    [scrollView setBorderType:CPLineBorder];

    return scrollView;
}

+ (CPScroller)makeHorizontalScroller
{
    var scroller = [[CPScroller alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 15.0)];

    [scroller setFloatValue:0.1];
    [scroller setKnobProportion:0.5];

    [scroller setStyle:CPScrollerStyleOverlay];

    return scroller;
}

+ (CPScroller)makeVerticalScroller
{
    var scroller = [[CPScroller alloc] initWithFrame:CGRectMake(0.0, 0.0, 15.0, 200.0)];

    [scroller setFloatValue:1];
    [scroller setKnobProportion:0.1];

    [scroller setStyle:CPScrollerStyleLegacy];

    return scroller;
}

+ (CPScroller)themedVerticalScroller
{
    var scroller = [self makeVerticalScroller],

    knobCssColor = [CPColor colorWithCSSDictionary:@{
                                                     @"background-color": A3ColorScrollerDark,
                                                     @"border-style": @"none",
                                                     @"border-radius": @"4px",
                                                     @"box-sizing": @"border-box"
                                                     }],

    lightKnobCssColor = [CPColor colorWithCSSDictionary:@{
                                                          @"background-color": A3ColorScrollerLight,
                                                          @"border-color": A3ColorInactiveBorder,
                                                          @"border-style": @"solid",
                                                          @"border-width": @"1px",
                                                          @"border-radius": @"4px",
                                                          @"box-sizing": @"border-box"
                                                          }],

    knobCssColorLegacy = [CPColor colorWithCSSDictionary:@{
                                                           @"background-color": A3ColorScrollerLegacy,
                                                           @"border-style": @"none",
                                                           @"border-radius": @"4px",
                                                           @"box-sizing": @"border-box",
                                                           @"transition-duration": @"0.35s",
                                                           @"transition-property": @"background-color"
                                                           }],

    knobCssColorLegacyOver = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorScrollerDark,
                                                               @"border-style": @"none",
                                                               @"border-radius": @"4px",
                                                               @"box-sizing": @"border-box",
                                                               @"transition-duration": @"0.35s",
                                                               @"transition-property": @"background-color"
                                                               }],

    trackCssColorLegacy = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": A3ColorScrollerBackground,
                                                            @"border-left-style": @"solid",
                                                            @"border-left-color": A3ColorScrollerBorder,
                                                            @"border-left-width": @"1px"
                                                            }],
    hudKnobCssColor = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": @"rgba(255, 255, 255, 0.35)",
                                                            @"border-radius": @"3px",
                                                            @"border": @"1px solid rgba(0,0,0,0.2)"
                                                        }],

    // HUD Track (Transparent/Dark)
    hudTrackCssColor = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": @"rgba(0, 0, 0, 0.15)",
                                                            @"border-radius": @"3px"
                                                        }],

    themedVerticalScrollerValues =
    [
     // Common
     [@"minimum-knob-length",    21.0,                               CPThemeStateVertical],

     // Overlay
     [@"scroller-width",         7.0,                                CPThemeStateVertical],
     [@"knob-inset",             CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateVertical],
     [@"track-inset",            CGInsetMake(2.0, 0.0, 2.0, 0.0),    CPThemeStateVertical],
     [@"track-border-overlay",   9.0,                                CPThemeStateVertical],
     [@"knob-slot-color",        [CPNull null],                      CPThemeStateVertical],
     [@"knob-color",             knobCssColor,                       CPThemeStateVertical],
     [@"knob-color",             lightKnobCssColor,                  [CPThemeStateVertical, CPThemeStateScrollerKnobLight]],
     [@"knob-color",             knobCssColor,                       [CPThemeStateVertical, CPThemeStateScrollerKnobDark]],
     [@"decrement-line-size",    CGSizeMakeZero(),                   CPThemeStateVertical],
     [@"increment-line-size",    CGSizeMakeZero(),                   CPThemeStateVertical],

     // Legacy
     [@"scroller-width",         15.0,                               [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
     [@"knob-inset",             CGInsetMake(3.0, 3.0, 3.0, 4.0),    [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
     [@"track-inset",            CGInsetMake(0.0, 0.0, 0.0, 0.0),    [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
     [@"track-border-overlay",   0.0,                                [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
     [@"knob-slot-color",        trackCssColorLegacy,                   [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
     [@"knob-color",             knobCssColorLegacy,                    [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
     [@"knob-color",             knobCssColorLegacyOver,                    [CPThemeStateVertical, CPThemeStateScrollViewLegacy, CPThemeStateSelected]],
     [@"decrement-line-size",    CGSizeMakeZero(),             [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
     [@"increment-line-size",    CGSizeMakeZero(),             [CPThemeStateVertical, CPThemeStateScrollViewLegacy]],

     // HUD
     [@"knob-color",  hudKnobCssColor,  [CPThemeStateVertical, CPThemeStateHUD]],
     [@"knob-slot-color", hudTrackCssColor, [CPThemeStateHUD, CPThemeStateVertical, CPThemeStateScrollViewLegacy]],
     [@"knob-color",  hudKnobCssColor,  [CPThemeStateHUD, CPThemeStateVertical, CPThemeStateScrollViewLegacy]]
    ];

    [self registerThemeValues:themedVerticalScrollerValues forView:scroller];

    return scroller;
}

+ (CPScroller)themedHorizontalScroller
{
    var scroller = [self makeHorizontalScroller],

    knobCssColor = [CPColor colorWithCSSDictionary:@{
                                                     @"background-color": A3ColorScrollerDark,
                                                     @"border-style": @"none",
                                                     @"border-radius": @"4px",
                                                     @"box-sizing": @"border-box"
                                                     }],

    lightKnobCssColor = [CPColor colorWithCSSDictionary:@{
                                                          @"background-color": A3ColorScrollerLight,
                                                          @"border-color": A3ColorInactiveBorder,
                                                          @"border-style": @"solid",
                                                          @"border-width": @"1px",
                                                          @"border-radius": @"4px",
                                                          @"box-sizing": @"border-box"
                                                          }],

    knobCssColorLegacy = [CPColor colorWithCSSDictionary:@{
                                                           @"background-color": A3ColorScrollerLegacy,
                                                           @"border-style": @"none",
                                                           @"border-radius": @"4px",
                                                           @"box-sizing": @"border-box",
                                                           @"transition-duration": @"0.35s",
                                                           @"transition-property": @"background-color"
                                                           }],

    knobCssColorLegacyOver = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorScrollerDark,
                                                               @"border-style": @"none",
                                                               @"border-radius": @"4px",
                                                               @"box-sizing": @"border-box",
                                                               @"transition-duration": @"0.35s",
                                                               @"transition-property": @"background-color"
                                                               }],

    trackCssColorLegacy = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": A3ColorScrollerBackground,
                                                            @"border-top-style": @"solid",
                                                            @"border-top-color": A3ColorScrollerBorder,
                                                            @"border-top-width": @"1px"
                                                            }],
    hudKnobCssColor = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": @"rgba(255, 255, 255, 0.35)",
                                                            @"border-radius": @"3px",
                                                            @"border": @"1px solid rgba(0,0,0,0.2)"
                                                        }],

    // HUD Track (Transparent/Dark)
    hudTrackCssColor = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": @"rgba(0, 0, 0, 0.15)",
                                                            @"border-radius": @"3px"
                                                        }],
    themedHorizontalScrollerValues =
    [
     // Common
     [@"minimum-knob-length",    21.0],

     // Overlay
     [@"scroller-width",         7.0],
     [@"knob-inset",             CGInsetMake(0.0, 0.0, 0.0, 0.0)],
     [@"track-inset",            CGInsetMake(0.0, 2.0, 0.0, 2.0)],
     [@"track-border-overlay",   9.0],
     [@"knob-slot-color",        [CPNull null]],
     [@"knob-color",             knobCssColor],
     [@"knob-color",             lightKnobCssColor,                       CPThemeStateScrollerKnobLight],
     [@"knob-color",             knobCssColor,                       CPThemeStateScrollerKnobDark],
     [@"decrement-line-size",    CGSizeMakeZero()],
     [@"increment-line-size",    CGSizeMakeZero()],

     // Legacy
     [@"scroller-width",         15.0,                               CPThemeStateScrollViewLegacy],
     [@"knob-inset",             CGInsetMake(4.0, 3.0, 3.0, 3.0),    CPThemeStateScrollViewLegacy],
     [@"track-inset",            CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateScrollViewLegacy],
     [@"track-border-overlay",   0.0,                                CPThemeStateScrollViewLegacy],
     [@"knob-slot-color",        trackCssColorLegacy,                   CPThemeStateScrollViewLegacy],
     [@"knob-color",             knobCssColorLegacy,                    CPThemeStateScrollViewLegacy],
     [@"knob-color",             knobCssColorLegacyOver,                    [CPThemeStateScrollViewLegacy, CPThemeStateSelected]],
     [@"decrement-line-size",    CGSizeMakeZero(),             CPThemeStateScrollViewLegacy],
     [@"increment-line-size",    CGSizeMakeZero(),             CPThemeStateScrollViewLegacy],

     // HUD
     [@"knob-color",  hudKnobCssColor,  CPThemeStateHUD],
     [@"knob-slot-color", hudTrackCssColor, [CPThemeStateHUD, CPThemeStateScrollViewLegacy]],
     [@"knob-color",  hudKnobCssColor,  [CPThemeStateHUD, CPThemeStateScrollViewLegacy]]
    ];

    [self registerThemeValues:themedHorizontalScrollerValues forView:scroller];

    return scroller;
}

#pragma mark -

+ (CPTextField)themedStandardTextField
{
    var textfield = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 160.0, 22.0)],

    bezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                      @"background-color": A3ColorBackgroundWhite,
                                                      @"border-color": A3ColorTextfieldActiveBorder,
                                                      @"border-style": @"solid",
                                                      @"border-width": @"1px",
                                                      @"border-radius": @"0px",
                                                      @"box-sizing": @"border-box",
                                                      @"transition-duration": @"0.35s, 0.35s",
                                                      @"transition-property": @"box-shadow, border"
                                                      }],

    bezelFocusedCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorBackgroundWhite,
                                                             @"border-color": @"A3ColorBorderBlue",
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"0px",
                                                             @"box-sizing": @"border-box",
                                                             @"box-shadow": @"0px 0px 2px 0px rgb(59,127,202)",
                                                             @"transition-duration": @"0.35s, 0.35s",
                                                             @"transition-property": @"box-shadow, border"
                                                             }],

    bezelDisabledCssColor = [CPColor colorWithCSSDictionary:@{
                                                              @"background-color": A3ColorBackgroundWhite,
                                                              @"border-color": A3ColorTextfieldInactiveBorder,
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px",
                                                              @"border-radius": @"0px",
                                                              @"box-sizing": @"border-box",
                                                              @"transition-duration": @"0.35s, 0.35s",
                                                              @"transition-property": @"box-shadow, border"
                                                              }];

    tableCssColor = [CPColor colorWithCSSDictionary:@{
                                                      @"border-style": @"none",
                                                      @"box-sizing": @"border-box",
                                                      @"transition-duration": @"0.35s, 0.35s",
                                                      @"transition-property": @"box-shadow, border"
                                                      }],

    tableFocusedCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorBackgroundWhite,
                                                             @"border-style": @"none",
                                                             @"box-sizing": @"border-box",
                                                             @"transition-duration": @"0.35s, 0.35s",
                                                             @"transition-property": @"box-shadow, border"
                                                             }],

    unborderedBezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                                @"border-color": A3ColorTransparent,
                                                                @"border-style": @"solid",
                                                                @"border-width": @"0px",
                                                                @"border-radius": @"0px",
                                                                @"box-sizing": @"border-box",
                                                                @"transition-duration": @"0.35s, 0.35s",
                                                                @"transition-property": @"box-shadow, border-color"
                                                                }],

    unborderedBezelFocusedCssColor = [CPColor colorWithCSSDictionary:@{
                                                                       @"border-color": @"A3ColorBorderBlue",
                                                                       @"border-style": @"solid",
                                                                       @"border-width": @"1px",
                                                                       @"border-radius": @"0px",
                                                                       @"box-sizing": @"border-box",
                                                                       @"box-shadow": @"0px 0px 2px 0px rgb(59,127,202)",
                                                                       @"transition-duration": @"0.35s, 0.35s",
                                                                       @"transition-property": @"box-shadow, border-color"
                                                                       }],

    borderedBezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                              @"border-color": A3ColorNotKeyDarkBorder,
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px",
                                                              @"border-radius": @"0px",
                                                              @"box-sizing": @"border-box",
                                                              @"transition-duration": @"0.35s, 0.35s",
                                                              @"transition-property": @"box-shadow, border-color"
                                                              }],

    borderedBezelFocusedCssColor = [CPColor colorWithCSSDictionary:@{
                                                                     @"border-color": @"A3ColorBorderBlue",
                                                                     @"border-style": @"solid",
                                                                     @"border-width": @"1px",
                                                                     @"border-radius": @"0px",
                                                                     @"box-sizing": @"border-box",
                                                                     @"box-shadow": @"0px 0px 2px 0px rgb(59,127,202)",
                                                                     @"transition-duration": @"0.35s, 0.35s",
                                                                     @"transition-property": @"box-shadow, border-color"
                                                                     }],
    // --- HUD STYLES ---
    hudBezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                                        @"background-color": @"rgba(0, 0, 0, 0.3)",
                                                                        @"border-color": @"rgba(255, 255, 255, 0.3)",
                                                                        @"border-style": @"solid",
                                                                        @"border-width": @"1px",
                                                                        @"border-radius": @"0px",
                                                                        @"box-sizing": @"border-box",
                                                                        @"transition-duration": @"0.35s, 0.35s",
                                                                        @"transition-property": @"box-shadow, border"
                                                                    }],

    hudBezelFocusedCssColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": @"rgba(0, 0, 0, 0.5)",
                                                                    @"border-color": @"#ffffff",
                                                                    @"border-style": @"solid",
                                                                    @"border-width": @"1px",
                                                                    @"border-radius": @"0px",
                                                                    @"box-sizing": @"border-box",
                                                                    @"box-shadow": @"0px 0px 3px 0px rgba(255,255,255,0.5)",
                                                                    @"transition-duration": @"0.35s, 0.35s",
                                                                    @"transition-property": @"box-shadow, border"

                                                                }],
    hudSelectionColor = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": @"rgba(255, 255, 255, 0.3)"
                                                         }],
    // Global for reuse by CPTokenField.
    themedTextFieldValues =
    [
     // CPThemeStateControlSizeRegular
     [@"vertical-alignment",    CPCenterVerticalTextAlignment],

     [@"bezel-color",           bezelCssColor,                                              CPThemeStateBezeled],
     [@"bezel-color",           bezelFocusedCssColor,                                       [CPThemeStateBezeled, CPThemeStateEditing]],
     [@"bezel-color",           bezelDisabledCssColor,                                      [CPThemeStateBezeled, CPThemeStateDisabled]], // FIXME: here !
     [@"bezel-color",           unborderedBezelCssColor,                                    CPThemeStateNormal],
     [@"bezel-color",           unborderedBezelFocusedCssColor,                             CPThemeStateEditing],
     [@"bezel-color",           borderedBezelCssColor,                                      CPThemeStateBordered],
     [@"bezel-color",           borderedBezelFocusedCssColor,                               [CPThemeStateBordered, CPThemeStateEditing]],

     [@"text-color",            A3CPColorActiveText],
     [@"text-color",            A3CPColorInactiveText,                                      [CPThemeStateBezeled, CPThemeStateDisabled]],
     [@"text-shadow-color",     nil],
     [@"text-shadow-offset",    CGSizeMakeZero()],

     [@"content-inset",      CGInsetMake(1.0, 0.0, 0.0, 0.0)],                           // For labels
     [@"content-inset",      CGInsetMake(0.0, 1.0, 1.0, -1.0),                           CPThemeStateEditing], // For labels
     [@"content-inset",      CGInsetMake(3.0, 5.0, 3.0, 3.0),                            CPThemeStateBezeled],
     [@"content-inset",      CGInsetMake(3.0, 5.0, 3.0, 3.0),                            [CPThemeStateBezeled, CPThemeStateEditing]],
     [@"content-inset",      CGInsetMake(3.0, 5.0, 3.0, 3.0),                            CPThemeStateBordered],
     [@"content-inset",      CGInsetMake(3.5, 5.0, 3.0, 3.0),                            [CPThemeStateBordered, CPThemeStateEditing]],

     [@"bezel-inset",        CGInsetMake(2.0, 5.0, 4.0, 4.0),                            CPThemeStateBezeled],
     [@"bezel-inset",        CGInsetMake(0.0, 1.0, 0.0, 1.0),                            [CPThemeStateBezeled, CPThemeStateEditing]],

     [@"text-color",         A3CPColorInactiveText,                                      CPTextFieldStatePlaceholder],

     [@"background-inset",   CGInsetMake(1.0, 3.0, 3.0, 1.0),                            CPThemeStateBezeled],
     [@"background-inset",   CGInsetMake(0.0, 0.0, 0.0, 0.0),                            CPThemeStateNormal],

     // TableDataView

     [@"line-break-mode",    CPLineBreakByTruncatingTail,                                CPThemeStateTableDataView],
     [@"vertical-alignment", CPCenterVerticalTextAlignment,                              CPThemeStateTableDataView],
     [@"content-inset",      CGInsetMake(0.0, 0.0, 0.0, 5.0),                            CPThemeStateTableDataView],
     [@"content-inset",      CGInsetMake(0.0, 0.0, 0.0, 5.0),                            [CPThemeStateTableDataView, CPThemeStateBezeled, CPThemeStateEditing]],
     [@"content-inset",      CGInsetMake(0.0, 0.0, 0.0, 5.0),                            [CPThemeStateTableDataView, CPThemeStateBezeled]],

     [@"bezel-color",        tableCssColor,                                              CPThemeStateTableDataView],
     [@"bezel-color",        tableFocusedCssColor,                                       [CPThemeStateTableDataView, CPThemeStateEditing]],

     [@"font",               [CPFont systemFontOfSize:CPFontCurrentSystemSize],          CPThemeStateTableDataView],

     [@"text-color",         A3CPColorActiveText,                 CPThemeStateTableDataView], // Normal
     [@"text-color",         A3CPColorActiveText,                 [CPThemeStateTableDataView, CPThemeStateSelectedDataView]], // Row selected but not active
     [@"text-color",         A3CPColorDefaultText,                [CPThemeStateTableDataView, CPThemeStateSelectedDataView, CPThemeStateFirstResponder, CPThemeStateKeyWindow]],  // Row selected and active
     [@"text-color",         A3CPColorActiveText,                 [CPThemeStateTableDataView, CPThemeStateSelectedDataView, CPThemeStateFirstResponder, CPThemeStateKeyWindow, CPThemeStateEditing]],

     // --- HUD TABLE CELLS ---
     [@"text-color",         [CPColor whiteColor],                [CPThemeStateTableDataView, CPThemeStateHUD]],
     [@"text-color",         [CPColor blackColor],                [CPThemeStateTableDataView, CPThemeStateHUD, CPThemeStateSelectedDataView]],
     [@"text-color",         [CPColor blackColor],                [CPThemeStateTableDataView, CPThemeStateHUD, CPThemeStateSelectedDataView, CPThemeStateFirstResponder, CPThemeStateKeyWindow]],
     // ------------------------------------

     [@"content-inset",      CGInsetMake(0.0, 0.0, 0.0, 0.0),                            [CPThemeStateTableDataView, CPThemeStateEditable]],
     [@"bezel-inset",        CGInsetMake(0.0, 1.0, 0.0, 5.0),                            [CPThemeStateTableDataView, CPThemeStateEditable, CPThemeStateEditing]],
     [@"bezel-inset",        CGInsetMake(0.0, 1.0, 0.0, 5.0),                            [CPThemeStateTableDataView, CPThemeStateEditable]],

     [@"text-color",         [CPColor colorWithCalibratedWhite:125.0 / 255.0 alpha:1.0], [CPThemeStateTableDataView, CPThemeStateGroupRow]],
     [@"text-color",         [CPColor whiteColor],                                       [CPThemeStateTableDataView, CPThemeStateGroupRow, CPThemeStateSelectedDataView, CPThemeStateFirstResponder, CPThemeStateKeyWindow]],
     [@"text-shadow-color",  [CPColor whiteColor],                                       [CPThemeStateTableDataView, CPThemeStateGroupRow]],
     [@"text-shadow-offset", CGSizeMake(0, 1),                                           [CPThemeStateTableDataView, CPThemeStateGroupRow]],
     [@"text-shadow-color",  [CPColor colorWithCalibratedWhite:0.0 alpha:0.6],           [CPThemeStateTableDataView, CPThemeStateGroupRow, CPThemeStateSelectedDataView, CPThemeStateFirstResponder, CPThemeStateKeyWindow]],
     [@"font",               [CPFont boldSystemFontOfSize:CPFontCurrentSystemSize],      [CPThemeStateTableDataView, CPThemeStateGroupRow]],

     [@"min-size",                   CGSizeMake(-1.0, 22.0)], // was 29
     [@"nib2cib-adjustment-frame",   CGRectMake(2.0, 0.0, -4.0, 0.0)],      // For labels
     [@"nib2cib-adjustment-frame",   CGRectMake(0.0, 0.0, 0.0, 0.0),                     CPThemeStateBezeled],  // for bordered fields, frame = alignment

     // CPThemeStateControlSizeSmall
     [@"content-inset",              CGInsetMake(7.0, 7.0, 5.0, 8.0),                    [CPThemeStateControlSizeSmall, CPThemeStateBezeled]],
     [@"content-inset",              CGInsetMake(7.0, 7.0, 5.0, 8.0),                    [CPThemeStateControlSizeSmall, CPThemeStateBezeled, CPThemeStateEditing]],

     [@"min-size",                   CGSizeMake(-1.0, 25.0),                             CPThemeStateControlSizeSmall],
     [@"nib2cib-adjustment-frame",   CGRectMake(2.0, 0.0, -4.0, 0.0),                    CPThemeStateControlSizeSmall],
     [@"nib2cib-adjustment-frame",   CGRectMake(-3.0, 4.0, 7.0, 7.0),                    [CPThemeStateControlSizeSmall, CPThemeStateBezeled]],

     // CPThemeStateControlSizeMini
     [@"content-inset",              CGInsetMake(6.0, 7.0, 5.0, 7.0),                    [CPThemeStateControlSizeMini, CPThemeStateBezeled]],
     [@"content-inset",              CGInsetMake(6.0, 7.0, 5.0, 7.0),                    [CPThemeStateControlSizeMini, CPThemeStateBezeled, CPThemeStateEditing]],
     [@"min-size",                   CGSizeMake(-1.0, 22.0),                             CPThemeStateControlSizeMini],
     [@"nib2cib-adjustment-frame",   CGRectMake(2.0, 0.0, -4.0, 0.0),                    CPThemeStateControlSizeMini],
     [@"nib2cib-adjustment-frame",   CGRectMake(-4.0, 4.0, 8.0, 7.0),                    [CPThemeStateControlSizeMini, CPThemeStateBezeled]],

     // --- HUD REGISTRATION ---
     
     // Standard Label Text in HUD (White)
     [@"text-color",            [CPColor whiteColor],                 CPThemeStateHUD],
     [@"text-color",            [CPColor colorWithWhite:1 alpha:0.5], [CPThemeStateHUD, CPThemeStateDisabled]],
     [@"text-color",            [CPColor whiteColor],               [CPThemeStateHUD, CPThemeStateEditing]],
     // Change the background color of selected text in HUD mode to improve contrast
     // [@"field-selection-color", hudSelectionColor,                  CPThemeStateHUD],

     // Input Fields in HUD (Bezeled)
     [@"bezel-color",           hudBezelCssColor,                   [CPThemeStateHUD, CPThemeStateBezeled]],
     [@"bezel-color",           hudBezelFocusedCssColor,            [CPThemeStateHUD, CPThemeStateBezeled, CPThemeStateEditing]]
    ];

    [self registerThemeValues:themedTextFieldValues forView:textfield];

    [textfield setBezeled:YES];

    [textfield setPlaceholderString:"Placeholder"];
    [textfield setStringValue:""];
    [textfield setEditable:YES];

    return textfield;
}

+ (CPTextField)themedRoundedTextField
{
    var textfield = [[CPTextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 160.0, 22.0)],

    bezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                      @"background-color": A3ColorBackgroundWhite,
                                                      @"border-color": A3ColorTextfieldActiveBorder,
                                                      @"border-style": @"solid",
                                                      @"border-width": @"1px",
                                                      @"border-radius": @"5px",
                                                      @"box-sizing": @"border-box",
                                                      @"transition-duration": @"0.35s, 0.35s",
                                                      @"transition-property": @"box-shadow, border"
                                                      }],

    bezelFocusedCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorBackgroundWhite,
                                                             @"border-color": @"A3ColorBorderBlue",
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"5px",
                                                             @"box-sizing": @"border-box",
                                                             @"box-shadow": @"0px 0px 2px 0px rgb(59,127,202)",
                                                             @"transition-duration": @"0.35s, 0.35s",
                                                             @"transition-property": @"box-shadow, border"
                                                             }],

    bezelDisabledCssColor = [CPColor colorWithCSSDictionary:@{
                                                              @"background-color": A3ColorBackgroundWhite,
                                                              @"border-color": A3ColorTextfieldInactiveBorder,
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px",
                                                              @"border-radius": @"5px",
                                                              @"box-sizing": @"border-box",
                                                              @"transition-duration": @"0.35s, 0.35s",
                                                              @"transition-property": @"box-shadow, border"
                                                              }];

    // Global for reuse by CPSearchField
    themedRoundedTextFieldValues =
    [
     [@"vertical-alignment",        CPTopVerticalTextAlignment,     [CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"bezel-color",               bezelCssColor,                  [CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"bezel-color",               bezelFocusedCssColor,           [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],
     [@"bezel-color",               bezelDisabledCssColor,          [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateDisabled]],

//     [@"font",                      [CPFont systemFontOfSize:CPFontCurrentSystemSize],      CPTextFieldStateRounded],
     [@"text-color",                A3CPColorActiveText,                                      CPTextFieldStateRounded],

     [@"content-inset",             CGInsetMake(2.0, 11.0, 4.0, 11.0),                        [CPTextFieldStateRounded, CPThemeStateBezeled]], // was 3.0, 11.0, 3.0, 11.0
     [@"content-inset",             CGInsetMake(2.0, 11.0, 4.0, 11.0),                        [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],

     [@"bezel-inset",               CGInsetMake(2.0, 11.0, 4.0, 11.0),                        [CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"bezel-inset",               CGInsetMake(0.0, 1.0, 0.0, 1.0),                        [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],

     [@"text-color",                 A3CPColorInactiveText,                                    [CPTextFieldStateRounded, CPTextFieldStatePlaceholder]],
     [@"text-color",                 A3CPColorInactiveText,                                    [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateDisabled]],
//     [@"text-shadow-color",          regularDisabledTextShadowColor,                         [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateDisabled]],

     [@"min-size",                   CGSizeMake(-1.0, 22.0),                                  [CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"max-size",                   CGSizeMake(-1.0, 22.0),                                 [CPTextFieldStateRounded, CPThemeStateBezeled]],
//     [@"nib2cib-adjustment-frame",   CGRectMake(-4.0, 7.0, 8.0, 10.0),                       [CPTextFieldStateRounded, CPThemeStateBezeled]],

     // CPThemeStateControlSizeSmall
     [@"content-inset",              CGInsetMake(7.0, 6.0, 4.0, 6.0),                        [CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"bezel-inset",                CGInsetMake(2.0, 4.0, 2.0, 4.0),                        [CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"bezel-inset",                CGInsetMake(0.0, 1.0, 0.0, 1.0),                        [CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],
     [@"min-size",                   CGSizeMake(-1.0, 19.0),                                 [CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"max-size",                   CGSizeMake(-1.0, 19.0),                                 [CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled]],
//     [@"nib2cib-adjustment-frame",   CGRectMake(-4.0, 7.0, 8.0, 9.0),                        [CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled]],

     // CPThemeStateControlSizeMini
     [@"content-inset",              CGInsetMake(7.0, 6.0, 4.0, 6.0),                        [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"bezel-inset",                CGInsetMake(2.0, 4.0, 2.0, 4.0),                        [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"bezel-inset",                CGInsetMake(0.0, 1.0, 0.0, 1.0),                        [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],
     [@"min-size",                   CGSizeMake(-1.0, 17.0),                                 [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"max-size",                   CGSizeMake(-1.0, 17.0),                                 [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled]],
//     [@"nib2cib-adjustment-frame",   CGRectMake(-4.0, 2.0, 8.0, 4.0),                        [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled]]
     ];

    [self registerThemeValues:themedRoundedTextFieldValues forView:textfield];

    [textfield setBezeled:YES];
    [textfield setBezelStyle:CPTextFieldRoundedBezel];

    [textfield setPlaceholderString:"Placeholder"];
    [textfield setStringValue:""];
    [textfield setEditable:YES];

    return textfield;
}

+ (CPSearchField)themedSearchField
{
    var searchField = [[CPSearchField alloc] initWithFrame:CGRectMake(0.0, 0.0, 160.0, 22.0)],

    // ==========================================================
    // 1. REGULAR IMAGES (16x16)
    // ==========================================================

    imageSearch = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgMagnifier,
        "mask-image": svgMagnifier,
        "background-color": A3ColorActiveText,
        "-webkit-mask-size": "contain", "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center", "mask-position": "center"
    } size:CGSizeMake(16,16)],

    imageFind = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgMagnifier,
        "mask-image": svgMagnifier,
        "background-color": A3ColorActiveText,
        "-webkit-mask-size": "contain", "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center", "mask-position": "center"
    } size:CGSizeMake(16,16)],

    imageCancel = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgCancel,
        "mask-image": svgCancel,
        "background-color": A3ColorActiveText,
        "-webkit-mask-size": "contain", "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center", "mask-position": "center"
    } size:CGSizeMake(11,11)],

    imageSearchLight = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgMagnifier,
        "mask-image": svgMagnifier,
        "background-color": A3ColorInactiveText,
        "-webkit-mask-size": "contain", "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center", "mask-position": "center"
    } size:CGSizeMake(16,16)],

    imageFindLight = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgMagnifier,
        "mask-image": svgMagnifier,
        "background-color": A3ColorInactiveText,
        "-webkit-mask-size": "contain", "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center", "mask-position": "center"
    } size:CGSizeMake(16,16)],

    // ==========================================================
    // 2. SMALL IMAGES (13x13)
    // ==========================================================

    imageSearchSmall = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgMagnifier,
        "mask-image": svgMagnifier,
        "background-color": A3ColorActiveText,
        "-webkit-mask-size": "contain", "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center", "mask-position": "center"
    } size:CGSizeMake(13,13)],

    imageFindSmall = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgMagnifier,
        "mask-image": svgMagnifier,
        "background-color": A3ColorActiveText,
        "-webkit-mask-size": "contain", "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center", "mask-position": "center"
    } size:CGSizeMake(13,13)],

    imageCancelSmall = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgCancel,
        "mask-image": svgCancel,
        "background-color": A3ColorActiveText,
        "-webkit-mask-size": "contain", "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center", "mask-position": "center"
    } size:CGSizeMake(9,9)],

    imageSearchLightSmall = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgMagnifier,
        "mask-image": svgMagnifier,
        "background-color": A3ColorInactiveText,
        "-webkit-mask-size": "contain", "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center", "mask-position": "center"
    } size:CGSizeMake(13,13)],

    imageFindLightSmall = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgMagnifier,
        "mask-image": svgMagnifier,
        "background-color": A3ColorInactiveText,
        "-webkit-mask-size": "contain", "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center", "mask-position": "center"
    } size:CGSizeMake(13,13)],

    // ==========================================================
    // 3. MINI IMAGES (11x11)
    // ==========================================================

    imageSearchMini = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgMagnifier,
        "mask-image": svgMagnifier,
        "background-color": A3ColorActiveText,
        "-webkit-mask-size": "contain", "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center", "mask-position": "center"
    } size:CGSizeMake(11,11)],

    imageFindMini = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgMagnifier,
        "mask-image": svgMagnifier,
        "background-color": A3ColorActiveText,
        "-webkit-mask-size": "contain", "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center", "mask-position": "center"
    } size:CGSizeMake(11,11)],

    imageCancelMini = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgCancel,
        "mask-image": svgCancel,
        "background-color": A3ColorActiveText,
        "-webkit-mask-size": "contain", "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center", "mask-position": "center"
    } size:CGSizeMake(7,7)],

    imageSearchLightMini = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgMagnifier,
        "mask-image": svgMagnifier,
        "background-color": A3ColorInactiveText,
        "-webkit-mask-size": "contain", "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center", "mask-position": "center"
    } size:CGSizeMake(11,11)],

    imageFindLightMini = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgMagnifier,
        "mask-image": svgMagnifier,
        "background-color": A3ColorInactiveText,
        "-webkit-mask-size": "contain", "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center", "mask-position": "center"
    } size:CGSizeMake(11,11)],

    // ==========================================================
    // 4. HUD IMAGES (White) - ALL SIZES
    // ==========================================================

    // Regular HUD
    imageSearchHUD = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgMagnifier, "mask-image": svgMagnifier,
        "background-color": @"#ffffff",
        "-webkit-mask-size": "contain", "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center", "mask-position": "center"
    } size:CGSizeMake(16,16)],

    imageCancelHUD = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgCancel, "mask-image": svgCancel,
        "background-color": @"#ffffff",
        "-webkit-mask-size": "contain", "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center", "mask-position": "center"
    } size:CGSizeMake(11,11)],

    // Small HUD
    imageSearchHUDSmall = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgMagnifier, "mask-image": svgMagnifier,
        "background-color": @"#ffffff",
        "-webkit-mask-size": "contain", "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center", "mask-position": "center"
    } size:CGSizeMake(13,13)],

    imageCancelHUDSmall = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgCancel, "mask-image": svgCancel,
        "background-color": @"#ffffff",
        "-webkit-mask-size": "contain", "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center", "mask-position": "center"
    } size:CGSizeMake(9,9)],

    // Mini HUD
    imageSearchHUDMini = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgMagnifier, "mask-image": svgMagnifier,
        "background-color": @"#ffffff",
        "-webkit-mask-size": "contain", "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center", "mask-position": "center"
    } size:CGSizeMake(11,11)],

    imageCancelHUDMini = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgCancel, "mask-image": svgCancel,
        "background-color": @"#ffffff",
        "-webkit-mask-size": "contain", "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center", "mask-position": "center"
    } size:CGSizeMake(7,7)],

    // ==========================================================
    // 5. COLORS & LAYOUT
    // ==========================================================

    hudBezelCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0, 0, 0, 0.25)",
        @"border-color": @"rgba(255, 255, 255, 0.25)",
        @"border-style": @"solid",
        @"border-width": @"1px",
        @"border-radius": @"11px",
        @"box-sizing": @"border-box",
        @"box-shadow": @"0 1px 0 rgba(255,255,255,0.1) inset"
    }],

    hudBezelFocusedCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0, 0, 0, 0.4)",
        @"border-color": @"rgba(255, 255, 255, 0.5)",
        @"border-style": @"solid",
        @"border-width": @"1px",
        @"border-radius": @"11px",
        @"box-sizing": @"border-box",
        @"box-shadow": @"0 0 3px rgba(255,255,255,0.3)"
    }],

    calcRectFunctionNotEditing = "" + function(s, rect) {
        var size        = [[s _potentialCurrentValueForThemeAttribute:@"image-search"] size],
            inset       = [s _potentialCurrentValueForThemeAttribute:@"image-search-inset"],
            margin      = [s _potentialCurrentValueForThemeAttribute:@"search-right-margin"],
            value       = [s objectValue],
            placeholder = [s placeholderString],
            hasValue    = ([value length] > 0),
            text        = hasValue ? value : placeholder,
            labelSize   = [text sizeWithFont:[s _potentialCurrentValueForThemeAttribute:@"font"]];

        if (hasValue || (placeholder === @" "))
            return CGRectMake(inset.left - inset.right, inset.top - inset.bottom + (CGRectGetHeight(rect) - size.height) / 2, size.width, size.height);
        else
            return CGRectMake((rect.size.width - labelSize.width) / 2 - size.width - margin, inset.top - inset.bottom + (rect.size.height - size.height) / 2, size.width, size.height);
    },

    calcRectFunctionEditing = "" + function(s, rect) {
        var size = [[s _potentialCurrentValueForThemeAttribute:@"image-search"] size] || CGSizeMakeZero(),
            inset = [s _potentialCurrentValueForThemeAttribute:@"image-search-inset"];
        return CGRectMake(inset.left - inset.right, inset.top - inset.bottom + (CGRectGetHeight(rect) - size.height) / 2, size.width, size.height);
    },

    animateLayoutFunction = "" + function(s) {
        for (var i = 0, subviews = [s subviews], nb = [subviews count], textView = nil; (!textView && (i < nb)); i++)
            if ([subviews[i] isKindOfClass:_CPImageAndTextView]) textView = subviews[i];

        [CPAnimationContext beginGrouping];
        var context = [CPAnimationContext currentContext];
        [context setDuration:0.2];
        [context setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
        [context setCompletionHandler:function() { [s themedLayoutFunctionCompletionHandler]; }];
        [[[s searchButton] animator] setFrame:[s searchButtonRectForBounds:[s bounds]]];
        [[textView animator]         setFrame:[s contentRectForBounds:[s bounds]]];
        [CPAnimationContext endGrouping];
    },

    // ==========================================================
    // 6. REGISTRATION
    // ==========================================================

    overrides =
    [
     // --- Regular Size ---
     [@"image-search-inset",        CGInsetMake(-1, 0, 0, 2)],
     [@"image-cancel-inset",        CGInsetMake(-1, 5, 0, 0)],
     
     [@"image-search",              imageSearch],
     [@"image-find",                imageSearch], // In Cocoa, find image shows only while editing
     [@"image-search",              imageSearch,                    CPThemeStateEditing],
     [@"image-find",                imageFind,                      CPThemeStateEditing],
     [@"image-search",              imageSearchLight,               CPThemeStateDisabled],
     [@"image-find",                imageFindLight,                 CPThemeStateDisabled],
     [@"image-cancel",              imageCancel],
     [@"image-cancel-pressed",      imageCancel],
     [@"search-right-margin",       4],

     // --- HUD Regular Overrides ---
     [@"image-search",              imageSearchHUD,                 CPThemeStateHUD],
     [@"image-find",                imageSearchHUD,                 [CPThemeStateHUD, CPThemeStateEditing]],
     [@"image-cancel",              imageCancelHUD,                 CPThemeStateHUD],
     [@"text-color",                [CPColor whiteColor],           [CPThemeStateHUD, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"text-color",                [CPColor colorWithWhite:1 alpha:0.5], [CPThemeStateHUD, CPTextFieldStateRounded, CPTextFieldStatePlaceholder]],
     [@"bezel-color",               hudBezelCssColor,               [CPThemeStateHUD, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"bezel-color",               hudBezelFocusedCssColor,        [CPThemeStateHUD, CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],

     // --- Alignment Fixes (For All) ---
     [@"vertical-alignment",        CPCenterVerticalTextAlignment],
     [@"vertical-alignment",        CPCenterVerticalTextAlignment,  [CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"vertical-alignment",        CPCenterVerticalTextAlignment,  [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],
     [@"content-inset",             CGInsetMake(0, 11, 0, 11),      [CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"content-inset",             CGInsetMake(0, 11, 0, 11),      [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],
     [@"bezel-inset",               CGInsetMake(2, 11, 4, 11),      [CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"min-size",                  CGSizeMake(0, 22.0),            [CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"max-size",                  CGSizeMake(-1, 22.0),           [CPTextFieldStateRounded, CPThemeStateBezeled]],

     // --- Small Size ---
     [@"image-search-inset",        CGInsetMake(-1, -1, 0, 2),      CPThemeStateControlSizeSmall],
     [@"image-cancel-inset",        CGInsetMake(-1, 5, 0, -1),      CPThemeStateControlSizeSmall],
     [@"image-search",              imageSearchSmall,               CPThemeStateControlSizeSmall],
     [@"image-find",                imageSearchSmall,               [CPThemeStateControlSizeSmall, CPThemeStateEditing]],
     [@"image-find",                imageFindSmall,                 [CPThemeStateControlSizeSmall, CPThemeStateEditing]], // Specific override
     [@"image-search",              imageSearchLightSmall,          [CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
     [@"image-find",                imageFindLightSmall,            [CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
     [@"image-cancel",              imageCancelSmall,               CPThemeStateControlSizeSmall],
     [@"image-cancel-pressed",      imageCancelSmall,               CPThemeStateControlSizeSmall],
     [@"search-right-margin",       6,                              CPThemeStateControlSizeSmall],

     [@"content-inset",             CGInsetMake(0, 11, 0, 11),      [CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"content-inset",             CGInsetMake(0, 11, 0, 11),      [CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],
     [@"min-size",                  CGSizeMake(0, 19.0),            [CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"max-size",                  CGSizeMake(-1, 19.0),           [CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled]],

     // --- HUD Small Overrides ---
     [@"image-search",              imageSearchHUDSmall,            [CPThemeStateHUD, CPThemeStateControlSizeSmall]],
     [@"image-find",                imageSearchHUDSmall,            [CPThemeStateHUD, CPThemeStateControlSizeSmall, CPThemeStateEditing]],
     [@"image-cancel",              imageCancelHUDSmall,            [CPThemeStateHUD, CPThemeStateControlSizeSmall]],
     [@"bezel-color",               hudBezelCssColor,               [CPThemeStateHUD, CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"bezel-color",               hudBezelFocusedCssColor,        [CPThemeStateHUD, CPThemeStateControlSizeSmall, CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],

     // --- Mini Size ---
     [@"image-search-inset",        CGInsetMake(-1, -2, 0, 2),      CPThemeStateControlSizeMini],
     [@"image-cancel-inset",        CGInsetMake(-1, 5, 0, -2),      CPThemeStateControlSizeMini],
     [@"image-search",              imageSearchMini,                CPThemeStateControlSizeMini],
     [@"image-find",                imageSearchMini,                [CPThemeStateControlSizeMini, CPThemeStateEditing]],
     [@"image-find",                imageFindMini,                  [CPThemeStateControlSizeMini, CPThemeStateEditing]],
     [@"image-search",              imageSearchLightMini,           [CPThemeStateControlSizeMini, CPThemeStateDisabled]],
     [@"image-find",                imageFindLightMini,             [CPThemeStateControlSizeMini, CPThemeStateDisabled]],
     [@"image-cancel",              imageCancelMini,                CPThemeStateControlSizeMini],
     [@"image-cancel-pressed",      imageCancelMini,                CPThemeStateControlSizeMini],
     [@"search-right-margin",       8,                              CPThemeStateControlSizeMini],

     [@"content-inset",             CGInsetMake(0, 11, 0, 11),      [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"content-inset",             CGInsetMake(0, 11, 0, 11),      [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],
     [@"min-size",                  CGSizeMake(0, 17.0),            [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"max-size",                  CGSizeMake(-1, 17.0),           [CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled]],

     // --- HUD Mini Overrides ---
     [@"image-search",              imageSearchHUDMini,             [CPThemeStateHUD, CPThemeStateControlSizeMini]],
     [@"image-find",                imageSearchHUDMini,             [CPThemeStateHUD, CPThemeStateControlSizeMini, CPThemeStateEditing]],
     [@"image-cancel",              imageCancelHUDMini,             [CPThemeStateHUD, CPThemeStateControlSizeMini]],
     [@"bezel-color",               hudBezelCssColor,               [CPThemeStateHUD, CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"bezel-color",               hudBezelFocusedCssColor,        [CPThemeStateHUD, CPThemeStateControlSizeMini, CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],

     // --- Animation & Menu ---
     [@"search-button-rect-function",  calcRectFunctionNotEditing,  [CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"search-button-rect-function",  calcRectFunctionEditing,     [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],
     [@"layout-function",              animateLayoutFunction],
     [@"search-menu-offset",        CGPointMake(1, 0)]
     ];

    [self registerThemeValues:overrides forView:searchField inherit:themedRoundedTextFieldValues];

    return searchField;
}

#pragma mark -
#pragma mark Date Pickers

+ (CPDatePicker)themedDatePicker
{
    var datePicker = [[CPDatePicker alloc] initWithFrame:CGRectMake(40.0, 40.0, 170.0, 29.0)],

    bezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                      @"background-color": A3ColorBackgroundWhite,
                                                      @"border-color": A3ColorTextfieldActiveBorder,
                                                      @"border-style": @"solid",
                                                      @"border-width": @"1px",
                                                      @"border-radius": @"0px",
                                                      @"box-sizing": @"border-box",
                                                      @"transition-duration": @"0.35s, 0.35s",
                                                      @"transition-property": @"box-shadow, border"
                                                      }],

    bezelFocusedCssColor = [CPColor colorWithCSSDictionary:@{
                                                             @"background-color": A3ColorBackgroundWhite,
                                                             @"border-color": @"A3ColorBorderBlue",
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"0px",
                                                             @"box-sizing": @"border-box",
                                                             @"box-shadow": @"0px 0px 2px 0px rgb(59,127,202)",
                                                             @"transition-duration": @"0.35s, 0.35s",
                                                             @"transition-property": @"box-shadow, border"
                                                             }],

    bezelDisabledCssColor = [CPColor colorWithCSSDictionary:@{
                                                              @"background-color": A3ColorBackgroundWhite,
                                                              @"border-color": A3ColorTextfieldInactiveBorder,
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px",
                                                              @"border-radius": @"0px",
                                                              @"box-sizing": @"border-box",
                                                              @"transition-duration": @"0.35s, 0.35s",
                                                              @"transition-property": @"box-shadow, border"
                                                              }],
   hudBezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                        @"background-color": @"rgba(0, 0, 0, 0.3)",
                                                        @"border-color": @"rgba(255, 255, 255, 0.3)",
                                                        @"border-style": @"solid",
                                                        @"border-width": @"1px",
                                                        @"border-radius": @"0px",
                                                        @"box-sizing": @"border-box",
                                                        @"transition-duration": @"0.35s, 0.35s",
                                                        @"transition-property": @"box-shadow, border"
                                                        }],

    hudBezelFocusedCssColor = [CPColor colorWithCSSDictionary:@{
                                                        @"background-color": @"rgba(0, 0, 0, 0.5)",
                                                        @"border-color": @"#ffffff",
                                                        @"border-style": @"solid",
                                                        @"border-width": @"1px",
                                                        @"border-radius": @"0px",
                                                        @"box-sizing": @"border-box",
                                                        @"box-shadow": @"0px 0px 3px 0px rgba(255,255,255,0.5)",
                                                        @"transition-duration": @"0.35s, 0.35s",
                                                        @"transition-property": @"box-shadow, border"
                                                        }],

    themeValues =
    [
     [@"vertical-alignment",            CPCenterVerticalTextAlignment],

     [@"bezel-color",                   bezelCssColor,                              [CPThemeStateBezeled, CPThemeStateBordered]],
     [@"bezel-color",                   bezelFocusedCssColor,                       [CPThemeStateBezeled, CPThemeStateBordered, CPThemeStateEditing, CPThemeStateKeyWindow]],
     [@"bezel-color",                   bezelDisabledCssColor,                      [CPThemeStateBezeled, CPThemeStateBordered, CPThemeStateDisabled]],

     // --- HUD Mappings ---
     [@"bezel-color",                   hudBezelCssColor,                           [CPThemeStateHUD, CPThemeStateBezeled, CPThemeStateBordered]],
     [@"bezel-color",                   hudBezelFocusedCssColor,                    [CPThemeStateHUD, CPThemeStateBezeled, CPThemeStateBordered, CPThemeStateEditing]],
     [@"text-color",                    [CPColor whiteColor],                       CPThemeStateHUD],
     [@"text-color",                    [CPColor colorWithWhite:1 alpha:0.4],       [CPThemeStateHUD, CPThemeStateDisabled]],
     // ------

     [@"uses-focus-ring",               YES],

     [@"text-color",                    A3CPColorActiveText],
     [@"text-color",                    A3CPColorInactiveText,                      [CPThemeStateBezeled, CPThemeStateDisabled]],

     // REMARK: We use a special theme state (CPThemeStateComposedControl) if there is a stepper
     [@"content-inset",                 CGInsetMake(2.0, 0.0, 2.0, 2.0),            CPThemeStateNormal],
     [@"content-inset",                 CGInsetMake(2.0, 0.0, 2.0, 2.0),            CPThemeStateComposedControl],
     [@"content-inset",                 CGInsetMake(2.0, 0.0, 2.0, 2.0),            [CPThemeStateComposedControl, CPThemeStateEditing]],

     [@"bezel-inset",                   CGInsetMakeZero()],

     [@"separator-content-inset",       CGInsetMake(0.0, -3.0, 0.0, -1.0)],
     [@"time-separator-content-inset",  CGInsetMake(0.0, -3.0, 0.0, 0.0)],

     [@"date-hour-margin",              3.0],
     [@"hour-ampm-margin",              3.0],
     [@"stepper-margin",                3.0],
     [@"stepper-margin",                3.0,                                        CPThemeStateEditing],

     // min/max size is different for textfield+stepper (CPThemeStateComposedControl) and no stepper (CPThemeStateNormal)
     [@"min-size",                      CGSizeMake(0, 23.0),                        CPThemeStateComposedControl],
     [@"max-size",                      CGSizeMake(-1.0, 23.0),                     CPThemeStateComposedControl],

     [@"min-size",                      CGSizeMake(0, 22.0),                        CPThemeStateNormal],
     [@"max-size",                      CGSizeMake(-1.0, 22.0),                     CPThemeStateNormal],

     // nib2cib-adjustment-frame is different for textfield+stepper (CPThemeStateComposedControl) and no stepper (CPThemeStateNormal)
//     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -4.0, -3.0, -4.0),          CPThemeStateComposedControl],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, -3.0, 0.0),             CPThemeStateComposedControl],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, 0.0, 0.0),             CPThemeStateNormal],

     // CPThemeStateControlSizeSmall
     [@"content-inset",                 CGInsetMake(2.0, 0.0, 2.0, 2.0),            CPThemeStateControlSizeSmall],
     [@"content-inset",                 CGInsetMake(2.0, 0.0, 2.0, 2.0),            [CPThemeStateControlSizeSmall, CPThemeStateComposedControl]],
     [@"content-inset",                 CGInsetMake(2.0, 0.0, 2.0, 2.0),            [CPThemeStateControlSizeSmall, CPThemeStateComposedControl, CPThemeStateEditing]],

     [@"date-hour-margin",              5.0,                                        CPThemeStateControlSizeSmall],
     [@"hour-ampm-margin",              2.0,                                        CPThemeStateControlSizeSmall],
     [@"stepper-margin",                2.0,                                        CPThemeStateControlSizeSmall],
     [@"stepper-margin",                2.0,                                        [CPThemeStateControlSizeSmall, CPThemeStateEditing]],

     // min/max size is different for textfield+stepper (CPThemeStateComposedControl) and no stepper (CPThemeStateNormal)
     [@"min-size",                      CGSizeMake(0, 20.0),                        [CPThemeStateControlSizeSmall, CPThemeStateComposedControl]],
     [@"max-size",                      CGSizeMake(-1.0, 20.0),                     [CPThemeStateControlSizeSmall, CPThemeStateComposedControl]],

     [@"min-size",                      CGSizeMake(0, 19.0),                        CPThemeStateControlSizeSmall],
     [@"max-size",                      CGSizeMake(-1.0, 19.0),                     CPThemeStateControlSizeSmall],

     // nib2cib-adjustment-frame is different for textfield+stepper (CPThemeStateComposedControl) and no stepper (CPThemeStateNormal)
//     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, -2.0, -2.0, -2.0),          [CPThemeStateControlSizeSmall, CPThemeStateComposedControl]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, -2.0, 0.0),            [CPThemeStateControlSizeSmall, CPThemeStateComposedControl]],
//     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 1.0, 2.0, 0.0),             CPThemeStateControlSizeSmall],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, 0.0, 0.0),             CPThemeStateControlSizeSmall],

     // CPThemeStateControlSizeMini
     [@"content-inset",                 CGInsetMake(2.0, 0.0, 2.0, 2.0),            CPThemeStateControlSizeMini],
     [@"content-inset",                 CGInsetMake(2.0, 0.0, 2.0, 2.0),            [CPThemeStateControlSizeMini, CPThemeStateComposedControl]],
     [@"content-inset",                 CGInsetMake(2.0, 0.0, 2.0, 2.0),            [CPThemeStateControlSizeMini, CPThemeStateComposedControl, CPThemeStateEditing]],

     [@"date-hour-margin",              0.0,                                        CPThemeStateControlSizeMini],
     [@"hour-ampm-margin",              1.0,                                        CPThemeStateControlSizeMini],
     [@"stepper-margin",                2.0,                                        CPThemeStateControlSizeMini],
     [@"stepper-margin",                2.0,                                        [CPThemeStateControlSizeMini, CPThemeStateEditing]],

     // min/max size is different for textfield+stepper (CPThemeStateComposedControl) and no stepper (CPThemeStateNormal)
     [@"min-size",                      CGSizeMake(0, 17.0),                        [CPThemeStateControlSizeMini, CPThemeStateComposedControl]],
     [@"max-size",                      CGSizeMake(-1.0, 17.0),                     [CPThemeStateControlSizeMini, CPThemeStateComposedControl]],

     [@"min-size",                      CGSizeMake(0, 17.0),                        CPThemeStateControlSizeMini],
     [@"max-size",                      CGSizeMake(-1.0, 17.0),                     CPThemeStateControlSizeMini],

     // nib2cib-adjustment-frame is different for textfield+stepper (CPThemeStateComposedControl) and no stepper (CPThemeStateNormal)
//     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, -2.0, 0.0),            [CPThemeStateControlSizeMini, CPThemeStateComposedControl]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, -2.0, 0.0),            [CPThemeStateControlSizeMini, CPThemeStateComposedControl]],
     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, 0.0, 0.0),             CPThemeStateControlSizeMini]
//     [@"nib2cib-adjustment-frame",      CGRectMake(0.0, 0.0, 2.0, 0.0),             CPThemeStateControlSizeMini]
     ];

    [datePicker setDatePickerStyle:CPTextFieldDatePickerStyle];
    [self registerThemeValues:themeValues forView:datePicker];

    return datePicker;
}

+ (CPDatePicker)themedDatePickerCalendar
{
    var datePicker = [[CPDatePicker alloc] initWithFrame:CGRectMake(40.0, 140.0, 276.0 ,148.0)],

    // --- ARROWS (SVG) ---
    svgArrowSolidDown = "data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAyNCAyNCI+PHBhdGggZD0iTTQgNiBMMjAgNiBMMTIgMjAgWiIgZmlsbD0iIzAwMDAwMCIvPjwvc3ZnPg==",

    // Use 12x12 size. With the SVG, this results in an ~8px visual arrow,
    // which matches the 8px circle dot perfectly.
    arrowImageLeft = [CPImage imageWithCSSDictionary:@{
                                                       "-webkit-mask-image": "url('" + svgArrowSolidDown + "')",
                                                       "mask-image": "url('" + svgArrowSolidDown + "')",
                                                       "background-color": A3ColorCalendarButtons,
                                                       "-webkit-mask-size": "contain",
                                                       "mask-size": "contain",
                                                       "-webkit-mask-repeat": "no-repeat",
                                                       "mask-repeat": "no-repeat",
                                                       "-webkit-mask-position": "center",
                                                       "mask-position": "center",
                                                       "transform": "rotate(90deg)"
                                                       }
                                    beforeDictionary:nil
                                     afterDictionary:nil
                                                size:CGSizeMake(12, 12)],

    arrowImageRight = [CPImage imageWithCSSDictionary:@{
                                                        "-webkit-mask-image": "url('" + svgArrowSolidDown + "')",
                                                        "mask-image": "url('" + svgArrowSolidDown + "')",
                                                        "background-color": A3ColorCalendarButtons,
                                                        "-webkit-mask-size": "contain",
                                                        "mask-size": "contain",
                                                        "-webkit-mask-repeat": "no-repeat",
                                                        "mask-repeat": "no-repeat",
                                                        "-webkit-mask-position": "center",
                                                        "mask-position": "center",
                                                        "transform": "rotate(-90deg)"
                                                        }
                                     beforeDictionary:nil
                                      afterDictionary:nil
                                                 size:CGSizeMake(12, 12)],

    circleImage = [CPImage imageWithCSSDictionary:@{
                                                    @"background": A3ColorCalendarButtons,
                                                    @"border-radius": @"50%"
                                                    }
                                             size:CGSizeMake(12, 12)],

    arrowImageLeftHighlighted = [CPImage imageWithCSSDictionary:@{
                                                                  "-webkit-mask-image": "url('" + svgArrowSolidDown + "')",
                                                                  "mask-image": "url('" + svgArrowSolidDown + "')",
                                                                  "background-color": A3ColorCalendarHighlightedButtons,
                                                                  "-webkit-mask-size": "contain",
                                                                  "mask-size": "contain",
                                                                  "-webkit-mask-repeat": "no-repeat",
                                                                  "mask-repeat": "no-repeat",
                                                                  "-webkit-mask-position": "center",
                                                                  "mask-position": "center",
                                                                  "transform": "rotate(90deg)"
                                                                  }
                                               beforeDictionary:nil
                                                afterDictionary:nil
                                                           size:CGSizeMake(12, 12)],

    arrowImageRightHighlighted = [CPImage imageWithCSSDictionary:@{
                                                                   "-webkit-mask-image": "url('" + svgArrowSolidDown + "')",
                                                                   "mask-image": "url('" + svgArrowSolidDown + "')",
                                                                   "background-color": A3ColorCalendarHighlightedButtons,
                                                                   "-webkit-mask-size": "contain",
                                                                   "mask-size": "contain",
                                                                   "-webkit-mask-repeat": "no-repeat",
                                                                   "mask-repeat": "no-repeat",
                                                                   "-webkit-mask-position": "center",
                                                                   "mask-position": "center",
                                                                   "transform": "rotate(-90deg)"
                                                                   }
                                                beforeDictionary:nil
                                                 afterDictionary:nil
                                                            size:CGSizeMake(12, 12)],
    circleImageHighlighted = [CPImage imageWithCSSDictionary:@{
                                                               @"background": A3ColorCalendarHighlightedButtons,
                                                               @"border-radius": @"50%"
                                                               }
                                                        size:CGSizeMake(12, 12)],

// --- CLOCK HANDS ---
    // The SVGs below are designed with a 1:3 aspect ratio (viewBox="0 0 1 3").
    // The visual hand (rect) occupies the top 2/3 (height="2"), leaving the bottom 1/3 transparent.
    // When centered by the clock code, the pivot point ends up 1/4 from the bottom of the visual hand,
    // creating a 3:1 Tip-to-Tail ratio (e.g., 45px Tip, 15px Tail).

    // Red Hand (3:1 Ratio)
    svgHandRed      = "data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxIiBoZWlnaHQ9IjMiIHZpZXdCb3g9IjAgMCAxIDMiPgo8cmVjdCB4PSIwLjI1IiB3aWR0aD0iMC41IiBoZWlnaHQ9IjIiIGZpbGw9IiNGRjNCMzAiLz4KPC9zdmc+",
    // Red Hand Dim (Disabled)
    svgHandRedDim   = "data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxIiBoZWlnaHQ9IjMiIHZpZXdCb3g9IjAgMCAxIDMiPjxyZWN0IHdpZHRoPSIxIiBoZWlnaHQ9IjIiIGZpbGw9IiNGRjNCMzAiIGZpbGwtb3BhY2l0eT0iMC41Ii8+PC9zdmc+",
    
    // Black Hand (3:1 Ratio)
    svgHandBlack    = "data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxIiBoZWlnaHQ9IjMiIHZpZXdCb3g9IjAgMCAxIDMiPjxyZWN0IHdpZHRoPSIxIiBoZWlnaHQ9IjIiIGZpbGw9IiMwMDAwMDAiLz48L3N2Zz4=",
    // Black Hand Dim (Disabled)
    svgHandBlackDim = "data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHdpZHRoPSIxIiBoZWlnaHQ9IjMiIHZpZXdCb3g9IjAgMCAxIDMiPjxyZWN0IHdpZHRoPSIxIiBoZWlnaHQ9IjIiIGZpbGw9IiMwMDAwMDAiIGZpbGwtb3BhY2l0eT0iMC4zIi8+PC9zdmc+",
    
    // Dot (Centered)
    svgHandDot      = "data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMCAxMCI+PGNpcmNsZSBjeD0iNSIgY3k9IjUiIHI9IjUiIGZpbGw9IiMwMDAwMDAiLz48L3N2Zz4=",
    svgHandDotDim   = "data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMCAxMCI+PGNpcmNsZSBjeD0iNSIgY3k9IjUiIHI9IjUiIGZpbGw9IiMwMDAwMDAiIGZpbGwtb3BhY2l0eT0iMC4zIi8+PC9zdmc=",

    // Calculated Sizes: 
    // Image Height = Desired Tip Length * 2. (Since center is pivot, and pivot is at 50% of image).
    // With 3:1 SVG, Visual Tip is 0.5 * Height. Visual Tail is 0.166 * Height.
    
    // Tip ~48px -> Height 96
    secondHandSize = CGSizeMake(4.0, 96.0),
    secondHandImage = [[CPImage alloc] initWithContentsOfFile:svgHandRed size:secondHandSize],

    // Tip ~48px -> Height 96
    minuteHandSize = CGSizeMake(4.0, 96.0),
    minuteHandImage = [[CPImage alloc] initWithContentsOfFile:svgHandBlack size:minuteHandSize],

    // Tip ~32px -> Height 64
    hourHandSize = CGSizeMake(4.0, 64.0),
    hourHandImage   = [[CPImage alloc] initWithContentsOfFile:svgHandBlack size:hourHandSize],

    middleHandSize = CGSizeMake(8.0, 8.0),
    middleHandImage = [[CPImage alloc] initWithContentsOfFile:svgHandDot size:middleHandSize],

    // Disabled states
    secondHandImageDisabled = [[CPImage alloc] initWithContentsOfFile:svgHandRedDim size:secondHandSize],
    minuteHandImageDisabled = [[CPImage alloc] initWithContentsOfFile:svgHandBlackDim size:minuteHandSize],
    hourHandImageDisabled   = [[CPImage alloc] initWithContentsOfFile:svgHandBlackDim size:hourHandSize],
    middleHandImageDisabled = [[CPImage alloc] initWithContentsOfFile:svgHandDotDim size:middleHandSize],

    // --- CLOCK FACE ---
    clockSize = CGSizeMake(120, 120),
    clockImageColor = [CPColor colorWithCSSDictionary:@{
                                                        @"background": @"rgb(255,255,255)",
                                                        @"border-radius": @"50%",
                                                        @"border-color": @"rgba(0,0,0,0)",
                                                        @"border-style": @"solid",
                                                        @"border-width": @"1px",
                                                        @"box-sizing": @"border-box"
                                                        }],

    borderedClockImageColor = [CPColor colorWithCSSDictionary:@{
                                                                @"background": @"rgb(255,255,255)",
                                                                @"border-radius": @"50%",
                                                                @"border-color": A3ColorActiveBorder,
                                                                @"border-style": @"solid",
                                                                @"border-width": @"1px",
                                                                @"box-sizing": @"border-box"
                                                                }],

    disabledClockImageColor = [CPColor colorWithCSSDictionary:@{
                                                                @"background": A3ColorBackgroundInactive,
                                                                @"border-radius": @"50%",
                                                                @"border-color": @"rgba(0,0,0,0)",
                                                                @"border-style": @"solid",
                                                                @"border-width": @"1px",
                                                                @"box-sizing": @"border-box"
                                                                }],

    disabledBorderedClockImageColor = [CPColor colorWithCSSDictionary:@{
                                                                        @"background": A3ColorBackgroundInactive,
                                                                        @"border-radius": @"50%",
                                                                        @"border-color": A3ColorInactiveBorder,
                                                                        @"border-style": @"solid",
                                                                        @"border-width": @"1px",
                                                                        @"box-sizing": @"border-box"
                                                                        }],

    unborderedBezelColor = [CPColor colorWithCSSDictionary:@{}],

    borderedBezelColor = [CPColor colorWithCSSDictionary:@{
                                                           @"border-color": A3ColorCalendarDark,
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"box-sizing": @"border-box"
                                                           }],

    disabledBorderedBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                   @"border-color": A3ColorInactiveBorder,
                                                                   @"border-style": @"solid",
                                                                   @"border-width": @"1px",
                                                                   @"box-sizing": @"border-box"
                                                                   }],

    tileBezelColor = [CPColor colorWithCSSDictionary:@{}],

    selectedTileBezelColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorCalendarActive,
                                                               @"border-radius": @"3px"
                                                               }],

    leftSelectedTileBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                   @"background-color": A3ColorCalendarActive,
                                                                   @"border-top-left-radius": @"3px",
                                                                   @"border-bottom-left-radius": @"3px",
                                                                   @"box-sizing": @"border-box"
                                                                   }],

    middleSelectedTileBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                     @"background-color": A3ColorCalendarActive
                                                                     }],

    rightSelectedTileBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": A3ColorCalendarActive,
                                                                    @"border-top-right-radius": @"3px",
                                                                    @"border-bottom-right-radius": @"3px"
                                                                    }],

    disabledSelectedTileBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                       @"background-color": A3ColorCalendarActiveNotKey,
                                                                       @"border-radius": @"3px"
                                                                       }],

    disabledLeftSelectedTileBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                           @"background-color": A3ColorCalendarActiveNotKey,
                                                                           @"border-top-left-radius": @"3px",
                                                                           @"border-bottom-left-radius": @"3px",
                                                                           @"box-sizing": @"border-box"
                                                                           }],

    disabledMiddleSelectedTileBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                             @"background-color": A3ColorCalendarActiveNotKey
                                                                             }],

    disabledRightSelectedTileBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                            @"background-color": A3ColorCalendarActiveNotKey,
                                                                            @"border-top-right-radius": @"3px",
                                                                            @"border-bottom-right-radius": @"3px"
                                                                            }],

    themeValues =
    [
     [@"bezel-color",                   unborderedBezelColor,                                   CPThemeStateAlternateState],
     [@"bezel-color",                   borderedBezelColor,                                     [CPThemeStateAlternateState, CPThemeStateBordered]],
     [@"bezel-color",                   unborderedBezelColor,                                   [CPThemeStateAlternateState, CPThemeStateDisabled]],
     [@"bezel-color",                   disabledBorderedBezelColor,                             [CPThemeStateAlternateState, CPThemeStateBordered, CPThemeStateDisabled]],

     [@"uses-focus-ring",               NO,                                                     CPThemeStateAlternateState],

     [@"separator-color",               A3CPColorCalendarDark],
     [@"separator-margin-width",        3],
     [@"separator-height",              1],

     [@"bezel-color-calendar",          tileBezelColor],
     [@"bezel-color-calendar",          disabledSelectedTileBezelColor,                         CPThemeStateSelected],
     [@"bezel-color-calendar-left",     disabledLeftSelectedTileBezelColor,                     CPThemeStateSelected],
     [@"bezel-color-calendar-middle",   disabledMiddleSelectedTileBezelColor,                   CPThemeStateSelected],
     [@"bezel-color-calendar-right",    disabledRightSelectedTileBezelColor,                    CPThemeStateSelected],
     [@"bezel-color-calendar",          selectedTileBezelColor,                                 [CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"bezel-color-calendar-left",     leftSelectedTileBezelColor,                             [CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"bezel-color-calendar-middle",   middleSelectedTileBezelColor,                           [CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"bezel-color-calendar-right",    rightSelectedTileBezelColor,                            [CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"bezel-color-calendar",          disabledSelectedTileBezelColor,                         [CPThemeStateSelected, CPThemeStateDisabled]],
     [@"bezel-color-calendar-left",     disabledLeftSelectedTileBezelColor,                     [CPThemeStateSelected, CPThemeStateDisabled]],
     [@"bezel-color-calendar-middle",   disabledMiddleSelectedTileBezelColor,                   [CPThemeStateSelected, CPThemeStateDisabled]],
     [@"bezel-color-calendar-right",    disabledRightSelectedTileBezelColor,                    [CPThemeStateSelected, CPThemeStateDisabled]],

     [@"bezel-color-clock",             clockImageColor,                                        CPThemeStateAlternateState],
     [@"bezel-color-clock",             borderedClockImageColor,                                [CPThemeStateAlternateState, CPThemeStateBordered]],
     [@"bezel-color-clock",             disabledClockImageColor,                                [CPThemeStateAlternateState, CPThemeStateDisabled]],
     [@"bezel-color-clock",             disabledBorderedClockImageColor,                        [CPThemeStateAlternateState, CPThemeStateDisabled, CPThemeStateBordered]],

     [@"title-text-color",           A3CPColorCalendarTitle],
     [@"title-font",                 [CPFont boldSystemFontOfSize:12.0]],

     [@"title-text-color",           [CPColor colorWithCalibratedRed:79.0 / 255.0 green:79.0 / 255.0 blue:79.0 / 255.0 alpha:0.5],       CPThemeStateDisabled],
     [@"title-font",                 [CPFont boldSystemFontOfSize:12.0],                                                                 CPThemeStateDisabled],

     [@"weekday-text-color",         A3CPColorCalendarDark],
     [@"weekday-font",               [CPFont boldSystemFontOfSize:11.0]],

     [@"clock-text-color",           [CPColor colorWithCalibratedRed:153.0 / 255.0 green:153.0 / 255.0 blue:153.0 / 255.0 alpha:1.0]],
     [@"clock-font",                 [CPFont systemFontOfSize:11.0]],

     [@"clock-text-color",           [CPColor colorWithCalibratedRed:153.0 / 255.0 green:153.0 / 255.0 blue:153.0 / 255.0 alpha:0.5],    CPThemeStateDisabled],
     [@"clock-font",                 [CPFont systemFontOfSize:11.0],                                                                     CPThemeStateDisabled],

     [@"clock-second-hand-over",            YES],
     [@"clock-draws-hours",                 YES],
     [@"clock-hours-font",                  [CPFont systemFontOfSize:11.0]],
     [@"clock-hours-font",                  [CPFont systemFontOfSize:11.0],                         CPThemeStateDisabled],
     [@"clock-hours-text-color",            A3CPColorActiveText],
     [@"clock-hours-text-color",            A3CPColorInactiveText,                                  CPThemeStateDisabled],
     [@"clock-hours-radius",                50],

     [@"arrow-image-left",                  arrowImageLeft],
     [@"arrow-image-right",                 arrowImageRight],
     [@"arrow-image-left-highlighted",      arrowImageLeftHighlighted],
     [@"arrow-image-right-highlighted",     arrowImageRightHighlighted],
     [@"circle-image",                      circleImage],
     [@"circle-image-highlighted",          circleImageHighlighted],
     [@"arrow-inset",                       CGInsetMake(6.0, 5.0, 0.0, 3.0)],
     [@"previous-button-size",              CGSizeMake(6, 8)],
     [@"current-button-size",               CGSizeMake(6, 8)],
     [@"next-button-size",                  CGSizeMake(6, 8)],

     [@"second-hand-image",  secondHandImage],
     [@"hour-hand-image",    hourHandImage],
     [@"middle-hand-image",  middleHandImage],
     [@"minute-hand-image",  minuteHandImage],

     [@"second-hand-image",  secondHandImageDisabled,    CPThemeStateDisabled],
     [@"hour-hand-image",    hourHandImageDisabled,      CPThemeStateDisabled],
     [@"middle-hand-image",  middleHandImageDisabled,    CPThemeStateDisabled],
     [@"minute-hand-image",  minuteHandImageDisabled,    CPThemeStateDisabled],

     [@"second-hand-size",   secondHandSize],
     [@"hour-hand-size",     hourHandSize],
     [@"middle-hand-size",   middleHandSize],
     [@"minute-hand-size",   minuteHandSize],

     [@"border-width",            0.0],
     [@"size-header",             CGSizeMake(138.0, 37.0)],
     [@"size-tile",               CGSizeMake(18.57, 16.0)],
     [@"tile-margin",             CGSizeMake(0, 1)],
     [@"size-clock",              clockSize],
     [@"size-calendar",           CGSizeMake(138.0, 111.0)],
     [@"calendar-clock-margin",   18],
     [@"min-size-calendar",       CGSizeMake(138.0, 148.0)],
     [@"max-size-calendar",       CGSizeMake(138.0, 148.0)],
     
     [@"title-inset",             CGInsetMake(2, 0, 0, 3)],
     
     // 2. Increase top inset from 2.0 to 6.0 to align buttons with text baseline
     [@"day-label-inset",         CGInsetMake(22, 0, 0, 4)],
     [@"tile-inset",              CGInsetMake(1, 0, 0, 4)],

     [@"arrow-inset",             CGInsetMake(6.0, 5.0, 0.0, 3.0)],
     [@"previous-button-size",    CGSizeMake(6, 8)],
     [@"current-button-size",     CGSizeMake(8, 8)],
     
     [@"next-button-size",        CGSizeMake(6, 8)],

     [@"nib2cib-adjustment-frame",              CGRectMake(0.0, 0.0, 0.0, 0.0),        CPThemeStateAlternateState],
     [@"clock-only-nib2cib-adjustment-frame",   CGRectMake(1.0, -2.0, -2.0, -3.0)]
    ];

    [datePicker setDatePickerStyle:CPClockAndCalendarDatePickerStyle];
    [datePicker setBackgroundColor:[CPColor whiteColor]];
    [self registerThemeValues:themeValues forView:datePicker];

    return datePicker;
}

+ (_CPDatePickerDayViewTextField)themedDatePickerDayViewTextField
{
    var textField = [[_CPDatePickerDayViewTextField alloc] initWithFrame:CGRectMakeZero()],

    themeValues =
    [
     // Standard
     [@"text-color",            A3CPColorCalendarTile],
     [@"text-color",            A3CPColorCalendarTile,              CPThemeStateHighlighted],
     [@"text-color",            A3CPColorCalendarCurrentDayTile,    [CPThemeStateHighlighted, CPThemeStateKeyWindow]],
     [@"text-color",            A3CPColorCalendarOutOfRangeTile,    CPThemeStateDisabled],
     [@"text-color",            A3CPColorCalendarTile,              CPThemeStateSelected],
     [@"text-color",            A3CPColorCalendarSelectedTile,      [CPThemeStateSelected, CPThemeStateKeyWindow]],
     
     // --- HUD Mappings ---
     // Normal Days: White
     [@"text-color",            [CPColor whiteColor],               CPThemeStateHUD],
     // Highlighted/Selected Days: Black (since background will be light white/transparent)
     [@"text-color",            [CPColor blackColor],               [CPThemeStateHUD, CPThemeStateSelected]], 
     [@"text-color",            [CPColor blackColor],               [CPThemeStateHUD, CPThemeStateHighlighted]],
     // Out of Range: Dimmed White
     [@"text-color",            [CPColor colorWithWhite:1 alpha:0.4], [CPThemeStateHUD, CPThemeStateDisabled]],

     [@"font",                  [CPFont systemFontOfSize:10.0]],
     [@"font",                  [CPFont boldSystemFontOfSize:10.0], CPThemeStateHighlighted],

     [@"alignment",             CPRightTextAlignment],
     [@"content-inset",         CGInsetMake(0, 2, 0, 0)],
    ];

    [self registerThemeValues:themeValues forView:textField];

    return textField;
}

+ (_CPDatePickerElementTextField)themedDatePickerElementTextField
{
    var textField = [[_CPDatePickerElementTextField alloc] initWithFrame:CGRectMakeZero()],

    bezelColorDatePickerTextField = [CPColor colorWithCSSDictionary:@{
                                                                      @"background-color": [[CPColor clearColor] cssString],
                                                                      @"border-style": @"solid",
                                                                      @"border-width": @"0px",
                                                                      @"border-radius": @"3px",
                                                                      @"box-sizing": @"border-box"
                                                                      }],

    selectedBezelColorDatePickerTextField = [CPColor colorWithCSSDictionary:@{
                                                                              @"background-color": [[CPColor selectedTextBackgroundColor] cssString],
                                                                              @"border-style": @"solid",
                                                                              @"border-width": @"0px",
                                                                              @"border-radius": @"3px",
                                                                              @"box-sizing": @"border-box"
                                                                              }],
    // --- HUD Selected Background ---
    hudSelectedBezelColor = [CPColor colorWithCSSDictionary:@{
                                                              @"background-color": @"rgba(255,255,255,0.3)",
                                                              @"border-radius": @"3px"
                                                             }],
    themeValues =
    [
     [@"content-inset",     CGInsetMake(2.0, 1.0, 0.0, -1.0)],
     [@"content-inset",     CGInsetMake(1.0, 1.0, 0.0, -1.0),                           CPThemeStateControlSizeSmall],
     [@"content-inset",     CGInsetMake(1.0, 1.0, 0.0, -1.0),                           CPThemeStateControlSizeMini],
     [@"bezel-color",       bezelColorDatePickerTextField],
     [@"bezel-color",       selectedBezelColorDatePickerTextField,                      [CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"min-size",          CGSizeMake(6.0, -1)],
     [@"font",              [CPFont systemFontForControlSize:CPRegularControlSize]],
     [@"font",              [CPFont systemFontForControlSize:CPSmallControlSize],       CPThemeStateControlSizeSmall],
     [@"font",              [CPFont systemFontForControlSize:CPMiniControlSize],        CPThemeStateControlSizeMini],
     [@"text-color",        A3CPColorActiveText],
     [@"text-color",        A3CPColorInactiveText,                                      CPThemeStateDisabled],

     // --- HUD States ---
     [@"bezel-color",       hudSelectedBezelColor,                                      [CPThemeStateHUD, CPThemeStateSelected]],
     [@"text-color",        [CPColor whiteColor],                                       CPThemeStateHUD],
     [@"text-color",        [CPColor colorWithWhite:1 alpha:0.4],                       [CPThemeStateHUD, CPThemeStateDisabled]]
     ];

    [self registerThemeValues:themeValues forView:textField];

    return textField;
}

+ (_CPDatePickerElementSeparator)themedDatePickerElementSeparator
{
    var textField = [[_CPDatePickerElementSeparator alloc] initWithFrame:CGRectMakeZero()],

    themeValues =
    [
     [@"content-inset",     CGInsetMake(2.0, 1.0, 0.0, 0.0)],
     [@"content-inset",     CGInsetMake(1.0, 1.0, 0.0, 0.0),                           CPThemeStateControlSizeSmall],
     [@"content-inset",     CGInsetMake(1.0, 1.0, 0.0, 0.0),                           CPThemeStateControlSizeMini],
     [@"min-size",          CGSizeMake(6.0, -1)],
     [@"font",              [CPFont systemFontForControlSize:CPRegularControlSize]],
     [@"font",              [CPFont systemFontForControlSize:CPSmallControlSize],       CPThemeStateControlSizeSmall],
     [@"font",              [CPFont systemFontForControlSize:CPMiniControlSize],        CPThemeStateControlSizeMini],
     [@"text-color",        A3CPColorActiveText],
     [@"text-color",        A3CPColorInactiveText,                                      CPThemeStateDisabled],

          // --- HUD States ---
     [@"text-color",        [CPColor whiteColor],                                       CPThemeStateHUD],
     [@"text-color",        [CPColor colorWithWhite:1 alpha:0.4],                       [CPThemeStateHUD, CPThemeStateDisabled]]
    ];

    [self registerThemeValues:themeValues forView:textField];

    return textField;
}

#pragma mark -

+ (CPTokenField)themedTokenField
{
    var tokenfield = [[CPTokenField alloc] initWithFrame:CGRectMake(0.0, 0.0, 160.0, 22.0)],

    overrides =
    [
     [@"bezel-inset", CGInsetMakeZero()],
     [@"bezel-inset", CGInsetMake(2.0, 5.0, 4.0, 4.0),    CPThemeStateBezeled],
     [@"bezel-inset", CGInsetMake(0.0, 1.0, 0.0, 1.0),    [CPThemeStateBezeled, CPThemeStateEditing]],

     [@"editor-inset", CGInsetMake(0.0, 0.0, 0.0, 0.0)], 

     // Non-bezeled token field with tokens
     [@"content-inset", CGInsetMake(6.0, 8.0, 4.0, 8.0)],

     // Non-bezeled token field with no tokens
     [@"content-inset", CGInsetMake(7.0, 8.0, 6.0, 8.0), CPTextFieldStatePlaceholder],

     // Bezeled token field with tokens
     [@"content-inset", CGInsetMake(3.0, 5.0, 3.0, 3.0), CPThemeStateBezeled],

     // Bezeled token field with no tokens
     [@"content-inset", CGInsetMake(3.0, 5.0, 3.0, 3.0), [CPThemeStateBezeled, CPTextFieldStatePlaceholder]]
     ];

    [self registerThemeValues:overrides forView:tokenfield inherit:themedTextFieldValues];

    return tokenfield;
}

+ (_CPTokenFieldToken)themedTokenFieldToken
{
    var token = [[_CPTokenFieldToken alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 19.0)],

    // --- Standard Colors ---
    bezelColorHighlighted = [CPColor colorWithCSSDictionary:@{
                                                              @"background-color": @"A3ColorBorderBlue",
                                                              @"border-color": @"A3ColorBorderBlue",
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px",
                                                              @"border-radius": @"3px",
                                                              @"box-sizing": @"border-box"
                                                              }],

    bezelColor = [CPColor colorWithCSSDictionary:@{
                                                   @"background-color": A3ColorBorderBlueLight,
                                                   @"border-color": A3ColorBorderBlueLight,
                                                   @"border-style": @"solid",
                                                   @"border-width": @"1px",
                                                   @"border-radius": @"3px",
                                                   @"box-sizing": @"border-box"
                                                   }],

    // --- HUD Colors ---
    hudBezelColor = [CPColor colorWithCSSDictionary:@{
                                                        @"background-color": @"rgba(255, 255, 255, 0.2)",
                                                        @"border-color": @"rgba(255, 255, 255, 0.25)",
                                                        @"border-style": @"solid",
                                                        @"border-width": @"1px",
                                                        @"border-radius": @"3px",
                                                        @"box-sizing": @"border-box"
                                                    }],

    hudBezelColorHighlighted = [CPColor colorWithCSSDictionary:@{
                                                        @"background-color": @"rgba(255, 255, 255, 0.45)",
                                                        @"border-color": @"rgba(255, 255, 255, 0.5)",
                                                        @"border-style": @"solid",
                                                        @"border-width": @"1px",
                                                        @"border-radius": @"3px",
                                                        @"box-sizing": @"border-box"
                                                    }],

    themeValues =
    [
     // Standard
     [@"bezel-color",    bezelColor,                     CPThemeStateBezeled],
     [@"bezel-color",    bezelColorHighlighted,          [CPThemeStateBezeled, CPThemeStateHighlighted]],
     [@"bezel-color",    bezelColor,                     [CPThemeStateBezeled, CPThemeStateDisabled]],

     [@"text-color",     A3CPColorActiveText],
     [@"text-color",     A3CPColorDefaultText,           CPThemeStateHighlighted],
     [@"text-color",     A3CPColorInactiveText,          CPThemeStateDisabled],

     // HUD Overrides
     [@"bezel-color",    hudBezelColor,                  [CPThemeStateHUD, CPThemeStateBezeled]],
     [@"bezel-color",    hudBezelColorHighlighted,       [CPThemeStateHUD, CPThemeStateBezeled, CPThemeStateHighlighted]],
     [@"text-color",     [CPColor whiteColor],           CPThemeStateHUD],
     [@"text-color",     [CPColor whiteColor],           [CPThemeStateHUD, CPThemeStateHighlighted]],
     [@"text-color",     [CPColor colorWithWhite:1 alpha:0.4], [CPThemeStateHUD, CPThemeStateDisabled]],

     [@"bezel-inset",    CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateBezeled],
     [@"content-inset",  CGInsetMake(-3.0, 16.0, 0.0, 16.0),  CPThemeStateBezeled],

     // Minimum height == maximum height since tokens are fixed height.
     [@"min-size",       CGSizeMake(0.0, 16.0)],
     [@"max-size",       CGSizeMake(-1.0, 16.0)],

     [@"vertical-alignment", CPCenterTextAlignment]
     ];

    [self registerThemeValues:themeValues forView:token];

    return token;
}

+ (_CPTokenFieldTokenDisclosureButton)themedTokenFieldTokenDisclosureButton
{
    var button = [[_CPTokenFieldTokenDisclosureButton alloc] initWithFrame:CGRectMake(0, 0, 9, 9)],

    // Change CPImage to CPColor using colorWithCSSDictionary
    arrowColor = [CPColor colorWithCSSDictionary:@{
                                                    "-webkit-mask-image": svgArrowDown,
                                                    "mask-image": svgArrowDown,
                                                    "background-color": A3ColorActiveText,
                                                    "-webkit-mask-size": "contain",
                                                    "mask-size": "contain",
                                                    "-webkit-mask-repeat": "no-repeat",
                                                    "mask-repeat": "no-repeat",
                                                    "-webkit-mask-position": "center",
                                                    "mask-position": "center"
                                                 }],

    arrowColorHighlighted = [CPColor colorWithCSSDictionary:@{
                                                                "-webkit-mask-image": svgArrowDown,
                                                                "mask-image": svgArrowDown,
                                                                "background-color": A3ColorWhite,
                                                                "-webkit-mask-size": "contain",
                                                                "mask-size": "contain",
                                                                "-webkit-mask-repeat": "no-repeat",
                                                                "mask-repeat": "no-repeat",
                                                                "-webkit-mask-position": "center",
                                                                "mask-position": "center"
                                                            }],
    // HUD Arrow (White)
    hudArrowColor = [CPColor colorWithCSSDictionary:@{
                                                    "-webkit-mask-image": svgArrowDown,
                                                    "mask-image": svgArrowDown,
                                                    "background-color": @"#FFFFFF",
                                                    "-webkit-mask-size": "contain",
                                                    "mask-size": "contain",
                                                    "-webkit-mask-repeat": "no-repeat",
                                                    "mask-repeat": "no-repeat",
                                                    "-webkit-mask-position": "center",
                                                    "mask-position": "center"
                                                 }],

    themeValues =
    [
     [@"content-inset",  CGInsetMake(0.0, 0.0, 0.0, 0.0),    CPThemeStateNormal],

     [@"bezel-color",    nil,                                CPThemeStateBordered],
     
     // Standard
     [@"bezel-color",    arrowColor,                         [CPThemeStateBordered, CPThemeStateHovered]],
     [@"bezel-color",    arrowColorHighlighted,              [CPThemeStateBordered, CPThemeStateHighlighted]],

     // HUD
     [@"bezel-color",    hudArrowColor,                      [CPThemeStateHUD, CPThemeStateBordered]],
     [@"bezel-color",    hudArrowColor,                      [CPThemeStateHUD, CPThemeStateBordered, CPThemeStateHovered]],
     [@"bezel-color",    hudArrowColor,                      [CPThemeStateHUD, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"min-size",       CGSizeMake(14.0, 12.0)],
     [@"max-size",       CGSizeMake(14.0, 12.0)],

     [@"offset",         CGPointMake(16, 1)]
     ];

    [self registerThemeValues:themeValues forView:button];

    return button;
}

+ (_CPTokenFieldTokenCloseButton)themedTokenFieldTokenCloseButton
{
    var button = [[_CPTokenFieldTokenCloseButton alloc] initWithFrame:CGRectMake(0, 0, 9, 9)],

    // Normal State - Changed color to A3ColorWhite
    bezelColor = [CPColor colorWithCSSDictionary:@{
        "-webkit-mask-image": svgCancel,
        "mask-image": svgCancel,
        "background-color": A3ColorWhite,
        "-webkit-mask-size": "contain",
        "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat",
        "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center",
        "mask-position": "center"
    }],

    // Highlighted State
    bezelHighlightedColor = [CPColor colorWithCSSDictionary:@{
        "-webkit-mask-image": svgCancel,
        "mask-image": svgCancel,
        "background-color": A3ColorWhite,
        "-webkit-mask-size": "contain",
        "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat",
        "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center",
        "mask-position": "center"
    }],

    // Disabled State
    bezelDisabledColor = [CPColor clearColor],

    // HUD Color (White)
    hudBezelColor = [CPColor colorWithCSSDictionary:@{
        "-webkit-mask-image": svgCancel,
        "mask-image": svgCancel,
        "background-color": @"#FFFFFF",
        "-webkit-mask-size": "contain",
        "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat",
        "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center",
        "mask-position": "center"
    }],

    themeValues =
    [
     // Standard
     [@"bezel-color",    bezelColor,                             [CPThemeStateBordered, CPThemeStateHovered]],
     [@"bezel-color",    bezelDisabledColor,                     [CPThemeStateBordered, CPThemeStateDisabled]], 
     [@"bezel-color",    bezelHighlightedColor,                  [CPThemeStateBordered, CPThemeStateHighlighted]],

     // HUD
     // We make it visible on hover and highlight in HUD
     [@"bezel-color",    hudBezelColor,                          [CPThemeStateHUD, CPThemeStateBordered, CPThemeStateHovered]],
     [@"bezel-color",    hudBezelColor,                          [CPThemeStateHUD, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"min-size",       CGSizeMake(8.0, 8.0)],
     [@"max-size",       CGSizeMake(8.0, 8.0)],

     [@"bezel-inset",    CGInsetMake(0.0, 0.0, 0.0, 0.0),        CPThemeStateBordered],
     [@"bezel-inset",    CGInsetMake(0.0, 0.0, 0.0, 0.0),        [CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"offset",         CGPointMake(12, 3),                     CPThemeStateBordered]
     ];

    [self registerThemeValues:themeValues forView:button];

    return button;
}

+ (CPComboBox)themedComboBox
{
    var combo = [[CPComboBox alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 31.0)],

    // ==========================================================
    // HELPERS
    // ==========================================================

    // Helper for Consistent Arrow Styling
    arrowCSS = function(color, rightOffset, boxSize) {
        var size = boxSize || "25px",
            offset = rightOffset || "-8px",
            marginTop = -(parseInt(size) / 2.5); // Centers the arrow visually

        return @{
                    @"content": @"''",
                    @"position": @"absolute",
                    @"top": @"50%",
                    @"right": offset,
                    @"width": size,
                    @"height": size,
                    @"margin-top": marginTop + "px",
                    @"z-index": "+1",

                    "-webkit-mask-image": svgDoubleArrow2,
                    "mask-image": svgDoubleArrow,
                    "-webkit-mask-size": "contain",
                    "mask-size": "contain",
                    "-webkit-mask-repeat": "no-repeat",
                    "mask-repeat": "no-repeat",
                    "-webkit-mask-position": "center",
                    "mask-position": "center",

                    @"background-color": color
                };
    },

    // Helper for Consistent Separator Styling
    separatorCSS = function(rightOffset, color) {
        var sepColor = color || @"rgb(225,225,225)";
        return @{
                    @"background-color": sepColor,
                    @"bottom": @"3px",
                    @"content": @"''",
                    @"position": @"absolute",
                    @"right": rightOffset || @"17px",
                    @"top": @"3px",
                    @"z-index": "+1",
                    @"width": @"1px"
                };
    },

    // ==========================================================
    // REGULAR SIZE DEFINITIONS (Standard)
    // ==========================================================

    buttonCssColor = [CPColor colorWithCSSDictionary:@{
                                                           @"background-color": A3ColorBackgroundWhite,
                                                           @"border-color": A3ColorActiveBorder,
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"border-radius": @"3px",
                                                           @"box-sizing": @"border-box"
                                                       }
                                    beforeDictionary:separatorCSS(@"17px", nil)
                                     afterDictionary:arrowCSS(A3ColorBorderBlue, "-8px", "25px")],

    bezelFocusedCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorBackgroundWhite,
                                                                 @"border-color": A3ColorBorderBlue,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"border-radius": @"3px",
                                                                 @"box-sizing": @"border-box",
                                                                 @"box-shadow": @"0px 0px 2px 0px rgb(59,127,202)",
                                                                 @"transition-duration": @"0.35s, 0.35s",
                                                                 @"transition-property": @"box-shadow, border"
                                                             }
                                         beforeDictionary:separatorCSS(@"17px", nil)
                                          afterDictionary:arrowCSS(A3ColorBorderBlue, "-8px", "25px")],

    notKeyButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorBackgroundWhite,
                                                                 @"border-color": A3ColorActiveBorder,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"border-radius": @"3px",
                                                                 @"box-sizing": @"border-box"
                                                             }
                                          beforeDictionary:separatorCSS(@"17px", nil)
                                           afterDictionary:arrowCSS(A3ColorActiveBorder, "-8px", "25px")],

    disabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorBackgroundInactive,
                                                               @"border-color": A3ColorInactiveBorder,
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"border-radius": @"3px",
                                                               @"box-sizing": @"border-box"
                                                               }
                                            beforeDictionary:nil
                                             afterDictionary:arrowCSS(A3ColorInactiveBorder, "-8px", "25px")],

    highlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"border-color": A3ColorBorderDark,
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"1px",
                                                                  @"border-radius": @"3px",
                                                                  @"box-sizing": @"border-box",
                                                                  @"background-color": A3ColorBackgroundHighlighted
                                                                  }],

    // ==========================================================
    // SMALL SIZE DEFINITIONS (Standard)
    // ==========================================================

    smallButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                           @"background-color": A3ColorBackgroundWhite,
                                                           @"border-color": A3ColorActiveBorder,
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"border-radius": @"3px",
                                                           @"box-sizing": @"border-box"
                                                       }
                                    beforeDictionary:separatorCSS(@"15px", nil)
                                     afterDictionary:arrowCSS(A3ColorBorderBlue, "-7px", "23px")],

    smallBezelFocusedCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorBackgroundWhite,
                                                                 @"border-color": A3ColorBorderBlue,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"border-radius": @"3px",
                                                                 @"box-sizing": @"border-box",
                                                                 @"box-shadow": @"0px 0px 2px 0px rgb(59,127,202)",
                                                                 @"transition-duration": @"0.35s, 0.35s",
                                                                 @"transition-property": @"box-shadow, border"
                                                             }
                                         beforeDictionary:separatorCSS(@"15px", nil)
                                          afterDictionary:arrowCSS(A3ColorBorderBlue, "-7px", "23px")],

    smallNotKeyButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorBackgroundWhite,
                                                                 @"border-color": A3ColorActiveBorder,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"border-radius": @"3px",
                                                                 @"box-sizing": @"border-box"
                                                             }
                                          beforeDictionary:separatorCSS(@"15px", nil)
                                           afterDictionary:arrowCSS(A3ColorActiveBorder, "-7px", "23px")],

    smallDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorBackgroundInactive,
                                                               @"border-color": A3ColorInactiveBorder,
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"border-radius": @"3px",
                                                               @"box-sizing": @"border-box"
                                                               }
                                            beforeDictionary:nil
                                             afterDictionary:arrowCSS(A3ColorInactiveBorder, "-7px", "23px")],

    smallHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"border-color": A3ColorBorderDark,
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"1px",
                                                                  @"border-radius": @"3px",
                                                                  @"box-sizing": @"border-box",
                                                                  @"background-color": A3ColorBackgroundInactive
                                                                  }],

    // ==========================================================
    // MINI SIZE DEFINITIONS (Standard)
    // ==========================================================

    miniButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                           @"background-color": A3ColorBackgroundWhite,
                                                           @"border-color": A3ColorActiveBorder,
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"border-radius": @"3px",
                                                           @"box-sizing": @"border-box"
                                                       }
                                    beforeDictionary:separatorCSS(@"13px", nil)
                                     afterDictionary:arrowCSS(A3ColorBorderBlue, "-7px", "20px")],

    miniBezelFocusedCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorBackgroundWhite,
                                                                 @"border-color": A3ColorBorderBlue,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"border-radius": @"3px",
                                                                 @"box-sizing": @"border-box",
                                                                 @"box-shadow": @"0px 0px 2px 0px rgb(59,127,202)",
                                                                 @"transition-duration": @"0.35s, 0.35s",
                                                                 @"transition-property": @"box-shadow, border"
                                                             }
                                         beforeDictionary:separatorCSS(@"13px", nil)
                                          afterDictionary:arrowCSS(A3ColorBorderBlue, "-7px", "20px")],

    miniNotKeyButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorBackgroundWhite,
                                                                 @"border-color": A3ColorActiveBorder,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"border-radius": @"3px",
                                                                 @"box-sizing": @"border-box"
                                                             }
                                          beforeDictionary:separatorCSS(@"13px", nil)
                                           afterDictionary:arrowCSS(A3ColorActiveBorder, "-7px", "20px")],

    miniDisabledButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorBackgroundInactive,
                                                               @"border-color": A3ColorInactiveBorder,
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"border-radius": @"3px",
                                                               @"box-sizing": @"border-box"
                                                               }
                                            beforeDictionary:nil
                                             afterDictionary:arrowCSS(A3ColorInactiveBorder, "-7px", "20px")],

    miniHighlightedButtonCssColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"border-color": A3ColorBorderDark,
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"1px",
                                                                  @"border-radius": @"3px",
                                                                  @"box-sizing": @"border-box",
                                                                  @"background-color": A3ColorBackgroundHighlighted
                                                                  }],

    // ==========================================================
    // HUD DEFINITIONS (All Sizes)
    // ==========================================================

    hudBaseDict = @{
        @"background-color": @"rgba(0, 0, 0, 0.25)",
        @"border-color": @"rgba(255, 255, 255, 0.25)",
        @"border-style": @"solid",
        @"border-width": @"1px",
        @"border-radius": @"3px",
        @"box-sizing": @"border-box",
        @"box-shadow": @"0 1px 0 rgba(255,255,255,0.1) inset"
    },

    hudFocusedDict = @{
        @"background-color": @"rgba(0, 0, 0, 0.4)",
        @"border-color": @"rgba(255, 255, 255, 0.5)",
        @"border-style": @"solid",
        @"border-width": @"1px",
        @"border-radius": @"3px",
        @"box-sizing": @"border-box",
        @"box-shadow": @"0 0 3px rgba(255,255,255,0.3)"
    },

    hudDisabledDict = @{
        @"background-color": @"rgba(0, 0, 0, 0.1)",
        @"border-color": @"rgba(255, 255, 255, 0.1)",
        @"border-style": @"solid",
        @"border-width": @"1px",
        @"border-radius": @"3px",
        @"box-sizing": @"border-box"
    },

    hudSepColor = @"rgba(255,255,255,0.2)",
    hudArrowColor = @"#ffffff",
    hudArrowDisabledColor = @"rgba(255,255,255,0.3)",

    // Regular HUD Colors
    hudButtonCssColor = [CPColor colorWithCSSDictionary:hudBaseDict beforeDictionary:separatorCSS(@"17px", hudSepColor) afterDictionary:arrowCSS(hudArrowColor, "-8px", "25px")],
    hudBezelFocusedCssColor = [CPColor colorWithCSSDictionary:hudFocusedDict beforeDictionary:separatorCSS(@"17px", hudSepColor) afterDictionary:arrowCSS(hudArrowColor, "-8px", "25px")],
    hudDisabledButtonCssColor = [CPColor colorWithCSSDictionary:hudDisabledDict beforeDictionary:separatorCSS(@"17px", @"rgba(255,255,255,0.1)") afterDictionary:arrowCSS(hudArrowDisabledColor, "-8px", "25px")],

    // Small HUD Colors
    smallHudButtonCssColor = [CPColor colorWithCSSDictionary:hudBaseDict beforeDictionary:separatorCSS(@"15px", hudSepColor) afterDictionary:arrowCSS(hudArrowColor, "-7px", "23px")],
    smallHudBezelFocusedCssColor = [CPColor colorWithCSSDictionary:hudFocusedDict beforeDictionary:separatorCSS(@"15px", hudSepColor) afterDictionary:arrowCSS(hudArrowColor, "-7px", "23px")],
    smallHudDisabledButtonCssColor = [CPColor colorWithCSSDictionary:hudDisabledDict beforeDictionary:separatorCSS(@"15px", @"rgba(255,255,255,0.1)") afterDictionary:arrowCSS(hudArrowDisabledColor, "-7px", "23px")],

    // Mini HUD Colors
    miniHudButtonCssColor = [CPColor colorWithCSSDictionary:hudBaseDict beforeDictionary:separatorCSS(@"13px", hudSepColor) afterDictionary:arrowCSS(hudArrowColor, "-7px", "20px")],
    miniHudBezelFocusedCssColor = [CPColor colorWithCSSDictionary:hudFocusedDict beforeDictionary:separatorCSS(@"13px", hudSepColor) afterDictionary:arrowCSS(hudArrowColor, "-7px", "20px")],
    miniHudDisabledButtonCssColor = [CPColor colorWithCSSDictionary:hudDisabledDict beforeDictionary:separatorCSS(@"13px", @"rgba(255,255,255,0.1)") afterDictionary:arrowCSS(hudArrowDisabledColor, "-7px", "20px")],

    // ==========================================================
    // REGISTRATION
    // ==========================================================

    overrides =
    [
        [@"direct-nib2cib-adjustment",  YES],
        [@"text-color",                 A3CPColorActiveText],
        [@"text-color",                 A3CPColorInactiveText,                     [CPThemeStateDisabled]],

        [@"text-color",                 A3CPColorActiveText,                      [CPThemeStateTableDataView, CPThemeStateSelectedDataView, CPThemeStateFirstResponder, CPThemeStateKeyWindow]],
        [@"text-color",                 A3CPColorActiveText,                      [CPThemeStateTableDataView, CPThemeStateSelectedDataView, CPThemeStateFirstResponder, CPThemeStateKeyWindow, CPThemeStateEditing]],
        [@"text-color",                 A3CPColorActiveText,                       [CPThemeStateTableDataView, CPThemeStateSelectedDataView]],
        [@"text-color",                 A3CPColorActiveText,                       [CPThemeStateTableDataView, CPThemeStateSelectedDataView, CPThemeStateKeyWindow]],


        // --- HUD TEXT COLORS ---
        [@"text-color",                 [CPColor whiteColor],                      CPThemeStateHUD],
        [@"text-color",                 [CPColor colorWithWhite:1.0 alpha:0.5],    [CPThemeStateHUD, CPThemeStateDisabled]],

        // Ensure text is centered
        [@"vertical-alignment",         CPCenterVerticalTextAlignment],

        // ==========================================================
        // REGULAR SIZE
        // ==========================================================
        
        [@"bezel-color",                bezelFocusedCssColor,                      [CPThemeStateBezeled, CPComboBoxStateButtonBordered, CPThemeStateEditing]],
        [@"bezel-color",                buttonCssColor,                            [CPComboBoxStateButtonBordered, CPThemeStateKeyWindow]],
        [@"bezel-color",                notKeyButtonCssColor,                      [CPComboBoxStateButtonBordered]],
        [@"bezel-color",                highlightedButtonCssColor,                 [CPComboBoxStateButtonBordered, CPThemeStateHighlighted]],
        [@"bezel-color",                disabledButtonCssColor,                    [CPComboBoxStateButtonBordered, CPThemeStateDisabled]],
        [@"bezel-color",                disabledButtonCssColor,                    [CPComboBoxStateButtonBordered, CPThemeStateDisabled, CPThemeStateKeyWindow]],
        
        // HUD Regular
        [@"bezel-color",                hudBezelFocusedCssColor,                   [CPThemeStateHUD, CPThemeStateBezeled, CPComboBoxStateButtonBordered, CPThemeStateEditing]],
        [@"bezel-color",                hudButtonCssColor,                         [CPThemeStateHUD, CPComboBoxStateButtonBordered]],
        [@"bezel-color",                hudButtonCssColor,                         [CPThemeStateHUD, CPComboBoxStateButtonBordered, CPThemeStateKeyWindow]],
        [@"bezel-color",                hudDisabledButtonCssColor,                 [CPThemeStateHUD, CPComboBoxStateButtonBordered, CPThemeStateDisabled]],
        
        // Regular Layout
        [@"content-inset",              CGInsetMake(0.0, 19.0, 1.0, 9.0),          [CPComboBoxStateButtonBordered]],
        [@"content-inset",              CGInsetMake(0.0, 17.0, 0.0, 5.0),          [CPThemeStateBezeled, CPComboBoxStateButtonBordered]],
        [@"min-size",                   CGSizeMake(32.0, 22.0)],
        [@"max-size",                   CGSizeMake(-1.0, 22.0)],

        // ==========================================================
        // SMALL SIZE
        // ==========================================================

        [@"bezel-color",                smallBezelFocusedCssColor,                 [CPThemeStateControlSizeSmall, CPThemeStateBezeled, CPComboBoxStateButtonBordered, CPThemeStateEditing]],
        [@"bezel-color",                smallButtonCssColor,                       [CPThemeStateControlSizeSmall, CPComboBoxStateButtonBordered, CPThemeStateKeyWindow]],
        [@"bezel-color",                smallNotKeyButtonCssColor,                 [CPThemeStateControlSizeSmall, CPComboBoxStateButtonBordered]],
        [@"bezel-color",                smallHighlightedButtonCssColor,            [CPThemeStateControlSizeSmall, CPComboBoxStateButtonBordered, CPThemeStateHighlighted]],
        [@"bezel-color",                smallDisabledButtonCssColor,               [CPThemeStateControlSizeSmall, CPComboBoxStateButtonBordered, CPThemeStateDisabled]],
        [@"bezel-color",                smallDisabledButtonCssColor,               [CPThemeStateControlSizeSmall, CPComboBoxStateButtonBordered, CPThemeStateDisabled, CPThemeStateKeyWindow]],
        
        // HUD Small
        [@"bezel-color",                smallHudBezelFocusedCssColor,              [CPThemeStateHUD, CPThemeStateControlSizeSmall, CPThemeStateBezeled, CPComboBoxStateButtonBordered, CPThemeStateEditing]],
        [@"bezel-color",                smallHudButtonCssColor,                    [CPThemeStateHUD, CPThemeStateControlSizeSmall, CPComboBoxStateButtonBordered]],
        [@"bezel-color",                smallHudButtonCssColor,                    [CPThemeStateHUD, CPThemeStateControlSizeSmall, CPComboBoxStateButtonBordered, CPThemeStateKeyWindow]],
        [@"bezel-color",                smallHudDisabledButtonCssColor,            [CPThemeStateHUD, CPThemeStateControlSizeSmall, CPComboBoxStateButtonBordered, CPThemeStateDisabled]],

        // Small Layout
        [@"content-inset",              CGInsetMake(1.0, 17.0, 1.0, 8.0),          [CPThemeStateControlSizeSmall, CPComboBoxStateButtonBordered]],
        [@"content-inset",              CGInsetMake(2.0, 15.0, 0, 2),              [CPThemeStateControlSizeSmall, CPThemeStateBezeled, CPComboBoxStateButtonBordered]],
        [@"min-size",                   CGSizeMake(38.0, 19.0),                    CPThemeStateControlSizeSmall],
        [@"max-size",                   CGSizeMake(-1.0, 19.0),                    CPThemeStateControlSizeSmall],
        
        // ==========================================================
        // MINI SIZE
        // ==========================================================

        [@"bezel-color",                miniBezelFocusedCssColor,                  [CPThemeStateControlSizeMini, CPThemeStateBezeled, CPComboBoxStateButtonBordered, CPThemeStateEditing]],
        [@"bezel-color",                miniButtonCssColor,                        [CPThemeStateControlSizeMini, CPComboBoxStateButtonBordered, CPThemeStateKeyWindow]],
        [@"bezel-color",                miniNotKeyButtonCssColor,                  [CPThemeStateControlSizeMini, CPComboBoxStateButtonBordered]],
        [@"bezel-color",                miniHighlightedButtonCssColor,             [CPThemeStateControlSizeMini, CPComboBoxStateButtonBordered, CPThemeStateHighlighted]],
        [@"bezel-color",                miniDisabledButtonCssColor,                [CPThemeStateControlSizeMini, CPComboBoxStateButtonBordered, CPThemeStateDisabled]],
        [@"bezel-color",                miniDisabledButtonCssColor,                [CPThemeStateControlSizeMini, CPComboBoxStateButtonBordered, CPThemeStateDisabled, CPThemeStateKeyWindow]],
        
        // HUD Mini
        [@"bezel-color",                miniHudBezelFocusedCssColor,               [CPThemeStateHUD, CPThemeStateControlSizeMini, CPThemeStateBezeled, CPComboBoxStateButtonBordered, CPThemeStateEditing]],
        [@"bezel-color",                miniHudButtonCssColor,                     [CPThemeStateHUD, CPThemeStateControlSizeMini, CPComboBoxStateButtonBordered]],
        [@"bezel-color",                miniHudButtonCssColor,                     [CPThemeStateHUD, CPThemeStateControlSizeMini, CPComboBoxStateButtonBordered, CPThemeStateKeyWindow]],
        [@"bezel-color",                miniHudDisabledButtonCssColor,             [CPThemeStateHUD, CPThemeStateControlSizeMini, CPComboBoxStateButtonBordered, CPThemeStateDisabled]],

        // Mini Layout
        [@"content-inset",              CGInsetMake(1.0, 15.0, 1.0, 10.0),         [CPThemeStateControlSizeMini, CPComboBoxStateButtonBordered]],
        [@"content-inset",              CGInsetMake(2.0, 13.0, 0, 2),              [CPThemeStateControlSizeMini, CPThemeStateBezeled, CPComboBoxStateButtonBordered]],
        [@"min-size",                   CGSizeMake(32.0, 15.0),                    CPThemeStateControlSizeMini],
        [@"max-size",                   CGSizeMake(-1.0, 15.0),                    CPThemeStateControlSizeMini],

        // Popup Button hit-areas
        [@"popup-button-size",  CGSizeMake(21.0, 22.0),                            [CPThemeStateBezeled, CPComboBoxStateButtonBordered]],
        [@"popup-button-size",  CGSizeMake(17.0, 22.0),                            CPThemeStateBezeled],
        
        [@"popup-button-size",  CGSizeMake(19.0, 19.0),                            [CPThemeStateControlSizeSmall, CPThemeStateBezeled, CPComboBoxStateButtonBordered]],
        [@"popup-button-size",  CGSizeMake(15.0, 19.0),                            [CPThemeStateControlSizeSmall, CPThemeStateBezeled]],
        
        [@"popup-button-size",  CGSizeMake(17.0, 16.0),                            [CPThemeStateControlSizeMini, CPThemeStateBezeled, CPComboBoxStateButtonBordered]],
        [@"popup-button-size",  CGSizeMake(13.0, 16.0),                            [CPThemeStateControlSizeMini, CPThemeStateBezeled]]
     ];

    [self registerThemeValues:overrides forView:combo inherit:themedTextFieldValues];

    return combo;
}

+ (CPRadioButton)themedRadioButton
{
    var button = [CPRadio radioWithTitle:@"Radio button"],

    // We use CSS borders for radio buttons, which are natively supported by the browser and scalable.
    // The "dot" is handled via inner-shadow or pseudo-element.

    // --- Regular Size (16x16) ---
    // Normal: Border 1px
    regularImageNormal = [CPImage imageWithCSSDictionary:@{
                                                           @"border-color": A3ColorActiveBorder,
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"border-radius": @"50%",
                                                           @"box-sizing": @"border-box",
                                                           @"background-color": A3ColorBackgroundWhite,
                                                           @"transition-duration": @"0.35s",
                                                           @"transition-property": @"all"
                                                           }
                                                    size:CGSizeMake(16,16)],

    // Selected: Border 2px, Dot 6px, Offset 3px -> (16 - 4 - 6) / 2 = 3
    regularImageSelected = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": @"A3ColorBorderBlue",
                                                             @"border-style": @"solid",
                                                             @"border-width": @"2px",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             @"background-color": @"A3ColorBorderBlue",
                                                             @"width": @"6px",
                                                             @"height": @"6px",
                                                             @"border-radius": @"50%",
                                                             @"content": @"''",
                                                             @"left": @"3px",
                                                             @"top": @"3px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(16,16)],

    regularImageDisabled = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundInactive
                                                             }
                                                   size:CGSizeMake(16,16)],

    // Highlighted: Border 1px, Dot 6px, Offset 4px -> (16 - 2 - 6) / 2 = 4
    regularImageHighlighted = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorBorderBlueHighlighted,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             @"background-color": A3ColorBorderBlueHighlighted,
                                                             @"width": @"6px",
                                                             @"height": @"6px",
                                                             @"border-radius": @"50%",
                                                             @"content": @"''",
                                                             @"left": @"4px",
                                                             @"top": @"4px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(16,16)],

    regularImageSelectedNotKey = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveDarkBorder, // Gray Border
                                                             @"border-style": @"solid",
                                                             @"border-width": @"2px",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             @"background-color": A3ColorInactiveDarkBorder, // Gray Dot
                                                             @"width": @"6px",
                                                             @"height": @"6px",
                                                             @"border-radius": @"50%",
                                                             @"content": @"''",
                                                             @"left": @"3px",
                                                             @"top": @"3px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(16,16)],

    // --- Small Size (14x14) ---
    smallImageNormal = [CPImage imageWithCSSDictionary:@{
                                                           @"border-color": A3ColorActiveBorder,
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"border-radius": @"50%",
                                                           @"box-sizing": @"border-box",
                                                           @"background-color": A3ColorBackgroundWhite,
                                                           @"transition-duration": @"0.35s",
                                                           @"transition-property": @"all"
                                                           }
                                                    size:CGSizeMake(14,14)],

    // Selected: Border 2px, Dot 5px, Offset 2.5px -> (14 - 4 - 5) / 2 = 2.5
    smallImageSelected = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": @"A3ColorBorderBlue",
                                                             @"border-style": @"solid",
                                                             @"border-width": @"2px",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             @"background-color": @"A3ColorBorderBlue",
                                                             @"width": @"5px",
                                                             @"height": @"5px",
                                                             @"border-radius": @"50%",
                                                             @"content": @"''",
                                                             @"left": @"2.5px",
                                                             @"top": @"2.5px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(14,14)],

    smallImageDisabled = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundInactive
                                                             }
                                                    size:CGSizeMake(14,14)],

    // Highlighted: Border 1px, Dot 5px, Offset 3.5px -> (14 - 2 - 5) / 2 = 3.5
    smallImageHighlighted = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorBorderBlueHighlighted,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             @"background-color": A3ColorBorderBlueHighlighted,
                                                             @"width": @"5px",
                                                             @"height": @"5px",
                                                             @"border-radius": @"50%",
                                                             @"content": @"''",
                                                             @"left": @"3.5px",
                                                             @"top": @"3.5px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(14,14)],

    smallImageSelectedNotKey = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveDarkBorder, // Gray Border
                                                             @"border-style": @"solid",
                                                             @"border-width": @"2px",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             @"background-color": A3ColorInactiveDarkBorder, // Gray Dot
                                                             @"width": @"5px",
                                                             @"height": @"5px",
                                                             @"border-radius": @"50%",
                                                             @"content": @"''",
                                                             @"left": @"2.5px",
                                                             @"top": @"2.5px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(14,14)],

    // --- Mini Size (12x12) ---
    miniImageNormal = [CPImage imageWithCSSDictionary:@{
                                                           @"border-color": A3ColorActiveBorder,
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"border-radius": @"50%",
                                                           @"box-sizing": @"border-box",
                                                           @"background-color": A3ColorBackgroundWhite,
                                                           @"transition-duration": @"0.35s",
                                                           @"transition-property": @"all"
                                                           }
                                                    size:CGSizeMake(12,12)],

    // Selected: Border 2px, Dot 4px, Offset 2px -> (12 - 4 - 4) / 2 = 2
    miniImageSelected = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": @"A3ColorBorderBlue",
                                                             @"border-style": @"solid",
                                                             @"border-width": @"2px",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             @"background-color": @"A3ColorBorderBlue",
                                                             @"width": @"4px",
                                                             @"height": @"4px",
                                                             @"border-radius": @"50%",
                                                             @"content": @"''",
                                                             @"left": @"2px",
                                                             @"top": @"2px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(12,12)],

    miniImageDisabled = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundInactive
                                                             }
                                                    size:CGSizeMake(12,12)],

    // Highlighted: Border 1px, Dot 4px, Offset 3px -> (12 - 2 - 4) / 2 = 3
    miniImageHighlighted = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorBorderBlueHighlighted,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             @"background-color": A3ColorBorderBlueHighlighted,
                                                             @"width": @"4px",
                                                             @"height": @"4px",
                                                             @"border-radius": @"50%",
                                                             @"content": @"''",
                                                             @"left": @"3px",
                                                             @"top": @"3px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(12,12)],

    miniImageSelectedNotKey = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveDarkBorder, // Gray Border
                                                             @"border-style": @"solid",
                                                             @"border-width": @"2px",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             @"background-color": A3ColorInactiveDarkBorder, // Gray Dot
                                                             @"width": @"4px",
                                                             @"height": @"4px",
                                                             @"border-radius": @"50%",
                                                             @"content": @"''",
                                                             @"left": @"2px",
                                                             @"top": @"2px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(12,12)],

    // --- HUD IMAGES ---
    hudImageNormal = [CPImage imageWithCSSDictionary:@{
                                                            @"border-color": @"rgba(255,255,255,0.5)",
                                                            @"border-style": @"solid",
                                                            @"border-width": @"1px",
                                                            @"border-radius": @"50%",
                                                            @"box-sizing": @"border-box",
                                                            @"background-color": @"rgba(0,0,0,0.3)",
                                                            @"transition-duration": @"0.2s",
                                                            @"transition-property": @"border-color, background-color"
                                                        } size:CGSizeMake(16,16)],

    hudImageSelected = [CPImage imageWithCSSDictionary:@{
                                                            @"border-color": @"#ffffff",
                                                            @"border-style": @"solid",
                                                            @"border-width": @"1px",
                                                            @"border-radius": @"50%",
                                                            @"box-sizing": @"border-box",
                                                            @"background-color": @"rgba(0,0,0,0.3)"
                                                        }
                                      beforeDictionary:nil
                                       afterDictionary:@{
                                                            @"background-color": @"#ffffff",
                                                            @"width": @"6px",
                                                            @"height": @"6px",
                                                            @"border-radius": @"50%",
                                                            @"content": @"''",
                                                            @"left": @"4px", // Adjusted center for 1px border
                                                            @"top": @"4px",
                                                            @"position": @"absolute",
                                                            @"z-index": @"300"
                                                        } size:CGSizeMake(16,16)],

    hudImageDisabled = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": @"rgba(255,255,255,0.3)",
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"50%",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": @"rgba(0,0,0,0.1)"
                                                         } size:CGSizeMake(16,16)],

    // HUD Selected & Disabled: Must include the dot but dimmed
    hudImageSelectedDisabled = [CPImage imageWithCSSDictionary:@{
                                                            @"border-color": @"rgba(255,255,255,0.3)",
                                                            @"border-style": @"solid",
                                                            @"border-width": @"1px",
                                                            @"border-radius": @"50%",
                                                            @"box-sizing": @"border-box",
                                                            @"background-color": @"rgba(0,0,0,0.1)"
                                                        }
                                      beforeDictionary:nil
                                       afterDictionary:@{
                                                            @"background-color": @"rgba(255,255,255,0.5)", // Dimmed White Dot
                                                            @"width": @"6px",
                                                            @"height": @"6px",
                                                            @"border-radius": @"50%",
                                                            @"content": @"''",
                                                            @"left": @"4px", // Matches hudImageSelected offset
                                                            @"top": @"4px",
                                                            @"position": @"absolute",
                                                            @"z-index": @"300"
                                                        } size:CGSizeMake(16,16)],

    // Global
    themedRadioButtonValues =
    [
     // --- Regular Size ---
     [@"alignment",                  CPLeftTextAlignment,                                CPThemeStateNormal],
     [@"content-inset",              CGInsetMake(0.0, 0.0, 0.0, 0.0),                    CPThemeStateNormal],
     [@"direct-nib2cib-adjustment",  YES],
     [@"text-color",                 A3CPColorActiveText,                                CPThemeStateNormal],
     [@"text-color",                 A3CPColorInactiveText,                              CPThemeStateDisabled],
     [@"image",                      regularImageNormal,                                 CPThemeStateNormal],
     [@"image",                      regularImageSelectedNotKey,                         CPThemeStateSelected],
     [@"image",                      regularImageSelected,                               [CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"image",                      regularImageDisabled,                               CPThemeStateDisabled],
     [@"image",                      regularImageHighlighted,                            CPThemeStateHighlighted],
     [@"image",                      regularImageSelected,                               [CPThemeStateSelected, CPThemeStateDisabled, CPThemeStateKeyWindow]], // Override disabled when selected
     [@"image",                      regularImageSelectedNotKey,                         [CPThemeStateSelected, CPThemeStateDisabled]], // Override disabled when selected
     [@"image-offset",               3],
     [@"min-size",                   CGSizeMake(16, 16)],
     [@"max-size",                   CGSizeMake(-1.0, -1.0)],
     [@"nib2cib-adjustment-frame",   CGRectMake(1.0, -1.0, -1.0, -2.0)],

     // --- Small Size ---
     [@"alignment",                  CPLeftTextAlignment,                                CPThemeStateControlSizeSmall],
     [@"content-inset",              CGInsetMake(0.0, 0.0, 0.0, 0.0),                    CPThemeStateControlSizeSmall],
     [@"text-color",                 A3CPColorActiveText,                                [CPThemeStateControlSizeSmall, CPThemeStateNormal]],
     [@"text-color",                 A3CPColorInactiveText,                              [CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
     [@"image",                      smallImageNormal,                                   [CPThemeStateControlSizeSmall, CPThemeStateNormal]],
     [@"image",                      smallImageSelectedNotKey,                           [CPThemeStateControlSizeSmall, CPThemeStateSelected]],
     [@"image",                      smallImageSelected,                                 [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"image",                      smallImageDisabled,                                 [CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
     [@"image",                      smallImageHighlighted,                              [CPThemeStateControlSizeSmall, CPThemeStateHighlighted]],
     [@"image",                      smallImageSelected,                                 [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateDisabled, CPThemeStateKeyWindow]], // Override disabled when selected
     [@"image",                      smallImageSelectedNotKey,                           [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateDisabled]], // Override disabled when selected
     [@"image-offset",               3,                                                  CPThemeStateControlSizeSmall],
     [@"min-size",                   CGSizeMake(14, 14)],
     [@"max-size",                   CGSizeMake(-1.0, -1.0)],
     [@"nib2cib-adjustment-frame",   CGRectMake(1.0, -1.0, -1.0, -2.0),                  CPThemeStateControlSizeSmall],

     // --- Mini Size ---
     [@"alignment",                  CPLeftTextAlignment,                                CPThemeStateControlSizeMini],
     [@"content-inset",              CGInsetMake(0.0, 0.0, 0.0, 0.0),                    CPThemeStateControlSizeMini],
     [@"text-color",                 A3CPColorActiveText,                                [CPThemeStateControlSizeMini, CPThemeStateNormal]],
     [@"text-color",                 A3CPColorInactiveText,                              [CPThemeStateControlSizeMini, CPThemeStateDisabled]],
     [@"image",                      miniImageNormal,                                    [CPThemeStateControlSizeMini, CPThemeStateNormal]],
     [@"image",                      miniImageSelectedNotKey,                            [CPThemeStateControlSizeMini, CPThemeStateSelected]],
     [@"image",                      miniImageSelected,                                  [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"image",                      miniImageDisabled,                                  [CPThemeStateControlSizeMini, CPThemeStateDisabled]],
     [@"image",                      miniImageHighlighted,                               [CPThemeStateControlSizeMini, CPThemeStateHighlighted]],
     [@"image",                      miniImageSelected,                                  [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateDisabled, CPThemeStateKeyWindow]], // Override disabled when selected
     [@"image",                      miniImageSelectedNotKey,                            [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateDisabled]], // Override disabled when selected
     [@"image-offset",               3,                                                  CPThemeStateControlSizeMini],
     [@"min-size",                   CGSizeMake(12, 12)],
     [@"max-size",                   CGSizeMake(-1.0, -1.0)],
     [@"nib2cib-adjustment-frame",   CGRectMake(1.0, -1.0, -1.0, -2.0),                  CPThemeStateControlSizeMini],

     // --- HUD MAPPINGS ---
     [@"text-color",                 [CPColor whiteColor],                               CPThemeStateHUD],
     [@"text-color",                 [CPColor colorWithWhite:1 alpha:0.4],               [CPThemeStateHUD, CPThemeStateDisabled]],
     
     [@"image",                      hudImageNormal,                                     CPThemeStateHUD],
     
     // HUD Selected: We MUST define specific rules for ControlSizes and KeyWindow combinations
     // to ensure the HUD theme wins over the Standard theme rules which have equal or higher specificity.
     
     [@"image",                      hudImageSelected,                                   [CPThemeStateHUD, CPThemeStateSelected]],
     [@"image",                      hudImageSelected,                                   [CPThemeStateHUD, CPThemeStateSelected, CPThemeStateKeyWindow]], // Overrides Standard [Selected, Key]
     [@"image",                      hudImageSelected,                                   [CPThemeStateHUD, CPThemeStateControlSizeSmall, CPThemeStateSelected]], // Overrides Standard [Small, Selected]
     [@"image",                      hudImageSelected,                                   [CPThemeStateHUD, CPThemeStateControlSizeMini, CPThemeStateSelected]], // Overrides Standard [Mini, Selected]
     
     [@"image",                      hudImageDisabled,                                   [CPThemeStateHUD, CPThemeStateDisabled]],
     
     // FIX: Use the specific "Selected+Disabled" image for HUD, beating the standard rules
     [@"image",                      hudImageSelectedDisabled,                           [CPThemeStateHUD, CPThemeStateSelected, CPThemeStateDisabled]], 
     [@"image",                      hudImageSelectedDisabled,                           [CPThemeStateHUD, CPThemeStateSelected, CPThemeStateDisabled, CPThemeStateKeyWindow]], 
     
     // Adjust layout slightly for HUD
     [@"image-offset",               4,                                                  CPThemeStateHUD]
     ];

    [self registerThemeValues:themedRadioButtonValues forView:button];

    return button;
}

+ (CPCheckBox)themedCheckBoxButton
{
    var button = [CPCheckBox checkBoxWithTitle:@"Checkbox"],

    // --- Regular Size (16x16, Border 1px, Checkmark 10px, Offset 2px) ---
    regularImageNormal = [CPImage imageWithCSSDictionary:@{
                                                           @"border-color": A3ColorActiveBorder,
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"border-radius": @"2px",
                                                           @"box-sizing": @"border-box",
                                                           @"background-color": A3ColorBackgroundWhite,
                                                           @"transition-duration": @"0.35s",
                                                           @"transition-property": @"all"
                                                           }
                                                    size:CGSizeMake(16,16)],

    regularImageSelected = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorActiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             "-webkit-mask-image": svgCheckmark,
                                                             "mask-image": svgCheckmark,
                                                             "-webkit-mask-size": "contain",
                                                             "mask-size": "contain",
                                                             "-webkit-mask-repeat": "no-repeat",
                                                             "mask-repeat": "no-repeat",
                                                             "-webkit-mask-position": "center",
                                                             "mask-position": "center",
                                                             @"background-color": @"A3ColorBorderBlue",
                                                             @"width": @"10px",
                                                             @"height": @"10px",
                                                             @"content": @"''",
                                                             @"left": @"2px",
                                                             @"top": @"2px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(16,16)],

    regularImageDisabled = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundInactive
                                                             }
                                                    size:CGSizeMake(16,16)],

    regularImageSelectedDisabled = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundInactive
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             "-webkit-mask-image": svgCheckmark,
                                                             "mask-image": svgCheckmark,
                                                             "-webkit-mask-size": "contain",
                                                             "mask-size": "contain",
                                                             "-webkit-mask-repeat": "no-repeat",
                                                             "mask-repeat": "no-repeat",
                                                             "-webkit-mask-position": "center",
                                                             "mask-position": "center",
                                                             @"background-color": A3ColorInactiveDarkBorder, // Gray Checkmark
                                                             @"width": @"10px",
                                                             @"height": @"10px",
                                                             @"content": @"''",
                                                             @"left": @"2px",
                                                             @"top": @"2px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(16,16)],

    regularImageHighlighted = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorBorderBlueHighlighted,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite
                                                             }
                                                    size:CGSizeMake(16,16)],

    regularImageSelectedNotKey = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveDarkBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             "-webkit-mask-image": svgCheckmark,
                                                             "mask-image": svgCheckmark,
                                                             "-webkit-mask-size": "contain",
                                                             "mask-size": "contain",
                                                             "-webkit-mask-repeat": "no-repeat",
                                                             "mask-repeat": "no-repeat",
                                                             "-webkit-mask-position": "center",
                                                             "mask-position": "center",
                                                             @"background-color": A3ColorInactiveDarkBorder, // Gray Checkmark
                                                             @"width": @"10px",
                                                             @"height": @"10px",
                                                             @"content": @"''",
                                                             @"left": @"2px",
                                                             @"top": @"2px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(16,16)],

    // --- Small Size (14x14, Border 1px, Checkmark 8px, Offset 2px) ---
    smallImageNormal = [CPImage imageWithCSSDictionary:@{
                                                           @"border-color": A3ColorActiveBorder,
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"border-radius": @"2px",
                                                           @"box-sizing": @"border-box",
                                                           @"background-color": A3ColorBackgroundWhite,
                                                           @"transition-duration": @"0.35s",
                                                           @"transition-property": @"all"
                                                           }
                                                    size:CGSizeMake(14,14)],

    smallImageSelected = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorActiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             "-webkit-mask-image": svgCheckmark,
                                                             "mask-image": svgCheckmark,
                                                             "-webkit-mask-size": "contain",
                                                             "mask-size": "contain",
                                                             "-webkit-mask-repeat": "no-repeat",
                                                             "mask-repeat": "no-repeat",
                                                             "-webkit-mask-position": "center",
                                                             "mask-position": "center",
                                                             @"background-color": @"A3ColorBorderBlue",
                                                             @"width": @"8px",
                                                             @"height": @"8px",
                                                             @"content": @"''",
                                                             @"left": @"2px",
                                                             @"top": @"2px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(14,14)],

    smallImageDisabled = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundInactive
                                                             }
                                                    size:CGSizeMake(14,14)],

    smallImageSelectedDisabled = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundInactive
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             "-webkit-mask-image": svgCheckmark,
                                                             "mask-image": svgCheckmark,
                                                             "-webkit-mask-size": "contain",
                                                             "mask-size": "contain",
                                                             "-webkit-mask-repeat": "no-repeat",
                                                             "mask-repeat": "no-repeat",
                                                             "-webkit-mask-position": "center",
                                                             "mask-position": "center",
                                                             @"background-color": A3ColorInactiveDarkBorder,
                                                             @"width": @"8px",
                                                             @"height": @"8px",
                                                             @"content": @"''",
                                                             @"left": @"2px",
                                                             @"top": @"2px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(14,14)],

    smallImageHighlighted = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorBorderBlueHighlighted,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite
                                                             }
                                                    size:CGSizeMake(14,14)],

    smallImageSelectedNotKey = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveDarkBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             "-webkit-mask-image": svgCheckmark,
                                                             "mask-image": svgCheckmark,
                                                             "-webkit-mask-size": "contain",
                                                             "mask-size": "contain",
                                                             "-webkit-mask-repeat": "no-repeat",
                                                             "mask-repeat": "no-repeat",
                                                             "-webkit-mask-position": "center",
                                                             "mask-position": "center",
                                                             @"background-color": A3ColorInactiveDarkBorder,
                                                             @"width": @"8px",
                                                             @"height": @"8px",
                                                             @"content": @"''",
                                                             @"left": @"2px",
                                                             @"top": @"2px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(14,14)],

    // --- Mini Size (12x12, Border 1px, Checkmark 7px, Offset 1.5px) ---
    miniImageNormal = [CPImage imageWithCSSDictionary:@{
                                                           @"border-color": A3ColorActiveBorder,
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"border-radius": @"2px",
                                                           @"box-sizing": @"border-box",
                                                           @"background-color": A3ColorBackgroundWhite,
                                                           @"transition-duration": @"0.35s",
                                                           @"transition-property": @"all"
                                                           }
                                                    size:CGSizeMake(12,12)],

    miniImageSelected = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorActiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             "-webkit-mask-image": svgCheckmark,
                                                             "mask-image": svgCheckmark,
                                                             "-webkit-mask-size": "contain",
                                                             "mask-size": "contain",
                                                             "-webkit-mask-repeat": "no-repeat",
                                                             "mask-repeat": "no-repeat",
                                                             "-webkit-mask-position": "center",
                                                             "mask-position": "center",
                                                             @"background-color": @"A3ColorBorderBlue",
                                                             @"width": @"7px",
                                                             @"height": @"7px",
                                                             @"content": @"''",
                                                             @"left": @"1.5px",
                                                             @"top": @"1.5px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(12,12)],

    miniImageDisabled = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundInactive
                                                             }
                                                    size:CGSizeMake(12,12)],

    miniImageSelectedDisabled = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundInactive
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             "-webkit-mask-image": svgCheckmark,
                                                             "mask-image": svgCheckmark,
                                                             "-webkit-mask-size": "contain",
                                                             "mask-size": "contain",
                                                             "-webkit-mask-repeat": "no-repeat",
                                                             "mask-repeat": "no-repeat",
                                                             "-webkit-mask-position": "center",
                                                             "mask-position": "center",
                                                             @"background-color": A3ColorInactiveDarkBorder,
                                                             @"width": @"7px",
                                                             @"height": @"7px",
                                                             @"content": @"''",
                                                             @"left": @"1.5px",
                                                             @"top": @"1.5px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(12,12)],

    miniImageHighlighted = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorBorderBlueHighlighted,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite
                                                             }
                                                    size:CGSizeMake(12,12)],

    miniImageSelectedNotKey = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveDarkBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             "-webkit-mask-image": svgCheckmark,
                                                             "mask-image": svgCheckmark,
                                                             "-webkit-mask-size": "contain",
                                                             "mask-size": "contain",
                                                             "-webkit-mask-repeat": "no-repeat",
                                                             "mask-repeat": "no-repeat",
                                                             "-webkit-mask-position": "center",
                                                             "mask-position": "center",
                                                             @"background-color": A3ColorInactiveDarkBorder,
                                                             @"width": @"7px",
                                                             @"height": @"7px",
                                                             @"content": @"''",
                                                             @"left": @"1.5px",
                                                             @"top": @"1.5px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(12,12)],

    // --- HUD IMAGES (14x14, Border 1px, Checkmark 10px, Offset 1px) ---
    hudImageNormal = [CPImage imageWithCSSDictionary:@{
                                                            @"border-color": @"rgba(255,255,255,0.5)",
                                                            @"border-style": @"solid",
                                                            @"border-width": @"1px",
                                                            @"border-radius": @"2px",
                                                            @"box-sizing": @"border-box",
                                                            @"background-color": @"rgba(0,0,0,0.3)",
                                                            @"transition-duration": @"0.2s",
                                                            @"transition-property": @"border-color, background-color"
                                                        } size:CGSizeMake(14,14)],

    hudImageSelected = [CPImage imageWithCSSDictionary:@{
                                                            @"border-color": @"rgba(255,255,255,0.8)",
                                                            @"border-style": @"solid",
                                                            @"border-width": @"1px",
                                                            @"border-radius": @"2px",
                                                            @"box-sizing": @"border-box",
                                                            @"background-color": @"rgba(0,0,0,0.3)"
                                                        } beforeDictionary:nil afterDictionary:@{
                                                             "-webkit-mask-image": svgCheckmark,
                                                             "mask-image": svgCheckmark,
                                                             "-webkit-mask-size": "contain",
                                                             "mask-size": "contain",
                                                             "-webkit-mask-repeat": "no-repeat",
                                                             "mask-repeat": "no-repeat",
                                                             "-webkit-mask-position": "center",
                                                             "mask-position": "center",
                                                             @"background-color": @"#ffffff", // White checkmark
                                                             @"width": @"10px",
                                                             @"height": @"10px",
                                                             @"content": @"''",
                                                             @"left": @"1px",
                                                             @"top": @"1px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                        } size:CGSizeMake(14,14)],

    hudImageDisabled = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": @"rgba(255,255,255,0.3)",
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": @"rgba(0,0,0,0.1)"
                                                         } size:CGSizeMake(14,14)],

    hudImageSelectedDisabled = [CPImage imageWithCSSDictionary:@{
                                                            @"border-color": @"rgba(255,255,255,0.3)",
                                                            @"border-style": @"solid",
                                                            @"border-width": @"1px",
                                                            @"border-radius": @"2px",
                                                            @"box-sizing": @"border-box",
                                                            @"background-color": @"rgba(0,0,0,0.1)"
                                                        } beforeDictionary:nil afterDictionary:@{
                                                             "-webkit-mask-image": svgCheckmark,
                                                             "mask-image": svgCheckmark,
                                                             "-webkit-mask-size": "contain",
                                                             "mask-size": "contain",
                                                             "-webkit-mask-repeat": "no-repeat",
                                                             "mask-repeat": "no-repeat",
                                                             "-webkit-mask-position": "center",
                                                             "mask-position": "center",
                                                             @"background-color": @"rgba(255,255,255,0.5)", // Dimmed White checkmark
                                                             @"width": @"10px",
                                                             @"height": @"10px",
                                                             @"content": @"''",
                                                             @"left": @"1px",
                                                             @"top": @"1px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                        } size:CGSizeMake(14,14)],


    // Global
    themedCheckBoxValues =
    [
     // --- Regular Size ---
     [@"alignment",                 CPLeftTextAlignment,                                CPThemeStateNormal],
     [@"content-inset",             CGInsetMakeZero(),                                  CPThemeStateNormal],
     [@"text-color",                A3CPColorActiveText,                                CPThemeStateNormal],
     [@"text-color",                A3CPColorInactiveText,                              CPThemeStateDisabled],
     [@"direct-nib2cib-adjustment", YES],

     [@"image",                     regularImageNormal,                                 CPThemeStateNormal],
     [@"image",                     regularImageSelectedNotKey,                         CPThemeStateSelected],
     [@"image",                     regularImageSelected,                               [CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"image",                     regularImageDisabled,                               CPThemeStateDisabled],
     [@"image",                     regularImageHighlighted,                            CPThemeStateHighlighted],
     [@"image",                     regularImageSelectedDisabled,                       [CPThemeStateSelected, CPThemeStateDisabled]], // Selected but Disabled
     [@"image",                     regularImageSelectedDisabled,                       [CPThemeStateSelected, CPThemeStateDisabled, CPThemeStateKeyWindow]], 
     
     [@"min-size",                  CGSizeMake(16.0, 16.0)],
     [@"max-size",                  CGSizeMake(-1.0, -1.0)],
     [@"nib2cib-adjustment-frame",  CGRectMake(1.0, -1.0, -2.0, -2.0)],
     [@"image-offset",              3],

     // --- Small Size ---
     [@"alignment",                 CPLeftTextAlignment,                                CPThemeStateControlSizeSmall],
     [@"content-inset",             CGInsetMakeZero(),                                  CPThemeStateControlSizeSmall],
     [@"text-color",                A3CPColorActiveText,                                [CPThemeStateControlSizeSmall, CPThemeStateNormal]],
     [@"text-color",                A3CPColorInactiveText,                              [CPThemeStateControlSizeSmall, CPThemeStateDisabled]],

     [@"image",                     smallImageNormal,                                   [CPThemeStateControlSizeSmall, CPThemeStateNormal]],
     [@"image",                     smallImageSelectedNotKey,                           [CPThemeStateControlSizeSmall, CPThemeStateSelected]],
     [@"image",                     smallImageSelected,                                 [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"image",                     smallImageDisabled,                                 [CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
     [@"image",                     smallImageHighlighted,                              [CPThemeStateControlSizeSmall, CPThemeStateHighlighted]],
     [@"image",                     smallImageSelectedDisabled,                         [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateDisabled]],
     [@"image",                     smallImageSelectedDisabled,                         [CPThemeStateControlSizeSmall, CPThemeStateSelected, CPThemeStateDisabled, CPThemeStateKeyWindow]],

     [@"min-size",                  CGSizeMake(14.0, 14.0)],
     [@"max-size",                  CGSizeMake(-1.0, -1.0)],
     [@"nib2cib-adjustment-frame",  CGRectMake(1.0, -1.0, -2.0, -2.0),                  CPThemeStateControlSizeSmall],
     [@"image-offset",              3,                                                  CPThemeStateControlSizeSmall],

     // --- Mini Size ---
     [@"alignment",                 CPLeftTextAlignment,                                CPThemeStateControlSizeMini],
     [@"content-inset",             CGInsetMakeZero(),                                  CPThemeStateControlSizeMini],
     [@"text-color",                A3CPColorActiveText,                                [CPThemeStateControlSizeMini, CPThemeStateNormal]],
     [@"text-color",                A3CPColorInactiveText,                              [CPThemeStateControlSizeMini, CPThemeStateDisabled]],

     [@"image",                     miniImageNormal,                                    [CPThemeStateControlSizeMini, CPThemeStateNormal]],
     [@"image",                     miniImageSelectedNotKey,                            [CPThemeStateControlSizeMini, CPThemeStateSelected]],
     [@"image",                     miniImageSelected,                                  [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"image",                     miniImageDisabled,                                  [CPThemeStateControlSizeMini, CPThemeStateDisabled]],
     [@"image",                     miniImageHighlighted,                               [CPThemeStateControlSizeMini, CPThemeStateHighlighted]],
     [@"image",                     miniImageSelectedDisabled,                          [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateDisabled]],
     [@"image",                     miniImageSelectedDisabled,                          [CPThemeStateControlSizeMini, CPThemeStateSelected, CPThemeStateDisabled, CPThemeStateKeyWindow]],

     [@"min-size",                  CGSizeMake(12.0, 12.0)],
     [@"max-size",                  CGSizeMake(-1.0, -1.0)],
     [@"nib2cib-adjustment-frame",  CGRectMake(1.0, -1.0, -2.0, -2.0),                  CPThemeStateControlSizeMini],
     [@"image-offset",              3,                                                  CPThemeStateControlSizeMini],

     // --- HUD MAPPINGS ---
     [@"text-color",    [CPColor whiteColor],                   CPThemeStateHUD],
     [@"text-color",    [CPColor colorWithWhite:1 alpha:0.4],   [CPThemeStateHUD, CPThemeStateDisabled]],
     
     [@"image",         hudImageNormal,                         CPThemeStateHUD],
     [@"image",         hudImageSelected,                       [CPThemeStateHUD, CPThemeStateSelected]],
     [@"image",         hudImageDisabled,                       [CPThemeStateHUD, CPThemeStateDisabled]],
     [@"image",         hudImageSelectedDisabled,               [CPThemeStateHUD, CPThemeStateSelected, CPThemeStateDisabled]],
     
     // Adjust layout slightly for HUD
     [@"image-offset",  4,                                      CPThemeStateHUD]
    ];
    [button setThemeState:CPThemeStateNormal];

    [self registerThemeValues:themedCheckBoxValues forView:button];

    return button;
}

+ (CPCheckBox)themedMixedCheckBoxButton
{
    var button = [self themedCheckBoxButton];

    [button setAllowsMixedState:YES];
    [button setState:CPMixedState];

    // --- Regular Size (16x16) ---
    var regularImageMixed = [CPImage imageWithCSSDictionary:@{
                                                       @"border-color": A3ColorActiveBorder,
                                                       @"border-style": @"solid",
                                                       @"border-width": @"1px",
                                                       @"border-radius": @"2px",
                                                       @"box-sizing": @"border-box",
                                                       @"background-color": A3ColorBackgroundWhite
                                                       }
                                    beforeDictionary:nil
                                     afterDictionary:@{
                                                       "-webkit-mask-image": svgDash,
                                                       "mask-image": svgDash,
                                                       "-webkit-mask-size": "contain",
                                                       "mask-size": "contain",
                                                       "-webkit-mask-repeat": "no-repeat",
                                                       "mask-repeat": "no-repeat",
                                                       "-webkit-mask-position": "center",
                                                       "mask-position": "center",
                                                       @"background-color": @"A3ColorBorderBlue",
                                                       @"width": @"10px",
                                                       @"height": @"10px",
                                                       @"content": @"''",
                                                       @"left": @"2px",
                                                       @"top": @"2px",
                                                       @"position": @"absolute",
                                                       @"z-index": @"300"
                                                       }
                                                size:CGSizeMake(16,16)],

    regularImageMixedNotKey = [CPImage imageWithCSSDictionary:@{
                                                       @"border-color": A3ColorInactiveDarkBorder,
                                                       @"border-style": @"solid",
                                                       @"border-width": @"1px",
                                                       @"border-radius": @"2px",
                                                       @"box-sizing": @"border-box",
                                                       @"background-color": A3ColorBackgroundWhite
                                                       }
                                    beforeDictionary:nil
                                     afterDictionary:@{
                                                       "-webkit-mask-image": svgDash,
                                                       "mask-image": svgDash,
                                                       "-webkit-mask-size": "contain",
                                                       "mask-size": "contain",
                                                       "-webkit-mask-repeat": "no-repeat",
                                                       "mask-repeat": "no-repeat",
                                                       "-webkit-mask-position": "center",
                                                       "mask-position": "center",
                                                       @"background-color": A3ColorInactiveDarkBorder,
                                                       @"width": @"10px",
                                                       @"height": @"10px",
                                                       @"content": @"''",
                                                       @"left": @"2px",
                                                       @"top": @"2px",
                                                       @"position": @"absolute",
                                                       @"z-index": @"300"
                                                       }
                                                size:CGSizeMake(16,16)],

    regularImageMixedDisabled = [CPImage imageWithCSSDictionary:@{
                                                         @"border-color": A3ColorInactiveBorder,
                                                         @"border-style": @"solid",
                                                         @"border-width": @"1px",
                                                         @"border-radius": @"2px",
                                                         @"box-sizing": @"border-box",
                                                         @"background-color": A3ColorBackgroundInactive
                                                         }
                                      beforeDictionary:nil
                                       afterDictionary:@{
                                                         "-webkit-mask-image": svgDash,
                                                         "mask-image": svgDash,
                                                         "-webkit-mask-size": "contain",
                                                         "mask-size": "contain",
                                                         "-webkit-mask-repeat": "no-repeat",
                                                         "mask-repeat": "no-repeat",
                                                         "-webkit-mask-position": "center",
                                                         "mask-position": "center",
                                                         @"background-color": A3ColorInactiveDarkBorder,
                                                         @"width": @"10px",
                                                         @"height": @"10px",
                                                         @"content": @"''",
                                                         @"left": @"2px",
                                                         @"top": @"2px",
                                                         @"position": @"absolute",
                                                         @"z-index": @"300"
                                                         }
                                                  size:CGSizeMake(16,16)],

    // --- Small Size (14x14) ---
    smallImageMixed = [CPImage imageWithCSSDictionary:@{
                                                         @"border-color": A3ColorActiveBorder,
                                                         @"border-style": @"solid",
                                                         @"border-width": @"1px",
                                                         @"border-radius": @"2px",
                                                         @"box-sizing": @"border-box",
                                                         @"background-color": A3ColorBackgroundWhite
                                                         }
                                      beforeDictionary:nil
                                       afterDictionary:@{
                                                         "-webkit-mask-image": svgDash,
                                                         "mask-image": svgDash,
                                                         "-webkit-mask-size": "contain",
                                                         "mask-size": "contain",
                                                         "-webkit-mask-repeat": "no-repeat",
                                                         "mask-repeat": "no-repeat",
                                                         "-webkit-mask-position": "center",
                                                         "mask-position": "center",
                                                         @"background-color": @"A3ColorBorderBlue",
                                                         @"width": @"8px",
                                                         @"height": @"8px",
                                                         @"content": @"''",
                                                         @"left": @"2px",
                                                         @"top": @"2px",
                                                         @"position": @"absolute",
                                                         @"z-index": @"300"
                                                         }
                                                  size:CGSizeMake(14,14)],

    smallImageMixedNotKey = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveDarkBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             "-webkit-mask-image": svgDash,
                                                             "mask-image": svgDash,
                                                             "-webkit-mask-size": "contain",
                                                             "mask-size": "contain",
                                                             "-webkit-mask-repeat": "no-repeat",
                                                             "mask-repeat": "no-repeat",
                                                             "-webkit-mask-position": "center",
                                                             "mask-position": "center",
                                                             @"background-color": A3ColorInactiveDarkBorder,
                                                             @"width": @"8px",
                                                             @"height": @"8px",
                                                             @"content": @"''",
                                                             @"left": @"2px",
                                                             @"top": @"2px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(14,14)],

    smallImageMixedDisabled = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundInactive
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             "-webkit-mask-image": svgDash,
                                                             "mask-image": svgDash,
                                                             "-webkit-mask-size": "contain",
                                                             "mask-size": "contain",
                                                             "-webkit-mask-repeat": "no-repeat",
                                                             "mask-repeat": "no-repeat",
                                                             "-webkit-mask-position": "center",
                                                             "mask-position": "center",
                                                             @"background-color": A3ColorInactiveDarkBorder,
                                                             @"width": @"8px",
                                                             @"height": @"8px",
                                                             @"content": @"''",
                                                             @"left": @"2px",
                                                             @"top": @"2px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(14,14)],

    // --- Mini Size (12x12) ---
    miniImageMixed = [CPImage imageWithCSSDictionary:@{
                                                         @"border-color": A3ColorActiveBorder,
                                                         @"border-style": @"solid",
                                                         @"border-width": @"1px",
                                                         @"border-radius": @"2px",
                                                         @"box-sizing": @"border-box",
                                                         @"background-color": A3ColorBackgroundWhite
                                                         }
                                      beforeDictionary:nil
                                       afterDictionary:@{
                                                         "-webkit-mask-image": svgDash,
                                                         "mask-image": svgDash,
                                                         "-webkit-mask-size": "contain",
                                                         "mask-size": "contain",
                                                         "-webkit-mask-repeat": "no-repeat",
                                                         "mask-repeat": "no-repeat",
                                                         "-webkit-mask-position": "center",
                                                         "mask-position": "center",
                                                         @"background-color": @"A3ColorBorderBlue",
                                                         @"width": @"7px",
                                                         @"height": @"7px",
                                                         @"content": @"''",
                                                         @"left": @"1.5px",
                                                         @"top": @"1.5px",
                                                         @"position": @"absolute",
                                                         @"z-index": @"300"
                                                         }
                                                  size:CGSizeMake(12,12)],

    miniImageMixedNotKey = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveDarkBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundWhite
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             "-webkit-mask-image": svgDash,
                                                             "mask-image": svgDash,
                                                             "-webkit-mask-size": "contain",
                                                             "mask-size": "contain",
                                                             "-webkit-mask-repeat": "no-repeat",
                                                             "mask-repeat": "no-repeat",
                                                             "-webkit-mask-position": "center",
                                                             "mask-position": "center",
                                                             @"background-color": A3ColorInactiveDarkBorder,
                                                             @"width": @"7px",
                                                             @"height": @"7px",
                                                             @"content": @"''",
                                                             @"left": @"1.5px",
                                                             @"top": @"1.5px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(12,12)],

    miniImageMixedDisabled = [CPImage imageWithCSSDictionary:@{
                                                             @"border-color": A3ColorInactiveBorder,
                                                             @"border-style": @"solid",
                                                             @"border-width": @"1px",
                                                             @"border-radius": @"2px",
                                                             @"box-sizing": @"border-box",
                                                             @"background-color": A3ColorBackgroundInactive
                                                             }
                                          beforeDictionary:nil
                                           afterDictionary:@{
                                                             "-webkit-mask-image": svgDash,
                                                             "mask-image": svgDash,
                                                             "-webkit-mask-size": "contain",
                                                             "mask-size": "contain",
                                                             "-webkit-mask-repeat": "no-repeat",
                                                             "mask-repeat": "no-repeat",
                                                             "-webkit-mask-position": "center",
                                                             "mask-position": "center",
                                                             @"background-color": A3ColorInactiveDarkBorder,
                                                             @"width": @"7px",
                                                             @"height": @"7px",
                                                             @"content": @"''",
                                                             @"left": @"1.5px",
                                                             @"top": @"1.5px",
                                                             @"position": @"absolute",
                                                             @"z-index": @"300"
                                                             }
                                                      size:CGSizeMake(12,12)],

    // --- HUD Mixed (14x14) ---
    hudImageMixed = [CPImage imageWithCSSDictionary:@{
                                                        @"border-color": @"#ffffff",
                                                        @"border-style": @"solid",
                                                        @"border-width": @"1px",
                                                        @"border-radius": @"2px",
                                                        @"box-sizing": @"border-box",
                                                        @"background-color": @"rgba(0,0,0,0.3)"
                                                    } beforeDictionary:nil afterDictionary:@{
                                                         "-webkit-mask-image": svgDash,
                                                         "mask-image": svgDash,
                                                         "-webkit-mask-size": "contain",
                                                         "mask-size": "contain",
                                                         "-webkit-mask-repeat": "no-repeat",
                                                         "mask-repeat": "no-repeat",
                                                         "-webkit-mask-position": "center",
                                                         "mask-position": "center",
                                                         @"background-color": @"#ffffff", // White dash
                                                         @"width": @"10px",
                                                         @"height": @"10px",
                                                         @"content": @"''",
                                                         @"left": @"1px",
                                                         @"top": @"1px",
                                                         @"position": @"absolute",
                                                         @"z-index": @"300"
                                                    } size:CGSizeMake(14,14)],

    hudImageMixedDisabled = [CPImage imageWithCSSDictionary:@{
                                                        @"border-color": @"rgba(255,255,255,0.3)",
                                                        @"border-style": @"solid",
                                                        @"border-width": @"1px",
                                                        @"border-radius": @"2px",
                                                        @"box-sizing": @"border-box",
                                                        @"background-color": @"rgba(0,0,0,0.1)"
                                                    } beforeDictionary:nil afterDictionary:@{
                                                         "-webkit-mask-image": svgDash,
                                                         "mask-image": svgDash,
                                                         "-webkit-mask-size": "contain",
                                                         "mask-size": "contain",
                                                         "-webkit-mask-repeat": "no-repeat",
                                                         "mask-repeat": "no-repeat",
                                                         "-webkit-mask-position": "center",
                                                         "mask-position": "center",
                                                         @"background-color": @"rgba(255,255,255,0.5)", // Dimmed White dash
                                                         @"width": @"10px",
                                                         @"height": @"10px",
                                                         @"content": @"''",
                                                         @"left": @"1px",
                                                         @"top": @"1px",
                                                         @"position": @"absolute",
                                                         @"z-index": @"300"
                                                    } size:CGSizeMake(14,14)],


    themeValues =
    [
     // Regular Size
     [@"image",          regularImageMixedNotKey,       CPButtonStateMixed],
     [@"image",          regularImageMixed,             [CPButtonStateMixed, CPThemeStateKeyWindow]],
     [@"image",          regularImageMixedDisabled,     [CPButtonStateMixed, CPThemeStateDisabled]],
     [@"image",          regularImageMixedDisabled,     [CPButtonStateMixed, CPThemeStateDisabled, CPThemeStateKeyWindow]],
     [@"image-offset",   3,                             CPButtonStateMixed],
     
     // Small Size
     [@"image",          smallImageMixedNotKey,         [CPThemeStateControlSizeSmall, CPButtonStateMixed]],
     [@"image",          smallImageMixed,               [CPThemeStateControlSizeSmall, CPButtonStateMixed, CPThemeStateKeyWindow]],
     [@"image",          smallImageMixedDisabled,       [CPThemeStateControlSizeSmall, CPButtonStateMixed, CPThemeStateDisabled]],
     [@"image-offset",   3,                             [CPThemeStateControlSizeSmall, CPButtonStateMixed]],
     
     // Mini Size
     [@"image",          miniImageMixedNotKey,          [CPThemeStateControlSizeMini, CPButtonStateMixed]],
     [@"image",          miniImageMixed,                [CPThemeStateControlSizeMini, CPButtonStateMixed, CPThemeStateKeyWindow]],
     [@"image",          miniImageMixedDisabled,        [CPThemeStateControlSizeMini, CPButtonStateMixed, CPThemeStateDisabled]],
     [@"image-offset",   3,                             [CPThemeStateControlSizeMini, CPButtonStateMixed]],

     // HUD
     [@"image",          hudImageMixed,                 [CPThemeStateHUD, CPButtonStateMixed]],
     [@"image",          hudImageMixedDisabled,         [CPThemeStateHUD, CPButtonStateMixed, CPThemeStateDisabled]],
     [@"image-offset",   4,                             [CPThemeStateHUD, CPButtonStateMixed]]
     ];

    [self registerThemeValues:themeValues forView:button];

    return button;
}

+ (CPSegmentedControl)makeSegmentedControl
{
    var segmentedControl = [[CPSegmentedControl alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 25.0)];

    [segmentedControl setTrackingMode:CPSegmentSwitchTrackingSelectAny];
    [segmentedControl setSegmentCount:3];

    [segmentedControl setWidth:40.0 forSegment:0];
    [segmentedControl setLabel:@"foo" forSegment:0];
    [segmentedControl setTag:1 forSegment:0];

    [segmentedControl setWidth:60.0 forSegment:1];
    [segmentedControl setLabel:@"bar" forSegment:1];
    [segmentedControl setTag:2 forSegment:1];

    [segmentedControl setWidth:35.0 forSegment:2];
    [segmentedControl setLabel:@"1" forSegment:2];
    [segmentedControl setTag:3 forSegment:2];

    return segmentedControl;
}

+ (CPSegmentedControl)themedSegmentedControl
{
    var segmentedControl = [self makeSegmentedControl],

    // ==========================================================
    // STANDARD THEME (Light)
    // ==========================================================

    // --- Normal States ---
    centerBezelColor = [CPColor colorWithCSSDictionary:@{
                                                         @"display": @"table-cell",
                                                         @"background-color": A3ColorBackgroundWhite,
                                                         @"border-color": A3ColorBorderDark,
                                                         @"border-style": @"solid",
                                                         @"border-width": @"1px",
                                                         @"box-sizing": @"border-box"
                                                         }],
                                                         
    leftBezelColor = [CPColor colorWithCSSDictionary:@{
                                                       @"display": @"table-cell",
                                                       @"background-color": A3ColorBackgroundWhite,
                                                       @"border-color": A3ColorBorderDark,
                                                       @"border-style": @"solid",
                                                       @"border-width": @"1px",
                                                       @"border-top-left-radius": @"3px",
                                                       @"border-bottom-left-radius": @"3px",
                                                       @"box-sizing": @"border-box"
                                                       }],

    rightBezelColor = [CPColor colorWithCSSDictionary:@{
                                                        @"display": @"table-cell",
                                                        @"background-color": A3ColorBackgroundWhite,
                                                        @"border-color": A3ColorBorderDark,
                                                        @"border-style": @"solid",
                                                        @"border-width": @"1px",
                                                        @"border-top-right-radius": @"3px",
                                                        @"border-bottom-right-radius": @"3px",
                                                        @"box-sizing": @"border-box"
                                                        }],

    // --- Selected Active (Blue) States ---
    centerSelectedBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorBorderBlue,
                                                                 @"border-color": A3ColorBorderBlue,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"box-sizing": @"border-box"
                                                                 }],

    leftSelectedBezelColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorBorderBlue,
                                                               @"border-color": A3ColorBorderBlue,
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"border-top-left-radius": @"3px",
                                                               @"border-bottom-left-radius": @"3px",
                                                               @"box-sizing": @"border-box"
                                                               }],

    rightSelectedBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                @"background-color": A3ColorBorderBlue,
                                                                @"border-color": A3ColorBorderBlue,
                                                                @"border-style": @"solid",
                                                                @"border-width": @"1px",
                                                                @"border-top-right-radius": @"3px",
                                                                @"border-bottom-right-radius": @"3px",
                                                                @"box-sizing": @"border-box"
                                                                }],

    // --- Selected Inactive (Gray) States ---
    centerSelectedNotKeyBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                       @"background-color": A3ColorBackgroundInactive,
                                                                       @"border-color": A3ColorInactiveDarkBorder,
                                                                       @"border-style": @"solid",
                                                                       @"border-width": @"1px",
                                                                       @"box-sizing": @"border-box"
                                                                       }],

    leftSelectedNotKeyBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                     @"background-color": A3ColorBackgroundInactive,
                                                                     @"border-color": A3ColorInactiveDarkBorder,
                                                                     @"border-style": @"solid",
                                                                     @"border-width": @"1px",
                                                                     @"border-top-left-radius": @"3px",
                                                                     @"border-bottom-left-radius": @"3px",
                                                                     @"box-sizing": @"border-box"
                                                                     }],

    rightSelectedNotKeyBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                      @"background-color": A3ColorBackgroundInactive,
                                                                      @"border-color": A3ColorInactiveDarkBorder,
                                                                      @"border-style": @"solid",
                                                                      @"border-width": @"1px",
                                                                      @"border-top-right-radius": @"3px",
                                                                      @"border-bottom-right-radius": @"3px",
                                                                      @"box-sizing": @"border-box"
                                                                      }],

    // --- Disabled States (Unselected) ---
    centerDisabledBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorBackgroundWhite, 
                                                                 @"border-color": A3ColorInactiveBorder,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"box-sizing": @"border-box"
                                                                 }],

    leftDisabledBezelColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorBackgroundWhite,
                                                               @"border-color": A3ColorInactiveBorder,
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"border-top-left-radius": @"3px",
                                                               @"border-bottom-left-radius": @"3px",
                                                               @"box-sizing": @"border-box"
                                                               }],

    rightDisabledBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                @"background-color": A3ColorBackgroundWhite,
                                                                @"border-color": A3ColorInactiveBorder,
                                                                @"border-style": @"solid",
                                                                @"border-width": @"1px",
                                                                @"border-top-right-radius": @"3px",
                                                                @"border-bottom-right-radius": @"3px",
                                                                @"box-sizing": @"border-box"
                                                                }],

    // --- Selected Disabled States ---
    centerSelectedDisabledBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorBackgroundInactive,
                                                                 @"border-color": A3ColorInactiveDarkBorder,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"box-sizing": @"border-box"
                                                                 }],

    leftSelectedDisabledBezelColor = [CPColor colorWithCSSDictionary:@{
                                                               @"background-color": A3ColorBackgroundInactive,
                                                               @"border-color": A3ColorInactiveDarkBorder,
                                                               @"border-style": @"solid",
                                                               @"border-width": @"1px",
                                                               @"border-top-left-radius": @"3px",
                                                               @"border-bottom-left-radius": @"3px",
                                                               @"box-sizing": @"border-box"
                                                               }],

    rightSelectedDisabledBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                @"background-color": A3ColorBackgroundInactive,
                                                                @"border-color": A3ColorInactiveDarkBorder,
                                                                @"border-style": @"solid",
                                                                @"border-width": @"1px",
                                                                @"border-top-right-radius": @"3px",
                                                                @"border-bottom-right-radius": @"3px",
                                                                @"box-sizing": @"border-box"
                                                                }],

    // ==========================================================
    // HUD THEME (Dark/Transparent)
    // ==========================================================

    // --- HUD Normal ---
    hudCenterBezelColor = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": @"rgba(0, 0, 0, 0.25)",
                                                            @"border-color": @"rgba(255, 255, 255, 0.25)",
                                                            @"border-style": @"solid",
                                                            @"border-width": @"1px",
                                                            @"box-sizing": @"border-box"
                                                            }],

    hudLeftBezelColor = [CPColor colorWithCSSDictionary:@{
                                                          @"background-color": @"rgba(0, 0, 0, 0.25)",
                                                          @"border-color": @"rgba(255, 255, 255, 0.25)",
                                                          @"border-style": @"solid",
                                                          @"border-width": @"1px",
                                                          @"border-top-left-radius": @"3px",
                                                          @"border-bottom-left-radius": @"3px",
                                                          @"box-sizing": @"border-box"
                                                          }],

    hudRightBezelColor = [CPColor colorWithCSSDictionary:@{
                                                           @"background-color": @"rgba(0, 0, 0, 0.25)",
                                                           @"border-color": @"rgba(255, 255, 255, 0.25)",
                                                           @"border-style": @"solid",
                                                           @"border-width": @"1px",
                                                           @"border-top-right-radius": @"3px",
                                                           @"border-bottom-right-radius": @"3px",
                                                           @"box-sizing": @"border-box"
                                                           }],

    // --- HUD Selected ---
    hudCenterSelectedBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": @"rgba(255, 255, 255, 0.25)",
                                                                    @"border-color": @"rgba(255, 255, 255, 0.5)",
                                                                    @"border-style": @"solid",
                                                                    @"border-width": @"1px",
                                                                    @"box-sizing": @"border-box"
                                                                    }],

    hudLeftSelectedBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"background-color": @"rgba(255, 255, 255, 0.25)",
                                                                  @"border-color": @"rgba(255, 255, 255, 0.5)",
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"1px",
                                                                  @"border-top-left-radius": @"3px",
                                                                  @"border-bottom-left-radius": @"3px",
                                                                  @"box-sizing": @"border-box"
                                                                  }],

    hudRightSelectedBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                   @"background-color": @"rgba(255, 255, 255, 0.25)",
                                                                   @"border-color": @"rgba(255, 255, 255, 0.5)",
                                                                   @"border-style": @"solid",
                                                                   @"border-width": @"1px",
                                                                   @"border-top-right-radius": @"3px",
                                                                   @"border-bottom-right-radius": @"3px",
                                                                   @"box-sizing": @"border-box"
                                                                   }],

    // --- HUD Disabled (Unselected) ---
    hudCenterDisabledBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": @"rgba(0, 0, 0, 0.1)",
                                                                    @"border-color": @"rgba(255, 255, 255, 0.1)",
                                                                    @"border-style": @"solid",
                                                                    @"border-width": @"1px",
                                                                    @"box-sizing": @"border-box"
                                                                    }],

    hudLeftDisabledBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"background-color": @"rgba(0, 0, 0, 0.1)",
                                                                  @"border-color": @"rgba(255, 255, 255, 0.1)",
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"1px",
                                                                  @"border-top-left-radius": @"3px",
                                                                  @"border-bottom-left-radius": @"3px",
                                                                  @"box-sizing": @"border-box"
                                                                  }],

    hudRightDisabledBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                   @"background-color": @"rgba(0, 0, 0, 0.1)",
                                                                   @"border-color": @"rgba(255, 255, 255, 0.1)",
                                                                   @"border-style": @"solid",
                                                                   @"border-width": @"1px",
                                                                   @"border-top-right-radius": @"3px",
                                                                   @"border-bottom-right-radius": @"3px",
                                                                   @"box-sizing": @"border-box"
                                                                   }],

    // --- HUD Selected Disabled ---
    hudCenterSelectedDisabledBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": @"rgba(255, 255, 255, 0.15)",
                                                                    @"border-color": @"rgba(255, 255, 255, 0.1)",
                                                                    @"border-style": @"solid",
                                                                    @"border-width": @"1px",
                                                                    @"box-sizing": @"border-box"
                                                                    }],

    hudLeftSelectedDisabledBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                  @"background-color": @"rgba(255, 255, 255, 0.15)",
                                                                  @"border-color": @"rgba(255, 255, 255, 0.1)",
                                                                  @"border-style": @"solid",
                                                                  @"border-width": @"1px",
                                                                  @"border-top-left-radius": @"3px",
                                                                  @"border-bottom-left-radius": @"3px",
                                                                  @"box-sizing": @"border-box"
                                                                  }],

    hudRightSelectedDisabledBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                   @"background-color": @"rgba(255, 255, 255, 0.15)",
                                                                   @"border-color": @"rgba(255, 255, 255, 0.1)",
                                                                   @"border-style": @"solid",
                                                                   @"border-width": @"1px",
                                                                   @"border-top-right-radius": @"3px",
                                                                   @"border-bottom-right-radius": @"3px",
                                                                   @"box-sizing": @"border-box"
                                                                   }];


    themedSegmentedControlValues =
    [
     // Center Segment
     [@"center-segment-bezel-color",     centerBezelColor,                       CPThemeStateNormal],
     [@"center-segment-bezel-color",     centerSelectedBezelColor,               [CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"center-segment-bezel-color",     centerSelectedNotKeyBezelColor,         CPThemeStateSelected],
     
     [@"center-segment-bezel-color",     centerSelectedDisabledBezelColor,       [CPThemeStateSelected, CPThemeStateDisabled]],
     [@"center-segment-bezel-color",     centerDisabledBezelColor,               CPThemeStateDisabled],

     // Left Segment
     [@"left-segment-bezel-color",       leftBezelColor,                         CPThemeStateNormal],
     [@"left-segment-bezel-color",       leftSelectedBezelColor,                 [CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"left-segment-bezel-color",       leftSelectedNotKeyBezelColor,           CPThemeStateSelected],
     
     [@"left-segment-bezel-color",       leftSelectedDisabledBezelColor,         [CPThemeStateSelected, CPThemeStateDisabled]],
     [@"left-segment-bezel-color",       leftDisabledBezelColor,                 CPThemeStateDisabled],

     // Right Segment
     [@"right-segment-bezel-color",      rightBezelColor,                        CPThemeStateNormal],
     [@"right-segment-bezel-color",      rightSelectedBezelColor,                [CPThemeStateSelected, CPThemeStateKeyWindow]],
     [@"right-segment-bezel-color",      rightSelectedNotKeyBezelColor,          CPThemeStateSelected],
     
     [@"right-segment-bezel-color",      rightSelectedDisabledBezelColor,        [CPThemeStateSelected, CPThemeStateDisabled]],
     [@"right-segment-bezel-color",      rightDisabledBezelColor,                CPThemeStateDisabled],

     // Text Colors
     [@"text-color",                     A3CPColorActiveText],
     [@"text-color",                     A3CPColorActiveText,                    CPThemeStateSelected], 
     
     // Only turn white if Key, Selected AND Enabled.
     [@"text-color",                     A3CPColorDefaultText,                   [CPThemeStateSelected, CPThemeStateKeyWindow]], 
     
     // Explicitly override White text for Disabled+Selected+KeyWindow state
     [@"text-color",                     A3CPColorInactiveText,                  [CPThemeStateSelected, CPThemeStateKeyWindow, CPThemeStateDisabled]],
     [@"text-color",                     A3CPColorInactiveText,                  CPThemeStateDisabled],

     // Layout (Regular)
     [@"content-inset",              CGInsetMake(-1.0, 11.0, 0.0, 12.0)],
     [@"bezel-inset",                CGInsetMake(0.0, 0.0, 0.0, 0.0)],
     [@"min-size",                   CGSizeMake(-1.0, 21.0)],
     [@"max-size",                   CGSizeMake(-1.0, 21.0)],
     [@"nib2cib-adjustment-frame",   CGRectMake(2.0, -2.0, -4.0, -3.0)],
     [@"font",                       [CPFont systemFontOfSize:13.0]],
     [@"vertical-alignment",         CPCenterVerticalTextAlignment],
     [@"line-break-mode",            CPLineBreakByTruncatingTail],
     [@"divider-thickness",          1.0],

     // Small Size
     [@"min-size",                   CGSizeMake(-1.0, 18.0),                 CPThemeStateControlSizeSmall],
     [@"max-size",                   CGSizeMake(-1.0, 18.0),                 CPThemeStateControlSizeSmall],
     [@"font",                       [CPFont systemFontOfSize:11.0],         CPThemeStateControlSizeSmall],

     // Mini Size
     [@"min-size",                   CGSizeMake(-1.0, 15.0),                 CPThemeStateControlSizeMini],
     [@"max-size",                   CGSizeMake(-1.0, 15.0),                 CPThemeStateControlSizeMini],
     [@"font",                       [CPFont systemFontOfSize:9.0],          CPThemeStateControlSizeMini],

     // --- HUD MAPPINGS ---
     
     // HUD Text Colors
     [@"text-color",                 [CPColor whiteColor],                   CPThemeStateHUD],
     [@"text-color",                 [CPColor whiteColor],                   [CPThemeStateHUD, CPThemeStateSelected]],
     [@"text-color",                 [CPColor whiteColor],                   [CPThemeStateHUD, CPThemeStateSelected, CPThemeStateKeyWindow]],
     
     // Explicitly override White text for HUD Disabled+Selected+KeyWindow state
     [@"text-color",                 [CPColor colorWithWhite:1 alpha:0.4],   [CPThemeStateHUD, CPThemeStateSelected, CPThemeStateKeyWindow, CPThemeStateDisabled]],
     [@"text-color",                 [CPColor colorWithWhite:1 alpha:0.4],   [CPThemeStateHUD, CPThemeStateDisabled]],

     // HUD Center Segment
     [@"center-segment-bezel-color",     hudCenterBezelColor,                [CPThemeStateHUD, CPThemeStateNormal]],
     [@"center-segment-bezel-color",     hudCenterSelectedBezelColor,        [CPThemeStateHUD, CPThemeStateSelected]],
     [@"center-segment-bezel-color",     hudCenterSelectedBezelColor,        [CPThemeStateHUD, CPThemeStateSelected, CPThemeStateKeyWindow]],
     
     [@"center-segment-bezel-color",     hudCenterSelectedDisabledBezelColor,[CPThemeStateHUD, CPThemeStateSelected, CPThemeStateDisabled]],
     [@"center-segment-bezel-color",     hudCenterDisabledBezelColor,        [CPThemeStateHUD, CPThemeStateDisabled]],

     // HUD Left Segment
     [@"left-segment-bezel-color",       hudLeftBezelColor,                  [CPThemeStateHUD, CPThemeStateNormal]],
     [@"left-segment-bezel-color",       hudLeftSelectedBezelColor,          [CPThemeStateHUD, CPThemeStateSelected]],
     [@"left-segment-bezel-color",       hudLeftSelectedBezelColor,          [CPThemeStateHUD, CPThemeStateSelected, CPThemeStateKeyWindow]],
     
     [@"left-segment-bezel-color",       hudLeftSelectedDisabledBezelColor,  [CPThemeStateHUD, CPThemeStateSelected, CPThemeStateDisabled]],
     [@"left-segment-bezel-color",       hudLeftDisabledBezelColor,          [CPThemeStateHUD, CPThemeStateDisabled]],

     // HUD Right Segment
     [@"right-segment-bezel-color",      hudRightBezelColor,                 [CPThemeStateHUD, CPThemeStateNormal]],
     [@"right-segment-bezel-color",      hudRightSelectedBezelColor,         [CPThemeStateHUD, CPThemeStateSelected]],
     [@"right-segment-bezel-color",      hudRightSelectedBezelColor,         [CPThemeStateHUD, CPThemeStateSelected, CPThemeStateKeyWindow]],
     
     [@"right-segment-bezel-color",      hudRightSelectedDisabledBezelColor, [CPThemeStateHUD, CPThemeStateSelected, CPThemeStateDisabled]],
     [@"right-segment-bezel-color",      hudRightDisabledBezelColor,         [CPThemeStateHUD, CPThemeStateDisabled]]
    ];

    [self registerThemeValues:themedSegmentedControlValues forView:segmentedControl];

    return segmentedControl;
}

#pragma mark -
#pragma mark Sliders

+ (CPSlider)makeHorizontalSlider
{
    return [[CPSlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 19.0)];
}

+ (CPSlider)themedHorizontalSlider
{
    var slider = [self makeHorizontalSlider],

    // Basic Knob
    knobCssColor = [CPColor colorWithCSSDictionary:@{
                                                     @"border-color": A3ColorActiveBorder,
                                                     @"border-style": @"solid",
                                                     @"border-width": @"1px",
                                                     @"border-radius": @"50%",
                                                     @"box-sizing": @"border-box",
                                                     @"background-color": A3ColorBackgroundWhite
                                                     }],

    trackCssColor = [CPColor colorWithCSSDictionary:@{
                                                      @"background-color": A3ColorActiveBorder
                                                      }],

    leftTrackCssColor = [CPColor colorWithCSSDictionary:@{
                                                          @"background-color": @"A3ColorBorderBlue"
                                                          }],

    leftTrackNotKeyCssColor = [CPColor colorWithCSSDictionary:@{
                                                                @"background-color": A3ColorSliderDisabledTrack
                                                                }],
    
    // --- HUD COLORS ---
    hudKnobColor = [CPColor colorWithCSSDictionary:@{
                                                        @"background-color": @"#FFFFFF",
                                                        @"border": @"1px solid #000000",
                                                        @"box-sizing": @"border-box",
                                                        @"border-radius": @"50%"
                                                    }],
    
    hudKnobDisabledColor = [CPColor colorWithCSSDictionary:@{
                                                        @"background-color": @"#808080", // Solid Grey
                                                        @"border": @"1px solid #444444",
                                                        @"box-sizing": @"border-box",
                                                        @"border-radius": @"50%"
                                                    }],

    hudLeftTrackColor = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": @"#FFFFFF"
                                                        }],

    hudRightTrackColor = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": @"#555555",
                                                            @"border": @"1px solid #000000"
                                                          }],

    hudLeftTrackDisabledColor = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": @"rgba(255, 255, 255, 0.3)"
                                                        }],

    hudRightTrackDisabledColor = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": @"rgba(85, 85, 85, 0.3)",
                                                            @"border": @"1px solid rgba(0, 0, 0, 0.3)"
                                                          }],

    // Ticked sliders (Down pointing)
    knobDownCssColor = [CPColor colorWithCSSDictionary:@{
                                                         "-webkit-mask-image": svgArrowDown,
                                                         "mask-image": svgArrowDown,
                                                         "background-color": A3ColorBackgroundWhite,
                                                         "-webkit-mask-size": "contain",
                                                         "mask-size": "contain",
                                                         "-webkit-mask-repeat": "no-repeat",
                                                         "mask-repeat": "no-repeat",
                                                         "-webkit-mask-position": "center",
                                                         "mask-position": "center"
                                                         }],

    themedHorizontalSliderValues =
    [
     [@"track-width",                   3],
     [@"track-color",                   trackCssColor],
     
     [@"left-track-color",              leftTrackCssColor,        CPThemeStateKeyWindow],
     [@"left-track-color",              leftTrackNotKeyCssColor], // Default (Non-Key)

     [@"knob-size",                     CGSizeMake(15, 15)],
     [@"knob-color",                    knobCssColor],
     
     [@"nib2cib-adjustment-frame",      CGRectMake(3.0, -2.0, -6.0, -4.0)],
     [@"direct-nib2cib-adjustment",     YES],
     [@"ib-size",                       17],

     // Ticked slider
     [@"knob-size",                     CGSizeMake(15, 19),                     CPThemeStateTickedSlider],
     [@"knob-color",                    knobDownCssColor,                       [CPThemeStateTickedSlider, CPThemeStateBelowRightTickedSlider]],
     
     [@"tick-mark-color",               A3CPColorActiveBorder],

     // --- HUD SPECIFIC FIXES ---
     
     // Knob
     [@"knob-color",        hudKnobColor,               CPThemeStateHUD],
     [@"knob-color",        hudKnobDisabledColor,       [CPThemeStateHUD, CPThemeStateDisabled]],

     // Left Track (Filled part)
     [@"left-track-color",  hudLeftTrackColor,          CPThemeStateHUD],
     [@"left-track-color",  hudLeftTrackDisabledColor,  [CPThemeStateHUD, CPThemeStateDisabled]],
     
     // Right Track (Empty part)
     [@"track-color",       hudRightTrackColor,         CPThemeStateHUD],
     [@"track-color",       hudRightTrackDisabledColor, [CPThemeStateHUD, CPThemeStateDisabled]],
     
     // Ensure height is sufficient for visibility
     [@"track-width",       4.0,                        CPThemeStateHUD]
    ];

    [self registerThemeValues:themedHorizontalSliderValues forView:slider];

    return slider;
}

+ (CPSlider)makeVerticalSlider
{
    return [[CPSlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 19.0, 100.0)];
}

+ (CPSlider)themedVerticalSlider
{
    var slider = [self makeVerticalSlider],

    knobCssColor = [CPColor colorWithCSSDictionary:@{
                                                     @"border-color": A3ColorActiveBorder,
                                                     @"border-style": @"solid",
                                                     @"border-width": @"1px",
                                                     @"border-radius": @"50%",
                                                     @"box-sizing": @"border-box",
                                                     @"background-color": A3ColorBackgroundWhite
                                                     }],

    trackCssColor = [CPColor colorWithCSSDictionary:@{
                                                      @"background-color": A3ColorActiveBorder
                                                      }],

    // --- HUD COLORS ---
    hudKnobColor = [CPColor colorWithCSSDictionary:@{
                                                        @"background-color": @"#FFFFFF",
                                                        @"border": @"1px solid #000000",
                                                        @"box-sizing": @"border-box",
                                                        @"border-radius": @"50%"
                                                    }],

    hudKnobDisabledColor = [CPColor colorWithCSSDictionary:@{
                                                        @"background-color": @"#808080", // Solid Grey
                                                        @"border": @"1px solid #444444",
                                                        @"box-sizing": @"border-box",
                                                        @"border-radius": @"50%"
                                                    }],

    themedVerticalSliderValues =
    [
     [@"track-width", 3],
     [@"track-color", trackCssColor,            CPThemeStateVertical],
     [@"knob-size",  CGSizeMake(15, 15),        CPThemeStateVertical],
     [@"knob-color", knobCssColor,              CPThemeStateVertical],
     [@"knob-color", hudKnobColor,             [CPThemeStateHUD, CPThemeStateVertical]],
     [@"knob-color", hudKnobDisabledColor,     [CPThemeStateHUD, CPThemeStateDisabled, CPThemeStateVertical]],

     [@"nib2cib-adjustment-frame",      CGRectMake(2.0, -3.0, -4.0, -6.0),      CPThemeStateVertical],
     [@"direct-nib2cib-adjustment",     YES,                                    CPThemeStateVertical],
     [@"ib-size",                       15,                                     CPThemeStateVertical]
     ];

    [self registerThemeValues:themedVerticalSliderValues forView:slider];

    return slider;
}

+ (CPSlider)makeCircularSlider
{
    var slider = [[CPSlider alloc] initWithFrame:CGRectMake(0.0, 0.0, 24.0, 24.0)];
    [slider setSliderType:CPCircularSlider];
    return slider;
}

+ (CPSlider)themedCircularSlider
{
    var slider = [self makeCircularSlider],

    knobCssColor = [CPColor colorWithCSSDictionary:@{
                                                     @"border-style": @"none",
                                                     @"border-radius": @"50%",
                                                     @"box-sizing": @"border-box",
                                                     @"background-color": A3ColorCircularSliderKnob
                                                     }],

    trackCssColor = [CPColor colorWithCSSDictionary:@{
                                                      @"border-color": A3ColorActiveBorder,
                                                      @"border-style": @"solid",
                                                      @"border-width": @"1px",
                                                      @"border-radius": @"50%",
                                                      @"box-sizing": @"border-box",
                                                      @"background-color": A3ColorBackgroundWhite
                                                      }],

    // --- HUD COLORS ---
    hudTrackCssColor = [CPColor colorWithCSSDictionary:@{
                                                         @"border-color": @"rgba(255, 255, 255, 0.3)",
                                                         @"border-style": @"solid",
                                                         @"border-width": @"1px",
                                                         @"border-radius": @"50%",
                                                         @"box-sizing": @"border-box",
                                                         @"background-color": @"rgba(0, 0, 0, 0.2)"
                                                         }],

    hudKnobCssColor = [CPColor colorWithCSSDictionary:@{
                                                        @"border-style": @"none",
                                                        @"border-radius": @"50%",
                                                        @"box-sizing": @"border-box",
                                                        @"background-color": @"#FFFFFF"
                                                        }],

    // Explicitly define disabled HUD styles with border-radius: 50% to prevent rectangular fallback
    hudTrackDisabledCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"border-color": @"rgba(255, 255, 255, 0.1)",
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"border-radius": @"50%", // Essential for shape
                                                                 @"box-sizing": @"border-box",
                                                                 @"background-color": @"rgba(0, 0, 0, 0.1)"
                                                                 }],

    hudKnobDisabledCssColor = [CPColor colorWithCSSDictionary:@{
                                                                @"border-style": @"none",
                                                                @"border-radius": @"50%", // Essential for shape
                                                                @"box-sizing": @"border-box",
                                                                @"background-color": @"#808080" // Solid Grey
                                                                }],

    themedCircularSliderValues =
    [
     [@"track-color",                   trackCssColor,                          CPThemeStateCircular],
     [@"knob-size",                     CGSizeMake(4.0, 4.0),                   CPThemeStateCircular],
     [@"knob-offset",                   6.0,                                    CPThemeStateCircular],
     [@"knob-color",                    knobCssColor,                           CPThemeStateCircular],
     
     [@"nib2cib-adjustment-frame",      CGRectMake(2.0, -3.0, -4.0, -6.0),      CPThemeStateCircular],
     [@"direct-nib2cib-adjustment",     YES,                                    CPThemeStateCircular],
     [@"ib-size",                       24,                                     CPThemeStateCircular],

     // --- HUD SPECIFIC FIXES ---
     [@"track-color",   hudTrackCssColor,           [CPThemeStateHUD, CPThemeStateCircular]],
     [@"knob-color",    hudKnobCssColor,            [CPThemeStateHUD, CPThemeStateCircular]],
     
     // Disabled States
     [@"track-color",   hudTrackDisabledCssColor,   [CPThemeStateHUD, CPThemeStateCircular, CPThemeStateDisabled]],
     [@"knob-color",    hudKnobDisabledCssColor,    [CPThemeStateHUD, CPThemeStateCircular, CPThemeStateDisabled]]
     ];

    [self registerThemeValues:themedCircularSliderValues forView:slider];

    return slider;
}

#pragma mark -
#pragma mark Button bars

+ (CPButtonBar)makeButtonBar
{
    var buttonBar = [[CPButtonBar alloc] initWithFrame:CGRectMake(0.0, 0.0, 147.0, 26.0)];

    [buttonBar setHasResizeControl:YES];

    var popup = [CPButtonBar actionPopupButton];
    [popup addItemWithTitle:"Item 1"];
    [popup addItemWithTitle:"Item 2"];

    [buttonBar setButtons:[[CPButtonBar plusButton], [CPButtonBar minusButton], popup]];

    return buttonBar;
}

+ (CPButtonBar)themedButtonBar
{
    var buttonBar = [self makeButtonBar],

    resizeCssColor = [CPColor colorWithCSSDictionary:@{
                                                       @"border-color": A3ColorSplitPaneDividerBorder,
                                                       @"border-style": @"solid",
                                                       @"border-width": @"0px 1px 0px 1px",
                                                       @"box-sizing": @"border-box",
                                                       @"background-color": A3ColorBackground
                                                       }],

    borderedBezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                              @"border-color": A3ColorSplitPaneDividerBorder,
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px 0px 0px 0px",
                                                              @"box-sizing": @"border-box",
                                                              @"background-color": A3ColorBackground
                                                              }],

    dividerCssColor = [CPColor colorWithCSSDictionary:@{
                                                        @"background-color": A3ColorSplitPaneDividerBorder
                                                        }],

    // --- HUD COLORS ---
    hudBorderedBezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                              @"border-color": @"rgba(255, 255, 255, 0.2)",
                                                              @"border-style": @"solid",
                                                              @"border-width": @"1px 0px 0px 0px",
                                                              @"box-sizing": @"border-box",
                                                              @"background-color": @"rgba(0, 0, 0, 0.3)"
                                                              }],

    hudResizeCssColor = [CPColor colorWithCSSDictionary:@{
                                                       @"border-color": @"rgba(255, 255, 255, 0.2)",
                                                       @"border-style": @"solid",
                                                       @"border-width": @"0px 1px 0px 1px",
                                                       @"box-sizing": @"border-box",
                                                       @"background-color": @"rgba(0, 0, 0, 0.3)"
                                                       }],

    hudDividerCssColor = [CPColor colorWithCSSDictionary:@{
                                                        @"background-color": @"rgba(255, 255, 255, 0.2)"
                                                        }],

    // --- ICONS (Standard) ---
    plusIcon = [CPImage imageWithCSSDictionary:@{
                                                 "-webkit-mask-image": svgPlus,
                                                 "mask-image": svgPlus,
                                                 "background-color": A3ColorActiveText,
                                                 "-webkit-mask-size": "contain",
                                                 "mask-size": "contain",
                                                 "-webkit-mask-repeat": "no-repeat",
                                                 "mask-repeat": "no-repeat",
                                                 "-webkit-mask-position": "center",
                                                 "mask-position": "center"
                                                }
                                         size:CGSizeMake(16,16)],

    minusIcon =  [CPImage imageWithCSSDictionary:@{
                                                   "-webkit-mask-image": svgMinus,
                                                   "mask-image": svgMinus,
                                                   "background-color": A3ColorActiveText,
                                                   "-webkit-mask-size": "contain",
                                                   "mask-size": "contain",
                                                   "-webkit-mask-repeat": "no-repeat",
                                                   "mask-repeat": "no-repeat",
                                                   "-webkit-mask-position": "center",
                                                   "mask-position": "center"
                                                  }
                                             size:CGSizeMake(16,16)],

    actionIcon = [CPImage imageWithCSSDictionary:@{
                                                   "-webkit-mask-image": svgGear,
                                                   "mask-image": svgGear,
                                                   "background-color": A3ColorActiveText,
                                                   "-webkit-mask-size": "contain",
                                                   "mask-size": "contain",
                                                   "-webkit-mask-repeat": "no-repeat",
                                                   "mask-repeat": "no-repeat",
                                                   "-webkit-mask-position": "center",
                                                   "mask-position": "center"
                                                  }
                                             size:CGSizeMake(16,16)],

     actionIconHighlighted = [CPImage imageWithCSSDictionary:@{
                                                   "-webkit-mask-image": svgGear2,
                                                   "mask-image": svgGear2,
                                                   "background-color": A3ColorActiveText,
                                                   "-webkit-mask-size": "contain",
                                                   "mask-size": "contain",
                                                   "-webkit-mask-repeat": "no-repeat",
                                                   "mask-repeat": "no-repeat",
                                                   "-webkit-mask-position": "center",
                                                   "mask-position": "center"
                                                  }
                                                size:CGSizeMake(16,16)],

    // --- HUD ICONS (White) ---
    plusIconHUD = [CPImage imageWithCSSDictionary:@{
                                                 "-webkit-mask-image": svgPlus,
                                                 "mask-image": svgPlus,
                                                 "background-color": @"#FFFFFF",
                                                 "-webkit-mask-size": "contain",
                                                 "mask-size": "contain",
                                                 "-webkit-mask-repeat": "no-repeat",
                                                 "mask-repeat": "no-repeat",
                                                 "-webkit-mask-position": "center",
                                                 "mask-position": "center"
                                                }
                                         size:CGSizeMake(16,16)],

    minusIconHUD =  [CPImage imageWithCSSDictionary:@{
                                                   "-webkit-mask-image": svgMinus,
                                                   "mask-image": svgMinus,
                                                   "background-color": @"#FFFFFF",
                                                   "-webkit-mask-size": "contain",
                                                   "mask-size": "contain",
                                                   "-webkit-mask-repeat": "no-repeat",
                                                   "mask-repeat": "no-repeat",
                                                   "-webkit-mask-position": "center",
                                                   "mask-position": "center"
                                                  }
                                             size:CGSizeMake(16,16)],

    actionIconHUD = [CPImage imageWithCSSDictionary:@{
                                                   "-webkit-mask-image": svgGear,
                                                   "mask-image": svgGear,
                                                   "background-color": @"#FFFFFF",
                                                   "-webkit-mask-size": "contain",
                                                   "mask-size": "contain",
                                                   "-webkit-mask-repeat": "no-repeat",
                                                   "mask-repeat": "no-repeat",
                                                   "-webkit-mask-position": "center",
                                                   "mask-position": "center"
                                                  }
                                             size:CGSizeMake(16,16)],

     actionIconHighlightedHUD = [CPImage imageWithCSSDictionary:@{
                                                   "-webkit-mask-image": svgGear2, 
                                                   "mask-image": svgGear2,
                                                   "background-color": @"#FFFFFF",
                                                   "-webkit-mask-size": "contain",
                                                   "mask-size": "contain",
                                                   "-webkit-mask-repeat": "no-repeat",
                                                   "mask-repeat": "no-repeat",
                                                   "-webkit-mask-position": "center",
                                                   "mask-position": "center"
                                                  }
                                                size:CGSizeMake(16,16)],


    themedButtonBarValues =
    [
     [@"bezel-color",               borderedBezelCssColor,              CPThemeStateBordered],
     [@"divider-color",             dividerCssColor],

     [@"button-vertical-offset",    0.0],

     [@"resize-control-size",       CGSizeMake(15, 28)],
     [@"resize-control-inset",      CGInsetMake(0, -1, 0, -1)],
     [@"resize-control-color",      resizeCssColor,                     CPThemeStateBordered],
     [@"auto-resize-control",       NO],

     [@"bordered-buttons",          NO],
     [@"draws-separator",           YES],
     [@"is-transparent",            NO],

     [@"spacing-size",              CGSizeMake(6, 28)],
     [@"min-size",                  CGSizeMake(0, 29)],
     [@"max-size",                  CGSizeMake(-1, 29)],

     [@"button-image-plus",         plusIcon,         CPThemeStateNormal],
     [@"button-image-minus",        minusIcon,        CPThemeStateNormal],
     [@"button-image-action",       actionIcon,       CPThemeStateNormal],
     [@"button-image-action",       actionIconHighlighted, CPThemeStateHighlighted],

     // --- HUD MAPPINGS ---
     [@"bezel-color",               hudBorderedBezelCssColor,           [CPThemeStateHUD, CPThemeStateBordered]],
     [@"divider-color",             hudDividerCssColor,                 CPThemeStateHUD],
     [@"resize-control-color",      hudResizeCssColor,                  [CPThemeStateHUD, CPThemeStateBordered]],

     [@"button-image-plus",         plusIconHUD,                        [CPThemeStateHUD, CPThemeStateNormal]],
     [@"button-image-minus",        minusIconHUD,                       [CPThemeStateHUD, CPThemeStateNormal]],
     [@"button-image-action",       actionIconHUD,                      [CPThemeStateHUD, CPThemeStateNormal]],
     [@"button-image-action",       actionIconHighlightedHUD,           [CPThemeStateHUD, CPThemeStateHighlighted]]
    ];
    [self registerThemeValues:themedButtonBarValues forView:buttonBar];

    return buttonBar;
}

+ (_CPButtonBarButton)themedButtonBarButton
{
    var button = [[_CPButtonBarButton alloc] initWithFrame:CGRectMake(0, 0, 34, 34)],

    buttonBezelColor = [CPColor colorWithCSSDictionary:@{
                                                         @"background-color": A3ColorTransparent
                                                         }],

    highlightedButtonBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": A3ColorBackgroundDarkened
                                                                    }],
    
    // Light highlight for HUD (on dark background)
    hudHighlightedButtonBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": @"rgba(255, 255, 255, 0.2)"
                                                                    }],

    themedButtonBarButtonValues =
    [
     [@"bezel-color",               buttonBezelColor],
     [@"bezel-color",               highlightedButtonBezelColor,        [CPThemeStateHighlighted, CPThemeStateBordered]],
     [@"bezel-color",               highlightedButtonBezelColor,        CPThemeStateHighlighted],
     
     // --- HUD Mappings ---
     [@"bezel-color",               hudHighlightedButtonBezelColor,     [CPThemeStateHUD, CPThemeStateHighlighted]],
     [@"bezel-color",               hudHighlightedButtonBezelColor,     [CPThemeStateHUD, CPThemeStateBordered, CPThemeStateHighlighted]],

     [@"min-size",                  CGSizeMake(18, 28)],
     [@"max-size",                  CGSizeMake(18, 28)],
     [@"min-size",                  CGSizeMake(34, 28),                 CPThemeStateBordered],
     [@"max-size",                  CGSizeMake(34, 28),                 CPThemeStateBordered],
     [@"highlights-by",             CPPushInCellMask | CPContentsCellMask, CPThemeStateNormal]
     ];

    [self registerThemeValues:themedButtonBarButtonValues forView:button];

    return button;
}

+ (_CPButtonBarSeparator)themedButtonBarSeparator
{
    var button = [[_CPButtonBarSeparator alloc] initWithFrame:CGRectMake(0, 0, 34, 34)],

    separatorCssImage = [CPImage imageWithCSSDictionary:@{
                                                          @"background-color": A3ColorTextfieldActiveBorder
                                                          }
                                                   size:CGSizeMake(1,14)],

    borderedSeparatorCssImage = [CPImage imageWithCSSDictionary:@{
                                                                  @"background-color": A3ColorTextfieldActiveBorder
                                                                  }
                                                           size:CGSizeMake(1,16)],
    
    // Light separators for HUD
    hudSeparatorCssImage = [CPImage imageWithCSSDictionary:@{
                                                          @"background-color": @"rgba(255, 255, 255, 0.3)"
                                                          }
                                                   size:CGSizeMake(1,14)],

    hudBorderedSeparatorCssImage = [CPImage imageWithCSSDictionary:@{
                                                                  @"background-color": @"rgba(255, 255, 255, 0.3)"
                                                                  }
                                                           size:CGSizeMake(1,16)],

    themedButtonBarSeparatorValues =
    [
     [@"image",     separatorCssImage],
     [@"image",     borderedSeparatorCssImage,      CPThemeStateBordered],
     
     // --- HUD Mappings ---
     [@"image",     hudSeparatorCssImage,           CPThemeStateHUD],
     [@"image",     hudBorderedSeparatorCssImage,   [CPThemeStateHUD, CPThemeStateBordered]]
     ];

    [self registerThemeValues:themedButtonBarSeparatorValues forView:button];

    return button;
}

+ (_CPButtonBarSearchField)themedButtonBarSearchField
{
    var button = [[_CPButtonBarSearchField alloc] initWithFrame:CGRectMake(0, 0, 34, 34)],

    searchFieldBezelCssColor = [CPColor colorWithCSSDictionary:@{
                                                                 @"background-color": A3ColorBackgroundLightlyDarkened,
                                                                 @"border-color": A3ColorTextfieldActiveBorder,
                                                                 @"border-style": @"solid",
                                                                 @"border-width": @"1px",
                                                                 @"border-radius": @"5px",
                                                                 @"box-sizing": @"border-box",
                                                                 @"transition-duration": @"0.35s",
                                                                 @"transition-property": @"background-color"
                                                                 }],

    searchFieldBezelFocusedCssColor = [CPColor colorWithCSSDictionary:@{
                                                                        @"background-color": A3ColorBackgroundWhite,
                                                                        @"border-color": A3ColorTextfieldActiveBorder,
                                                                        @"border-style": @"solid",
                                                                        @"border-width": @"1px",
                                                                        @"border-radius": @"5px",
                                                                        @"box-sizing": @"border-box",
                                                                        @"transition-duration": @"0.35s",
                                                                        @"transition-property": @"background-color"
                                                                        }],

    themedButtonBarSearchFieldValues =
    [
     [@"bezel-color",   searchFieldBezelCssColor,           [CPTextFieldStateRounded, CPThemeStateBezeled]],
     [@"bezel-color",   searchFieldBezelFocusedCssColor,    [CPTextFieldStateRounded, CPThemeStateBezeled, CPThemeStateEditing]],
     [@"extra-spacing", 0],
     [@"extra-spacing", 4,                                  CPThemeStateBordered]
     ];

    [self registerThemeValues:themedButtonBarSearchFieldValues forView:button inheritFrom:[self themedSearchField]];

    return button;
}

+ (_CPButtonBarPopUpButton)themedButtonBarPopUpButton
{
    var button = [[_CPButtonBarPopUpButton alloc] initWithFrame:CGRectMake(0, 0, 34, 34)],

    // Normal State: Transparent
    buttonBezelColor = [CPColor colorWithCSSDictionary:@{
                                                         @"background-color": A3ColorTransparent
                                                        }],

    // Highlighted State: Darkened Background
    highlightedButtonBezelColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": A3ColorBackgroundDarkened
                                                                   }],

    themedButtonBarPopUpButtonValues =
    [
     // Normal
     [@"bezel-color",       buttonBezelColor],

     // Highlighted (Catch-all for simple highlight)
     [@"bezel-color",       highlightedButtonBezelColor,        CPThemeStateHighlighted],
     
     // Highlighted (Specific for Key Window)
     [@"bezel-color",       highlightedButtonBezelColor,        [CPThemeStateHighlighted, CPThemeStateKeyWindow]],

     // Highlighted (Specific combinations to ensure override of parent class)
     [@"bezel-color",       highlightedButtonBezelColor,        [CPPopUpButtonStatePullsDown, CPButtonStateBezelStyleRegularSquare, CPThemeStateHighlighted]],

     // Layout
     [@"content-inset",     CGInsetMake(-1.0, 12.0, 1.0, 2.0)],
     [@"menu-offset",       CGSizeMake(1, -5)],
     [@"min-size",          CGSizeMake(34, 28)],
     [@"max-size",          CGSizeMake(34, 28)]
     ];

    [self registerThemeValues:themedButtonBarPopUpButtonValues forView:button inheritFrom:[self themedPullDownMenu]];

    return button;
}

+ (_CPButtonBarAdaptativePopUpButton)themedButtonBarAdaptativePopUpButton
{
    var button = [[_CPButtonBarAdaptativePopUpButton alloc] initWithFrame:CGRectMakeZero()],

    themedButtonBarAdaptativePopUpButtonValues =
    [
     [@"extra-spacing", 0],
     [@"extra-spacing", 4,                  CPThemeStateBordered]
    ];

    [self registerThemeValues:themedButtonBarAdaptativePopUpButtonValues forView:button inheritFrom:[self themedPopUpButton]];

    return button;
}

+ (_CPButtonBarAdaptativePullDownButton)themedButtonBarAdaptativePullDownButton
{
    var button = [[_CPButtonBarAdaptativePullDownButton alloc] initWithFrame:CGRectMakeZero()],

    themedButtonBarAdaptativePullDownButtonValues =
    [
     [@"content-inset",     CGInsetMake(-4.0, 13, 0, 3.0)],
     [@"extra-spacing",     0],
     [@"extra-spacing",     4,                                  CPThemeStateBordered]
     ];

    [self registerThemeValues:themedButtonBarAdaptativePullDownButtonValues forView:button inheritFrom:[self themedPullDownMenu]];

    return button;
}

+ (_CPButtonBarAdaptativeLabel)themedButtonBarAdaptativeLabel
{
    var button = [[_CPButtonBarAdaptativeLabel alloc] initWithTitle:@"Dummy"],

    themedButtonBarAdaptativeLabelValues =
    [
     [@"text-color",        A3CPColorActiveText],

     // --- HUD Mappings ---
     [@"text-color",        [CPColor whiteColor],               CPThemeStateHUD],

     [@"content-inset",     CGInsetMake(0.0, 0.0, 0.0, 0.0)],
     [@"extra-spacing",     0],
     [@"extra-spacing",     4,                                  CPThemeStateBordered]
     ];

    [self registerThemeValues:themedButtonBarAdaptativeLabelValues forView:button];

    return button;
}

+ (_CPButtonBarLabel)themedButtonBarLabel
{
    var button = [[_CPButtonBarLabel alloc] initWithTitle:@"Dummy"],

    themedButtonBarLabelValues =
    [
     [@"text-color",        A3CPColorActiveText],
     
     // --- HUD Mappings ---
     [@"text-color",        [CPColor whiteColor],               CPThemeStateHUD],

     [@"content-inset",     CGInsetMake(0.0, 0.0, 0.0, 0.0)],
     [@"extra-spacing",     0],
     [@"extra-spacing",     4,                                  CPThemeStateBordered]
     ];

    [self registerThemeValues:themedButtonBarLabelValues forView:button];

    return button;
}

#pragma mark -
#pragma mark Tables

+ (_CPTableColumnHeaderView)makeColumnHeader
{
    var header = [[_CPTableColumnHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 23.0)];

    [header setStringValue:@"Table Header"];

    return header;
}

+ (_CPTableColumnHeaderView)themedColumnHeader
{
    var header = [self makeColumnHeader],
    
    // Standard Background
    background = [CPColor colorWithCSSDictionary:@{
                                                   @"background-color": A3ColorBackgroundWhite,
                                                   @"border-bottom": @"1px solid " + A3ColorTableDivider
                                                   }
                                beforeDictionary:nil
                                 afterDictionary:@{
                                                   @"background-color": A3ColorTableHeaderSeparator,
                                                   @"bottom": @"3px",
                                                   @"content": @"''",
                                                   @"position": @"absolute",
                                                   @"right": @"0px",
                                                   @"top": @"2px",
                                                   @"width": @"1px"
                                                   }],

    pressed = [CPColor colorWithCSSDictionary:@{
                                                @"background-color": A3ColorTableColumnHeaderPressed
                                                }
                             beforeDictionary:@{
                                                @"background-color": A3ColorTableDivider,
                                                @"bottom": @"0px",
                                                @"content": @"''",
                                                @"position": @"absolute",
                                                @"left": @"0px",
                                                @"top": @"0px",
                                                @"width": @"1px"
                                                }
                              afterDictionary:@{
                                                @"background-color": A3ColorTableDivider,
                                                @"bottom": @"0px",
                                                @"content": @"''",
                                                @"position": @"absolute",
                                                @"right": @"0px",
                                                @"top": @"0px",
                                                @"width": @"1px"
                                                }],

    // --- HUD Background ---
    hudBackground = [CPColor colorWithCSSDictionary:@{
                                                   @"background-color": @"rgba(0, 0, 0, 0.25)",
                                                   @"border-bottom": @"1px solid rgba(255, 255, 255, 0.2)"
                                                   }
                                beforeDictionary:nil
                                 afterDictionary:@{
                                                   @"background-color": @"rgba(255, 255, 255, 0.2)",
                                                   @"bottom": @"3px",
                                                   @"content": @"''",
                                                   @"position": @"absolute",
                                                   @"right": @"0px",
                                                   @"top": @"2px",
                                                   @"width": @"1px"
                                                   }],

    ghost = [CPColor colorWithCSSDictionary:@{}
                           beforeDictionary:nil
                            afterDictionary:nil],

    themedColumnHeaderValues =
    [
     [@"background-color",      background],
     [@"background-color",      pressed,            CPThemeStateHighlighted],
     [@"background-color",      ghost,              CPThemeStateVertical],
     
     // HUD Mapping
     [@"background-color",      hudBackground,      CPThemeStateHUD],
     [@"text-color",            [CPColor whiteColor], CPThemeStateHUD],

     [@"dont-draw-separator",   YES],

     [@"text-inset",            CGInsetMake(-2, 5, 0, 6)],
     [@"text-color",            A3CPColorTableHeaderText],
     [@"text-color",            A3CPColorSelectedTableHeaderText,       CPThemeStateSelected],
     [@"font",                  [CPFont systemFontOfSize:11.0]],
     [@"text-alignment",        CPLeftTextAlignment],
     [@"line-break-mode",       CPLineBreakByTruncatingTail]
     ];

    [self registerThemeValues:themedColumnHeaderValues forView:header];

    return header;
}

+ (CPTableHeaderView)themedTableHeaderRow
{
    var header = [[CPTableHeaderView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 23.0)],

    // Standard Background
    background = [CPColor colorWithCSSDictionary:@{
                                                   @"background-color": A3ColorBackgroundWhite,
                                                   @"border-color": A3ColorTableDivider,
                                                   @"border-style": @"solid",
                                                   @"border-bottom-width": @"1px",
                                                   @"border-top-width": @"0px",
                                                   @"border-left-width": @"0px",
                                                   @"border-right-width": @"0px",
                                                   @"box-sizing": @"border-box"
                                                   }],

    // HUD Background
    hudBackground = [CPColor colorWithCSSDictionary:@{
                                                   @"background-color": @"rgba(0, 0, 0, 0.25)",
                                                   @"border-color": @"rgba(255, 255, 255, 0.2)",
                                                   @"border-style": @"solid",
                                                   @"border-bottom-width": @"1px",
                                                   @"border-top-width": @"0px",
                                                   @"border-left-width": @"0px",
                                                   @"border-right-width": @"0px",
                                                   @"box-sizing": @"border-box"
                                                   }],

    animateSwapFunction = "" + function(s, aFromIndex, aToIndex, _columnDragClipView, _columnDragView) {

        var theTableView         = [s tableView],
            animatedColumn       = [[theTableView tableColumns] objectAtIndex:aToIndex],
            animatedHeader       = [animatedColumn headerView],
            animatedHeaderOrigin = [animatedHeader frameOrigin],

            destinationX,
            draggedHeader        = [[[theTableView tableColumns] objectAtIndex:aFromIndex] headerView],

            scrollView = [s enclosingScrollView],
            animatedView = [theTableView _animationViewForColumn:aToIndex],
            animatedOrigin = [animatedView frameOrigin];

        [_columnDragClipView addSubview:animatedView positioned:CPWindowBelow relativeTo:_columnDragView];

        [[animatedHeader subviews] makeObjectsPerformSelector:@selector(setHidden:) withObject:YES];
        [animatedHeader setThemeState:CPThemeStateVertical];

        if (aFromIndex < aToIndex)
            destinationX = CGRectGetMinX([theTableView rectOfColumn:aFromIndex]);
        else
            destinationX = animatedOrigin.x + CGRectGetWidth([theTableView rectOfColumn:aFromIndex]);

        [CPAnimationContext beginGrouping];

        var context = [CPAnimationContext currentContext];

        [context setDuration:0.15];
        [context setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
        [context setCompletionHandler:function() {

            [animatedView removeFromSuperview];

            [s _finalize_moveColumn:aFromIndex toColumn:aToIndex];

            [animatedHeader unsetThemeState:CPThemeStateVertical];
            [[animatedHeader subviews] makeObjectsPerformSelector:@selector(setHidden:) withObject:NO];

            if ([animatedView isSelected])
            {
                [animatedHeader setThemeState:CPThemeStateSelected];

                // We have to reselect the animated column
                [[theTableView selectedColumnIndexes] addIndex:aFromIndex];
            }

            // Reload animated column
            var columnVisRect  = CGRectIntersection([theTableView rectOfColumn:aFromIndex], [theTableView visibleRect]),
                rowsIndexes    = [CPIndexSet indexSetWithIndexesInRange:[theTableView rowsInRect:columnVisRect]],
                columnsIndexes = [CPIndexSet indexSetWithIndex:aFromIndex];

            [theTableView _loadDataViewsInRows:rowsIndexes columns:columnsIndexes];
            [theTableView _layoutViewsForRowIndexes:rowsIndexes columnIndexes:columnsIndexes];

            [theTableView._tableDrawView displayRect:columnVisRect];
        }];

        [[animatedView animator] setFrameOrigin:CGPointMake(destinationX, animatedOrigin.y)];

        [CPAnimationContext endGrouping];
    },

    animateReturnFunction = "" + function(s, aColumnIndex, _columnDragView) {

        var animatedColumn       = [[[s tableView] tableColumns] objectAtIndex:aColumnIndex],
            animatedHeader       = [animatedColumn headerView],
            animatedHeaderOrigin = [animatedHeader frameOrigin];

        [CPAnimationContext beginGrouping];

        var context = [CPAnimationContext currentContext];

        [context setDuration:0.15];
        [context setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
        [context setCompletionHandler:function() {

            [s _finalize_stopDraggingTableColumn:aColumnIndex];
        }];

        [[_columnDragView animator] setFrameOrigin:CGPointMake(animatedHeaderOrigin.x, 0)];

        [CPAnimationContext endGrouping];
    },

    themeValues = [
        [@"background-color",   background],
        [@"background-color",   hudBackground,          CPThemeStateHUD],
        [@"swap-animation",     animateSwapFunction],
        [@"return-animation",   animateReturnFunction]
    ];

    [self registerThemeValues:themeValues forView:header];

    return header;
}

+ (_CPCornerView)themedCornerview
{
    var scrollerWidth = [CPScroller scrollerWidth],
        corner = [[_CPCornerView alloc] initWithFrame:CGRectMake(0.0, 0.0, scrollerWidth, 23.0)],

    // Standard Background (White)
    background = [CPColor colorWithCSSDictionary:@{
                                                   @"background-color": A3ColorBackgroundWhite,
                                                   @"border-color": A3ColorTableDivider,
                                                   @"border-style": @"solid",
                                                   @"border-bottom-width": @"1px",
                                                   @"border-top-width": @"0px",
                                                   @"border-left-width": @"0px",
                                                   @"border-right-width": @"0px",
                                                   @"box-sizing": @"border-box"
                                                   }],
    
    // HUD Background (Dark Transparent)
    hudBackground = [CPColor colorWithCSSDictionary:@{
                                                   @"background-color": @"rgba(0, 0, 0, 0.25)",
                                                   @"border-color": @"rgba(255, 255, 255, 0.2)",
                                                   @"border-style": @"solid",
                                                   @"border-bottom-width": @"1px",
                                                   @"border-top-width": @"0px",
                                                   @"border-left-width": @"0px",
                                                   @"border-right-width": @"0px",
                                                   @"box-sizing": @"border-box"
                                                   }],

    themeValues = [
        [@"background-color", background],
        [@"background-color", hudBackground, CPThemeStateHUD]
    ];

    [self registerThemeValues:themeValues forView:corner];

    return corner;
}


+ (CPTableView)themedTableView
{
    var tableview = [[CPTableView alloc] initWithFrame:CGRectMake(0.0, 0.0, 150.0, 150.0)],
        
        // Images
        sortImage = [CPImage imageWithCSSDictionary:@{
            "-webkit-mask-image": svgArrowUp,
            "mask-image": svgArrowUp,
            "background-color": A3ColorActiveText,
            "-webkit-mask-size": "contain", "mask-size": "contain",
            "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
            "-webkit-mask-position": "center", "mask-position": "center"
        } size:CGSizeMake(18, 16)],

        sortImageReversed = [CPImage imageWithCSSDictionary:@{
            "-webkit-mask-image": svgArrowDown,
            "mask-image": svgArrowDown,
            "background-color": A3ColorActiveText,
            "-webkit-mask-size": "contain", "mask-size": "contain",
            "-webkit-mask-repeat": "no-repeat", "mask-repeat": "no-repeat",
            "-webkit-mask-position": "center", "mask-position": "center"
        } size:CGSizeMake(18, 16)],

        imageGenericFile = nil, 
        
        alternatingRowColors = [A3CPColorTableRow, A3CPColorTableAlternateRow],
        gridColor = [CPColor colorWithHexString:@"dce0e2"],
        sourceListSelectionColor = @{
             CPSourceListGradient: CGGradientCreateWithColorComponents(CGColorSpaceCreateDeviceRGB(), [109.0/255.0, 150.0/255.0, 238.0/255.0, 1.0, 72.0/255.0, 113.0/255.0, 201.0/255.0, 1.0], [0, 1], 2),
             CPSourceListTopLineColor: [CPColor colorWithCalibratedRed:70.0/255.0 green:107.0/255.0 blue:215.0/255.0 alpha:1.0],
             CPSourceListBottomLineColor: [CPColor colorWithCalibratedRed:42.0/255.0 green:74.0/255.0 blue:177.0/255.0 alpha:1.0]
        },

    // Unfocused HUD Selection
    hudUnfocusedSelectionColor = [CPColor colorWithWhite:1.0 alpha:0.9],

    // Alternating Rows: Clear + Very Faint White
    hudAlternatingRowColors = [[CPColor clearColor], [CPColor colorWithWhite:1.0 alpha:0.05]],

    themedTableViewValues =
    [
     [@"alternating-row-colors",                 alternatingRowColors],
     [@"grid-color",                             gridColor],
     [@"highlighted-grid-color",                 [CPColor whiteColor]],
     [@"selection-color",                        @"A3CPColorBorderBlue"],
     [@"unfocused-selection-color",              A3CPColorBorderBlueInactive], 
     [@"sourcelist-selection-color",             sourceListSelectionColor],
     [@"sort-image",                             sortImage],
     [@"sort-image-reversed",                    sortImageReversed],
     [@"image-generic-file",                     imageGenericFile],
     [@"default-row-height",                     17.0], 
     [@"header-view-height",                     22],
     [@"background-color",                       [CPColor whiteColor]],

     // --- HUD OVERRIDES ---
     [@"header-view-height",                     22.0,                                   CPThemeStateHUD],
     [@"background-color",                       [CPColor clearColor],                   CPThemeStateHUD], // CSS colors do not work here
     [@"alternating-row-colors",                 hudAlternatingRowColors,                CPThemeStateHUD],

     // Key/Active Selection
     [@"selection-color",                        [CPColor whiteColor],                      CPThemeStateHUD],
     [@"selection-color",                        [CPColor whiteColor],                      [CPThemeStateHUD, CPThemeStateKeyWindow]],

     // Inactive Selection
     [@"unfocused-selection-color",              hudUnfocusedSelectionColor,             CPThemeStateHUD],
     [@"unfocused-selection-color",              hudUnfocusedSelectionColor,             [CPThemeStateHUD, CPThemeStateKeyWindow]],

     // --- DRAG & DROP ---
     [@"dropview-on-background-color",           [CPColor colorWithRed:72/255 green:134/255 blue:202/255 alpha:0.25]],
     [@"dropview-on-border-color",               [CPColor colorWithHexString:@"4886ca"]],
     [@"dropview-on-border-width",               3.0],
     [@"dropview-on-border-radius",              8.0],
     [@"dropview-on-selected-background-color",  [CPColor clearColor]],
     [@"dropview-on-selected-border-color",      [CPColor whiteColor]],
     [@"dropview-on-selected-border-width",      2.0],
     [@"dropview-on-selected-border-radius",     8.0],
     [@"dropview-above-border-color",            [CPColor colorWithHexString:@"4886ca"]],
     [@"dropview-above-border-width",            3.0],
     [@"dropview-above-selected-border-color",   [CPColor colorWithHexString:@"8BB6F0"]],
     [@"dropview-above-selected-border-width",   2.0]
     ];

    [tableview setUsesAlternatingRowBackgroundColors:YES];
    [self registerThemeValues:themedTableViewValues forView:tableview];

    return tableview;
}

+ (CPTextField)themedTableDataView
{
    var view = [self themedStandardTextField];

    [view setBezeled:NO];
    [view setEditable:NO];
    [view setThemeState:CPThemeStateTableDataView];

    return view;
}

#pragma mark -

+ (CPSplitView)themedSplitView
{
    var splitView = [[CPSplitView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 200.0)],
        
        // Replaced PatternImage
        horizontalDividerColor = [CPColor colorWithCSSDictionary:@{
            @"background-color": A3ColorBackground,
            @"border-top": @"1px solid " + A3ColorBorderLight
        }],
        
        verticalDividerColor = [CPColor colorWithCSSDictionary:@{
            @"background-color": A3ColorBackground,
            @"border-left": @"1px solid " + A3ColorBorderLight
        }],

        thinDividerCssColor = [CPColor colorWithCSSDictionary:@{
                                                                @"background-color": A3ColorInactiveBorder
                                                                }
                                             beforeDictionary:nil
                                              afterDictionary:nil],

        thickDividerCssColor = [CPColor colorWithCSSDictionary:@{
                                                                @"background-color": A3ColorSplitPaneDividerBackground,
                                                                @"border-color": A3ColorSplitPaneDividerBorder,
                                                                @"box-sizing": @"border-box",
                                                                @"border-style": @"solid",
                                                                @"border-top-width": @"1px",
                                                                @"border-left-width": @"0px",
                                                                @"border-right-width": @"0px",
                                                                @"border-bottom-width": @"1px"
                                                                }
                                              beforeDictionary:nil
                                               afterDictionary:@{
                                                                 @"border-color": A3ColorInactiveBorder,
                                                                 @"background-color": A3ColorInactiveBorder,
                                                                 @"width": @"6px",
                                                                 @"height": @"6px",
                                                                 @"box-sizing": @"border-box",
                                                                 @"border-style": @"solid",
                                                                 @"border-radius": @"50%",
                                                                 @"border-width": @"1px",
                                                                 @"content": @"''",
                                                                 @"left": @"0px",
                                                                 @"top": @"2px",
                                                                 @"right": @"0px",
                                                                 @"bottom": @"1px",
                                                                 @"margin": @"auto",
                                                                 @"position": @"absolute",
                                                                 @"z-index": @"300"
                                                                 }],

        verticalThickDividerCssColor = [CPColor colorWithCSSDictionary:@{
                                                                        @"background-color": A3ColorSplitPaneDividerBackground,
                                                                        @"border-color": A3ColorSplitPaneDividerBorder,
                                                                        @"box-sizing": @"border-box",
                                                                        @"border-style": @"solid",
                                                                        @"border-top-width": @"0px",
                                                                        @"border-left-width": @"1px",
                                                                        @"border-right-width": @"1px",
                                                                        @"border-bottom-width": @"0px"
                                                                        }
                                                      beforeDictionary:nil
                                                       afterDictionary:@{
                                                                         @"border-color": A3ColorInactiveBorder,
                                                                         @"background-color": A3ColorInactiveBorder,
                                                                         @"width": @"6px",
                                                                         @"height": @"6px",
                                                                         @"box-sizing": @"border-box",
                                                                         @"border-style": @"solid",
                                                                         @"border-radius": @"50%",
                                                                         @"border-width": @"1px",
                                                                         @"content": @"''",
                                                                         @"left": @"1px",
                                                                         @"top": @"0px",
                                                                         @"right": @"2px",
                                                                         @"bottom": @"0px",
                                                                         @"margin": @"auto",
                                                                         @"position": @"absolute",
                                                                         @"z-index": @"300"
                                                                         }],
    paneDividerCssColor = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": A3ColorSplitPaneDividerBackground,
                                                            @"border-color": A3ColorSplitPaneDividerBorder,
                                                            @"box-sizing": @"border-box",
                                                            @"border-style": @"solid",
                                                            @"border-top-width": @"1px",
                                                            @"border-left-width": @"0px",
                                                            @"border-right-width": @"0px",
                                                            @"border-bottom-width": @"1px"
                                                            }
                                         beforeDictionary:nil
                                          afterDictionary:@{
                                                            @"border-color": A3ColorInactiveBorder, 
                                                            @"background-color": A3ColorInactiveBorder,
                                                            @"width": @"6px",
                                                            @"height": @"6px",
                                                            @"box-sizing": @"border-box",
                                                            @"border-style": @"solid",
                                                            @"border-radius": @"50%",
                                                            @"border-width": @"1px",
                                                            @"content": @"''",
                                                            @"left": @"0px",
                                                            @"top": @"1px",
                                                            @"right": @"0px",
                                                            @"bottom": @"1px",
                                                            @"margin": @"auto",
                                                            @"position": @"absolute",
                                                            @"z-index": @"300"
                                                            }],

    verticalPaneDividerCssColor = [CPColor colorWithCSSDictionary:@{
                                                                    @"background-color": A3ColorSplitPaneDividerBackground,
                                                                    @"border-color": A3ColorSplitPaneDividerBorder,
                                                                    @"box-sizing": @"border-box",
                                                                    @"border-style": @"solid",
                                                                    @"border-top-width": @"0px",
                                                                    @"border-left-width": @"1px",
                                                                    @"border-right-width": @"1px",
                                                                    @"border-bottom-width": @"0px"
                                                                    }
                                                 beforeDictionary:nil
                                                  afterDictionary:@{
                                                                    @"border-color": A3ColorInactiveBorder,
                                                                    @"background-color": A3ColorInactiveBorder,
                                                                    @"width": @"6px",
                                                                    @"height": @"6px",
                                                                    @"box-sizing": @"border-box",
                                                                    @"border-style": @"solid",
                                                                    @"border-radius": @"50%",
                                                                    @"border-width": @"1px",
                                                                    @"content": @"''",
                                                                    @"left": @"1px",
                                                                    @"top": @"0px",
                                                                    @"right": @"1px",
                                                                    @"bottom": @"0px",
                                                                    @"margin": @"auto",
                                                                    @"position": @"absolute",
                                                                    @"z-index": @"300"
                                                                    }],
                                                                    
    // --- HUD STYLES ---
    
    // Thin Divider (Simple Light Line)
    hudThinDividerCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(255, 255, 255, 0.2)"
    }],

    // Horizontal Thick/Pane (Dark track, light borders, light dimple)
    hudThickDividerCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0, 0, 0, 0.15)",
        @"border-color": @"rgba(255, 255, 255, 0.15)",
        @"box-sizing": @"border-box",
        @"border-style": @"solid",
        @"border-top-width": @"1px",
        @"border-left-width": @"0px",
        @"border-right-width": @"0px",
        @"border-bottom-width": @"1px"
    } beforeDictionary:nil afterDictionary:@{
        @"border-color": @"rgba(255, 255, 255, 0.4)",
        @"background-color": @"rgba(255, 255, 255, 0.4)",
        @"width": @"6px",
        @"height": @"6px",
        @"box-sizing": @"border-box",
        @"border-style": @"solid",
        @"border-radius": @"50%",
        @"border-width": @"1px",
        @"content": @"''",
        @"left": @"0px",
        @"top": @"2px",
        @"right": @"0px",
        @"bottom": @"1px",
        @"margin": @"auto",
        @"position": @"absolute",
        @"z-index": @"300"
    }],

    // Vertical Thick/Pane (Dark track, light borders, light dimple)
    hudVerticalThickDividerCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0, 0, 0, 0.15)",
        @"border-color": @"rgba(255, 255, 255, 0.15)",
        @"box-sizing": @"border-box",
        @"border-style": @"solid",
        @"border-top-width": @"0px",
        @"border-left-width": @"1px",
        @"border-right-width": @"1px",
        @"border-bottom-width": @"0px"
    } beforeDictionary:nil afterDictionary:@{
        @"border-color": @"rgba(255, 255, 255, 0.4)",
        @"background-color": @"rgba(255, 255, 255, 0.4)",
        @"width": @"6px",
        @"height": @"6px",
        @"box-sizing": @"border-box",
        @"border-style": @"solid",
        @"border-radius": @"50%",
        @"border-width": @"1px",
        @"content": @"''",
        @"left": @"1px",
        @"top": @"0px",
        @"right": @"2px",
        @"bottom": @"0px",
        @"margin": @"auto",
        @"position": @"absolute",
        @"z-index": @"300"
    }];

    var themedSplitViewValues =
    [
     [@"divider-thickness", 1.0],
     [@"pane-divider-thickness", 10.0],
     [@"pane-divider-color", [CPColor colorWithRed:255.0 / 255.0 green:165.0 / 255.0 blue:165.0 / 255.0 alpha:1.0]],
     [@"horizontal-divider-color", horizontalDividerColor],
     [@"vertical-divider-color", verticalDividerColor],

     [@"divider-thickness",         9,                              CPThemeStateSplitViewDividerStyleThick],
     [@"divider-thickness",         1,                              CPThemeStateSplitViewDividerStyleThin],
     [@"divider-thickness",         10,                             CPThemeStateSplitViewDividerStylePaneSplitter],

     // Standard Colors
     [@"divider-color",             thickDividerCssColor,           CPThemeStateSplitViewDividerStyleThick],
     [@"divider-color",             verticalThickDividerCssColor,   [CPThemeStateSplitViewDividerStyleThick, CPThemeStateVertical]],
     [@"divider-color",             thinDividerCssColor,            CPThemeStateSplitViewDividerStyleThin],
     [@"divider-color",             paneDividerCssColor,            CPThemeStateSplitViewDividerStylePaneSplitter],
     [@"divider-color",             verticalPaneDividerCssColor,    [CPThemeStateSplitViewDividerStylePaneSplitter, CPThemeStateVertical]],

     // --- HUD Mappings ---
     // Thin Divider
     [@"divider-color",             hudThinDividerCssColor,         [CPThemeStateHUD, CPThemeStateSplitViewDividerStyleThin]],
     
     // Thick Divider (Horizontal & Vertical)
     [@"divider-color",             hudThickDividerCssColor,        [CPThemeStateHUD, CPThemeStateSplitViewDividerStyleThick]],
     [@"divider-color",             hudVerticalThickDividerCssColor,[CPThemeStateHUD, CPThemeStateSplitViewDividerStyleThick, CPThemeStateVertical]],
     
     // Pane Splitter (Horizontal & Vertical) - Uses same style as Thick for HUD
     [@"divider-color",             hudThickDividerCssColor,        [CPThemeStateHUD, CPThemeStateSplitViewDividerStylePaneSplitter]],
     [@"divider-color",             hudVerticalThickDividerCssColor,[CPThemeStateHUD, CPThemeStateSplitViewDividerStylePaneSplitter, CPThemeStateVertical]]
     ];

    [self registerThemeValues:themedSplitViewValues forView:splitView];

    return splitView;
}

+ (CPAlert)themedAlert
{
    var alert = [CPAlert new],
        buttonOffset = 10.0,
        defaultElementsMargin = 5.0, // Slightly increased spacing

        errorIcon = [CPImage imageWithCSSDictionary:@{
            @"background-image": svgAlertIconError,
            @"background-size": @"contain",
            @"background-repeat": @"no-repeat",
            @"background-position": @"center"
        } size:CGSizeMake(53, 46)],

        helpIcon = [CPImage imageWithCSSDictionary:@{
            @"background-image": svgAlertIconHelp,
            @"background-size": @"contain",
            @"background-repeat": @"no-repeat",
            @"background-position": @"center"
        } size:CGSizeMake(24, 24)],

        informationIcon = [CPImage imageWithCSSDictionary:@{
            @"background-image": svgAlertIconInformation,
            @"background-size": @"contain",
            @"background-repeat": @"no-repeat",
            @"background-position": @"center"
        } size:CGSizeMake(53, 46)],

        warningIcon = [CPImage imageWithCSSDictionary:@{
            @"background-image":svgAlertIconWarning,
            @"background-size": @"contain",
            @"background-repeat": @"no-repeat",
            @"background-position": @"center"
        } size:CGSizeMake(48, 43)],

        helpIconPressed = helpIcon,

        helpLeftOffset = 15,
        imageOffset = CGPointMake(20, 20), // Adjusted for better alignment
        informativeFont = [CPFont systemFontOfSize:CPFontCurrentSystemSize],
        
        // Standard Window Inset (Asymmetrical for icon)
        inset = CGInsetMake(15, 15, 15, 80),
        // HUD Window Inset (Symmetrical, visually pleasing for bubbles)
        hudInset = CGInsetMake(20, 20, 20, 20),
        
        messageFont = [CPFont boldSystemFontOfSize:CPFontDefaultSystemFontSize + 1],
        size = CGSizeMake(400.0, 120.0),
        suppressionButtonXOffset = 2.0,
        suppressionButtonYOffset = 10.0,
        suppressionButtonFont = [CPFont systemFontOfSize:CPFontCurrentSystemSize];

    themedAlertValues =
    [
     // Common / Standard
     [@"button-offset",                      buttonOffset],
     [@"content-inset",                      inset],
     [@"default-elements-margin",            defaultElementsMargin],
     [@"error-image",                        errorIcon],
     [@"help-image",                         helpIcon],
     [@"help-image-left-offset",             helpLeftOffset],
     [@"help-image-pressed",                 helpIconPressed],
     [@"image-offset",                       imageOffset],
     [@"information-image",                  informationIcon],
     [@"informative-text-alignment",         CPJustifiedTextAlignment],
     [@"informative-text-color",             [CPColor blackColor]],
     [@"informative-text-font",              informativeFont],
     [@"informative-text-shadow-color",      nil],
     [@"informative-text-shadow-offset",     CGSizeMakeZero()],
     
     [@"message-text-alignment",             CPJustifiedTextAlignment],
     [@"message-text-color",                 [CPColor blackColor]],
     [@"message-text-font",                  messageFont],
     [@"message-text-shadow-color",          nil],
     [@"message-text-shadow-offset",         CGSizeMakeZero()],

     [@"modal-window-button-margin-x",       -18.0],
     [@"modal-window-button-margin-y",       15.0],
     [@"suppression-button-text-color",      [CPColor blackColor]],
     [@"suppression-button-text-font",       suppressionButtonFont],
     [@"suppression-button-text-shadow-color", nil],
     [@"suppression-button-text-shadow-offset", CGSizeMakeZero()],
     [@"size",                               size],
     [@"suppression-button-x-offset",        suppressionButtonXOffset],
     [@"suppression-button-y-offset",        suppressionButtonYOffset],
     [@"warning-image",                      warningIcon],

     // --- HUD Specific Overrides ---
     // Balanced padding
     [@"content-inset",                      hudInset,               CPThemeStateHUD],
     
     // White text for dark background
     [@"message-text-color",                 [CPColor whiteColor],   CPThemeStateHUD],
     [@"informative-text-color",             [CPColor whiteColor],   CPThemeStateHUD],
     [@"suppression-button-text-color",      [CPColor whiteColor],   CPThemeStateHUD],

     // Text Shadows for readability on HUD
     [@"message-text-shadow-color",          [CPColor blackColor],   CPThemeStateHUD],
     [@"message-text-shadow-offset",         CGSizeMake(0, 1),       CPThemeStateHUD],
     [@"informative-text-shadow-color",      [CPColor blackColor],   CPThemeStateHUD],
     [@"informative-text-shadow-offset",     CGSizeMake(0, 1),       CPThemeStateHUD],
     [@"suppression-button-text-shadow-color", [CPColor blackColor], CPThemeStateHUD],
     [@"suppression-button-text-shadow-offset", CGSizeMake(0, 1),    CPThemeStateHUD],

     // Reset button margins for HUD as they are usually self-contained
     [@"modal-window-button-margin-x",       0.0,                   CPThemeStateHUD],
     [@"modal-window-button-margin-y",       0.0,                   CPThemeStateHUD]
     ];

    [self registerThemeValues:themedAlertValues forView:alert];

    return [alert themeView];
}

+ (CPStepper)themedStepper
{
    var stepper = [CPStepper stepper],

    // Helper to create the arrow CSS.
    arrowCSS = function(svg, color) {
        return @{
            @"content": @"''",
            @"width": @"100%",
            @"height": @"100%",
            @"top": @"0px",
            @"left": @"0px",
            @"position": @"absolute",
            @"z-index": @"300",

            "-webkit-mask-image": svg,
            "mask-image": svg,
            "-webkit-mask-size": @"100%",
            "mask-size": @"100%",
            "-webkit-mask-repeat": @"no-repeat",
            "mask-repeat": @"no-repeat",
            "-webkit-mask-position": @"center",
            "mask-position": @"center",

            @"background-color": color
        };
    },

    // --- Regular Size ---

    upCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorBackgroundWhite,
        @"border-color": A3ColorActiveBorder,
        @"border-style": @"solid",
        @"border-width": @"1px 1px 0px 1px",
        @"border-top-left-radius": @"3px",
        @"border-top-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowUp, A3ColorStepperArrow)],

    disabledUpCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorBackgroundInactive,
        @"border-color": A3ColorInactiveBorder,
        @"border-style": @"solid",
        @"border-width": @"1px 1px 0px 1px",
        @"border-top-left-radius": @"3px",
        @"border-top-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowUp, A3ColorInactiveDarkBorder)],

    highlightedUpCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorBorderBlueHighlighted,
        @"border-color": A3ColorBorderBlueHighlighted,
        @"border-style": @"solid",
        @"border-width": @"1px 1px 0px 1px",
        @"border-top-left-radius": @"3px",
        @"border-top-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowUp, A3ColorHighlightedStepperArrow)],

    downCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorBackgroundWhite,
        @"border-color": A3ColorActiveBorder,
        @"border-style": @"solid",
        @"border-width": @"0px 1px 1px 1px",
        @"border-bottom-left-radius": @"3px",
        @"border-bottom-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowDown, A3ColorStepperArrow)],

    disabledDownCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorBackgroundInactive,
        @"border-color": A3ColorInactiveBorder,
        @"border-style": @"solid",
        @"border-width": @"0px 1px 1px 1px",
        @"border-bottom-left-radius": @"3px",
        @"border-bottom-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowDown, A3ColorInactiveDarkBorder)],

    highlightedDownCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorBorderBlueHighlighted,
        @"border-color": A3ColorBorderBlueHighlighted,
        @"border-style": @"solid",
        @"border-width": @"0px 1px 1px 1px",
        @"border-bottom-left-radius": @"3px",
        @"border-bottom-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowDown, A3ColorHighlightedStepperArrow)],

    // --- HUD Regular Colors ---

    hudUpCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0,0,0,0.2)",
        @"border-color": @"rgba(255,255,255,0.3)",
        @"border-style": @"solid",
        @"border-width": @"1px 1px 0px 1px",
        @"border-top-left-radius": @"3px",
        @"border-top-right-radius": @"3px",
        @"border-bottom-left-radius": @"0px",
        @"border-bottom-right-radius": @"0px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowUp, @"#FFFFFF")],

    hudUpHighlightedCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0,0,0,0.4)",
        @"border-color": @"rgba(255,255,255,0.5)",
        @"border-style": @"solid",
        @"border-width": @"1px 1px 0px 1px",
        @"border-top-left-radius": @"3px",
        @"border-top-right-radius": @"3px",
        @"border-bottom-left-radius": @"0px",
        @"border-bottom-right-radius": @"0px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowUp, @"#FFFFFF")],

    hudUpDisabledCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0,0,0,0.1)",
        @"border-color": @"rgba(255,255,255,0.1)",
        @"border-style": @"solid",
        @"border-width": @"1px 1px 0px 1px",
        @"border-top-left-radius": @"3px",
        @"border-top-right-radius": @"3px",
        @"border-bottom-left-radius": @"0px",
        @"border-bottom-right-radius": @"0px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowUp, @"rgba(255,255,255,0.3)")],

    hudDownCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0,0,0,0.2)",
        @"border-color": @"rgba(255,255,255,0.3)",
        @"border-style": @"solid",
        @"border-width": @"0px 1px 1px 1px",
        @"border-top-left-radius": @"0px",
        @"border-top-right-radius": @"0px",
        @"border-bottom-left-radius": @"3px",
        @"border-bottom-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowDown, @"#FFFFFF")],

    hudDownHighlightedCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0,0,0,0.4)",
        @"border-color": @"rgba(255,255,255,0.5)",
        @"border-style": @"solid",
        @"border-width": @"0px 1px 1px 1px",
        @"border-top-left-radius": @"0px",
        @"border-top-right-radius": @"0px",
        @"border-bottom-left-radius": @"3px",
        @"border-bottom-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowDown, @"#FFFFFF")],

    hudDownDisabledCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0,0,0,0.1)",
        @"border-color": @"rgba(255,255,255,0.1)",
        @"border-style": @"solid",
        @"border-width": @"0px 1px 1px 1px",
        @"border-top-left-radius": @"0px",
        @"border-top-right-radius": @"0px",
        @"border-bottom-left-radius": @"3px",
        @"border-bottom-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowDown, @"rgba(255,255,255,0.3)")],

    // --- HUD Small Colors ---

    smallHudUpCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0,0,0,0.2)",
        @"border-color": @"rgba(255,255,255,0.3)",
        @"border-style": @"solid",
        @"border-width": @"1px 1px 0px 1px",
        @"border-top-left-radius": @"3px",
        @"border-top-right-radius": @"3px",
        @"border-bottom-left-radius": @"0px",
        @"border-bottom-right-radius": @"0px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowUp, @"#FFFFFF")],

    smallHudUpHighlightedCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0,0,0,0.4)",
        @"border-color": @"rgba(255,255,255,0.5)",
        @"border-style": @"solid",
        @"border-width": @"1px 1px 0px 1px",
        @"border-top-left-radius": @"3px",
        @"border-top-right-radius": @"3px",
        @"border-bottom-left-radius": @"0px",
        @"border-bottom-right-radius": @"0px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowUp, @"#FFFFFF")],

    smallHudUpDisabledCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0,0,0,0.1)",
        @"border-color": @"rgba(255,255,255,0.1)",
        @"border-style": @"solid",
        @"border-width": @"1px 1px 0px 1px",
        @"border-top-left-radius": @"3px",
        @"border-top-right-radius": @"3px",
        @"border-bottom-left-radius": @"0px",
        @"border-bottom-right-radius": @"0px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowUp, @"rgba(255,255,255,0.3)")],

    smallHudDownCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0,0,0,0.2)",
        @"border-color": @"rgba(255,255,255,0.3)",
        @"border-style": @"solid",
        @"border-width": @"0px 1px 1px 1px",
        @"border-top-left-radius": @"0px",
        @"border-top-right-radius": @"0px",
        @"border-bottom-left-radius": @"3px",
        @"border-bottom-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowDown, @"#FFFFFF")],

    smallHudDownHighlightedCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0,0,0,0.4)",
        @"border-color": @"rgba(255,255,255,0.5)",
        @"border-style": @"solid",
        @"border-width": @"0px 1px 1px 1px",
        @"border-top-left-radius": @"0px",
        @"border-top-right-radius": @"0px",
        @"border-bottom-left-radius": @"3px",
        @"border-bottom-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowDown, @"#FFFFFF")],

    smallHudDownDisabledCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0,0,0,0.1)",
        @"border-color": @"rgba(255,255,255,0.1)",
        @"border-style": @"solid",
        @"border-width": @"0px 1px 1px 1px",
        @"border-top-left-radius": @"0px",
        @"border-top-right-radius": @"0px",
        @"border-bottom-left-radius": @"3px",
        @"border-bottom-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowDown, @"rgba(255,255,255,0.3)")],

    // --- HUD Mini Colors ---

    miniHudUpCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0,0,0,0.2)",
        @"border-color": @"rgba(255,255,255,0.3)",
        @"border-style": @"solid",
        @"border-width": @"1px 1px 0px 1px",
        @"border-top-left-radius": @"3px",
        @"border-top-right-radius": @"3px",
        @"border-bottom-left-radius": @"0px",
        @"border-bottom-right-radius": @"0px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowUp, @"#FFFFFF")],

    miniHudUpHighlightedCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0,0,0,0.4)",
        @"border-color": @"rgba(255,255,255,0.5)",
        @"border-style": @"solid",
        @"border-width": @"1px 1px 0px 1px",
        @"border-top-left-radius": @"3px",
        @"border-top-right-radius": @"3px",
        @"border-bottom-left-radius": @"0px",
        @"border-bottom-right-radius": @"0px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowUp, @"#FFFFFF")],

    miniHudUpDisabledCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0,0,0,0.1)",
        @"border-color": @"rgba(255,255,255,0.1)",
        @"border-style": @"solid",
        @"border-width": @"1px 1px 0px 1px",
        @"border-top-left-radius": @"3px",
        @"border-top-right-radius": @"3px",
        @"border-bottom-left-radius": @"0px",
        @"border-bottom-right-radius": @"0px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowUp, @"rgba(255,255,255,0.3)")],

    miniHudDownCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0,0,0,0.2)",
        @"border-color": @"rgba(255,255,255,0.3)",
        @"border-style": @"solid",
        @"border-width": @"0px 1px 1px 1px",
        @"border-top-left-radius": @"0px",
        @"border-top-right-radius": @"0px",
        @"border-bottom-left-radius": @"3px",
        @"border-bottom-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowDown, @"#FFFFFF")],

    miniHudDownHighlightedCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0,0,0,0.4)",
        @"border-color": @"rgba(255,255,255,0.5)",
        @"border-style": @"solid",
        @"border-width": @"0px 1px 1px 1px",
        @"border-top-left-radius": @"0px",
        @"border-top-right-radius": @"0px",
        @"border-bottom-left-radius": @"3px",
        @"border-bottom-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowDown, @"#FFFFFF")],

    miniHudDownDisabledCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0,0,0,0.1)",
        @"border-color": @"rgba(255,255,255,0.1)",
        @"border-style": @"solid",
        @"border-width": @"0px 1px 1px 1px",
        @"border-top-left-radius": @"0px",
        @"border-top-right-radius": @"0px",
        @"border-bottom-left-radius": @"3px",
        @"border-bottom-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowDown, @"rgba(255,255,255,0.3)")],

    // --- Small Size ---

    smallUpCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorBackgroundWhite,
        @"border-color": A3ColorActiveBorder,
        @"border-style": @"solid",
        @"border-width": @"1px 1px 0px 1px",
        @"border-top-left-radius": @"3px",
        @"border-top-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowUp, A3ColorStepperArrow)],

    smallDisabledUpCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorBackgroundInactive,
        @"border-color": A3ColorInactiveBorder,
        @"border-style": @"solid",
        @"border-width": @"1px 1px 0px 1px",
        @"border-top-left-radius": @"3px",
        @"border-top-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowUp, A3ColorInactiveDarkBorder)],

    smallHighlightedUpCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorBorderBlueHighlighted,
        @"border-color": A3ColorBorderBlueHighlighted,
        @"border-style": @"solid",
        @"border-width": @"1px 1px 0px 1px",
        @"border-top-left-radius": @"3px",
        @"border-top-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowUp, A3ColorHighlightedStepperArrow)],

    smallDownCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorBackgroundWhite,
        @"border-color": A3ColorActiveBorder,
        @"border-style": @"solid",
        @"border-width": @"0px 1px 1px 1px",
        @"border-bottom-left-radius": @"3px",
        @"border-bottom-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowDown, A3ColorStepperArrow)],

    smallDisabledDownCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorBackgroundInactive,
        @"border-color": A3ColorInactiveBorder,
        @"border-style": @"solid",
        @"border-width": @"0px 1px 1px 1px",
        @"border-bottom-left-radius": @"3px",
        @"border-bottom-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowDown, A3ColorInactiveDarkBorder)],

    smallHighlightedDownCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorBorderBlueHighlighted,
        @"border-color": A3ColorBorderBlueHighlighted,
        @"border-style": @"solid",
        @"border-width": @"0px 1px 1px 1px",
        @"border-bottom-left-radius": @"3px",
        @"border-bottom-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowDown, A3ColorHighlightedStepperArrow)],

    // --- Mini Size ---

    miniUpCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorBackgroundWhite,
        @"border-color": A3ColorActiveBorder,
        @"border-style": @"solid",
        @"border-width": @"1px 1px 0px 1px",
        @"border-top-left-radius": @"3px",
        @"border-top-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowUp, A3ColorStepperArrow)],

    miniDisabledUpCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorBackgroundInactive,
        @"border-color": A3ColorInactiveBorder,
        @"border-style": @"solid",
        @"border-width": @"1px 1px 0px 1px",
        @"border-top-left-radius": @"3px",
        @"border-top-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowUp, A3ColorInactiveDarkBorder)],

    miniHighlightedUpCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorBorderBlueHighlighted,
        @"border-color": A3ColorBorderBlueHighlighted,
        @"border-style": @"solid",
        @"border-width": @"1px 1px 0px 1px",
        @"border-top-left-radius": @"3px",
        @"border-top-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowUp, A3ColorHighlightedStepperArrow)],

    miniDownCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorBackgroundWhite,
        @"border-color": A3ColorActiveBorder,
        @"border-style": @"solid",
        @"border-width": @"0px 1px 1px 1px",
        @"border-bottom-left-radius": @"3px",
        @"border-bottom-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowDown, A3ColorStepperArrow)],

    miniDisabledDownCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorBackgroundInactive,
        @"border-color": A3ColorInactiveBorder,
        @"border-style": @"solid",
        @"border-width": @"0px 1px 1px 1px",
        @"border-bottom-left-radius": @"3px",
        @"border-bottom-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowDown, A3ColorInactiveDarkBorder)],

    miniHighlightedDownCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorBorderBlueHighlighted,
        @"border-color": A3ColorBorderBlueHighlighted,
        @"border-style": @"solid",
        @"border-width": @"0px 1px 1px 1px",
        @"border-bottom-left-radius": @"3px",
        @"border-bottom-right-radius": @"3px",
        @"box-sizing": @"border-box"
    } beforeDictionary:nil afterDictionary:arrowCSS(svgArrowDown, A3ColorHighlightedStepperArrow)],

    themeValues =
    [
     [@"direct-nib2cib-adjustment",  YES],

     // CPThemeStateControlSizeRegular
     [@"bezel-color-up-button",      upCssColor,                            [CPThemeStateBordered]],
     [@"bezel-color-down-button",    downCssColor,                          [CPThemeStateBordered]],
     [@"bezel-color-up-button",      disabledUpCssColor,                    [CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color-down-button",    disabledDownCssColor,                  [CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color-up-button",      highlightedUpCssColor,                 [CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color-down-button",    highlightedDownCssColor,               [CPThemeStateBordered, CPThemeStateHighlighted]],

     // --- HUD Regular Mappings ---
     // We explicitly register Bordered combinations because CPDatePickers usually render steppers as "Bordered"
     // even in HUD mode, and specificity rules might otherwise pick the standard bordered look.

     // Up Button (Regular)
     [@"bezel-color-up-button",      hudUpCssColor,                         CPThemeStateHUD],
     [@"bezel-color-up-button",      hudUpCssColor,                         [CPThemeStateHUD, CPThemeStateBordered]],
     [@"bezel-color-up-button",      hudUpHighlightedCssColor,              [CPThemeStateHUD, CPThemeStateHighlighted]],
     [@"bezel-color-up-button",      hudUpHighlightedCssColor,              [CPThemeStateHUD, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color-up-button",      hudUpDisabledCssColor,                 [CPThemeStateHUD, CPThemeStateDisabled]],
     [@"bezel-color-up-button",      hudUpDisabledCssColor,                 [CPThemeStateHUD, CPThemeStateBordered, CPThemeStateDisabled]],

     // Down Button (Regular)
     [@"bezel-color-down-button",    hudDownCssColor,                       CPThemeStateHUD],
     [@"bezel-color-down-button",    hudDownCssColor,                       [CPThemeStateHUD, CPThemeStateBordered]],
     [@"bezel-color-down-button",    hudDownHighlightedCssColor,            [CPThemeStateHUD, CPThemeStateHighlighted]],
     [@"bezel-color-down-button",    hudDownHighlightedCssColor,            [CPThemeStateHUD, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color-down-button",    hudDownDisabledCssColor,               [CPThemeStateHUD, CPThemeStateDisabled]],
     [@"bezel-color-down-button",    hudDownDisabledCssColor,               [CPThemeStateHUD, CPThemeStateBordered, CPThemeStateDisabled]],

     [@"up-button-size",             CGSizeMake(13.0, 11.0)],
     [@"down-button-size",           CGSizeMake(13.0, 11.0)],
     [@"nib2cib-adjustment-frame",   CGRectMake(3.0, -24.0, -6.0, -4.0)],

     // CPThemeStateControlSizeSmall
     [@"bezel-color-up-button",      smallUpCssColor,                       [CPThemeStateControlSizeSmall, CPThemeStateBordered]],
     [@"bezel-color-down-button",    smallDownCssColor,                     [CPThemeStateControlSizeSmall, CPThemeStateBordered]],
     [@"bezel-color-up-button",      smallDisabledUpCssColor,               [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color-down-button",    smallDisabledDownCssColor,             [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color-up-button",      smallHighlightedUpCssColor,            [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color-down-button",    smallHighlightedDownCssColor,          [CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateHighlighted]],

     // --- HUD Small ---
     // Explicitly covering Bordered states to ensure HUD override
     // Up Button
     [@"bezel-color-up-button",      smallHudUpCssColor,                    [CPThemeStateHUD, CPThemeStateControlSizeSmall]],
     [@"bezel-color-up-button",      smallHudUpCssColor,                    [CPThemeStateHUD, CPThemeStateControlSizeSmall, CPThemeStateBordered]],
     [@"bezel-color-up-button",      smallHudUpHighlightedCssColor,         [CPThemeStateHUD, CPThemeStateControlSizeSmall, CPThemeStateHighlighted]],
     [@"bezel-color-up-button",      smallHudUpHighlightedCssColor,         [CPThemeStateHUD, CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color-up-button",      smallHudUpDisabledCssColor,            [CPThemeStateHUD, CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
     [@"bezel-color-up-button",      smallHudUpDisabledCssColor,            [CPThemeStateHUD, CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDisabled]],

     // Down Button
     [@"bezel-color-down-button",    smallHudDownCssColor,                  [CPThemeStateHUD, CPThemeStateControlSizeSmall]],
     [@"bezel-color-down-button",    smallHudDownCssColor,                  [CPThemeStateHUD, CPThemeStateControlSizeSmall, CPThemeStateBordered]],
     [@"bezel-color-down-button",    smallHudDownHighlightedCssColor,       [CPThemeStateHUD, CPThemeStateControlSizeSmall, CPThemeStateHighlighted]],
     [@"bezel-color-down-button",    smallHudDownHighlightedCssColor,       [CPThemeStateHUD, CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color-down-button",    smallHudDownDisabledCssColor,          [CPThemeStateHUD, CPThemeStateControlSizeSmall, CPThemeStateDisabled]],
     [@"bezel-color-down-button",    smallHudDownDisabledCssColor,          [CPThemeStateHUD, CPThemeStateControlSizeSmall, CPThemeStateBordered, CPThemeStateDisabled]],

     [@"up-button-size",             CGSizeMake(11.0, 10.0),                CPThemeStateControlSizeSmall],
     [@"down-button-size",           CGSizeMake(11.0, 9.0),                 CPThemeStateControlSizeSmall],
     [@"nib2cib-adjustment-frame",   CGRectMake(2.0, -21.0, -4.0, -3.0),    CPThemeStateControlSizeSmall],

     // CPThemeStateControlSizeMini
     [@"bezel-color-up-button",      miniUpCssColor,                        [CPThemeStateControlSizeMini, CPThemeStateBordered]],
     [@"bezel-color-down-button",    miniDownCssColor,                      [CPThemeStateControlSizeMini, CPThemeStateBordered]],
     [@"bezel-color-up-button",      miniDisabledUpCssColor,                [CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color-down-button",    miniDisabledDownCssColor,              [CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateDisabled]],
     [@"bezel-color-up-button",      miniHighlightedUpCssColor,             [CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color-down-button",    miniHighlightedDownCssColor,           [CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateHighlighted]],

     // --- HUD Mini ---
     // Explicitly covering Bordered states to ensure HUD override
     // Up Button
     [@"bezel-color-up-button",      miniHudUpCssColor,                     [CPThemeStateHUD, CPThemeStateControlSizeMini]],
     [@"bezel-color-up-button",      miniHudUpCssColor,                     [CPThemeStateHUD, CPThemeStateControlSizeMini, CPThemeStateBordered]],
     [@"bezel-color-up-button",      miniHudUpHighlightedCssColor,          [CPThemeStateHUD, CPThemeStateControlSizeMini, CPThemeStateHighlighted]],
     [@"bezel-color-up-button",      miniHudUpHighlightedCssColor,          [CPThemeStateHUD, CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color-up-button",      miniHudUpDisabledCssColor,             [CPThemeStateHUD, CPThemeStateControlSizeMini, CPThemeStateDisabled]],
     [@"bezel-color-up-button",      miniHudUpDisabledCssColor,             [CPThemeStateHUD, CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateDisabled]],

     // Down Button
     [@"bezel-color-down-button",    miniHudDownCssColor,                   [CPThemeStateHUD, CPThemeStateControlSizeMini]],
     [@"bezel-color-down-button",    miniHudDownCssColor,                   [CPThemeStateHUD, CPThemeStateControlSizeMini, CPThemeStateBordered]],
     [@"bezel-color-down-button",    miniHudDownHighlightedCssColor,        [CPThemeStateHUD, CPThemeStateControlSizeMini, CPThemeStateHighlighted]],
     [@"bezel-color-down-button",    miniHudDownHighlightedCssColor,        [CPThemeStateHUD, CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateHighlighted]],
     [@"bezel-color-down-button",    miniHudDownDisabledCssColor,           [CPThemeStateHUD, CPThemeStateControlSizeMini, CPThemeStateDisabled]],
     [@"bezel-color-down-button",    miniHudDownDisabledCssColor,           [CPThemeStateHUD, CPThemeStateControlSizeMini, CPThemeStateBordered, CPThemeStateDisabled]],

     [@"up-button-size",             CGSizeMake(9.0, 8.0),                  CPThemeStateControlSizeMini],
     [@"down-button-size",           CGSizeMake(9.0, 7.0),                  CPThemeStateControlSizeMini],
     [@"nib2cib-adjustment-frame",   CGRectMake(2.0, -15.0, -4.0, 0.0),     CPThemeStateControlSizeMini]
     ];

    [self registerThemeValues:themeValues forView:stepper];

    return stepper;
}

+ (CPRuleEditor)themedRuleEditor
{
    var ruleEditor = [[CPRuleEditor alloc] initWithFrame:CGRectMake(0.0, 0.0, 400.0, 300.0)],
    backgroundColors = [[CPColor whiteColor], [CPColor colorWithRed:235 / 255 green:239 / 255 blue:252 / 255 alpha:1]],
    selectedActiveRowColor = [CPColor colorWithHexString:@"5f83b9"],
    selectedInactiveRowColor = [CPColor colorWithWhite:0.83 alpha:1],
    sliceTopBorderColor = [CPColor colorWithWhite:0.9 alpha:1.0],
    sliceBottomBorderColor = [CPColor colorWithWhite:0.729412 alpha:1.0],
    sliceLastBottomBorderColor = [CPColor colorWithWhite:0.6 alpha:1.0],
    
    // SVGs for buttons
    buttonAddImage = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgPlus,
        "mask-image": svgPlus,
        "background-color": A3ColorActiveText,
        "-webkit-mask-size": "contain",
        "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat",
        "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center",
        "mask-position": "center"
    } size:CGSizeMake(12, 12)],

    buttonRemoveImage = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgMinus,
        "mask-image": svgMinus,
        "background-color": A3ColorActiveText,
        "-webkit-mask-size": "contain",
        "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat",
        "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center",
        "mask-position": "center"
    } size:CGSizeMake(12, 12)],

    fontColor = [CPColor colorWithWhite:150 / 255 alpha:1],

    ruleEditorThemedValues =
    [
     [@"alternating-row-colors",         backgroundColors],
     [@"selected-color",                 selectedActiveRowColor,                 CPThemeStateNormal],
     [@"selected-color",                 selectedInactiveRowColor,               CPThemeStateDisabled],
     [@"slice-top-border-color",         sliceTopBorderColor],
     [@"slice-bottom-border-color",      sliceBottomBorderColor],
     [@"slice-last-bottom-border-color", sliceLastBottomBorderColor],
     [@"font",                           [CPFont systemFontOfSize:10.0]],
     [@"font-color",                     fontColor],
     [@"add-image",                      buttonAddImage,                         CPThemeStateNormal],
     [@"remove-image",                   buttonRemoveImage,                      CPThemeStateNormal],
     [@"vertical-alignment",             CPCenterVerticalTextAlignment]
     ];

    [self registerThemeValues:ruleEditorThemedValues forView:ruleEditor];

    return ruleEditor;
}

+ (_CPToolTipWindowView)themedTooltip
{
    var toolTipView = [[_CPToolTipWindowView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 100.0) styleMask:_CPToolTipWindowMask],

    themeValues =
    [
     [@"stroke-color",       [CPColor colorWithHexString:@"B0B0B0"]],
     [@"stroke-width",       1.0],
     [@"border-radius",      2.0],
     [@"background-color",   [CPColor colorWithHexString:@"FFFFCA"]],
     [@"color",              [CPColor blackColor]]
     ];

    [self registerThemeValues:themeValues forView:toolTipView];

    return toolTipView;
}

+ (CPColorWell)themedColorWell
{
    // The CPColorPanel CPColorWell depends on requires CPApp.
    [CPApplication sharedApplication];

    var colorWell = [[CPColorWell alloc] initWithFrame:CGRectMake(0.0, 0.0, 60.0, 24.0)],

    bezelColor = [CPColor colorWithCSSDictionary:@{
        @"border": @"1px solid " + A3ColorBorderDark,
        @"background-color": A3ColorBackgroundWhite
    }],

    themedColorWellValues = [
                             [@"bezel-color",            bezelColor,                         CPThemeStateBordered],
                             [@"content-inset",          CGInsetMake(5.0, 5.0, 5.0, 5.0),    CPThemeStateBordered],
                             [@"content-border-inset",   CGInsetMake(5.0, 5.0, 4.0, 5.0),    CPThemeStateBordered]
                             ];

    [self registerThemeValues:themedColorWellValues forView:colorWell];

    return colorWell;
}

+ (CPProgressIndicator)themedBarProgressIndicator
{
    var progressBar = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
    [progressBar setDoubleValue:30];

    // --- Standard Colors ---
    var bezelColor = [CPColor colorWithCSSDictionary:@{
            @"border": @"1px solid " + A3ColorBorderDark,
            @"background-color": A3ColorBackgroundWhite,
            @"border-radius": @"3px",
            @"box-sizing": @"border-box"
        }],

        barColor = [CPColor colorWithCSSDictionary:@{
            @"background-color": @"#5982DA",
            @"border-radius": @"2px"
        }],

    // --- HUD Colors ---
        hudBezelColor = [CPColor colorWithCSSDictionary:@{
            @"background-color": @"rgba(0, 0, 0, 0.2)",
            @"border": @"1px solid rgba(255, 255, 255, 0.2)",
            @"border-radius": @"3px",
            @"box-sizing": @"border-box",
            @"box-shadow": @"inset 0 1px 2px rgba(0,0,0,0.1)"
        }],

        hudBarColor = [CPColor colorWithCSSDictionary:@{
            @"background-color": @"rgba(255, 255, 255, 0.9)",
            @"border-radius": @"2px",
            @"box-shadow": @"0 0 4px rgba(255, 255, 255, 0.4)"
        }];

    themedProgressIndicator =
    [
     // Standard State
     [@"bezel-color",       bezelColor],
     [@"bar-color",         barColor],
     
     // HUD State
     [@"bezel-color",       hudBezelColor,  CPThemeStateHUD],
     [@"bar-color",         hudBarColor,    CPThemeStateHUD],

     // Control Sizes (Heights)
     [@"default-height",    20.0], // Regular
     [@"default-height",    16.0,           CPThemeStateControlSizeSmall],
     [@"default-height",    10.0,           CPThemeStateControlSizeMini]
     ];

    [self registerThemeValues:themedProgressIndicator forView:progressBar];

    return progressBar;
}

// ThemeDescriptors.j

+ (CPProgressIndicator)themedIndeterminateBarProgressIndicator
{
    var progressBar = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
    [progressBar setIndeterminate:YES];

    // --- Standard Colors (Blue with White Stripes) ---
    var bezelColor = [CPColor colorWithCSSDictionary:@{
            @"border": @"1px solid " + A3ColorBorderDark,
            @"background-color": A3ColorBackgroundWhite,
            @"border-radius": @"3px",
            @"box-sizing": @"border-box"
        }],

        // Gradient: Blue base + diagonal white stripes
        // Uses the class-defined animation 'cp-progress-indicator-bar-slide'
        barColor = [CPColor colorWithCSSDictionary:@{
            @"background-color": @"#5982DA",
            @"background-image": @"linear-gradient(45deg, rgba(255, 255, 255, 0.15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, 0.15) 50%, rgba(255, 255, 255, 0.15) 75%, transparent 75%, transparent)",
            @"background-size": @"30px 30px",
            @"border-radius": @"2px",
            @"animation": @"cp-progress-indicator-bar-slide 1s linear infinite",
            @"-webkit-animation": @"cp-progress-indicator-bar-slide 1s linear infinite"
        }],

    // --- HUD Colors (White with Dark Stripes) ---
        hudBezelColor = [CPColor colorWithCSSDictionary:@{
            @"background-color": @"rgba(0, 0, 0, 0.2)",
            @"border": @"1px solid rgba(255, 255, 255, 0.2)",
            @"border-radius": @"3px",
            @"box-sizing": @"border-box",
            @"box-shadow": @"inset 0 1px 2px rgba(0,0,0,0.1)"
        }],

        // Gradient: White base + diagonal dark stripes (faint)
        hudBarColor = [CPColor colorWithCSSDictionary:@{
            @"background-color": @"rgba(255, 255, 255, 0.8)",
            @"background-image": @"linear-gradient(45deg, rgba(0, 0, 0, 0.1) 25%, transparent 25%, transparent 50%, rgba(0, 0, 0, 0.1) 50%, rgba(0, 0, 0, 0.1) 75%, transparent 75%, transparent)",
            @"background-size": @"30px 30px",
            @"border-radius": @"2px",
            @"box-shadow": @"0 0 4px rgba(255, 255, 255, 0.4)",
            @"animation": @"cp-progress-indicator-bar-slide 1s linear infinite",
            @"-webkit-animation": @"cp-progress-indicator-bar-slide 1s linear infinite"
        }];

    themedIndeterminateProgressIndicator =
    [
     // Standard State
     [@"bezel-color",               bezelColor],
     [@"indeterminate-bar-color",   barColor],
     
     // HUD State
     [@"bezel-color",               hudBezelColor,  CPThemeStateHUD],
     [@"indeterminate-bar-color",   hudBarColor,    CPThemeStateHUD],

     // Control Sizes
     [@"default-height",            20.0], // Regular
     [@"default-height",            16.0,           CPThemeStateControlSizeSmall],
     [@"default-height",            10.0,           CPThemeStateControlSizeMini]
     ];

    [self registerThemeValues:themedIndeterminateProgressIndicator forView:progressBar];

    return progressBar;
}

+ (CPProgressIndicator)themedSpinningProgressIndicator
{
    var progressBar = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    [progressBar setStyle:CPProgressIndicatorSpinningStyle];
    [progressBar setIndeterminate:YES];
    [progressBar startAnimation:nil];

    // Standard Colors (Grey)
    var spinnerColor        = [CPColor colorWithHexString:@"888888"],
        spinnerTrackColor   = [CPColor colorWithHexString:@"e6e6e6"],
    
    // HUD Colors (White/Transparent)
        hudSpinnerColor      = [CPColor whiteColor],
        hudSpinnerTrackColor = [CPColor colorWithWhite:1.0 alpha:0.2];

    var themeValues =
    [
     // --- Standard Theme ---
     [@"spinner-color",         spinnerColor],
     [@"spinner-track-color",   spinnerTrackColor],

     // Line widths based on size
     [@"spinner-line-width",    4.0],                               // Regular
     [@"spinner-line-width",    3.0,    CPThemeStateControlSizeSmall], // Small
     [@"spinner-line-width",    2.0,    CPThemeStateControlSizeMini],  // Mini

     // --- HUD Theme ---
     [@"spinner-color",         hudSpinnerColor,        CPThemeStateHUD],
     [@"spinner-track-color",   hudSpinnerTrackColor,   CPThemeStateHUD]
     ];

    [self registerThemeValues:themeValues forView:progressBar];

    return progressBar;
}

+ (CPProgressIndicator)themedCircularProgressIndicator
{
    var progressBar = [[CPProgressIndicator alloc] initWithFrame:CGRectMake(0, 0, 32, 32)];
    [progressBar setStyle:CPProgressIndicatorSpinningStyle];
    [progressBar setIndeterminate:NO];

    var themeValues =
    [
     [@"circular-border-color", [CPColor colorWithHexString:@"A0A0A0"]],
     [@"circular-border-size", 1],
     [@"circular-color", [CPColor colorWithHexString:@"5982DA"]]
     ];

    [self registerThemeValues:themeValues forView:progressBar];

    return progressBar;
}

+ (CPBox)themedBox
{
    var box = [[CPBox alloc] initWithFrame:CGRectMake(0, 0, 100, 100)],

    // Standard Style
    backgroundColor = [CPColor colorWithCSSDictionary:@{
                                                         @"background-color": @"rgba(0,0,0,0.04)",
                                                         @"border-color": @"rgba(0,0,0,0.1)",
                                                         @"border-style": @"solid",
                                                         @"border-width": @"1px",
                                                         @"border-radius": @"5px",
                                                         @"box-sizing": @"border-box"
                                                         }],
    borderColor = [CPColor colorWithCSSDictionary:@{
                                                     @"background-color": @"rgba(0,0,0,0.1)"
                                                    }],

    // --- HUD Styles ---
    hudBackgroundColor = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": @"rgba(0, 0, 0, 0.25)",
                                                            @"border-color": @"rgba(255, 255, 255, 0.45)", // Increased from 0.25 to 0.45 for visibility
                                                            @"border-style": @"solid",
                                                            @"border-width": @"1px",
                                                            @"border-radius": @"5px",
                                                            @"box-sizing": @"border-box"
                                                        }],
    
    // For CPBoxSeparator and custom borders in HUD
    hudBorderColor = [CPColor colorWithCSSDictionary:@{
                                                        @"background-color": @"rgba(255, 255, 255, 0.45)"
                                                    }],
    themeValues =
    [
     [@"background-color", backgroundColor],
     [@"border-color",     borderColor],
     [@"border-width",     1.0],
     [@"content-margin",   CGSizeMakeZero()],
     
     [@"title-font",       [CPFont systemFontOfSize:11]],
     [@"title-left-offset", 10.0],
     [@"title-top-offset", -3.0],
     [@"title-color",      A3CPColorActiveText],

     [@"nib2cib-adjustment-primary-frame",   CGRectMake(3, -4, -6, -6)], 
     [@"content-adjustment", CGRectMake(-1, -1, 2, 2)],
     [@"min-y-correction-no-title", 1],
     [@"min-y-correction-title", 2],

     // --- HUD MAPPINGS ---
     [@"background-color", hudBackgroundColor,      CPThemeStateHUD],
     [@"border-color",     hudBorderColor,          CPThemeStateHUD],
     [@"title-color",      [CPColor whiteColor],    CPThemeStateHUD]
     ];

    [self registerThemeValues:themeValues forView:box];

    return box;
}

+ (CPLevelIndicator)themedLevelIndicator
{
    var levelIndicator = [[CPLevelIndicator alloc] initWithFrame:CGRectMake(0, 0, 100, 100)],

    bezelColor = [CPColor colorWithCSSDictionary:@{
        @"border": @"1px solid " + A3ColorBorderDark
    }],

    // --- Standard Colors (Traffic Light) ---
    // Using CSS Dictionary for consistency and sharp rendering
    greenColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"#6CC644" // Green
    }],
    
    yellowColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"#F7D325" // Yellow
    }],
    
    redColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"#BD2C00" // Red
    }],

    // --- HUD Styles ---
    hudBezelColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0, 0, 0, 0.2)",
        @"border": @"1px solid rgba(255, 255, 255, 0.2)",
        @"box-sizing": @"border-box",
        @"box-shadow": @"inset 0 1px 2px rgba(0,0,0,0.1)"
    }],

    // Monochrome white for HUD
    hudSegmentColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(255, 255, 255, 0.9)",
        @"box-shadow": @"0 0 2px rgba(255, 255, 255, 0.4)"
    }],

    themeValues =
    [
     [@"bezel-color",    bezelColor],
     [@"color-empty",    [CPColor clearColor]],
     
     // Standard State: Traffic Light Colors
     [@"color-normal",   greenColor],
     [@"color-warning",  yellowColor],
     [@"color-critical", redColor],
     
     [@"spacing",        1.0],

     // --- HUD Mappings ---
     [@"bezel-color",    hudBezelColor,      CPThemeStateHUD],
     
     // In HUD mode, we force all states (normal, warning, critical) to use the same monochrome HUD color
     [@"color-normal",   hudSegmentColor,    CPThemeStateHUD],
     [@"color-warning",  hudSegmentColor,    CPThemeStateHUD],
     [@"color-critical", hudSegmentColor,    CPThemeStateHUD]
     ];

    [self registerThemeValues:themeValues forView:levelIndicator];

    return levelIndicator;
}

+ (CPShadowView)themedShadowView
{
    var shadowView = [[CPShadowView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100, 100)],

    // Using CSS box-shadow
    lightColor = [CPColor colorWithCSSDictionary:@{
        @"box-shadow": @"0 0 5px rgba(0,0,0,0.3)"
    }],

    heavyColor = [CPColor colorWithCSSDictionary:@{
        @"box-shadow": @"0 0 10px rgba(0,0,0,0.5)"
    }],

    themedShadowViewValues =
    [
     [@"bezel-color",        heavyColor],
     [@"content-inset",      CGInsetMake(5.0, 7.0, 5.0, 7.0)],

     [@"bezel-color",        lightColor,                         CPThemeStateShadowViewLight],
     [@"bezel-color",        heavyColor,                         CPThemeStateShadowViewHeavy],

     [@"content-inset",      CGInsetMake(3.0, 3.0, 5.0, 3.0),    CPThemeStateShadowViewLight],
     [@"content-inset",      CGInsetMake(5.0, 7.0, 5.0, 7.0),    CPThemeStateShadowViewHeavy]
     ];

    [self registerThemeValues:themedShadowViewValues forView:shadowView];

    return shadowView;
}

+ (CPBrowser)themedBrowser
{
    var browser = [[CPBrowser alloc] initWithFrame:CGRectMake(0.0, 0.0, 100, 100.0)],

    // SVGs for browser
    imageResize = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgDoubleArrow, 
        "mask-image": svgDoubleArrow,
        "background-color": A3ColorActiveText,
        "-webkit-mask-size": "contain",
        "mask-size": "contain",
        "-webkit-mask-repeat": "no-repeat",
        "mask-repeat": "no-repeat",
        "-webkit-mask-position": "center",
        "mask-position": "center",
        "transform": "rotate(90deg)"
    } size:CGSizeMake(15, 14)],
    
    imageLeaf = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgRadioDot, // Placeholder leaf
        "mask-image": svgRadioDot,
        "background-color": A3ColorActiveText
    } size:CGSizeMake(9, 9)],

    themedBrowser =
    [
     ["image-control-resize", imageResize],
     ["image-control-leaf", imageLeaf],
     ["image-control-leaf-pressed", imageLeaf]
     ];

    [self registerThemeValues:themedBrowser forView:browser];

    return browser;
}

#pragma mark -
#pragma mark Windows

+ (_CPModalWindowView)themedModalWindowView
{
    var modalWindowView = [[_CPModalWindowView alloc] initWithFrame:CGRectMake(0, 0, 200, 200) styleMask:_CPModalWindowView];

    // Using pure CSS window frame
    var bezelColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorBackground,
        @"border": @"1px solid " + A3ColorWindowBorder,
        @"border-radius": @"6px",
        @"box-shadow": @"0 5px 15px rgba(0,0,0,0.5)"
    }],

    themeValues =
    [
     [@"bezel-color", bezelColor]
     ];

    [self registerThemeValues:themeValues forView:modalWindowView];

    return modalWindowView;
}

+ (_CPWindowView)themedWindowView
{
    var windowView = [[_CPWindowView alloc] initWithFrame:CGRectMakeZero(0.0, 0.0, 200, 200)],

    sheetShadow = [CPColor colorWithCSSDictionary:@{
                                                    @"background-color":    A3ColorBackground,
                                                    @"background-image":    @"linear-gradient(to bottom, rgba(216,216,216,1), rgba(216,216,216,0))"
                                                    }],

    resizeIndicator = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": @"url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMiAxMiI+PHBhdGggZD0iTTEwIDEwTDIgMTBtOCAwaDB2LTh6IiBzdHJva2U9IiM2NjYiIHN0cm9rZS13aWR0aD0iMiIgZmlsbD0ibm9uZSIvPjwvc3ZnPg==')",
        "mask-image": @"url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMiAxMiI+PHBhdGggZD0iTTEwIDEwTDIgMTBtOCAwaDB2LTh6IiBzdHJva2U9IiM2NjYiIHN0cm9rZS13aWR0aD0iMiIgZmlsbD0ibm9uZSIvPjwvc3ZnPg==')",
        "background-color": A3ColorActiveText
    } size:CGSizeMake(12, 12)],

    // Global
    themedWindowViewValues =
    [
     [@"shadow-inset",                   CGInsetMake(0, 0, 0, 0)],
     [@"shadow-distance",                5],
     [@"window-shadow-color",            @"0px 5px 10px 0px rgba(0, 0, 0, 0.25)"],
     [@"resize-indicator",               resizeIndicator],
     [@"attached-sheet-shadow-color",    sheetShadow,           CPThemeStateNormal],
     [@"shadow-height",                  5],
     [@"shadown-horizontal-offset",      2],
     [@"sheet-vertical-offset",          -1],
     [@"size-indicator",                 CGSizeMake(12, 12)],
     [@"border-top-left-radius",         @"0px"], 
     [@"border-top-right-radius",        @"0px"], 
     [@"border-bottom-left-radius",      @"7px"],
     [@"border-bottom-right-radius",     @"7px"]
     ];

    [self registerThemeValues:themedWindowViewValues forView:windowView];

    return windowView;
}

+ (_CPHUDWindowView)themedHUDWindowView
{
    var HUDWindowView = [[_CPHUDWindowView alloc] initWithFrame:CGRectMake(0, 0, 200, 200) styleMask:CPHUDBackgroundWindowMask | CPClosableWindowMask],
    
    HUDBezelColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0, 0, 0, 0.85)",
        @"border-radius": @"5px"
    }],

    closeImage = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgCancel,
        "mask-image": svgCancel,
        "transition": @"background-color 0.2s ease-in-out",
        "background-color": A3ColorWhite
    } size:CGSizeMake(14, 14)],

    closeActiveImage = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgCancel,
        "mask-image": svgCancel,
        "transition": @"background-color 0.2s ease-in-out",
        "background-color": @"rgba(255, 200, 200, 1.0)" // reddish
    } size:CGSizeMake(14, 14)],

    themeValues =
    [
     [@"close-image-size",           CGSizeMake(16.0, 18.0)],
     [@"close-image-origin",         CGPointMake(6.0,4.0)],
     [@"close-image",                closeImage],
     [@"close-active-image",         closeActiveImage],
     [@"bezel-color",                HUDBezelColor],
     [@"title-font",                 [CPFont systemFontOfSize:14]],
     [@"title-text-color",           [CPColor colorWithWhite:255.0 / 255.0 alpha:1]],
     [@"title-text-color",           [CPColor colorWithWhite:255.0 / 255.0 alpha:1], CPThemeStateKeyWindow],
     [@"title-text-color",           [CPColor colorWithWhite:255.0 / 255.0 alpha:1], CPThemeStateMainWindow],
     [@"title-text-shadow-color",    [CPColor blackColor]],
     [@"title-text-shadow-offset",   CGSizeMake(0.0, 1.0)],
     [@"title-alignment",            CPCenterTextAlignment],
     [@"title-line-break-mode",      CPLineBreakByTruncatingTail],
     [@"title-vertical-alignment",   CPCenterVerticalTextAlignment],
     [@"title-bar-height",           26]
     ];

    [self registerThemeValues:themeValues forView:HUDWindowView inherit:themedWindowViewValues];

    [HUDWindowView setTitle:@"HUDWindow"];

    return HUDWindowView;
}

+ (_CPStandardWindowView)themedStandardWindowView
{
    var standardWindowView = [[_CPStandardWindowView alloc] initWithFrame:CGRectMake(0, 0, 200, 200) styleMask:CPClosableWindowMask],

    // --- Colors ---
    bezelHeadCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorWindowHeadActive,
        @"border-top-color": A3ColorWindowBorder,
        @"border-top-style": @"solid",
        @"border-top-width": @"1px",
        @"border-left-color": A3ColorWindowBorder,
        @"border-left-style": @"solid",
        @"border-left-width": @"1px",
        @"border-right-color": A3ColorWindowBorder,
        @"border-right-style": @"solid",
        @"border-right-width": @"1px",
        @"border-top-left-radius": @"6px",
        @"border-top-right-radius": @"6px",
        @"border-bottom-left-radius": @"0px",
        @"border-bottom-right-radius": @"0px",
        @"box-sizing": @"border-box"
    }],

    inactiveBezelHeadCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorWindowHeadInactive,
        @"border-top-color": A3ColorWindowBorder,
        @"border-top-style": @"solid",
        @"border-top-width": @"1px",
        @"border-left-color": A3ColorWindowBorder,
        @"border-left-style": @"solid",
        @"border-left-width": @"1px",
        @"border-right-color": A3ColorWindowBorder,
        @"border-right-style": @"solid",
        @"border-right-width": @"1px",
        @"border-top-left-radius": @"6px",
        @"border-top-right-radius": @"6px",
        @"border-bottom-left-radius": @"0px",
        @"border-bottom-right-radius": @"0px",
        @"box-sizing": @"border-box"
    }],

    solidCssColor = [CPColor colorWithCSSDictionary:@{ @"background-color": A3ColorBackgroundHighlighted }],

    bezelCssColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorBackground,
        @"border-color": A3ColorWindowBorder,
        @"border-style": @"solid",
        @"border-width": @"1px",
        @"border-top-left-radius": @"0px",
        @"border-top-right-radius": @"0px",
        @"border-bottom-left-radius": @"7px",
        @"border-bottom-right-radius": @"7px",
        @"box-sizing": @"border-box"
    }],

    dividerCssColor = [CPColor colorWithCSSDictionary:@{ @"background-color": A3ColorBorderMedium }],

    // --- BUTTON IMAGES (Normal) ---
    // Note: We include 'transition' for smooth fade between normal and active
    
    closeButtonImage = [CPImage imageWithCSSDictionary:@{
        @"background-color": A3ColorWindowButtonClose,
        @"border-radius": @"50%",
        @"width": @"12px",
        @"height": @"12px",
        @"transition": @"background-color 0.15s ease-in-out"
    } size:CGSizeMake(12,12)],

    minimizeButtonImage = [CPImage imageWithCSSDictionary:@{
        @"background-color": A3ColorWindowButtonMin,
        @"border-radius": @"50%",
        @"width": @"12px",
        @"height": @"12px",
        @"transition": @"background-color 0.15s ease-in-out"
    } size:CGSizeMake(12,12)],

    zoomButtonImage = [CPImage imageWithCSSDictionary:@{
        @"background-color": A3ColorWindowButtonZoom,
        @"border-radius": @"50%",
        @"width": @"12px",
        @"height": @"12px",
        @"transition": @"background-color 0.15s ease-in-out"
    } size:CGSizeMake(12,12)],

    // --- BUTTON IMAGES (Active/Highlighted) ---
    
    closeButtonImageHighlighted = [CPImage imageWithCSSDictionary:@{
        @"background-color": A3ColorWindowButtonCloseDark,
        @"border-radius": @"50%",
        @"width": @"12px",
        @"height": @"12px"
    } size:CGSizeMake(12,12)],

    minimizeButtonImageHighlighted = [CPImage imageWithCSSDictionary:@{
        @"background-color": A3ColorWindowButtonMinDark,
        @"border-radius": @"50%",
        @"width": @"12px",
        @"height": @"12px"
    } size:CGSizeMake(12,12)],

    zoomButtonImageHighlighted = [CPImage imageWithCSSDictionary:@{
        @"background-color": A3ColorWindowButtonZoomDark,
        @"border-radius": @"50%",
        @"width": @"12px",
        @"height": @"12px"
    } size:CGSizeMake(12,12)],

    resizeIndicator = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": @"url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMiAxMiI+PHBhdGggZD0iTTEwIDEwTDIgMTBtOCAwaDB2LTh6IiBzdHJva2U9IiM2NjYiIHN0cm9rZS13aWR0aD0iMiIgZmlsbD0ibm9uZSIvPjwvc3ZnPg==')",
        "mask-image": @"url('data:image/svg+xml;charset=utf-8;base64,PHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCAxMiAxMiI+PHBhdGggZD0iTTEwIDEwTDIgMTBtOCAwaDB2LTh6IiBzdHJva2U9IiM2NjYiIHN0cm9rZS13aWR0aD0iMiIgZmlsbD0ibm9uZSIvPjwvc3ZnPg==')",
        "background-color": A3ColorActiveText
    } size:CGSizeMake(12, 12)],

    themeValues =
    [
     [@"gradient-height",            31.0],
     [@"bezel-head-color",           inactiveBezelHeadCssColor, CPThemeStateNormal],
     [@"bezel-head-color",           bezelHeadCssColor, CPThemeStateKeyWindow],
     [@"bezel-head-color",           bezelHeadCssColor, CPThemeStateMainWindow],
     [@"bezel-head-sheet-color",     [CPColor redColor]],
     [@"solid-color",                solidCssColor],

     [@"title-font",                 [CPFont systemFontOfSize:CPFontCurrentSystemSize+1]],
     [@"title-text-color",           A3CPColorInactiveText],
     [@"title-text-color",           A3CPColorActiveText, CPThemeStateKeyWindow],
     [@"title-text-color",           A3CPColorActiveText, CPThemeStateMainWindow],
     [@"title-text-shadow-color",    nil],
     [@"title-text-shadow-offset",   CGSizeMakeZero()],
     [@"title-alignment",            CPCenterTextAlignment],
     [@"title-line-break-mode",      CPLineBreakByTruncatingTail],
     [@"title-vertical-alignment",   CPCenterVerticalTextAlignment],

     [@"divider-color",                         dividerCssColor],
     [@"body-color",                            bezelCssColor],
     [@"title-bar-height",                      31],
     [@"title-margin",                          4],
     [@"frame-outset",                          CGInsetMake(1, 1, 1, 1)],

     // --- REGISTER BUTTON IMAGES ---
     
     // 1. Normal State
     [@"close-image-button",                    closeButtonImage],
     [@"minimize-image-button",                 minimizeButtonImage],
     [@"zoom-image-button",                     zoomButtonImage],

     // 2. Highlighted (Pressed) State
     // Use the specific keys defined in _CPStandardWindowView source
     [@"close-image-highlighted-button",        closeButtonImageHighlighted],
     [@"minimize-image-highlighted-button",     minimizeButtonImageHighlighted],
     [@"zoom-image-highlighted-button",         zoomButtonImageHighlighted],

     [@"close-image-size",                      CGSizeMake(12.0, 12.0)],
     [@"close-image-origin",                    CGPointMake(10.0, 10.0)],
     [@"minimize-image-size",                   CGSizeMake(12.0, 12.0)],
     [@"minimize-image-origin",                 CGPointMake(30.0, 10.0)],
     [@"zoom-image-size",                       CGSizeMake(12.0, 12.0)],
     [@"zoom-image-origin",                     CGPointMake(50.0, 10.0)],

     [@"resize-indicator",                      resizeIndicator],
     [@"size-indicator",                        CGSizeMake(12, 12)]
     ];

    [self registerThemeValues:themeValues forView:standardWindowView inheritFrom:[self themedWindowView]];

    return standardWindowView;
}

+ (_CPDocModalWindowView)themedDocModalWindowView
{
    var docModalWindowView = [[_CPDocModalWindowView alloc] initWithFrame:CGRectMake(0, 0, 200, 200) styleMask:nil];

    // Apply the same styling as the standard Modal Window to cover the background
    var bezelColor = [CPColor colorWithCSSDictionary:@{
                                                            @"background-color": A3ColorBackgroundWhite,
                                                            @"border": @"1px solid " + A3ColorWindowBorder,
                                                            @"border-radius": @"6px",
                                                            @"box-shadow": @"0 5px 15px rgba(0,0,0,0.5)"
                                                        }];

    var themeValues = [
        [@"bezel-color", bezelColor],
        [@"body-color", [CPColor whiteColor]],
        [@"shadow-height", 0.0],
        [@"title-bar-height", 0.0]
    ];

    [self registerThemeValues:themeValues forView:docModalWindowView];

    return docModalWindowView;
}

+ (_CPBorderlessBridgeWindowView)themedBorderlessBridgeWindowView
{
    var bordelessBridgeWindowView = [[_CPBorderlessBridgeWindowView alloc] initWithFrame:CGRectMake(0,0,0,0)],

    toolbarBackgroundColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": A3ColorBackground
    }],
    hudBezelColor = [CPColor colorWithCSSDictionary:@{
        @"background-color": @"rgba(0, 0, 0, 0.85)",
        @"border-radius": @"5px"
    }],

    themeValues =
    [
     [@"toolbar-background-color", toolbarBackgroundColor],
     [@"bezel-color", hudBezelColor, CPThemeStateHUD]
    ];

    [self registerThemeValues:themeValues forView:bordelessBridgeWindowView inherit:themedWindowViewValues];

    return bordelessBridgeWindowView;
}

#pragma mark -

+ (_CPToolbarView)themedToolbarView
{
    var toolbarView = [[_CPToolbarView alloc] initWithFrame:CGRectMake(0.0, 0.0, 100.0, 59.0)],

    toolbarExtraItemsImage = [CPImage imageWithCSSDictionary:@{
        "-webkit-mask-image": svgDoubleArrow, 
        "mask-image": svgDoubleArrow,
        "background-color": A3ColorActiveText
    } size:CGSizeMake(10, 15)],
    
    toolbarExtraItemsAlternateImage = toolbarExtraItemsImage,
    
    toolbarSeparatorColor = [CPColor colorWithCSSDictionary:@{
        @"border-left": @"1px solid " + A3ColorBorderLight
    }],

    themeValues =
    [
     [@"extra-item-extra-image",                 toolbarExtraItemsImage],
     [@"extra-item-extra-alternate-image",       toolbarExtraItemsAlternateImage],
     [@"item-margin",                            10.0],
     [@"extra-item-width",                       20.0],
     [@"content-inset",                          CGInsetMake(4.0, 4.0, 4.0, 10)],
     [@"regular-size-height",                    59.0],
     [@"small-size-height",                      46.0],
     [@"image-item-separator-color",             toolbarSeparatorColor],
     [@"image-item-separator-size",              CGRectMake(0.0, 0.0, 2.0, 32.0)]
     ];


    [self registerThemeValues:themeValues forView:toolbarView];

    return toolbarView;
}

#pragma mark -
#pragma mark Menus

+ (_CPMenuItemMenuBarView)themedMenuItemMenuBarView
{
    var menuItemMenuBarView = [[_CPMenuItemMenuBarView alloc] initWithFrame:CGRectMake(0.0, 0.0, 16.0, 16.0)],

    themeValues =
    [
     [@"horizontal-margin",             9.0],
     [@"submenu-indicator-margin",      3.0],
     [@"vertical-margin",               3.0] 
     ];

    [self registerThemeValues:themeValues forView:menuItemMenuBarView];

    return menuItemMenuBarView;
}

+ (_CPMenuItemStandardView)themedMenuItemStandardView
{
    var menuItemStandardView = [[_CPMenuItemStandardView alloc] initWithFrame:CGRectMake(0.0, 0.0, 16.0, 16.0)],

    menuItemDefaultOnStateImage = [CPImage imageWithCSSDictionary:@{
                                                    "-webkit-mask-image": svgCheckmark,
                                                    "mask-image": svgCheckmark,
                                                    "background-color": A3ColorMenuCheckmark,
                                                    "-webkit-mask-size": "contain",
                                                    "mask-size": "contain",
                                                    "-webkit-mask-repeat": "no-repeat",
                                                    "mask-repeat": "no-repeat",
                                                    "-webkit-mask-position": "center",
                                                    "mask-position": "center"
                                                    }
                                                 size:CGSizeMake(14,14)],

    menuItemDefaultOnStateHighlightedImage = [CPImage imageWithCSSDictionary:@{
                                                    "-webkit-mask-image": svgCheckmark,
                                                    "mask-image": svgCheckmark,
                                                    "background-color": A3ColorBackgroundWhite,
                                                    "-webkit-mask-size": "contain",
                                                    "mask-size": "contain",
                                                    "-webkit-mask-repeat": "no-repeat",
                                                    "mask-repeat": "no-repeat",
                                                    "-webkit-mask-position": "center",
                                                    "mask-position": "center"
                                                    }
                                                            size:CGSizeMake(14,14)],

    menuItemDefaultMixedStateImage = [CPImage imageWithCSSDictionary:@{
                                                    "-webkit-mask-image": svgDash,
                                                    "mask-image": svgDash,
                                                    "background-color": A3ColorMenuCheckmark,
                                                    "-webkit-mask-size": "contain",
                                                    "mask-size": "contain",
                                                    "-webkit-mask-repeat": "no-repeat",
                                                    "mask-repeat": "no-repeat",
                                                    "-webkit-mask-position": "center",
                                                    "mask-position": "center"
                                                    }
                                                    size:CGSizeMake(14,14)],

    menuItemDefaultMixedStateHighlightedImage = [CPImage imageWithCSSDictionary:@{
                                                    "-webkit-mask-image": svgDash,
                                                    "mask-image": svgDash,
                                                    "background-color": A3ColorBackgroundWhite,
                                                    "-webkit-mask-size": "contain",
                                                    "mask-size": "contain",
                                                    "-webkit-mask-repeat": "no-repeat",
                                                    "mask-repeat": "no-repeat",
                                                    "-webkit-mask-position": "center",
                                                    "mask-position": "center"
                                                    }
                                                                           size:CGSizeMake(14,14)],

    submenuIndicatorImage = [CPImage imageWithCSSDictionary:@{
                                                    "-webkit-mask-image": svgArrowRight,
                                                    "mask-image": svgArrowRight,
                                                    "background-color": A3ColorMenuCheckmark,
                                                    "-webkit-mask-size": "contain",
                                                    "mask-size": "contain",
                                                    "-webkit-mask-repeat": "no-repeat",
                                                    "mask-repeat": "no-repeat",
                                                    "-webkit-mask-position": "center",
                                                    "mask-position": "center"
                                                    }
                                                       size:CGSizeMake(8, 10)],

    submenuIndicatorHighlightedImage = [CPImage imageWithCSSDictionary:@{
                                                    "-webkit-mask-image": svgArrowRight,
                                                    "mask-image": svgArrowRight,
                                                    "background-color": A3ColorBackgroundWhite,
                                                    "-webkit-mask-size": "contain",
                                                    "mask-size": "contain",
                                                    "-webkit-mask-repeat": "no-repeat",
                                                    "mask-repeat": "no-repeat",
                                                    "-webkit-mask-position": "center",
                                                    "mask-position": "center"
                                                    }
                                                                  size:CGSizeMake(8, 10)],
     menuItemHUDOnStateImage = [CPImage imageWithCSSDictionary:@{
                                                                        "-webkit-mask-image": svgCheckmark,
                                                                        "mask-image": svgCheckmark,
                                                                        "background-color": A3ColorWhite, // White Checkmark
                                                                        "-webkit-mask-size": "contain",
                                                                        "mask-size": "contain",
                                                                        "-webkit-mask-repeat": "no-repeat",
                                                                        "mask-repeat": "no-repeat",
                                                                        "-webkit-mask-position": "center",
                                                                        "mask-position": "center"
                                                                    } size:CGSizeMake(14,14)],

    menuItemHUDMixedStateImage = [CPImage imageWithCSSDictionary:@{
                                                                        "-webkit-mask-image": svgDash,
                                                                        "mask-image": svgDash,
                                                                        "background-color": A3ColorWhite, // White Dash
                                                                        "-webkit-mask-size": "contain",
                                                                        "mask-size": "contain",
                                                                        "-webkit-mask-repeat": "no-repeat",
                                                                        "mask-repeat": "no-repeat",
                                                                        "-webkit-mask-position": "center",
                                                                        "mask-position": "center"
                                                                    } size:CGSizeMake(14,14)],

    themeValues =
    [
     [@"submenu-indicator-color",                                   A3CPColorActiveText],
     [@"menu-item-selection-color",                                 @"A3CPColorBorderBlue"],
     [@"menu-item-text-color",                                      @"A3CPColorActiveText"],
     [@"menu-item-disabled-text-color",                             A3CPColorInactiveText],
     [@"menu-item-text-shadow-color",                               nil],
     [@"menu-item-default-off-state-image",                         [CPImage dummyCSSImageOfSize:CGSizeMake(14,14)]],
     [@"menu-item-default-off-state-highlighted-image",             [CPImage dummyCSSImageOfSize:CGSizeMake(14,14)]],

     [@"menu-item-default-on-state-image",                          menuItemDefaultOnStateImage],
     [@"menu-item-default-on-state-highlighted-image",              menuItemDefaultOnStateHighlightedImage],

     [@"menu-item-default-mixed-state-image",                       menuItemDefaultMixedStateImage],
     [@"menu-item-default-mixed-state-highlighted-image",           menuItemDefaultMixedStateHighlightedImage],

     [@"submenu-indicator-image",                                   submenuIndicatorImage],
     [@"submenu-indicator-highlighted-image",                       submenuIndicatorHighlightedImage],

     [@"menu-item-separator-color",                                 A3CPColorInactiveBorder],
     [@"menu-item-separator-height",                                2.0],
     [@"menu-item-separator-view-height",                           12.0],
     [@"left-margin",                                               1.0],
     [@"right-margin",                                              17.0],
     [@"state-column-width",                                        19.0],
     [@"indentation-width",                                         12.0],

     [@"vertical-margin",                                           1.0],
     [@"vertical-offset",                                           -1.0],

     [@"right-columns-margin",                                      30.0],

     // HUD
     [@"menu-item-text-color",                                      A3CPColorActiveTextHighlighted, CPThemeStateHUD],
     [@"menu-item-default-on-state-image",    menuItemHUDOnStateImage, CPThemeStateHUD],
     [@"menu-item-default-mixed-state-image", menuItemHUDMixedStateImage, CPThemeStateHUD],
     [@"submenu-indicator-color",             A3CPColorActiveTextHighlighted, CPThemeStateHUD],
    ];

    [self registerThemeValues:themeValues forView:menuItemStandardView];

    return menuItemStandardView;
}

+ (_CPMenuView)themedMenuView
{
    var menuView = [[_CPMenuView alloc] initWithFrame:CGRectMake(0.0, 0.0, 200.0, 100.0)],

    // Standard Arrows (Dark)
    menuWindowMoreAboveImage = [CPImage imageWithCSSDictionary:@{
                                                                 "-webkit-mask-image": svgArrowUp,
                                                                 "mask-image": svgArrowUp,
                                                                 "background-color": A3ColorMenuCheckmark,
                                                                 "-webkit-mask-size": "16px 16px",
                                                                 "mask-size": "16px 16px",
                                                                 "-webkit-mask-repeat": "no-repeat",
                                                                 "mask-repeat": "no-repeat",
                                                                 "-webkit-mask-position": "center",
                                                                 "mask-position": "center",
                                                                 "width": "100%",
                                                                 "height": "100%"
                                                                 }
                                                          size:CGSizeMake(40, 24)],

    menuWindowMoreBelowImage = [CPImage imageWithCSSDictionary:@{
                                                                 "-webkit-mask-image": svgArrowDown,
                                                                 "mask-image": svgArrowDown,
                                                                 "background-color": A3ColorMenuCheckmark,
                                                                 "-webkit-mask-size": "16px 16px",
                                                                 "mask-size": "16px 16px",
                                                                 "-webkit-mask-repeat": "no-repeat",
                                                                 "mask-repeat": "no-repeat",
                                                                 "-webkit-mask-position": "center",
                                                                 "mask-position": "center",
                                                                 "width": "100%",
                                                                 "height": "100%"
                                                                 }
                                                          size:CGSizeMake(40, 24)],

    // HUD Arrows (White)
    menuWindowMoreAboveImageHUD = [CPImage imageWithCSSDictionary:@{
                                                                 "-webkit-mask-image": svgArrowUp,
                                                                 "mask-image": svgArrowUp,
                                                                 "background-color": @"#ffffff",
                                                                 "-webkit-mask-size": "16px 16px",
                                                                 "mask-size": "16px 16px",
                                                                 "-webkit-mask-repeat": "no-repeat",
                                                                 "mask-repeat": "no-repeat",
                                                                 "-webkit-mask-position": "center",
                                                                 "mask-position": "center",
                                                                 "width": "100%",
                                                                 "height": "100%"
                                                                 }
                                                          size:CGSizeMake(40, 24)],

    menuWindowMoreBelowImageHUD = [CPImage imageWithCSSDictionary:@{
                                                                 "-webkit-mask-image": svgArrowDown,
                                                                 "mask-image": svgArrowDown,
                                                                 "background-color": @"#ffffff",
                                                                 "-webkit-mask-size": "16px 16px",
                                                                 "mask-size": "16px 16px",
                                                                 "-webkit-mask-repeat": "no-repeat",
                                                                 "mask-repeat": "no-repeat",
                                                                 "-webkit-mask-position": "center",
                                                                 "mask-position": "center",
                                                                 "width": "100%",
                                                                 "height": "100%"
                                                                 }
                                                          size:CGSizeMake(40, 24)],

    // Define the HUD Window style (The container)
    // Dark background (95% opaque black) + Light Gray Border (30% opaque white)
    menuWindowPopUpBackgroundStyleColorHUD = [CPColor colorWithCSSDictionary:@{
                                                                                    @"background-color": @"rgba(30, 30, 30, 0.95)", 
                                                                                    @"border-color": @"rgba(255, 255, 255, 0.3)",   
                                                                                    @"border-style": @"solid",
                                                                                    @"border-width": @"1px",
                                                                                    @"border-radius": @"6px",
                                                                                    @"box-shadow": @"0 5px 15px rgba(0,0,0,0.6)",
                                                                                    @"box-sizing": @"border-box"
                                                                                }],

    generalIconNew = [CPImage imageWithCSSDictionary:@{"background-color": A3ColorActiveText} size:CGSizeMake(16,16)],
    
    menuWindowPopUpBackgroundStyleColor = [CPColor colorWithCSSDictionary:@{
                                                                            @"background-color": A3ColorMenuLightBackground, 
                                                                            @"border-color": A3ColorMenuBorder,
                                                                            @"border-style": @"solid",
                                                                            @"border-width": @"1px",
                                                                            @"border-top-left-radius": @"6px",
                                                                            @"border-top-right-radius": @"6px",
                                                                            @"border-bottom-left-radius": @"7px",
                                                                            @"border-bottom-right-radius": @"7px",
                                                                            @"box-sizing": @"border-box" 
                                                                            }],

    menuWindowMenuBarBackgroundStyleColor = [CPColor colorWithCSSDictionary:@{
                                                                              @"background-color": A3ColorMenuLightBackground, 
                                                                              @"border-top-color": A3ColorBackground,
                                                                              @"border-bottom-color": A3ColorMenuBorder,
                                                                              @"border-left-color": A3ColorMenuBorder,
                                                                              @"border-right-color": A3ColorMenuBorder,
                                                                              @"border-style": @"solid",
                                                                              @"border-top-width": @"0px",
                                                                              @"border-left-width": @"1px",
                                                                              @"border-right-width": @"1px",
                                                                              @"border-bottom-width": @"1px",
                                                                              @"border-top-left-radius": @"0px",
                                                                              @"border-top-right-radius": @"0px",
                                                                              @"border-bottom-left-radius": @"7px",
                                                                              @"border-bottom-right-radius": @"7px",
                                                                              @"box-sizing": @"border-box" 
                                                                              }],

    menuBarWindowBackgroundColor = [CPColor colorWithCSSDictionary:@{
                                                                     @"background-color": A3ColorMenuLightBackground, 
                                                                     @"border-bottom-color": A3ColorMenuBorder, 
                                                                     @"border-bottom-style": @"solid",
                                                                     @"border-bottom-width": @"1px",
                                                                     @"border-radius": @"0px",
                                                                     @"box-sizing": @"border-box"
                                                                     }],

    menuBarWindowBackgroundSelectedColor = [CPColor colorWithCSSDictionary:@{
                                                                             @"background-color": A3ColorBorderBlueHighlighted,
                                                                             @"border-bottom-color": A3ColorBackgroundHighlighted,
                                                                             @"border-bottom-style": @"solid",
                                                                             @"border-bottom-width": @"1px",
                                                                             @"box-sizing": @"border-box"
                                                                             }],

    themeValues =
    [
     [@"menu-window-more-above-image",                       menuWindowMoreAboveImage], 
     [@"menu-window-more-below-image",                       menuWindowMoreBelowImage], 
     [@"menu-window-pop-up-background-style-color",          menuWindowPopUpBackgroundStyleColor],
     [@"menu-window-menu-bar-background-style-color",        menuWindowMenuBarBackgroundStyleColor],
     [@"menu-window-margin-inset",                           CGInsetMake(4.0, 0.0, 6.0, 0.0)], 
     [@"menu-window-scroll-indicator-height",                24.0],
     [@"menu-window-submenu-delta-x",                        -2.0],
     [@"menu-window-submenu-delta-y",                        -4.0], 
     [@"menu-window-submenu-first-level-delta-y",            -1.0],

     [@"menu-bar-window-background-color",                   menuBarWindowBackgroundColor],
     [@"menu-bar-window-background-selected-color",          menuBarWindowBackgroundSelectedColor],
     [@"menu-bar-window-font",                               [CPFont systemFontOfSize:13.0]], 
     [@"menu-bar-window-first-item-font",                    [CPFont boldSystemFontOfSize:13.0]],
     [@"menu-bar-window-height",                             23.0], 
     [@"menu-bar-window-margin",                             10.0],
     [@"menu-bar-window-left-margin",                        10.0],
     [@"menu-bar-window-right-margin",                       10.0],

     [@"menu-bar-text-color",                                @"A3CPColorActiveText"], 
     [@"menu-bar-title-color",                               [CPColor redColor]], 
     [@"menu-bar-text-shadow-color",                         nil], 
     [@"menu-bar-title-shadow-color",                        nil], 
     [@"menu-bar-highlight-color",                           menuBarWindowBackgroundSelectedColor],
     [@"menu-bar-highlight-text-color",                      A3CPColorDefaultText], 
     [@"menu-bar-highlight-text-shadow-color",               nil], 
     [@"menu-bar-height",                                    23.0], 
     [@"menu-bar-icon-image",                                nil],
     [@"menu-bar-icon-image-alpha-value",                    1.0],

     [@"menu-general-icon-new",                              generalIconNew],

     [@"menu-window-pop-up-background-style-color", menuWindowPopUpBackgroundStyleColorHUD, CPThemeStateHUD],

     [@"menu-bar-text-color",                       [CPColor whiteColor],                   CPThemeStateHUD],
     [@"menu-window-more-above-image",              menuWindowMoreAboveImageHUD,            CPThemeStateHUD],
     [@"menu-window-more-below-image",              menuWindowMoreBelowImageHUD,            CPThemeStateHUD]
    ];

    [self registerThemeValues:themeValues forView:menuView];

    return menuView;
}

#pragma mark -

+ (_CPPopoverWindowView)themedPopoverWindowView
{
    var popoverWindowView = [[_CPPopoverWindowView alloc] initWithFrame:CGRectMake(0, 0, 200, 200) styleMask:nil],

    gradient = CGGradientCreateWithColorComponents(
                                                   CGColorSpaceCreateDeviceRGB(),
                                                   [
                                                    (254.0 / 255), (254.0 / 255), (254.0 / 255), 0.93,
                                                    (241.0 / 255), (241.0 / 255), (241.0 / 255), 0.93
                                                    ],
                                                   [0, 1],
                                                   2
                                                   ),

    gradientHUD = CGGradientCreateWithColorComponents(
                                                      CGColorSpaceCreateDeviceRGB(),
                                                      [
                                                       (38.0 / 255), (38.0 / 255), (38.0 / 255), 0.93,
                                                       (18.0 / 255), (18.0 / 255), (18.0 / 255), 0.93
                                                       ],
                                                      [0, 1],
                                                      2),

    strokeColor = [CPColor colorWithHexString:@"B8B8B8"],
    strokeColorHUD = [CPColor colorWithHexString:@"222222"],

    themeValues =
    [
     [@"border-radius",              5.0],
     [@"stroke-width",               1.0],
     [@"shadow-size",                CGSizeMake(0, 6)],
     [@"shadow-blur",                15.0],
     [@"background-gradient",        gradient],
     [@"background-gradient-hud",    gradientHUD],
     [@"stroke-color",               strokeColor],
     [@"stroke-color-hud",           strokeColorHUD]
     ];

    [self registerThemeValues:themeValues forView:popoverWindowView];

    return popoverWindowView;
}

+ (CPTabView)themedTabView
{
    var tabView = [[CPTabView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];

    themeValues =
    [
     [@"nib2cib-adjustment-frame",  CGRectMake(7.0, -10.0, -14.0, -16.0)], 
     [@"should-center-on-border",   YES],
     [@"box-content-inset",         CGInsetMake(16, 4, 4, 2)] 
     ];

    [self registerThemeValues:themeValues forView:tabView];

    return tabView;
}

@end
