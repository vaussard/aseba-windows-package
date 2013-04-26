 /*
	Aseba - an event-based framework for distributed robot control
	Copyright (C) 2007--2011:
		Stephane Magnenat <stephane at magnenat dot net>
		(http://stephane.magnenat.net)
		and other contributors, see authors.txt for details
	
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU Lesser General Public License as published
	by the Free Software Foundation, version 3 of the License.
	
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU Lesser General Public License for more details.
	
	You should have received a copy of the GNU Lesser General Public License
	along with this program. If not, see <http://www.gnu.org/licenses/>.
*/

!include "GetTime.nsh"

; Offer the user with several pre-defined installations
!ifndef DEVEL_PACKAGE
InstType $(STR_InstallFull)
InstType $(STR_InstallRecommended)
InstType $(STR_InstallMin)
!endif

Section "-Init before install" InitBeforeInst	; Hidden section -> always executed
	; Create the output directory, if it doesn't exist
	SetOutPath "$INSTDIR"

	; Enable logging
	LogSet ${LOG_TO_FILE}

	; Get UTC Time
	${GetTime} "" "LS" $0 $1 $2 $3 $4 $5 $6
	; $0="01"      day
	; $1="04"      month
	; $2="2005"    year
	; $3="Friday"  day of week name
	; $4="11"      hour
	; $5="05"      minute
	; $6="50"      seconds
 
	LogText ""
	LogText "***********************************************************************"
	LogText ""
	LogText "Starting new installation."
	LogText "Aseba Windows ${VERSION}"
	LogText "Date: $0/$1/$2 ($3) $4:$5:$6 (UTC)"

SectionEnd
	
; Small trick to have this function in both the installer / uninstaller
!macro CleanShortcuts un
Function ${un}CleanShortcuts
	DetailPrint $(STR_Clean)

	DetailPrint $(STR_Uninst_Menu)
	; Try both current user / all users
	SetShellVarContext all		; current / all. Install program for all users
	!insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder
	RMDir /r "$SMPROGRAMS\$StartMenuFolder"

	SetShellVarContext current		; current / all. Install program for all users
	!insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder
	RMDir /r "$SMPROGRAMS\$StartMenuFolder"
	
	DetailPrint $(STR_Done)
FunctionEnd
!macroend

!ifndef DEVEL_PACKAGE
	!insertmacro CleanShortcuts ""
	!insertmacro CleanShortcuts "un."
!endif

Function WriteVersionFile
	LogText "Writing version.txt"
	FileOpen $0 "$INSTDIR\version.txt" w 	; Overwrite
	FileWrite $0 "${VERSION}"
	FileClose $0
FunctionEnd

!ifndef DEVEL_PACKAGE
Function nsInstallType
	!insertmacro MUI_HEADER_TEXT $(STR_Install_Type) $(STR_Components)
	nsDialogs::Create 1018
	Pop $Dialog

	${If} $Dialog == error
		Abort
	${EndIf}

	; Thymio install
	${NSD_CreateBitmap} 6% 0 35% 45% ""
	Pop $ImageThymio
	${NSD_SetStretchedImage} $ImageThymio $PLUGINSDIR\thymio2.bmp $ImageThymioHandle

	${NSD_CreateButton} 42% 0% 50% 45% $(STR_Robot_Install)
	Pop $ButtonFull
	${NSD_OnClick} $ButtonFull cbButtonFull
	
	; HLine	
	${NSD_CreateHLine} 0% 47% 100% 1% ""
	Pop $HLine
	
	; Aseba-only install
	${NSD_CreateBitmap} 6% 50% 35% 45% ""
	Pop $ImageStudio
	${NSD_SetStretchedImage} $ImageStudio $PLUGINSDIR\studio.bmp $ImageStudioHandle
	
	${NSD_CreateButton} 42% 50% 50% 45% $(STR_Aseba_Install)
	Pop $ButtonMin
	${NSD_OnClick} $ButtonMin cbButtonMin
	
	; Disable the "Next" button
	GetDlgItem $0 $HWNDPARENT 1 # next/install button
	EnableWindow $0 0

	nsDialogs::Show	
FunctionEnd

Function cbButtonFull
	StrCpy $FullInstall "true"
	SendMessage $HWNDPARENT "0x408" "1" ""
FunctionEnd

Function cbButtonMin
	StrCpy $FullInstall "false"
	SendMessage $HWNDPARENT "0x408" "1" ""
FunctionEnd
!endif
