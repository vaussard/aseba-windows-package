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
  !include "x64.nsh"		; x64 support
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
  !define ASEBA_SRC ".\git\aseba"				; Git
  !define ASEBA_BIN ".\git\aseba-build-d"		; Git
  !include "${ASEBA_BIN}\version.nsi"			; Get NSIS style version number
  !define ASEBA_DEP ".\src\dependencies\debug"
  !define DRV_SRC ".\src\thymio-drv"
  !define DEVCON_SRC ".\src\devcon"
  !define EPUCK_KIT ".\src\epuck-kit"
  !define LOG_TO_FILE on 		; on / off. You need a special build of NSIS with logging enabled. To be downloaded on the NSIS website
  !define REGISTRY_KEY "Software\asebadbg"
  ShowInstDetails show
  ShowUninstDetails show

  ;Default installation folder
  InstallDir "$PROGRAMFILES\AsebaStudioDbg"
  
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
  
  ; Install type (with / without the driver)
  Page custom nsInstallType

  ; Components
  !insertmacro MUI_PAGE_COMPONENTS
  
  ; Choose directory
  !insertmacro MUI_PAGE_DIRECTORY
  
  ;Start Menu Folder Page Configuration
  !define MUI_STARTMENUPAGE_DEFAULTFOLDER "Aseba Studio Debug"
  !define MUI_STARTMENUPAGE_REGISTRY_ROOT "HKCU" 
  !define MUI_STARTMENUPAGE_REGISTRY_KEY ${REGISTRY_KEY} 
  !define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"
  !insertmacro MUI_PAGE_STARTMENU "Application" $StartMenuFolder
  
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
;LicenseLangString license ${LANG_ENGLISH} "${ASEBA_SRC}\license.txt"
;LicenseLangString license ${LANG_FRENCH}  "${ASEBA_SRC}\license.txt"

;--------------------------------
;Name and file (Defined here to be translation-enabled)

  !define MY_NAME $(STR_Package_Name)
  OutFile "aseba-dbg-${VERSION}-win32.exe"
  Name ${MY_NAME}

;--------------------------------
;Installer Sections

!include "GetTime.nsh"

; Offer the user with several pre-defined installations
InstType $(STR_InstallFull)
InstType $(STR_InstallRecommended)
InstType $(STR_InstallMin)

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
!insertmacro CleanShortcuts ""
!insertmacro CleanShortcuts "un."

Function WriteVersionFile
	LogText "Writing version.txt"
	FileOpen $0 "$INSTDIR\version.txt" w 	; Overwrite
	FileWrite $0 "${VERSION}"
	FileClose $0
FunctionEnd

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

SectionGroup "!Aseba" GroupAseba
	Section "!Aseba Studio IDE" SecStudio
		SectionIn 1 2 3

		SetOutPath "$INSTDIR"

		# Main files
		;File "${ASEBA_BIN}\studio\asebastudio.exe"
		File "${ASEBA_BIN}\studio\asebastudio.exe"
		!ifdef DEV_VERSION
			File "${ASEBA_BIN}\studio\aseba-doc.qhc"
			File "${ASEBA_BIN}\studio\aseba-doc.qch"
		!endif
		File "${ASEBA_SRC}\menu\windows\asebastudio.ico"
		File "${ASEBA_SRC}\menu\windows\asebathymio.ico"
		
		# Version file (version.txt)
		Call WriteVersionFile
		
		${If} $Language == '1036'
			; French
			File "${ASEBA_DEP}\README.fr.txt"
		${Else}
			File "${ASEBA_DEP}\README.en.txt"
		${EndIf}

		;Store installation folder
		WriteRegStr HKCU ${REGISTRY_KEY} "" $INSTDIR

		;Create uninstaller
		WriteUninstaller "$INSTDIR\Uninstall.exe"

		; Populate the start menu
		${If} $AlreadyInstalled == "true"
			; Clean old shortcuts
			Call CleanShortcuts
		${EndIf}
		SetShellVarContext current
		SetOutPath "$DOCUMENTS"		; Working directory for the shortcut
		SetShellVarContext all		; current / all. Install program for all users
		!insertmacro MUI_STARTMENU_WRITE_BEGIN Application
			CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
			CreateShortCut "$SMPROGRAMS\$StartMenuFolder\$(STR_Uninstall).lnk" "$INSTDIR\Uninstall.exe"
			CreateShortCut "$SMPROGRAMS\$StartMenuFolder\$(STR_Package_Name).lnk" "$INSTDIR\asebastudio.exe" "" "$INSTDIR\asebastudio.ico"		; Regular Aseba Studio
			!ifdef DEV_VERSION
				CreateShortCut "$SMPROGRAMS\$StartMenuFolder\$(STR_Doc_Browser).lnk" "$INSTDIR\asebastudio.exe" "-doc" "$INSTDIR\asebathymio.ico"
			!endif
			${If} $FullInstall == "true"
				!ifdef DEV_VERSION
					CreateShortCut "$SMPROGRAMS\$StartMenuFolder\$(STR_Package_Name_Thymio).lnk" "$INSTDIR\asebastudio.exe" "-ar ser:name=Thymio-II" "$INSTDIR\asebathymio.ico"
				!else
					CreateShortCut "$SMPROGRAMS\$StartMenuFolder\$(STR_Package_Name_Thymio).lnk" "$INSTDIR\asebastudio.exe" "ser:name=Thymio-II" "$INSTDIR\asebathymio.ico"
				!endif
			${EndIf}
		!insertmacro MUI_STARTMENU_WRITE_END
	SectionEnd

	Section "Qt4" SecQt
		SectionIn 1 2 3

		SetOutPath "$INSTDIR"

		!ifndef DEBUG_PACKAGE
		File "${ASEBA_DEP}\libgcc_s_dw2-1.dll"
		File "${ASEBA_DEP}\mingwm10.dll"
		File "${ASEBA_DEP}\QtCored4.dll"
		File "${ASEBA_DEP}\QtGuid4.dll"
		File "${ASEBA_DEP}\QtOpenGLd4.dll"
		File "${ASEBA_DEP}\QtXmld4.dll"
		!ifdef DEV_VERSION
			File "${ASEBA_DEP}\QtHelpd4.dll"
			File "${ASEBA_DEP}\QtCLucened4.dll"
			File "${ASEBA_DEP}\QtNetworkd4.dll"
			File "${ASEBA_DEP}\QtSqld4.dll"
		!endif
		File "${ASEBA_DEP}\qwtd5.dll"
		File "${ASEBA_DEP}\SDL.dll"
		!endif ;DEBUG_PACKAGE

		SetOutPath "$INSTDIR\sqldrivers"
		File "${ASEBA_DEP}\qsqlite4d.dll"

	SectionEnd
