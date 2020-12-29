﻿;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; NSIS installer script for     ;
; UltraStar WorldParty   ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

!include MUI2.nsh			;Used for create the interface
!include LogicLib.nsh		;Used for internal calculations
!include InstallOptions.nsh	;Used for components selections
!include nsDialogs.nsh		;Used for custom pages
!include UAC.nsh			;Used for get privileges to write on disk
!include FileFunc.nsh 		;used for get size info at uninstaller

; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~
; Variables
; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~

; Installer Paths:

!define path_settings ".\settings"
!define path_languages ".\languages"
!define path_dependencies ".\dependencies"
!define path_images ".\dependencies\images"
!define path_plugins ".\dependencies\plugins"

; MultiLanguage - Show all languages:
!define MUI_LANGDLL_ALLLANGUAGES

!addPluginDir "${path_plugins}\"

!include "${path_settings}\variables.nsh"
!include "${path_settings}\functions.nsh"

; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~
; Export Settings
; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~

SetCompress force
SetCompressor /FINAL /SOLID lzma
SetCompressorDictSize 64
SetDatablockOptimize On


CRCCheck on

XPStyle on

Name "${name} ${version}"
Brandingtext "${name} ${version} Installation"

!system 'md "dist"'
OutFile "dist\${installerexe}.exe"

InstallDir "${PRODUCT_PATH}"
InstallDirRegKey "${PRODUCT_UNINST_ROOT_KEY}" "${PRODUCT_UNINST_KEY}" "InstallDir"

; Windows Vista / Windows 7:
; must be "user" for UAC plugin 
RequestExecutionLevel user

; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~
; Interface Settings
; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~

; Icons:

!define MUI_ICON "${img_install}"
!define MUI_UNICON "${img_uninstall}"

; Header and Side Images:

!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "${path_images}\${img_header}"
!define MUI_HEADERIMAGE_UNBITMAP "${path_images}\${img_header}"

!define MUI_WELCOMEFINISHPAGE_BITMAP "${path_images}\${img_side}"
!define MUI_UNWELCOMEFINISHPAGE_BITMAP "${path_images}\${img_side}"

; Abort Warnings:

!define MUI_ABORTWARNING
!define MUI_ABORTWARNING_TEXT "$(abort_install)"
!define MUI_ABORTWARNING_CANCEL_DEFAULT

!define MUI_UNABORTWARNING
!define MUI_UNABORTWARNING_TEXT "$(abort_uninstall)"
!define MUI_UNABORTWARNING_CANCEL_DEFAULT

; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~
; Pages Installation Routine Settings
; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~

; Welcome Page:

!define MUI_WELCOMEPAGE_TITLE_3LINES
!define MUI_WELCOMEPAGE_TITLE "$(page_welcome_title)"
!define MUI_WELCOMEPAGE_TEXT "$(page_welcome_txt)"

; License Page:

!define MUI_LICENSEPAGE_RADIOBUTTONS


; Finish Pages:

!define MUI_FINISHPAGE_TITLE_3LINES

!define MUI_FINISHPAGE_TEXT_LARGE
!define MUI_FINISHPAGE_TEXT "$(page_finish_txt)"

; MUI_FINISHPAGE_RUN is executed as admin by default.
; To get the config.ini location right it must be executed with user 
; rights instead.
!define MUI_FINISHPAGE_RUN
!define MUI_FINISHPAGE_RUN_NOTCHECKED
!define MUI_FINISHPAGE_RUN_FUNCTION RunAppAsUser 

Function RunAppAsUser 
    UAC::ShellExec 'open' '' '$INSTDIR\${exe}.exe' '' '$INSTDIR'
FunctionEnd

!define MUI_FINISHPAGE_LINK "$(page_finish_linktxt)"
!define MUI_FINISHPAGE_LINK_LOCATION "${homepage}"

