;compile to this filename
!to "jmain.prg",cbm

!source "macros.asm"

VIC_SPRITE_X_POS        = $d000
VIC_SPRITE_Y_POS        = $d001
VIC_SPRITE_X_EXTEND     = $d010
VIC_SPRITE_ENABLE       = $d015
VIC_CONTROL             = $d016
VIC_MEMORY_CONTROL      = $d018
VIC_SPRITE_MULTICOLOR   = $d01c
VIC_SPRITE_MULTICOLOR_1 = $d025
VIC_SPRITE_MULTICOLOR_2 = $d026
VIC_SPRITE_COLOR        = $d027

VIC_BORDER_COLOR        = $d020
VIC_BACKGROUND_COLOR    = $d021

CIA_PRA                 = $dd00

VIC_INT_SCANLINE = %.......1

;global parameters
PARAM1                  = $03
PARAM2                  = $04
PARAM3                  = $05
PARAM4                  = $06
PARAM5                  = $07
PARAM6                  = $08

;zero page pointers
ZEROPAGE_POINTER_1      = $17
ZEROPAGE_POINTER_2      = $19
ZEROPAGE_POINTER_3      = $21
ZEROPAGE_POINTER_4      = $23

;address of the screen buffer
SCREEN_CHAR             = $CC00

;address of sprite pointers
SPRITE_POINTER_BASE     = SCREEN_CHAR + 1016

;number of sprites divided by four
NUMBER_OF_SPRITES_DIV_4       = 8

;number of hardware sprites in use
NO_SPRITES_IN_USE             = 0

;sprite number constant
SPRITE_BASE                   = 64

SPRITE_0  = SPRITE_BASE + 0
SPRITE_1  = SPRITE_BASE + 1
SPRITE_2  = SPRITE_BASE + 2
SPRITE_3  = SPRITE_BASE + 3
SPRITE_4  = SPRITE_BASE + 4
SPRITE_5  = SPRITE_BASE + 5
SPRITE_6  = SPRITE_BASE + 6
SPRITE_7  = SPRITE_BASE + 7
SPRITE_8  = SPRITE_BASE + 8
SPRITE_9  = SPRITE_BASE + 9
SPRITE_10 = SPRITE_BASE + 10
SPRITE_11 = SPRITE_BASE + 11
SPRITE_12 = SPRITE_BASE + 12
SPRITE_13 = SPRITE_BASE + 13
SPRITE_14 = SPRITE_BASE + 14
SPRITE_15 = SPRITE_BASE + 15
SPRITE_16 = SPRITE_BASE + 16
SPRITE_17 = SPRITE_BASE + 17
SPRITE_18 = SPRITE_BASE + 18
SPRITE_19 = SPRITE_BASE + 19
SPRITE_20 = SPRITE_BASE + 20
SPRITE_21 = SPRITE_BASE + 21
SPRITE_22 = SPRITE_BASE + 22
SPRITE_23 = SPRITE_BASE + 23
SPRITE_24 = SPRITE_BASE + 24
SPRITE_25 = SPRITE_BASE + 25
SPRITE_26 = SPRITE_BASE + 26
SPRITE_27 = SPRITE_BASE + 27
SPRITE_28 = SPRITE_BASE + 28
SPRITE_29 = SPRITE_BASE + 29
SPRITE_30 = SPRITE_BASE + 30
SPRITE_31 = SPRITE_BASE + 31