SectionGroupEnd

Section "Simulations" SecSim 
	SectionIn 1 2

	SetOutPath "$INSTDIR"

	!ifndef DEBUG_PACKAGE
	File "${ASEBA_BIN}\targets\challenge\asebachallenge.exe"
	;File "${ASEBA_BIN}\strip\asebachallenge.exe"
	File "${ASEBA_SRC}\menu\windows\asebachallenge.ico"
	File "${ASEBA_BIN}\targets\enki-marxbot\asebamarxbot.exe"
	;File "${ASEBA_BIN}\strip\asebamarxbot.exe"
	File "${ASEBA_BIN}\targets\playground\asebaplayground.exe"
	;File "${ASEBA_BIN}\strip\asebaplayground.exe"
	File "${ASEBA_SRC}\menu\windows\asebaplayground.ico"
	File "${ASEBA_SRC}\targets\playground\unifr.playground"
	!endif ; DEBUG_PACKAGE

	; Populate the start menu
	SetShellVarContext all		; current / all. Install program for all users
	!insertmacro MUI_STARTMENU_WRITE_BEGIN Application
		CreateDirectory "$SMPROGRAMS\$StartMenuFolder\$(STR_Simulations)"
		CreateShortCut "$SMPROGRAMS\$StartMenuFolder\$(STR_Simulations)\Aseba Challenge.lnk" "$INSTDIR\asebachallenge.exe" "" "$INSTDIR\asebachallenge.ico"
		CreateShortCut "$SMPROGRAMS\$StartMenuFolder\$(STR_Simulations)\Aseba Playground.lnk" "$INSTDIR\asebaplayground.exe" "" "$INSTDIR\asebaplayground.ico"
		CreateShortCut "$SMPROGRAMS\$StartMenuFolder\$(STR_Simulations)\Aseba MarXbot.lnk" "$INSTDIR\asebamarxbot.exe"
	!insertmacro MUI_STARTMENU_WRITE_END
SectionEnd

