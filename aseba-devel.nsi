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

;--------------------------------
;Includes

  !include "MUI2.nsh"		; Modern UI 2
;  !include "x64.nsh"		; x64 support
  !include nsDialogs.nsh	; custom dialogs
  !include LogicLib.nsh		; ${If} statement

; Compression
  SetCompressor /SOLID lzma

;--------------------------------
;General

  ; Some defines
  ;!define DEBUG_PACKAGE			; Won't include heavy files to speed-up debug process (reduce compression time)
									; --> Comment this line out for release
;  !define VERSION "1.0.0-git-dev"
;  !define ASEBA_SRC ".\src\aseba\aseba"		; SVN
  !define DEV_VERSION							; Take into account new features
  !define ASEBA_SRC "..\git\aseba"				; Git
  !define ASEBA_BIN "..\git\aseba-build"			; Git
  !define ASEBA_DEP "..\src\dependencies"
  !define DASHEL_SRC "..\src\dashel\dashel"		; Dashel svn
  !include "${ASEBA_BIN}\version.nsi"			; Get NSIS style version number
  !define LOG_TO_FILE on 		; on / off. You need a special build of NSIS with logging enabled. To be downloaded on the NSIS website
  ShowInstDetails show
  ShowUninstDetails show

  ;Default installation folder
  InstallDir "$DOCUMENTS\AsebaDev"
  
;--------------------------------
;Variables

;  Var StartMenuFolder

;--------------------------------
;Interface Settings

  !define MUI_ABORTWARNING

;--------------------------------
;Pages

  !define MUI_WELCOMEPAGE_TITLE_3LINES		; Add extra space for the title on the welcome page
  !insertmacro MUI_PAGE_WELCOME
  
  ; Licence
  !define MUI_LICENSEPAGE_TEXT_TOP $(STR_License_Top)
  !insertmacro MUI_PAGE_LICENSE $(license)
  
  ; Components
  !insertmacro MUI_PAGE_COMPONENTS
  
  ; Choose directory
  !insertmacro MUI_PAGE_DIRECTORY
  
  !insertmacro MUI_PAGE_INSTFILES
  
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

