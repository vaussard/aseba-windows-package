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

  !define DEVEL_PACKAGE							; Do not include all features of our nsi scripts
  !define REGISTRY_KEY "Software\aseba"
  !addincludedir ".\include"
  !include aseba-common-header.nsh
  !include "${ASEBA_BIN}\version.nsi"			; Get NSIS style version number

;--------------------------------
;General

  ;Default installation folder
  InstallDir "$DOCUMENTS\AsebaDev"
  
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

;Translations
  !insertmacro LANG_LOAD "English"			; translations/English.nsh
  !insertmacro LANG_LOAD "French"			; translations/French.nsh

; License: only the english license is used, because FSF strongly discourage using an unofficial translation
LicenseLangString license ${LANG_ENGLISH} "${ASEBA_SRC}\license.txt"
LicenseLangString license ${LANG_FRENCH}  "${ASEBA_SRC}\license.txt"


;--------------------------------
;Name and file (Defined here to be translation-enabled)

  !define MY_NAME $(STR_Package_Name_Devel)
  OutFile "aseba-devel-${VERSION}-win32.exe"
  Name ${MY_NAME}

;--------------------------------
;Installer Sections

  !include aseba-common-start.nsh		; Logging, version file, shortcut cleaning, installation type

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
;Uninstaller Section

Section "Uninstall"
	; Remove the application
	DetailPrint $(STR_Uninst_Folder)
	RMDir /r "$INSTDIR"
	DetailPrint $(STR_Done)
SectionEnd