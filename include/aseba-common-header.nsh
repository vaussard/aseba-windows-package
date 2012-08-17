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
  !include nsDialogs.nsh	; custom dialogs
  !include LogicLib.nsh		; ${If} statement

  ; Compression
  SetCompressor /SOLID lzma

;--------------------------------
;Defines
  
  ;!define FAKE_PACKAGE			; Won't include heavy files to speed-up debug process (reduce compression time)
									; --> Comment this line out for release
  !define DEV_VERSION							; Take into account new features
  !define QT_VERSION "qt-4.7.4"

  !define ASEBA_SRC "..\git\aseba"
  !define ASEBA_BIN "..\git\aseba-build"			; Git
  !define ASEBA_BIN_STRIP "${ASEBA_BIN}\strip"		; Stripped binaries
  !define ASEBA_BIN_DBG "..\git\aseba-build-d"		; Git
  
  !define ASEBA_DEP "..\src\dependencies"
  !define ASEBA_DEP_DBG "..\src\dependencies\debug"

  !define DASHEL_SRC "..\src\dashel\dashel"		; Dashel svn

  !define DRV_SRC "..\src\thymio-drv"
  !define DEVCON_SRC "..\src\devcon"
  !define EPUCK_KIT "..\src\epuck-kit"
  
  !define LOG_TO_FILE on 		; on / off. You need a special build of NSIS with logging enabled. To be downloaded on the NSIS website
  
  ShowInstDetails show
  ShowUninstDetails show

    ;Get installation folder from registry if available
  InstallDirRegKey HKCU ${REGISTRY_KEY} ""

  ;Remember the language selection
  !define MUI_LANGDLL_REGISTRY_ROOT "HKCU"
  !define MUI_LANGDLL_REGISTRY_KEY ${REGISTRY_KEY}
  !define MUI_LANGDLL_REGISTRY_VALUENAME "Language"

  ;Request application privileges for Windows Vista
  RequestExecutionLevel admin

;--------------------------------
;Variables

!ifndef DEVEL_PACKAGE
  Var StartMenuFolder

  ; For the install type selection
  Var Dialog
  Var ButtonFull
  Var ButtonMin
  Var ImageThymio
  Var ImageThymioHandle
  Var ImageStudio
  Var ImageStudioHandle
  Var HLine
  
  Var AlreadyInstalled
  Var FullInstall
!endif
  
;--------------------------------
;Interface Settings

  !define MUI_ABORTWARNING

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

; From: http://nsis.sourceforge.net/CreateInternetShortcut_macro_%26_function
!macro CreateInternetShortcut FILENAME URL ICONFILE ICONINDEX
  WriteINIStr "${FILENAME}.url" "InternetShortcut" "URL" "${URL}"
  WriteINIStr "${FILENAME}.url" "InternetShortcut" "IconFile" "${ICONFILE}"
  WriteINIStr "${FILENAME}.url" "InternetShortcut" "IconIndex" "${ICONINDEX}"
!macroend

; Convenience macro for the devel package
!macro ASEBA_INSTALL_HEADER DIRECTORY
	SetOutPath "$INSTDIR\include\aseba\${DIRECTORY}"
	File "${ASEBA_SRC}\${DIRECTORY}\*.h"
!macroend

!macro ASEBA_INSTALL_HEADER_FILE DIRECTORY FILE
	SetOutPath "$INSTDIR\include\aseba\${DIRECTORY}"
	File "${ASEBA_SRC}\${DIRECTORY}\${FILE}"
!macroend