;--------------------------------
;Language macros (from http://nsis.sourceforge.net/Creating_language_files_and_integrating_with_MUI)

!macro LANG_LOAD LANGLOAD
  !insertmacro MUI_LANGUAGE "${LANGLOAD}"
  !verbose push
  !verbose off
  !include "translations\${LANGLOAD}.nsh"
  !verbose pop
  !undef LANG
!macroend
 
!macro LANG_STRING NAME VALUE
  LangString "${NAME}" "${LANG_${LANG}}" "${VALUE}"
!macroend
 
!macro LANG_UNSTRING NAME VALUE
  !insertmacro LANG_STRING "un.${NAME}" "${VALUE}"
!macroend

!insertmacro LANG_LOAD "English"		; translations/English.nsh
!insertmacro LANG_LOAD "French"			; translations/French.nsh

; License: only the english license is used, because FSF strongly discourage using an unofficial translation
LicenseLangString license ${LANG_ENGLISH} "${ASEBA_SRC}\license.txt"
LicenseLangString license ${LANG_FRENCH}  "${ASEBA_SRC}\license.txt"

;Convenience macro
!macro ASEBA_INSTALL_HEADER DIRECTORY
	SetOutPath "$INSTDIR\include\aseba\${DIRECTORY}"
	File "${ASEBA_SRC}\${DIRECTORY}\*.h"
!macroend

!macro ASEBA_INSTALL_HEADER_FILE DIRECTORY FILE
	SetOutPath "$INSTDIR\include\aseba\${DIRECTORY}"
	File "${ASEBA_SRC}\${DIRECTORY}\${FILE}"
!macroend

;--------------------------------
;Name and file (Defined here to be translation-enabled)

  !define MY_NAME $(STR_Package_Name_Devel)
  OutFile "aseba-devel-${VERSION}-win32.exe"
  Name ${MY_NAME}

;--------------------------------
;Installer Sections

!include "GetTime.nsh"

Section "-Init before install" InitBeforeInst	; Hidden section -> always executed
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
	LogText "Aseba Windows Devel ${VERSION}"
	LogText "Date: $0/$1/$2 ($3) $4:$5:$6 (UTC)"
SectionEnd
	
Function WriteVersionFile
	LogText "Writing version.txt"
	FileOpen $0 "$INSTDIR\version.txt" w 	; Overwrite
	FileWrite $0 "${VERSION}"
	FileClose $0
FunctionEnd

Section "-main" 
	SetOutPath "$INSTDIR"
	
	;Ensure a clean folder
	RMDir /r "$INSTDIR"

	;Version file (version.txt)
	Call WriteVersionFile
		
	File "${ASEBA_DEP}\devel\README.txt"

	;Create uninstaller
	WriteUninstaller "$INSTDIR\Uninstall.exe"
SectionEnd

SectionGroup "!Libraries" GroupLib
	Section "!Dashel" SecDashel
		SetOutPath "$INSTDIR\lib"

		# Main files
		; File "${DASHEL_SRC}\libdashel.a"
		File "${DASHEL_SRC}\lib*.a"
	SectionEnd

	Section "!Aseba" SecAseba
		SetOutPath "$INSTDIR\lib"

		# Main files
		File "${ASEBA_BIN}\lib*.a"
	SectionEnd
SectionGroupEnd

SectionGroup "!Headers" GroupHeaders
	Section "!Dashel" SecHeaderDashel
		SetOutPath "$INSTDIR\include\dashel"

		# Main files
		File "${DASHEL_SRC}\dashel\dashel.h"
	SectionEnd

	Section "!Aseba" SecHeaderAseba
		!insertmacro ASEBA_INSTALL_HEADER "msg"
		!insertmacro ASEBA_INSTALL_HEADER "common"
		!insertmacro ASEBA_INSTALL_HEADER "vm"
		!insertmacro ASEBA_INSTALL_HEADER "transport\buffer"
		!insertmacro ASEBA_INSTALL_HEADER_FILE "utils" "utils.h"
		!insertmacro ASEBA_INSTALL_HEADER_FILE "compiler" "compiler.h"
	SectionEnd
SectionGroupEnd

SectionGroup "!Examples"
	Section "Replay"
		SetOutPath "$INSTDIR\examples\replay"
		
		File "${ASEBA_SRC}\replay\*.txt"
		File "${ASEBA_SRC}\replay\*.cpp"
	SectionEnd
SectionGroupEnd


; First function to be executed by the installer
Function .onInit
	; Display the "Language Select" menu
	!insertmacro MUI_LANGDLL_DISPLAY

	; Group as Read-only and Expanded
	SectionGetFlags ${GroupLib} $0
	IntOp $0 $0 | ${SF_RO}
	IntOp $0 $0 | ${SF_EXPAND}
	SectionSetFlags ${GroupLib} $0
	; Section as Read-only
	SectionGetFlags ${SecDashel} $0
	IntOp $0 $0 | ${SF_RO}
	SectionSetFlags ${SecDashel} $0
	; Section as Read-only
	SectionGetFlags ${SecAseba} $0
	IntOp $0 $0 | ${SF_RO}
	SectionSetFlags ${SecAseba} $0

	; Group as Read-only and Expanded
	SectionGetFlags ${GroupHeaders} $0
	IntOp $0 $0 | ${SF_RO}
	IntOp $0 $0 | ${SF_EXPAND}
	SectionSetFlags ${GroupHeaders} $0
	; Section as Read-only
	SectionGetFlags ${SecHeaderDashel} $0
	IntOp $0 $0 | ${SF_RO}
	SectionSetFlags ${SecHeaderDashel} $0
	; Section as Read-only
	SectionGetFlags ${SecHeaderAseba} $0
	IntOp $0 $0 | ${SF_RO}
	SectionSetFlags ${SecHeaderAseba} $0
FunctionEnd

; First function to be executed by the uninstaller
Function un.onInit
  ; Get the language preference from the registry
  !insertmacro MUI_UNGETLANGUAGE
FunctionEnd

;--------------------------------
;Descriptions

  ;Assign language strings to sections
  ; !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    ; !insertmacro MUI_DESCRIPTION_TEXT ${GroupAseba} $(DESC_GroupAseba)
  ; !insertmacro MUI_FUNCTION_DESCRIPTION_END
 
;--------------------------------
;Uninstaller Section

Section "Uninstall"
	; Remove the application
	DetailPrint $(STR_Uninst_Folder)
	RMDir /r "$INSTDIR"
	DetailPrint $(STR_Done)
SectionEnd