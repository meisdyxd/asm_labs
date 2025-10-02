set folder=lab5
set name=%main
set func=func

set compiler=tasm
set linker=tlink
set debugger=td

%compiler% /l %folder%\%func%.asm
pause

%compiler% %folder%\%name%.asm


%linker% %name%.obj+%func%.obj


%debugger% %name%.exe