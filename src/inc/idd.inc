; IDD.INC--
;
; Copyright (c) The Asmc Contributors. All rights reserved.
; Consult your license regarding permissions and restrictions.
;
ifndef __IDD_INC
define __IDD_INC

externdef IDD_Calendar:PIDD
externdef IDD_CalHelp:PIDD
ifdef __CI__
externdef IDD_CICreate:PIDD
externdef IDD_CIEdit:PIDD
externdef IDD_CIHelp:PIDD
externdef IDD_CISetup:PIDD
endif
externdef IDD_Commandline:PIDD
externdef IDD_CompareOptions:PIDD
externdef IDD_ConfirmAddFiles:PIDD
externdef IDD_ConfirmContinue:PIDD
externdef IDD_ConfirmDelete:PIDD
externdef IDD_ConsoleSize:PIDD
externdef IDD_Deflate64:PIDD
externdef IDD_DriveNotReady:PIDD
externdef IDD_DZCompareDirectories:PIDD
externdef IDD_DZCompression:PIDD
externdef IDD_DZConfiguration:PIDD
externdef IDD_DZConfirmations:PIDD
externdef IDD_DZCopy:PIDD
externdef IDD_DZDecompress:PIDD
externdef IDD_DZDefaultColor:PIDD
externdef IDD_DZEnviron:PIDD
externdef IDD_DZExit:PIDD
externdef IDD_DZFFHelp:PIDD
externdef IDD_DZFileAttributes:PIDD
externdef IDD_DZFindFile:PIDD
externdef IDD_DZHelp:PIDD
externdef IDD_DZHistory:PIDD
externdef IDD_DZMenuEdit:PIDD
externdef IDD_DZMenuFile:PIDD
externdef IDD_DZMenuHelp:PIDD
externdef IDD_DZMenuPanel:PIDD
externdef IDD_DZMenuSetup:PIDD
externdef IDD_DZMenuTools:PIDD
externdef IDD_DZMKList:PIDD
externdef IDD_DZMove:PIDD
externdef IDD_DZPanelFilter:PIDD
externdef IDD_DZPanelOptions:PIDD
externdef IDD_DZRecursiveCompare:PIDD
externdef IDD_DZSaveSetup:PIDD
externdef IDD_DZScreenOptions:PIDD
externdef IDD_DZSubInfo:PIDD
externdef IDD_DZSystemInfo:PIDD
externdef IDD_DZSystemOptions:PIDD
externdef IDD_DZTransfer:PIDD
externdef IDD_DZZipAttributes:PIDD
externdef IDD_EditColor:PIDD
externdef IDD_FFReplace:PIDD
externdef IDD_HEFormat:PIDD
externdef IDD_HELine:PIDD
externdef IDD_HEMenusline:PIDD
externdef IDD_HEStatusline:PIDD
externdef IDD_Menusline:PIDD
externdef IDD_OperationFilters:PIDD
externdef IDD_Replace:PIDD
externdef IDD_ReplacePrompt:PIDD
ifdef __BMP__
externdef IDD_SaveScreen:PIDD
endif
externdef IDD_Search:PIDD
externdef IDD_Statusline:PIDD
externdef IDD_TEOptions:PIDD
externdef IDD_TEQuickMenu:PIDD
externdef IDD_TEReload:PIDD
externdef IDD_TEReload2:PIDD
externdef IDD_TESave:PIDD
externdef IDD_TESeek:PIDD
externdef IDD_TEWindows:PIDD
externdef IDD_TVCopy:PIDD
externdef IDD_TVHelp:PIDD
externdef IDD_TVMenusline:PIDD
externdef IDD_TVQuickMenu:PIDD
externdef IDD_TVSeek:PIDD
externdef IDD_TVStatusline:PIDD
externdef IDD_UnzipCRCError:PIDD
externdef IDD_WOpenFile:PIDD

endif