!define MUI_FINISHPAGE_SHOWREADME
!define MUI_FINISHPAGE_SHOWREADME_TEXT $(page_finish_desktop)
!define MUI_FINISHPAGE_SHOWREADME_FUNCTION CreateDesktopShortCuts

!define MUI_FINISHPAGE_NOAUTOCLOSE
!define MUI_UNFINISHPAGE_NOAUTOCLOSE

!define MUI_FINISHPAGE_NOREBOOTSUPPORT

; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~
; Pages Installation Routine
; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "${license}"
!insertmacro MUI_PAGE_DIRECTORY

; Start menu page

; TODO: verify. don't think we should disallow disabling shortcuts. think of a portable version
!define MUI_STARTMENUPAGE_NODISABLE

!define MUI_STARTMENUPAGE_DEFAULTFOLDER "${name}"
!define MUI_STARTMENUPAGE_REGISTRY_ROOT "${PRODUCT_UNINST_ROOT_KEY}"
!define MUI_STARTMENUPAGE_REGISTRY_KEY "${PRODUCT_UNINST_KEY}"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "${name}"

Var StartMenuFolder
!insertmacro MUI_PAGE_STARTMENU Application $StartMenuFolder

!insertmacro MUI_PAGE_INSTFILES

; WorldParty Settings Page



; User data info

Var UseAppData    ; true if APPDATA is used for user data, false for INSTDIR
Var UserDataPath  ; Path to user data dir (e.g. $INSTDIR)
Var ConfigIniPath ; Path to config.ini (e.g. "$INSTDIR\config.ini")

; Checks for write permissions on $INSTDIR\config.ini.
; This function creates $INSTDIR\config.use as a marker file if
; the user has write permissions.
; Note: Must be run with user privileges
Function CheckInstDirUserPermissions
	ClearErrors
	; try to open the ini file.
	; Use "append" mode so an existing config.ini is not destroyed.
	FileOpen $0 "$INSTDIR\config.ini" a
	IfErrors end
	; we have write permissions -> create a marker file
	FileOpen $1 "$INSTDIR\config.use" a	
	FileClose $1
end:
	FileClose $0
FunctionEnd

; Determines the directory used for config.ini and other user
; settings and data.
; Sets $UseAppData, $UserDataPath and $ConfigIniPath
Function DetermineUserDataDir
	Delete "$INSTDIR\config.use"
	!insertmacro UAC.CallFunctionAsUser CheckInstDirUserPermissions
	IfFileExists "$INSTDIR\config.use" 0 notexists
	StrCpy $UseAppData false
	StrCpy $UserDataPath "$INSTDIR"
	Goto end
notexists:
	StrCpy $UseAppData true
	SetShellVarContext current
	StrCpy $UserDataPath "$APPDATA\${exe}"
	SetShellVarContext all
end:
	Delete "$INSTDIR\config.use"	
	StrCpy $ConfigIniPath "$UserDataPath\config.ini"
FunctionEnd