;this creates a basic start
*=$0801

          ;SYS 2064
          !byte $0C,$08,$0A,$00,$9E,$20,$32,$30,$36,$34,$00,$00,$00,$00,$00
    
          ;init sprite registers
          ;no visible sprites
          lda #0
          sta VIC_SPRITE_ENABLE
                    
          ;set charset to $3000 from VIC start = $C000+$3000 = $F000
          lda #$3c
          sta VIC_MEMORY_CONTROL

          ;set VIC to bank 3 = $C000-$FFFF
          lda CIA_PRA
          and #$fc
          sta CIA_PRA
    
          ;----------------------------------
          ;copy charset and sprites to target          
          ;----------------------------------
          
          ;block interrupts 
          ;since we turn ROMs off this would result in crashes if we didn't
          sei
          
          ;save old configuration
          lda $01
          sta PARAM1
          
          ;only RAM
          ;to copy under the IO rom
          lda #%00110000
          sta $01
          
          ;take source address from CHARSET
          LDA #<CHARSET
          STA ZEROPAGE_POINTER_1
          LDA #>CHARSET
          STA ZEROPAGE_POINTER_1 + 1
          
          ;now copy
          jsr CopyCharSet
    
          ;take source address from SPRITES
          lda #<SPRITES
          sta ZEROPAGE_POINTER_1
          lda #>SPRITES
          sta ZEROPAGE_POINTER_1 + 1
          
          jsr CopySprites
          
          ;restore ROMs
          lda PARAM1
          sta $01
          
          cli   
    
          ;background black
          lda #0
          sta VIC_BORDER_COLOR
          sta VIC_BACKGROUND_COLOR
          
          ;set sprite flags
          lda #0
          sta VIC_SPRITE_X_EXTEND
          sta VIC_SPRITE_ENABLE
          sta VIC_SPRITE_MULTICOLOR
          
          ;sprite multi colors
          lda #11
          sta VIC_SPRITE_MULTICOLOR_1
          lda #1
          sta VIC_SPRITE_MULTICOLOR_2
          
          ;clear screen
          lda #32
          ldy #1
          jsr ClearScreen
          
          jsr initSprites
    
;------------------------------------------------------------
;the main game loop
;------------------------------------------------------------
!zone GameLoop 
GameLoop  
          jsr WaitFrame
          
          lda #6
          sta VIC_BORDER_COLOR
    
          jsr drawSprites
          
          ldx #00
-         inx
          bne -
          
          jmp GameLoop    

;------------------------------------------------------------          
; Find an empty / unused hardware sprite
; x holds sprite number of empty sprite
; a holds 0 or sprite shape of sprite #7
; if x==8 no empty sprite was found
;------------------------------------------------------------
!zone findEmptySprite
findEmptySprite
          ldx #$00
-         lda SPRITE_POINTER_BASE,x
          beq .endLoop
          inx
          ; check no more than 8 sprites
          cpx #$08
          bne -
.endLoop
         rts

;------------------------------------------------------------          
; Initialise sprite positions and shapes
;------------------------------------------------------------
!zone InitSprites 
initSprites
          ;set sprite flags
          lda #0
          sta VIC_SPRITE_X_EXTEND
          lda #$ff
          sta VIC_SPRITE_ENABLE
          sta VIC_SPRITE_MULTICOLOR
          
          ;sprite multi colors
          lda #11
          sta VIC_SPRITE_MULTICOLOR_1
          lda #1
          sta VIC_SPRITE_MULTICOLOR_2

          ldx #$00
          lda #$25
          sta PARAM1
-
          sta SPRITE_POSITION_X,x
          lda #$35
          sta SPRITE_POSITION_Y,x
          lda PARAM1
          clc
          adc #28
          sta PARAM1
          inx
          cpx #$08
          bne -
          
          rts
    
;------------------------------------------------------------
; Draw hardware sprites
;------------------------------------------------------------
!zone drawSprites 
drawSprites
          ; enable all sprites
          lda #$ff
          sta VIC_SPRITE_ENABLE
    
          ; pick sprites shapes from sprite shape array
          ldx #$00
-          
          lda SPRITE_SHAPE, x
          sta SPRITE_POINTER_BASE,x
          inx
          cpx #$08
          bne -
          
          ; draw sprite shapes on their locations
          ldx #$00
.drawNextSprite
          lda #$01
          sta VIC_SPRITE_COLOR, x
          
          lda SPRITE_POSITION_X, x
          sta PARAM1
          txa
          asl
          tay
          lda PARAM1
          sta VIC_SPRITE_X_POS, y
          
          lda SPRITE_POSITION_Y, x
          sta VIC_SPRITE_Y_POS, y
          
          inx
          cpx #$08
          bne .drawNextSprite
                  
          rts 

