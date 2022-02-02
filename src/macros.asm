;
; Macros
;

native          .macro                  ; go 65816 mode
                clc
                xce
                .endm 

emulation       .macro                  ; go 6502 mode
                sec
                xce
                .endm 

setdatabank     .macro
                pha                     ; push the value to the stack
                plb                     ; pull value from stack to data bank register
                .endm

rega8          .macro                  ; Make accumulator 8-bits
                SEP #$20
                .as
                .endm

rega16          .macro                  ; Make accumulator 16-bit
                REP #$20
                .al
                .endm

regxy8          .macro                  ; Make index registers 8-bits
                SEP #$10
                .xs
                .endm

regxy16         .macro                  ; Make index registers 16-bits
                REP #$10
                .xl
                .endm

regaxy8        .macro                  ; Make accumulator and index registers 8-bits
                SEP #$30
                .as
                .xs
                .endm

regaxy16        .macro                  ; Make accumulator and index registers 16-bits
                REP #$30
                .al
                .xl
                .endm