Function Settings

	; localize settings
	
	!insertmacro INSTALLOPTIONS_WRITE "Settings" "Field 1" "Text" "$(page_settings_fullscreen_label)"
	!insertmacro INSTALLOPTIONS_WRITE "Settings" "Field 2" "Text" "$(page_settings_language_label)"
	!insertmacro INSTALLOPTIONS_WRITE "Settings" "Field 3" "Text" "$(page_settings_resolution_label)"
	!insertmacro INSTALLOPTIONS_WRITE "Settings" "Field 4" "Text" "$(page_settings_tabs_label)"	
	
	!insertmacro INSTALLOPTIONS_WRITE "Settings" "Field 9" "Text" "$(page_settings_fullscreen_info)"
	!insertmacro INSTALLOPTIONS_WRITE "Settings" "Field 10" "Text" "$(page_settings_config_info)"
	!insertmacro INSTALLOPTIONS_WRITE "Settings" "Field 11" "Text" "$(page_settings_language_info)"
	!insertmacro INSTALLOPTIONS_WRITE "Settings" "Field 12" "Text" "$(page_settings_resolution_info)"
	!insertmacro INSTALLOPTIONS_WRITE "Settings" "Field 13" "Text" "$(page_settings_tabs_info)"
	!insertmacro INSTALLOPTIONS_WRITE "Settings" "Field 14" "Text" "$(page_settings_sorting_label)"	

	!insertmacro INSTALLOPTIONS_WRITE "Settings" "Field 16" "Text" "$(page_settings_sorting_info)"	
	!insertmacro INSTALLOPTIONS_WRITE "Settings" "Field 17" "Text" "$(page_settings_config_title)"
	!insertmacro INSTALLOPTIONS_WRITE "Settings" "Field 18" "Text" "$(page_settings_songdir_label)"
	!insertmacro INSTALLOPTIONS_WRITE "Settings" "Field 19" "Text" "$(page_settings_songdir_info)"

	; Set default value
	
	!insertmacro INSTALLOPTIONS_WRITE "Settings" "Field 18" "State" "$INSTDIR\songs"
	

	; show dialog
	!insertmacro MUI_HEADER_TEXT " " "$(page_settings_subtitle)"   
	!insertmacro INSTALLOPTIONS_DISPLAY "Settings"
	
	; Get all the variables:

	Var /GLOBAL LABEL_COMPONENTS

	Var /GLOBAL CHECKBOX_COVERS
	Var /GLOBAL CB_COVERS_State
	Var /GLOBAL CHECKBOX_SCORES
	Var /GLOBAL CB_SCORES_State
	Var /GLOBAL CHECKBOX_CONFIG
	Var /GLOBAL CB_CONFIG_State
	Var /GLOBAL CHECKBOX_SCREENSHOTS
	Var /GLOBAL CB_SCREENSHOTS_State
	Var /GLOBAL CHECKBOX_PLAYLISTS
	Var /GLOBAL CB_PLAYLISTS_State
	Var /GLOBAL CHECKBOX_SONGS 
	Var /GLOBAL CB_SONGS_State

	Var /GLOBAL fullscreen
	Var /GLOBAL language2
	Var /GLOBAL resolution
	Var /GLOBAL tabs
	Var /GLOBAL sorting
	Var /GLOBAL songdir

	!insertmacro INSTALLOPTIONS_READ $fullscreen "Settings" "Field 5" "State"
	!insertmacro INSTALLOPTIONS_READ $language2 "Settings" "Field 6" "State"
	!insertmacro INSTALLOPTIONS_READ $resolution "Settings" "Field 7" "State"
	!insertmacro INSTALLOPTIONS_READ $tabs "Settings" "Field 8" "State"
	!insertmacro INSTALLOPTIONS_READ $sorting "Settings" "Field 15" "State"
	!insertmacro INSTALLOPTIONS_READ $songdir "Settings" "Field 18" "State"

	WriteINIStr "$ConfigIniPath" "Game" "Language" "$language2"
	WriteINIStr "$ConfigIniPath" "Game" "Tabs" "$tabs"
	WriteINIStr "$ConfigIniPath" "Game" "Sorting" "$sorting"

	WriteINIStr "$ConfigIniPath" "Graphics" "FullScreen" "$fullscreen"
	WriteINIStr "$ConfigIniPath" "Graphics" "Resolution" "$resolution"

	${If} $songdir != "$INSTDIR\songs"
	WriteINIStr "$ConfigIniPath" "Directories" "SongDir1" "$songdir"
	${EndIf}
		
FunctionEnd ; Settings page End

!insertmacro MUI_PAGE_FINISH

; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~
; Pages UnInstallation Routine
; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~

!define MUI_WELCOMEPAGE_TITLE_3LINES
!define MUI_WELCOMEPAGE_TITLE "$(page_un_welcome_title)"

!define MUI_FINISHPAGE_TITLE_3LINES

!insertmacro MUI_UNPAGE_WELCOME
!insertmacro MUI_UNPAGE_CONFIRM

