.586
.MODEL flat, stdcall
option casemap :none
.STACK 4096

include E:\dev\LibsAndPrograms\masm32\include\windows.inc
include E:\dev\LibsAndPrograms\masm32\include\user32.inc
include E:\dev\LibsAndPrograms\masm32\include\kernel32.inc
;include E:\dev\LibsAndPrograms\masm32\include\gdi32.inc
;include E:\dev\LibsAndPrograms\masm32\include\comdlg32.inc

include ib_convert.inc
include ib_longop.inc

includelib E:\dev\LibsAndPrograms\masm32\lib\user32.lib
includelib E:\dev\LibsAndPrograms\masm32\lib\kernel32.lib
;includelib E:\dev\LibsAndPrograms\masm32\lib\gdi32.lib
;includelib E:\dev\LibsAndPrograms\masm32\lib\comdlg32.lib

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

.DATA

  BoxHeader db "Test window", 0
  BoxContent db 32 dup('*'), 0

  Value dd 0FF0044AAh, 0EE00BBBBh
  ValueSize equ $ - Value

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

.CODE
main:

  push offset Value
  push 9
  push offset BoxContent 
  call IbHexToStr 

  invoke MessageBoxA, 0, addr BoxContent, addr BoxHeader, MB_ICONINFORMATION

@test_end:
  invoke ExitProcess, 0  

END main