set compiler=tasm
set linker=tlink
set debugger=td
set name=main
set folder=lab6

%compiler% %folder%\%name%.asm
pause

%linker% %name%.obj /t
pause

del %name%.obj
del %name%.map

%debugger% %name%.com