UninstPage custom un.AskDelete un.DeleteAll

Function un.AskDelete

	nsDialogs::Create /NOUNLOAD 1018

	${NSD_CreateLabel} 0 -195 100% 12u "$(delete_components)"
	Pop $LABEL_COMPONENTS

	${NSD_CreateCheckbox} 0 -175 100% 8u "$(delete_covers)"
	Pop $CHECKBOX_COVERS
	nsDialogs::OnClick /NOUNLOAD $CHECKBOX_COVERS $1

	${NSD_CreateCheckbox} 0 -155 100% 8u "$(delete_config)"
	Pop $CHECKBOX_CONFIG
	nsDialogs::OnClick /NOUNLOAD $CHECKBOX_CONFIG $2

	${NSD_CreateCheckbox} 0 -135 100% 8u "$(delete_highscores)"
	Pop $CHECKBOX_SCORES 
	nsDialogs::OnClick /NOUNLOAD $CHECKBOX_SCORES $3

	${NSD_CreateCheckbox} 0 -115 100% 8u "$(delete_screenshots)"
	Pop $CHECKBOX_SCREENSHOTS 
	nsDialogs::OnClick /NOUNLOAD $CHECKBOX_SCREENSHOTS $4

	${NSD_CreateCheckbox} 0 -95 100% 8u "$(delete_playlists)"
	Pop $CHECKBOX_PLAYLISTS
	nsDialogs::OnClick /NOUNLOAD $CHECKBOX_PLAYLISTS $5

	${NSD_CreateCheckbox} 0 -65 100% 18u "$(delete_songs)"
	Pop $CHECKBOX_SONGS 
	nsDialogs::OnClick /NOUNLOAD $CHECKBOX_SONGS $6


	nsDialogs::Show

FunctionEnd

Function un.DeleteAll

	${NSD_GetState} $CHECKBOX_COVERS $CB_COVERS_State
	${NSD_GetState} $CHECKBOX_CONFIG $CB_CONFIG_State
	${NSD_GetState} $CHECKBOX_SCORES $CB_SCORES_State
	${NSD_GetState} $CHECKBOX_SCORES $CB_SCREENSHOTS_State
	${NSD_GetState} $CHECKBOX_SCORES $CB_PLAYLISTS_State
	${NSD_GetState} $CHECKBOX_SONGS  $CB_SONGS_State

	${If} $CB_COVERS_State == "1" ; Remove covers
		RMDir /r "$INSTDIR\covers"
		SetShellVarContext current	
		RMDir /r "$APPDATA\${exe}\covers"
		SetShellVarContext all
	${EndIf}

	${If} $CB_CONFIG_State == "1" ; Remove config
		SetShellVarContext current
		Delete "$APPDATA\${exe}\config.ini" 
		SetShellVarContext all
		Delete "$INSTDIR\config.ini"
	${EndIf}

	${If} $CB_SCORES_State == "1" ; Remove highscores
		SetShellVarContext current
		Delete "$APPDATA\${exe}\Ultrastar.db" 
		SetShellVarContext all
		Delete "$INSTDIR\Ultrastar.db"
	${EndIf}

	${If} $CB_SCREENSHOTS_State == "1" ; Remove screenshots
		RMDir /r "$INSTDIR\sreenshots"
		SetShellVarContext current
		RMDir /r "$APPDATA\${exe}\screenshots"
		SetShellVarContext all
	${EndIf}

	${If} $CB_SCREENSHOTS_State == "1" ; Remove playlists
		RMDir /r "$INSTDIR\playlists"
		SetShellVarContext current
		RMDir /r "$APPDATA\${exe}\playlists"
		SetShellVarContext all
	${EndIf}

	${If} $CB_SONGS_State == "1" ; Remove songs
		RMDir /r "$INSTDIR\songs"
		SetShellVarContext current
		RMDir /r "$APPDATA\${exe}\songs"
		SetShellVarContext all
	${EndIf}