SectionGroup $(NAME_GroupCLI) GroupCLI
	Section "Aseba Switch" SecSwitch
		SectionIn 1 2

		SetOutPath "$INSTDIR"
		
		File "${ASEBA_BIN}\switch\asebaswitch.exe"
		;File "${ASEBA_BIN}\strip\asebaswitch.exe"

		SetShellVarContext all		; current / all. Install program for all users
		!insertmacro MUI_STARTMENU_WRITE_BEGIN Application
			CreateDirectory "$SMPROGRAMS\$StartMenuFolder\$(STR_Tools)"
			CreateShortCut "$SMPROGRAMS\$StartMenuFolder\$(STR_Tools)\$(STR_Cmd_Line).lnk" "%windir%\system32\cmd.exe" "$INSTDIR"
		!insertmacro MUI_STARTMENU_WRITE_END
	SectionEnd

	Section /o $(NAME_SecTools) SecTools
		SectionIn 1

		SetOutPath "$INSTDIR"
		
		!ifndef DEBUG_PACKAGE
		File "${ASEBA_BIN}\cmd\asebacmd.exe"
		File "${ASEBA_BIN}\dump\asebadump.exe"
		File "${ASEBA_BIN}\eventlogger\asebaeventlogger.exe"
		File "${ASEBA_BIN}\replay\asebaplay.exe"
		File "${ASEBA_BIN}\replay\asebarec.exe"    
		;File "${ASEBA_BIN}\strip\asebacmd.exe"
		;File "${ASEBA_BIN}\strip\asebadump.exe"
		;File "${ASEBA_BIN}\strip\asebaeventlogger.exe"
		;File "${ASEBA_BIN}\strip\asebaplay.exe"
		;File "${ASEBA_BIN}\strip\asebarec.exe"    
		!endif ; DEBUG_PACKAGE

		SetShellVarContext all		; current / all. Install program for all users
		!insertmacro MUI_STARTMENU_WRITE_BEGIN Application
			CreateDirectory "$SMPROGRAMS\$StartMenuFolder\$(STR_Tools)"
			CreateShortCut "$SMPROGRAMS\$StartMenuFolder\$(STR_Tools)\$(STR_Cmd_Line).lnk" "%windir%\system32\cmd.exe" "$INSTDIR"
		!insertmacro MUI_STARTMENU_WRITE_END
	SectionEnd
SectionGroupEnd

Section "-Install the driver" InstDriver	; Hidden section -> always executed
	${If} $FullInstall == "true"
		; Install the ThymioII driver
		CreateDirectory "$INSTDIR\drivers"
		SetOutPath "$INSTDIR\drivers"
		
		DetailPrint $(STR_Drv_Install)

		File "${DRV_SRC}\mchpcdc.inf"
		File "${DRV_SRC}\mchpcdc.cat"
		File "${DRV_SRC}\dpinst32.exe"
		File "${DRV_SRC}\dpinst64.exe"
		
		${If} ${RunningX64}
			DetailPrint $(STR_Drv_64bits)
			ExecWait '"$INSTDIR\drivers\dpinst64.exe" /c /sa /lm /sw /PATH "$INSTDIR\drivers"' $0
		${Else}
			DetailPrint $(STR_Drv_32bits)
			ExecWait '"$INSTDIR\drivers\dpinst32.exe" /c /sa /lm /sw /PATH "$INSTDIR\drivers"' $0
		${EndIf}
		DetailPrint "$(STR_Drv_Return_Code) $0"
		IntCmpU $0 0x80000000 drv_error no_error drv_error
		drv_error:
			DetailPrint $(STR_Drv_Problem)
			Goto done
		no_error:
			DetailPrint $(STR_Done)
		done:
	${EndIf}
SectionEnd

Section "-Install devcon" InstDevcon	; Hidden section -> always executed
	${If} $FullInstall == "true"
		SetOutPath "$INSTDIR"
		
		File "${DEVCON_SRC}\restart.bat"
		File "${DEVCON_SRC}\restartusb.exe"

		SetShellVarContext all		; current / all. Install program for all users
		!insertmacro MUI_STARTMENU_WRITE_BEGIN Application
			CreateDirectory "$SMPROGRAMS\$StartMenuFolder\$(STR_Tools)"
			CreateShortCut "$SMPROGRAMS\$StartMenuFolder\$(STR_Tools)\$(STR_USB_Restart).lnk" "$INSTDIR\restart.bat" "$INSTDIR"
		!insertmacro MUI_STARTMENU_WRITE_END
	${EndIf}
SectionEnd

Section "-Install the e-puck kit" InstEpuck	; Hidden section -> always executed
	${If} $FullInstall == "true"
		; Install the e-puck kit
		CreateDirectory "$INSTDIR\epuck"
		SetOutPath "$INSTDIR\epuck"
		
		DetailPrint $(STR_Epuck_Install)

		File "${EPUCK_KIT}\install.html"
		File "${ASEBA_SRC}\targets\e-puck\hex\epuckaseba.hex"
		File "${ASEBA_SRC}\targets\e-puck\hex\epuckBTseteventfilter.hex"		

		CreateDirectory "$INSTDIR\epuck\examples"
		SetOutPath "$INSTDIR\epuck\examples"
		
		File "${ASEBA_SRC}\targets\e-puck\examples\aseba-epuck-article.aesl"		
		File "${ASEBA_SRC}\targets\e-puck\examples\black-stripple-following.aesl"		
		
		SetShellVarContext all		; current / all. Install program for all users
		!insertmacro MUI_STARTMENU_WRITE_BEGIN Application
			CreateDirectory "$SMPROGRAMS\$StartMenuFolder\$(STR_Epuck_Menu)"
			CreateShortCut "$SMPROGRAMS\$StartMenuFolder\$(STR_Epuck_Menu)\$(STR_Epuck_Guide).lnk" "$INSTDIR\epuck\install.html" "$INSTDIR"
			CreateShortCut "$SMPROGRAMS\$StartMenuFolder\$(STR_Epuck_Menu)\$(STR_Epuck_Folder).lnk" "explorer.exe" "$INSTDIR\epuck"
		!insertmacro MUI_STARTMENU_WRITE_END
	${EndIf}