;------------------------------------------------------------
;wait for the raster to reach line $f8
;this is keeping our timing stable
;------------------------------------------------------------
!zone WaitFrame 
WaitFrame 
          ;are we on line $F8 already? if so, wait for the next full screen
          ;prevents mistimings if called too fast
          lda $d012
          cmp #$F8
          beq WaitFrame

          ;wait for the raster to reach line $f8 (should be closer to the start of this line this way)
.WaitStep2
          lda #02
          sta VIC_BORDER_COLOR
    
          lda $d012
          cmp #$F8
          bne .WaitStep2
          
          rts
 
;------------------------------------------------------------
;copies charset from ZEROPAGE_POINTER_1 to $F000
;------------------------------------------------------------
!zone CopyCharSet 
CopyCharSet
          ;set target address ($F000)
          lda #$00
          sta ZEROPAGE_POINTER_2
          lda #$F0
          sta ZEROPAGE_POINTER_2 + 1

          ldx #$00
          ldy #$00
          lda #0
          sta PARAM2

.NextLine
          lda (ZEROPAGE_POINTER_1),Y
          sta (ZEROPAGE_POINTER_2),Y
          inx
          iny
          cpx #$08
          bne .NextLine
          cpy #$00
          bne .PageBoundaryNotReached
          
          ;we've reached the next 256 bytes, inc high byte
          inc ZEROPAGE_POINTER_1 + 1
          inc ZEROPAGE_POINTER_2 + 1

.PageBoundaryNotReached

          ;only copy 254 chars to keep irq vectors intact
          inc PARAM2
          lda PARAM2
          cmp #254
          beq .CopyCharsetDone
          ldx #$00
          jmp .NextLine

.CopyCharsetDone
          rts
  
;------------------------------------------------------------
;copies sprites from ZEROPAGE_POINTER_1 to $D000
;       sprites are copied in numbers of four
;------------------------------------------------------------

!zone CopySprites
CopySprites
          ldy #$00
          ldx #$00
          
          lda #00
          sta ZEROPAGE_POINTER_2
          lda #$d0
          sta ZEROPAGE_POINTER_2 + 1
          
          ;4 sprites per loop
.SpriteLoop
          lda (ZEROPAGE_POINTER_1),y
          sta (ZEROPAGE_POINTER_2),y
          iny
          bne .SpriteLoop
          inx
          inc ZEROPAGE_POINTER_1+1
          inc ZEROPAGE_POINTER_2+1
          cpx #NUMBER_OF_SPRITES_DIV_4
          bne .SpriteLoop

          rts 
  
;------------------------------------------------------------
;clears the screen
;A = char
;Y = color
;------------------------------------------------------------

!zone ClearScreen
ClearScreen
          ldx #$00
.ClearLoop          
          sta SCREEN_CHAR,x
          sta SCREEN_CHAR + 250,x
          sta SCREEN_CHAR + 500,x
          sta SCREEN_CHAR + 750,x
          inx
          cpx #250
          bne .ClearLoop

          tya
          ldx #$00
.ColorLoop          
          sta $d800,x
          sta $d800 + 250,x
          sta $d800 + 500,x
          sta $d800 + 750,x
          inx
          cpx #250
          bne .ColorLoop

          rts   

;------------------------------------------------------------
; find lowest SPRITE_POSTITION_Y index
; output:
;  PARAM1 lowest value
;  PARAM2 index of lowest value
;------------------------------------------------------------
!zone findLowestY
.findLowestY 
          ldy #$1f
          ldx #$ff
          stx PARAM1
-          
          lda SPRITE_POSITION_Y,y
          cmp PARAM1
          bcs .valueIsNotLower
          
          sta PARAM1
          sty PARAM2
.valueIsNotLower
          dey
          cpy #$ff
          bne -
          rts
 
;------------------------------------------------------------
; DATA DEFINITIONS
;------------------------------------------------------------
SPRITE_POSITION_X
          !fill 32,0
          
SPRITE_POSITION_Y
          !fill 32,0

SPRITE_SHAPE
          !fill 32, [SPRITE_BASE + i]
          
CHARSET
          !binary "j.chr"
        
SPRITES
          !binary "j.spr"   
    ;!source "sprites.asm"