FunctionEnd

!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~
; Sections Installation Routine
; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~

;-----------------
; MAIN COMPONENTS 
;-----------------
Section Install

	SectionIn RO
	SetOutPath $INSTDIR
	SetOverwrite try
	
	; make installation folder read/writable for all authenticated users,
	; so shared settings, songs, logfile,... can be used and overall game handling is easier
	; TODO: use All Users->AppData for this instead in future releases
	AccessControl::GrantOnFile \
	"$INSTDIR\" "(BU)" "GenericRead + GenericExecute + GenericWrite + Delete"

	Call DetermineUserDataDir
	
	!include "${path_settings}\files_main_install.nsh"

	; Create Shortcuts:
	SetOutPath "$INSTDIR"

!insertmacro MUI_STARTMENU_WRITE_BEGIN Application
	SetShellVarContext all
	SetOutPath "$INSTDIR"

	CreateDirectory "$SMPROGRAMS\$StartMenuFolder"
	CreateShortCut "$SMPROGRAMS\$StartMenuFolder\$(sm_shortcut).lnk" "$INSTDIR\${exe}.exe"
	CreateShortCut "$SMPROGRAMS\$StartMenuFolder\$(sm_website).lnk" "${homepage}" 
	CreateShortCut "$SMPROGRAMS\$StartMenuFolder\$(sm_songs).lnk" "$INSTDIR\songs"
	CreateShortCut "$SMPROGRAMS\$StartMenuFolder\$(sm_uninstall).lnk" "$INSTDIR\${exeuninstall}.exe"
	
	; SendTo shortcut
	;CreateShortCut "$SENDTO\${name}.lnk" "$INSTDIR\${exe}.exe" "-SongPath"
	