SectionEnd

; First function to be executed by the installer
Function .onInit
	; Display the "Language Select" menu
	!insertmacro MUI_LANGDLL_DISPLAY

	; Load bitmaps
	InitPluginsDir
	File /oname=$PLUGINSDIR\thymio2.bmp "thymio2-epuck.bmp"
	File /oname=$PLUGINSDIR\studio.bmp "studio.bmp"

	; Group Studio as Read-only and Expanded
	SectionGetFlags ${GroupAseba} $0
	IntOp $0 $0 | ${SF_RO}
	IntOp $0 $0 | ${SF_EXPAND}
	SectionSetFlags ${GroupAseba} $0

	; Section Studio IDE as Read-only
	SectionGetFlags ${SecStudio} $0
	IntOp $0 $0 | ${SF_RO}
	SectionSetFlags ${SecStudio} $0

	; Section Qt as Read-only
	SectionGetFlags ${SecQt} $0
	IntOp $0 $0 | ${SF_RO}
	SectionSetFlags ${SecQt} $0

	; Check for a previous installation
	ReadRegStr $0 HKCU ${REGISTRY_KEY} ""	; Read installation folder
	${If} $0 != ""
		DetailPrint "Previous installation detected at $0"
		StrCpy $AlreadyInstalled "true"
		; Check installation type
		${If} ${FileExists} "$INSTDIR\drivers\mchpcdc.inf"
			DetailPrint "Full installation detected"
			StrCpy $FullInstall "true"
		${Else}
			DetailPrint "Aseba-only installation detected"
			StrCpy $FullInstall "false"
		${EndIf}

		MessageBox MB_YESNO $(STR_Previous_Install) IDNO cancel IDYES ok

		cancel:
			Abort
		ok:
	${Else}
		StrCpy $AlreadyInstalled "false"
	${EndIf}

FunctionEnd

; First function to be executed by the uninstaller
Function un.onInit
  ; Get the language preference from the registry
  !insertmacro MUI_UNGETLANGUAGE
FunctionEnd

;--------------------------------
;Descriptions

  ;Assign language strings to sections
  !insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${GroupAseba} $(DESC_GroupAseba)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecStudio} $(DESC_SecStudioIDE)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecQt} $(DESC_SecQt)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecSim} $(DESC_SecSim)
    !insertmacro MUI_DESCRIPTION_TEXT ${GroupCLI} $(DESC_GroupCLI)
    !insertmacro MUI_DESCRIPTION_TEXT ${SecSwitch} $(DESC_SecSwitch)
	!insertmacro MUI_DESCRIPTION_TEXT ${SecTools} $(DESC_SecTools)
  !insertmacro MUI_FUNCTION_DESCRIPTION_END
 
;--------------------------------
;Uninstaller Section

Section "Uninstall"
	; Remove the driver
	${If} ${FileExists} "$INSTDIR\drivers\mchpcdc.inf"
		; Driver was installed
		DetailPrint $(STR_Drv_Uninstall)
		${If} ${RunningX64}
			DetailPrint $(STR_Drv_64bits)
			ExecWait '"$INSTDIR\drivers\dpinst64.exe" /c /u "$INSTDIR\drivers\mchpcdc.inf" /d'
		${Else}
			DetailPrint $(STR_Drv_32bits)
			ExecWait '"$INSTDIR\drivers\dpinst32.exe" /c /u "$INSTDIR\drivers\mchpcdc.inf" /d'
		${EndIf}	
		RMDir /r "$INSTDIR\drivers"
		DetailPrint $(STR_Done)
	${EndIf}
	
	; Remove the application
	DetailPrint $(STR_Uninst_Folder)
	RMDir /r "$INSTDIR"
	DetailPrint $(STR_Done)

	Call un.CleanShortcuts

	DeleteRegKey HKCU ${REGISTRY_KEY}
	DetailPrint $(STR_Done)
SectionEnd