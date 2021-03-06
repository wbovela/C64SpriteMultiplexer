; Macros

!addr {
    Kernal_PrintImmediate = $fa17
	Kernal_CursorPosition = $fff0
	Kernal_SetWindow      = $c02d
	Kernal_GetChar        = $ffe4
}
	
    Color_Black   = 0
    Color_White   = 1
    Color_Red     = 2
    Color_Cyan    = 3
    Color_Purple  = 4
    Color_Green   = 5
    Color_Blue    = 6
    Color_Yellow  = 7
	Color_Orange  = 8
    Color_Brown   = 9
    Color_LtRed   = 10
    Color_DkGray  = 11
    Color_MdGray  = 12
    Color_LtGreen = 13
    Color_LtBlue  = 14
    Color_LtGray  = 15
	
!macro SaveRegisters {
	pha
    txa
    pha
	tya
    pha
}

!macro RestoreRegisters {
	pla
    tay
    pla
    tax
    pla
}    

!macro PrintAt .x, .y {
	ldx #.y
    ldy #.x
    clc
    jsr Kernal_CursorPosition
    jsr Kernal_PrintImmediate
}


;;; define a pixel row of a C64 hardware sprite
!macro SpriteLine .v {
	!by .v >> 16, (.v >> 8) & 255, .v & 255
}