!insertmacro MUI_STARTMENU_WRITE_END

	; Vista Game Explorer:
	; (removed due to incompatibility with Windows 7, needs rewrite)

	; Create Uninstaller:

	WriteUninstaller "$INSTDIR\${exeuninstall}.exe"

	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "${name}"
	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\${exe}.exe"
	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "InstallDir" "$INSTDIR"
	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\${exeuninstall}.exe"
	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
	
	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Version" "${FullVersion}"
	WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "Language" "$language"

	SetOutPath "$INSTDIR"

 ;-------------- calculate the total size of the program -----	
		${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
		IntFmt $0 "0x%08X" $0
		WriteRegDWORD HKLM "${PRODUCT_UNINST_KEY}" "EstimatedSize" "$0"
		
SectionEnd

;------------------------------------
; UNINSTALL
;------------------------------------

Section Uninstall

	; Delete created Icons in startmenu

	!insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder
	 SetShellVarContext all
	 RMDir /r "$SMPROGRAMS\$StartMenuFolder\"
	 
	 ; Delete created Icon on Desktop
	 Delete "$Desktop\$(sm_shortcut).lnk"
 
	!include "${path_settings}\files_main_uninstall.nsh"
	
	!insertmacro MUI_STARTMENU_GETFOLDER Application $StartMenuFolder	
	Delete "$SMPROGRAMS\$StartMenuFolder\$(sm_shortcut).lnk"
	Delete "$SMPROGRAMS\$StartMenuFolder\$(sm_website).lnk"
	Delete "$SMPROGRAMS\$StartMenuFolder\$(sm_songs).lnk"
	Delete "$SMPROGRAMS\$StartMenuFolder\$(sm_uninstall).lnk"
	RMDir "$SMPROGRAMS\$StartMenuFolder"
	
	DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"

	; Unregister from Windows Vista Game Explorer
	; (removed due to incompatibility with Windows 7)

SectionEnd

; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~
; Language Support
; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~

!include "${path_settings}\languages.nsh"
!insertmacro MUI_RESERVEFILE_LANGDLL

; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~
; Main
; ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~ ~+~

Function .onInit

	${UAC.I.Elevate.AdminOnly}

	System::Call 'kernel32::CreateMutexA(i 0, i 0, t "${exe} Installer.exe") ?e'

	Pop $R0

	StrCmp $R0 0 +3
	MessageBox MB_OK|MB_ICONEXCLAMATION $(oninit_running)
	Abort

	ReadRegStr $R0 "${PRODUCT_UNINST_ROOT_KEY}" "${PRODUCT_UNINST_KEY}" 'DisplayVersion'

	${If} "$R0" == "${PRODUCT_VERSION}"
		MessageBox MB_YESNO|MB_ICONEXCLAMATION \
			"${name} $R0 $(oninit_alreadyinstalled). $\n$\n $(oninit_installagain)" \
			IDYES continue
		Abort
	${EndIf}

	ReadRegStr $R1 "${PRODUCT_UNINST_ROOT_KEY}" "${PRODUCT_UNINST_KEY}" 'UninstallString'
	StrCmp $R1 "" done
	
	ReadRegStr $R2 "${PRODUCT_UNINST_ROOT_KEY}" "${PRODUCT_UNINST_KEY}" 'Version' 
	StrCmp $R1 "" 0 +1
		StrCpy $R1 " ($R1)"

	${If} "$R0" != "${PRODUCT_VERSION}"
		MessageBox MB_YESNO|MB_ICONEXCLAMATION \
			"${name} $R0 $(oninit_alreadyinstalled). $\n$\n $(oninit_updateWorldParty) $R0$R1 -> ${version} (${FullVersion})" \
			IDYES continue
			Abort
	${EndIf}


continue:
	ReadRegStr $R2 "${PRODUCT_UNINST_ROOT_KEY}" "${PRODUCT_UNINST_KEY}" 'UninstallString'
	MessageBox MB_YESNO|MB_ICONEXCLAMATION "$(oninit_uninstall)" IDNO done
	ExecWait '"$R2" _?=$INSTDIR'

done:

;--------- Splash image
  InitPluginsDir
  File "/oname=${path_images}\logo.bmp" "${path_images}\logo.bmp"

  advsplash::show 230 750 1000 -1 ${path_images}\logo

  Pop $0 ; $0 has '1' if the user closed the splash screen early,
         ; '0' if everything closed normally, and '-1' if some error occurred.
;-----------------------

	!insertmacro MUI_LANGDLL_DISPLAY

	!insertmacro INSTALLOPTIONS_EXTRACT_AS ".\settings\settings.ini" "Settings"

FunctionEnd

Function un.onInit

	${nsProcess::FindProcess} "${exe}.exe" $R0
	StrCmp $R0 0 0 +2
	MessageBox MB_YESNO|MB_ICONEXCLAMATION '$(oninit_closeWorldParty)' IDYES closeit IDNO end

closeit:
	${nsProcess::KillProcess} "${exe}.exe" $R0
	goto continue

	${nsProcess::FindProcess} "${exe}.exe" $R0
	StrCmp $R0 0 0 +2
	MessageBox MB_YESNO|MB_ICONEXCLAMATION '$(oninit_closeWorldParty)' IDYES closeWorldParty IDNO end

closeWorldParty:
	${nsProcess::KillProcess} "${exe}.exe" $R0
	goto continue

end:
	${nsProcess::Unload}
	Abort

continue:
	
	; restore the installer language. the language has been manually written in order to have
	; the installer always open the language dialog
	!define MUI_LANGDLL_REGISTRY_ROOT ${PRODUCT_UNINST_ROOT_KEY}
	!define MUI_LANGDLL_REGISTRY_KEY "${PRODUCT_UNINST_KEY}"
	!define MUI_LANGDLL_REGISTRY_VALUENAME "Language"
	
	!insertmacro MUI_UNGETLANGUAGE

FunctionEnd

Function .onInstFailed
	${UAC.Unload}
FunctionEnd
 
Function .onInstSuccess
	${UAC.Unload}
FunctionEnd
