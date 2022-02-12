;------------------------------------------
; SuperCPU BASIC Commands
; Scott Hutter / xlar54
;------------------------------------------

.cpu "65816"
.include "macros.asm"

* = $c000
 
CHRGET = $0073
CHRGOT = $0079
SNERR = $AF08
NEWSTT = $a7ae
GONE = $a7e4
STROUT = $ab1e
 
   ;jsr intromsg
 
   lda #<newgone
   sta $0308
   lda #>newgone
   sta $0309

    lda #<cpeek
    sta $311
    lda #>cpeek
    sta $312

   rts
 
; table for commmands
table=*
   .word notimp-1 ; @a
   .word do_bank-1 ; @b
   .word notimp-1  ; @c
   .word notimp-1 ; @d
   .word notimp-1 ; @e
   .word notimp-1 ; @f
   .word notimp-1 ; @g
   .word notimp-1 ; @h
   .word notimp-1 ; @i
   .word notimp-1 ; @j
   .word notimp-1 ; @k
   .word do_load-1 ; @l
   .word notimp-1 ; @m
   .word notimp-1 ; @n
   .word notimp-1 ; @o
   .word do_cpoke-1 ; @p
   .word notimp-1 ; @q
   .word notimp-1 ; @r
   .word notimp-1 ; @s
   .word notimp-1 ; @t
   .word notimp-1 ; @u
   .word notimp-1 ; @v
   .word notimp-1 ; @w
   .word notimp-1 ; @x
   .word notimp-1 ; @y
   .word notimp-1 ; @z
 
newgone = *
   jsr CHRGET
   php
   cmp #"@"
   beq newdispatch
 
; not our @ token ... jmp back
; into GONE
   plp
; jump past the JSR CHRGET call in GONE
   jmp GONE+3
 
newdispatch = *
   plp
   jsr dispatch
   jmp NEWSTT
 
dispatch = *
   jsr CHRGET
   cmp #'a'
   bcs contin1
   jmp SNERR
contin1 = *
   cmp #'z'
   bcc contin2
   jmp SNERR
contin2 =  *
   sec
   sbc #'a'
   cmp #'z'
   asl
   tax
   lda table+1,x
   pha
   lda table,x
   pha
   jmp CHRGET
 
msg .text "?not implemented  error"
    .byte 0
 
notimp = *
   ldy #>msg
   lda #<msg    
   jmp STROUT

intromsg = *    
    ldy #>imsg
    lda #<imsg
    jmp STROUT 
 
imsg 
    .text "supercpu ram wedge", $0d
    .text "by jim lawless", $0d
    .text "modified by scott hutter",$0d

; please add your vanity text here for any
; customizations you make
 
   .byte 0
 
do_bank = *
    jsr $b79e ; get byte into .x
    txa
    sta bank_stor
    rts

do_cpoke = *
    native
    regaxy8
    
    lda bank_stor   ; store bank at $16
    sta $16
    jsr $b7eb       ; handle values (puts lo and hi byte of addresses at $14/$15) and value in X
    txa 
    sta [$14]       ; requires lo byte, hi byte, bank
    
    emulation
    rts

bank_stor:
    .byte $06

do_load = *
      native
      rega8
      regaxy8

      cmp #$22       ; quote char?
      bne _errorjmp  ; no - error
      lda #$00
      sta fnamelen
_fnameloop
      jsr $0073      ; start getting filename
      cmp #$22       ; end quote?
      beq +          ; yes, skip ahead
      ldy fnamelen   ; get filename length count
      sta fname,y    ; grab next filename char
      iny            ; increase count
      sty fnamelen   ; save new filename length
      jmp _fnameloop

_errorjmp
      jmp _error

+     jsr $0073      ; get char
      cmp #$2c       ; if not comma, error
      bne _error
      jsr $0073      ; get char
      beq _error     ; zero flag is set if end of line or :
      jsr $ad8a      ; evaluate the memory address
      jsr $b7f7      ; put value at $14/$15
      lda $14        ; move values to ae-b0
      sta $ae
      lda $15
      sta $af
      lda bank_stor
      sta $b0
      ldy #$00       ; get current char of line
      lda ($007a),y
      cmp #$2c       ; if not comma, error
      bne _error
      jsr $0073      ; get char
      jsr $ad8a      ; evaluate
      jsr $b7f7      ; put value at $14/$15
      lda $15        ; if > 255, error
      bne _error
      lda $14        ; if > 30, error
      cmp #$1e
      bcs _error

      lda fnamelen
      ldx #<fname
      ldy #>fname
      jsr $ffbd     ; call setnam

      lda #$02      ; file number 2
      ldx $14       ; device number
      bne _skip
      ldx #$08      ; default to device 8
_skip   
      ldy #$02      ; secondary address 2
      jsr $ffba     ; call setlfs

      jsr $ffc0     ; call open
      bcs _error    ; if carry set, the file could not be opened

      ; check drive error channel here to test for
      ; file not found error etc.

      ldx #$02      ; filenumber 2
      jsr $ffc6     ; call chkin (file 2 now used as input)

        ldy #$00
_loop   jsr $ffb7     ; call readst (read status byte)
        bne _eof      ; either eof or read error
        jsr $ffcf     ; call chrin (get a byte from file)

         sta [$ae],y   ; write byte to memory       
         inc $0000ae
         bne _skip2
         inc $0000af

_skip2   jmp _loop     ; next byte

_eof
        and #$40      ; end of file?
        beq _readerror
_close
        lda #$02      ; filenumber 2
        jsr $ffc3     ; call close

        jsr $ffcc     ; call clrchn

        emulation
        rts
_error
        ; akkumulator contains basic error code
        ; most likely errors:
        ; a = $05 (device not present)
        ;... error handling for open errors ...
        emulation
        jmp _close    ; even if open failed, the file has to be closed
_readerror
        ; for further information, the drive error channel has to be read

        ;... error handling for read errors ...
        emulation
        jmp _close

fname:  
.byte $00, $00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00
fnamelen:
.byte $00



   

cpeek:
    native
    regaxy8

    jsr $bc9b   ; convert value from float to int @ $64/$65
    lda $64
    ldx $65
    stx $fb     ; store the lo and hi bytes temporarily
    sta $fc
    
    lda bank_stor   ; store bank at $fd
    sta $fd

    lda [$fb]   ; get value at 24 bit address
    tay         ; lsb of value in y
    lda #$00    ; msb of value in a
    jsr $b391   ; convert int back to float

    emulation
    rts



end



