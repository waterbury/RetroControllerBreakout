;SATURN TO PARALLEL
;(C) 2010 Ted Wahrburg (Xbox Live: Waterbury)
;For use with Microchip PIC16F747
;
;---------------------------------------------------------------------------------------------------------------------
;Delay Routine generated from "http://www.piclist.com/techref/piclist/codegen/delay.htm" Generated in 2009/2010.
;---------------------------------------------------------------------------------------------------------------------

;This Program comes with no warranty. USE AT YOUR OWN RISK. Free for all non-commercial use. Plese provide proper credit if code is used in future project.
;
;Converts Saturn, NES, and SNES Standard Game Pad protocol to Individual Button Outputs, with a pin for each button.
;Default Pin state is low. Pins go high with button presses

;SNES mode B Combos:
;Code Allows for a Mode B to be activated when the user presses X while holding Select on an SNES controller. 
;Pressing these two buttons in Mode B causes Mode A to become active again
;
;When in Mode B, Start+L causes RC0(Start Button) to go high. Start+R causes RC7(Select Button) to go high. 
;When in both Modes A & B, Start+A+B+C causes RC5 to go high. This combo is useful to trigger a utility button, such as the Xbox 360 Guide Button
;
;####################################
;Change Log:
; V.1.0) Implemented Saturn Controller Routine with coresponding status LEDs.
; V.2.0) Completely Rewrote Saturn Controller Routine, added support for SNES & NES Controllers. Saturn Mode B routines are broken in this version.
; V.2.1) Fixed Timing with SNES/NES Latch. Impliment Saturn Mode B Routines, it is not working correctly.....
; V.2.2) Fixed bug with SNES Mode B that would cause SAT Mode B Routine to be run instead..
; V.2.3) Uncommented Saturn Code. It works with Mode B Routine still commented out.
; V.2.4) Uncommented Saturn Mode B Code. Saturn controllers don't seem to be reading as detected as all..SNES Code + Mode B seems find.
; V.2.5) Saturn Mode B Routine works now. Problem seems to have stemmed from SAT_OPTIONS_REGISTER. 
;			The register resided @ address 0x33, and it's bits would always read high. Created psuedo "REGISTER_THIRTYTHREE" to reside @ 0x33. 
;			SAT_OPTIONS_REGISTER seems to work fine now in memeory address 0x34, at this time I do not understand why register 0x33 is giving me problems.
; V.2.6) Sets Saturn Reconnected bit as high on power up. Disabling Power Up Test. Changing Reconnect delay from 500ms to 200ms.
; V.2.7) Fixed SNES Left Bumper & Right Bumper inversion. L Button in Mode B is now tied to RB3, R Button is tied to RC2. Setting RA7 as an input, to be used as default output state select. 

;PIC(pin) : Saturn(pin: Input)
;RA0(02) : D3(7)
;RA1(03) : D2(8)
;RA2(04) : D1(2)
;RA3(05) : D0(3)
;PIC(pin) : Saturn(pin: Output)
;RA5(07) : S0(4)
;RA6(14) : S1(5)
;
;RA7(13) : Output Logic Level Select Input. Hold pin low to select Active High for button presses, Active Low for non-presses. Holding Pin high will inverse this.
;
;
;PIC(pin) : SNES(pin)
;RD0(19) : SNES Data Latch (SNES PIN 3) 'Orange'
;RD1(20) : SNES Data Clock (SNES PIN 2) 'Yellow'

;RD2(21) : NES Serial Data
;RD3(22) : SNES Serial Data(SNES PIN 4) 'Red'

;RD4(27) : NES Data Latch <--- Will be redundant as RD0 should work fine.
;RD5(28) : NES Data Clock

;RD7(30) : "SNES Mode B LED"

;RE0(08) : Saturn Contoller Plugged In LED
;RE1(09) : SNES Contoller Plugged In LED
;RE2(10) : NES Contoller Plugged In LED
;
;PIC(PIN) : Button Output
;RB0(33) : "R"
;RB1(34) : "X"
;RB2(35) : "Y"
;RB3(36) : "Z"
;RB4(37) : "D-RIGHT"
;RB5(38) : "D-LEFT"
;RB6(39) : "D-DOWN"
;RB7(40) : "D-UP"
;RC0(15) : "START"
;RC1(16) : "A"
;RC2(17) : "C"
;RC3(18) : "B"
;RC4(23) : "L"
;RC5(24) : "RESET CHECK, USE TO ATTACH TO RIGHT THUMSTICK BUTTON OR XBOX 360 GUIDE CONTROL FOR EXAMPLE"
;RC6(25) : "Saturn Mode B LED"
;RC7(26) : "SELECT"


;ERRORLEVEL -302 ;remove message about using proper bank



LIST P=PIC16F747;indicates intended PIC chip
#include <P16F747.inc>
;*****************************************
;CONFIGURATION BITS
    __config _CONFIG1, _INTRC_IO & _WDT_OFF & _PWRTE_OFF & _MCLR_OFF & _CP_OFF & _BOREN_0 & _IESO_OFF & _FCMEN_OFF & _DEBUG_OFF
	__config _CONFIG2, _BORSEN_0 & _IESO_OFF & _FCMEN_OFF

;*****************************************
;DEFINE FILES
    cblock 0x20
SAT_B_OUTPUT    ;create a temp file for prepairing port B
SAT_C_OUTPUT    ;create a temp file for prepairing port C
SAT_B_OUTPUT_TEMP
SAT_SELECT_11_OUTPUT
SATDIGITAL_ID;byte containing ID of Saturn Digital Pads, to be compared in Program
SAT_RESET_BITS
SAT_RESET_MASK

NES_C_OUTPUT
NES_B_OUTPUT
NES_DPAD_BITS
NES_DPAD_MASK

SNES_C_OUTPUT
SNES_B_OUTPUT
SNES_CONNECTED_CHECK; Indicates if controller is plugged in or not
SNES_RESET_MASK
SNES_RESET_CHECK

B_OUTPUT
C_OUTPUT

;SNES_OPTIONS_REGISTER Is a register for temp data, 
; - bit 0 is SNES Reset Buttons Held Check, 
; - bit 1 is SNES Combo X Button Held Check,
; - bit 2 is for SNES Reconnected Check
; - bit 3 is NES Connected Bit
; - bit 4 is NES Reconnected Check 
; - bit 5 is NES Reset Buttons Held Check,
; - bit 7 is SNES Mode B Bit
SNES_OPTIONS_REGISTER

REGISTER_THIRTYTHREE

;SAT_OPTIONS_REGISTER Is a register for temp data, 
; - bit 0 is Saturn Reset Buttons Held Check, 
; - bit 1 is Saturn Combo Z Button Held Check,
; - bit 2 is for Saturn Reconnected Check
; - bit 7 is Saturn Mode B Bit
SAT_OPTIONS_REGISTER

d1
d2
d3

    endc

;*****************************************
;SETUP PORTS
    org 0
Start
    ;bcf    STATUS,RP0
    ;bsf    STATUS,RP1 ; Select Register Page 2
    
	bcf    STATUS,RP1
    bsf    STATUS,RP0; select register Page 1

	movlw b'01100000'
	iorwf	OSCCON,F;sets PIC's Internal Oscillator speed at 4Mhz.
    
	MOVLW 0x0F ; Mask all analog capable pins
	MOVWF ADCON1 ; as digital I/O

	movlw   0x8F; make RA7 & RA<3:0> as inputs
    movwf   TRISA; and RA<6:4> as outputs

    clrf    TRISB; set RB<7:0> as outputs
    clrf    TRISC; set RC<7:0> as outputs

	movlw	0x0C; Mask RD3+RD2 as an inputs
    movwf	TRISD; and RD<7:4>, RA1, & RA0 as outputs

    clrf    TRISE; set RC<2:0> as outputs
    
	bcf		STATUS,RP0; back to Register Page 0

	;call	POWERUP_TEST

   	clrf	B_OUTPUT
	clrf	C_OUTPUT


	movlw	0x02
	movwf	SATDIGITAL_ID	
	
	;Sets Button Registers High by default----
	movlw	0xFF
	movwf	SNES_C_OUTPUT
	movwf	SNES_B_OUTPUT
	movwf	NES_C_OUTPUT
	movwf	NES_B_OUTPUT
	movwf	SAT_B_OUTPUT
	movwf	SAT_C_OUTPUT

	movlw	0x0F
	movwf	NES_DPAD_MASK
;------------------------------------------
	;clrf	RESET_CHECK	
	clrf	SNES_OPTIONS_REGISTER; clears register, SNES combo is disabled by default
	clrf	SAT_OPTIONS_REGISTER; clears register, Saturn combo is disabled by default

	clrf	PORTD;clears PORTD
	clrf	PORTA; set all of port A low by default
	
	movlw	0xF0
	movwf	SAT_RESET_MASK

	movlw	0x74
	movwf	SNES_RESET_MASK; Mask to check if SNES RESET has been activated, byte: 0111-0100

; Trigger as though SNES & NES controller has been recently reconnected on power up of microcontroller.
	bsf		SNES_OPTIONS_REGISTER, 2
	bsf		SNES_OPTIONS_REGISTER, 4

; Trigger as though Saturn controller has been recently reconnected on power up of microcontroller.
	bsf		SAT_OPTIONS_REGISTER,2



;*****************************************
;MAIN PROGRAM


BEGIN

	movlw	b'00100010'
	iorwf    PORTD,1;set NES+SNES data clock high as default by OR'ing 00100010 with current port stat

SNES_ROUTINE

    movlw	b'00110011'
	iorwf	PORTD;set set data latch + clock high for 12us, plus clock, OR's 00110011 with PORTD
	
	movlw   0xF0; +1us = 2us
	movwf	SAT_B_OUTPUT; makes first nibble of SAT_B_OUTPUT high, +1us = 3us
	movwf   SAT_C_OUTPUT; makes first nibble of SAT_C_OUTPUT high, +1us = 4us
	movwf	SAT_B_OUTPUT_TEMP; makes first nibble of SAT_B_OUTPUT_TEMP high, +1us = 5us
	movlw	0xFF;+1us = 6us
    movwf	B_OUTPUT;Sets all B_OUTPUT pins high by default, +1us = 7us
    movwf	C_OUTPUT;Sets all C_OUTPUT pins high by default, +1us = 8us
    movwf	NES_B_OUTPUT;Sets all NES_B_OUTPUT pins high by default, +1us = 9us
    movwf	NES_C_OUTPUT;Sets all NES_C_OUTPUT pins high by default, +1us = 10us
	clrf	SNES_CONNECTED_CHECK; +1us = 11us
	movlw	b'11100010';+1us = 12us
;---------------------------------------------------------------------
	andwf	PORTD,1;set NES+SNES data latch low for 6us, keeps both Clocks High
	movlw	0xFF;+1us = 2us
    movwf	SNES_B_OUTPUT;Sets all SNES_B_OUTPUT pins high by default, +1us = 3us
    movwf	SNES_C_OUTPUT;Sets all SNES_C_OUTPUT pins high by default, +1us = 4us
	movwf	SNES_RESET_CHECK;Sets SNES RESET CHECK Register HIGH, +1us = 5us
	movlw	b'11000000'; Prepare to Set Clock Bits Low, ignoring LED bits, +1us = 6us
	

;-----------------------------------------------------------------------------------  (SNES BUTTON  B, NES BUTTON A -CYCLE 01-)
	andwf	PORTD,1;set NES+SNES data clocks low for 6us and sample data
	movlw	b'00100010';+1us = 2us  Prepare SNES + NES Clock To Go High

	;NES-----------
	btfss	PORTD, 2   ;2 cycle(3us & 4us) if pin is high(button not pressed), 1 cycle (4us) if pin is low(button is pressed)
	bcf		NES_C_OUTPUT, 1  ;4us -set output pin low(button IS pressed)

	;SNES-----------
	btfss	PORTD, 3   ;2 cycle(5us & 6us) if pin is high(button not pressed), 1 cycle (5us) if pin is low(button is pressed)  "B Button?"
	bcf		SNES_RESET_CHECK, 1  ;6us -set output pin low(button IS pressed)

;-------------------------------------------------------------------------------------------------------------------------------------------------------------
	iorwf	PORTD,1;set NES+SNES data clock high for 6us by OR'ing PORTD, all pins should be low except LEDS prior to this
	movlw	0x0F; +1us = 2us
	movwf	SAT_SELECT_11_OUTPUT; +1us = 3us
	movlw	0xFF;+1us = 4us
	movwf	NES_DPAD_BITS;Sets NES_DPAD_BITS Register HIGH, +1us = 5us
	movlw	b'11000000';+1us = 6us
;-----------------------------------------------------------------------------------  (SNES BUTTON  Y, NES BUTTON B  -CYCLE 02-)
	andwf	PORTD,1;set NES+SNES data clocks low for 6us and sample data
	movlw	b'00100010';+1us = 2us  Prepare SNES + NES Clock To Go High

	;NES-----------
	btfss	PORTD, 2   ;2 cycle(3us & 4us) if pin is high(button not pressed), 1 cycle (4us) if pin is low(button is pressed)
	bcf		NES_B_OUTPUT, 1  ;4us -set output pin low(button IS pressed)

	;SNES-----------
	btfss	PORTD, 3   ;2 cycle(5us & 6us) if pin is high(button not pressed), 1 cycle (5us) if pin is low(button is pressed)
	bcf		SNES_B_OUTPUT, 1  ;6us -set output pin low(button IS pressed)


;-------------------------------------------------------------------------------------------------------------------------------------------------------------
	iorwf	PORTD,1;set NES+SNES data clock high for 6us by OR'ing PORTD, all pins should be low except LEDS prior to this
	call	four_microsec;+4us = 5us
	movlw	b'11000000';+1us = 6us
;-----------------------------------------------------------------------------------  (SNES+NES BUTTON  SELECT  -CYCLE 03-)
	andwf	PORTD,1;set NES+SNES data clocks low for 6us and sample data
	movlw	b'00100010';+1us = 2us  Prepare SNES + NES Clock To Go High

	;NES-----------
	btfss	PORTD, 2   ;2 cycle(3us & 4us) if pin is high(button not pressed), 1 cycle (4us) if pin is low(button is pressed)
	bcf		NES_C_OUTPUT, 7  ;4us -set output pin low(button IS pressed)

	;SNES-----------
	btfss	PORTD, 3   ;2 cycle(5us & 6us) if pin is high(button not pressed), 1 cycle (5us) if pin is low(button is pressed)
	bcf		SNES_RESET_CHECK, 7  ;6us -set output pin low(button IS pressed)

	 

;-------------------------------------------------------------------------------------------------------------------------------------------------------------
	iorwf	PORTD,1;set NES+SNES data clock high for 6us by OR'ing PORTD, all pins should be low except LEDS prior to this
	call	four_microsec;+4us = 5us
	movlw	b'11000000';+1us = 6us
;-----------------------------------------------------------------------------------  (SNES+NES BUTTON  START  -CYCLE 04-)
	andwf	PORTD,1;set NES+SNES data clocks low for 6us and sample data
	movlw	b'00100010';+1us = 2us  Prepare SNES + NES Clock To Go High

	;NES-----------
	btfss	PORTD, 2   ;2 cycle(3us & 4us) if pin is high(button not pressed), 1 cycle (4us) if pin is low(button is pressed)
	bcf		NES_C_OUTPUT, 0  ;4us -set output pin low(button IS pressed)

	;SNES-----------
	btfss	PORTD, 3   ;2 cycle(5us & 6us) if pin is high(button not pressed), 1 cycle (5us) if pin is low(button is pressed)
	bcf		SNES_RESET_CHECK, 0  ;6us -set output pin low(button IS pressed)


;-------------------------------------------------------------------------------------------------------------------------------------------------------------
	iorwf	PORTD,1;set NES+SNES data clock high for 6us by OR'ing PORTD, all pins should be low except LEDS prior to this
	call	four_microsec;+4us = 5us
	movlw	b'11000000';+1us = 6us
;-----------------------------------------------------------------------------------  (SNES+NES BUTTON  D-UP  -CYCLE 05-)
	andwf	PORTD,1;set NES+SNES data clocks low for 6us and sample data
	movlw	b'00100010';+1us = 2us  Prepare SNES + NES Clock To Go High

	;NES-----------
	btfss	PORTD, 2   ;2 cycle(3us & 4us) if pin is high(button not pressed), 1 cycle (5us) if pin is low(button is pressed)
	bcf		NES_DPAD_BITS, 7  ;4us -set output pin low(button IS pressed)

	;SNES-----------
	btfss	PORTD, 3   ;2 cycle(5us & 6us) if pin is high(button not pressed), 1 cycle (5us) if pin is low(button is pressed)
	bcf		SNES_B_OUTPUT, 7  ;6us -set output pin low(button IS pressed)


;-------------------------------------------------------------------------------------------------------------------------------------------------------------
	iorwf	PORTD,1;set NES+SNES data clock high for 6us by OR'ing PORTD, all pins should be low except LEDS prior to this
	call	four_microsec;+4us = 5us
	movlw	b'11000000';+1us = 6us
;-----------------------------------------------------------------------------------  (SNES+NES BUTTON  D-DOWN  -CYCLE 06-)
	andwf	PORTD,1;set NES+SNES data clocks low for 6us and sample data
	movlw	b'00100010';+1us = 2us  Prepare SNES + NES Clock To Go High

	;NES-----------
	btfss	PORTD, 2   ;2 cycle(3us & 4us) if pin is high(button not pressed), 1 cycle (5us) if pin is low(button is pressed)
	bcf		NES_DPAD_BITS, 6  ;4us -set output pin low(button IS pressed)

	;SNES-----------
	btfss	PORTD, 3   ;2 cycle(5us & 6us) if pin is high(button not pressed), 1 cycle (5us) if pin is low(button is pressed)
	bcf		SNES_B_OUTPUT, 6  ;6us -set output pin low(button IS pressed)


;-------------------------------------------------------------------------------------------------------------------------------------------------------------
	iorwf	PORTD,1;set NES+SNES data clock high for 6us by OR'ing PORTD, all pins should be low except LEDS prior to this
	call	four_microsec;+4us = 5us
	movlw	b'11000000';+1us = 6us
;-----------------------------------------------------------------------------------  (SNES+NES BUTTON  D-LEFT  -CYCLE 07-)
	andwf	PORTD,1;set NES+SNES data clocks low for 6us and sample data
	movlw	b'00100010';+1us = 2us  Prepare SNES + NES Clock To Go High
	
	;NES-----------
	btfss	PORTD, 2   ;2 cycle(3us & 4us) if pin is high(button not pressed), 1 cycle (5us) if pin is low(button is pressed)
	bcf		NES_DPAD_BITS, 5  ;4us -set output pin low(button IS pressed)

	;SNES-----------
	btfss	PORTD, 3   ;2 cycle(5us & 6us) if pin is high(button not pressed), 1 cycle (5us) if pin is low(button is pressed)
	bcf		SNES_B_OUTPUT, 5  ;6us -set output pin low(button IS pressed)


;-------------------------------------------------------------------------------------------------------------------------------------------------------------
	iorwf	PORTD,1;set NES+SNES data clock high for 6us by OR'ing PORTD, all pins should be low except LEDS prior to this
	nop		;+1us = 2us
	nop		;+1us = 3us
	nop		;+1us = 4us
	bcf		SNES_OPTIONS_REGISTER,3; Sets NES Connected bit low, will go back high soon if controller is connected. +1us = 5us
	movlw	b'11000000';+1us = 6us
;-----------------------------------------------------------------------------------  (SNES+NES BUTTON  D-RIGHT  -CYCLE 08-)
	andwf	PORTD,1;set NES+SNES data clocks low for 6us and sample data
	movlw	b'00100010';+1us = 2us  Prepare SNES + NES Clock To Go High

	btfss	PORTD, 2   ;2 cycle(3us & 4us) if pin is high(button not pressed), 1 cycle (5us) if pin is low(button is pressed)
	bcf		NES_DPAD_BITS, 4  ;4us -set output pin low(button IS pressed)

	btfss	PORTD, 3   ;2 cycle(5us & 6us) if pin is high(button not pressed), 1 cycle (5us) if pin is low(button is pressed)
	bcf		SNES_B_OUTPUT, 4  ;6us -set output pin low(button IS pressed)


;-------------------------------------------------------------------------------------------------------------------------------------------------------------
	iorwf	PORTD,1;set NES+SNES data clock high for 6us by OR'ing PORTD, all pins should be low except LEDS prior to this

;NES Pad Detection-----------------------------
	movf	NES_DPAD_BITS,0;Moves DPad bits to W Register with bits 7-4 high, 1-1-1-1 [Du-Dd-Dl-Dr] +1us = 2us
	xorwf	NES_DPAD_MASK,0; XOR register and w, w will be zero if f = w, +1us = 3us
	btfss	STATUS, Z ; Skip if zero flag is set, this would mean no controller is connected. 2 cycle(4us & 5us) if bit is high(controller not connected), 1 cycle (4us) if bit is low(controller is connected)
	bsf		SNES_OPTIONS_REGISTER,3; Set NES Controller Bit High if not all D-Pad buttons are marked as pressed +1us = 5us
	
	movlw	b'11100000';+1us = 6us
;-----------------------------------------------------------------------------------  (SNES BUTTON  A  -CYCLE 09-)
	andwf	PORTD,1;set SNES data clock low for 6us and sample data
	movlw	b'00100010';+1us = 2us  Prepare SNES + NES Clock To Go High
	nop;3us
	nop;4us

	btfss	PORTD, 3   ;2 cycle(5us & 6us) if pin is high(button not pressed), 1 cycle (5us) if pin is low(button is pressed)
	bcf		SNES_RESET_CHECK, 3  ;6us -set output pin low(button IS pressed)


;-------------------------------------------------------------------------------------------------------------------------------------------------------------
	iorwf	PORTD,1;set NES+SNES data clock high for 6us by OR'ing PORTD, all pins should be low except LEDS prior to this

	movf	NES_DPAD_BITS,0;Moves NES DPad Bits to W, +1us = 2us
	andwf	NES_B_OUTPUT,1;AND's NES DPad bits with rest of NES B Output bits +1us = 3us
	btfss	SNES_OPTIONS_REGISTER,3 ; Skip if NES Controller is connected. 2 cycle(4us & 5us) if bit is high(controller is connected), 1 cycle (4us) if bit is low(controller is not connected)
	bsf		SNES_OPTIONS_REGISTER,4; Set NES Reconnect Controller Bit High. Will go low after controller is reconnected. +1us = 5us

	movlw	b'11100000';+1us = 6us
;-----------------------------------------------------------------------------------  (SNES BUTTON  X  -CYCLE 10-)
	andwf	PORTD,1;set SNES data clock low for 6us and sample data
	movlw	b'00100010';+1us = 2us  Prepare SNES + NES Clock To Go High
	nop;3us
	nop;4us

	btfss	PORTD, 3   ;2 cycle(5us & 6us) if pin is high(button not pressed), 1 cycle (5us) if pin is low(button is pressed)
	bcf		SNES_B_OUTPUT, 2  ;6us -set output pin low(button IS pressed)


;-------------------------------------------------------------------------------------------------------------------------------------------------------------
	iorwf	PORTD,1;set NES+SNES data clock high for 6us by OR'ing PORTD, all pins should be low except LEDS prior to this
	nop		;+1us = 2us
	nop		;+1us = 3us
	btfss	SNES_OPTIONS_REGISTER,3 ; Skip if NES Controller is connected. 2 cycle(4us & 5us) if bit is high(controller is connected), 1 cycle (4us) if bit is low(controller is not connected)
	bcf		PORTD,6; clear NES Plugged In LED, +1us = 5us
	movlw	b'11100000';+1us = 6us
;-----------------------------------------------------------------------------------  (SNES BUTTON  L  -CYCLE 11-)
	andwf	PORTD,1;set SNES data clock low for 6us and sample data
	movlw	b'00100010';+1us = 2us  Prepare SNES + NES Clock To Go High
	nop;3us
	nop;4us

	btfss	PORTD, 3   ;2 cycle(5us & 6us) if pin is high(button not pressed), 1 cycle (5us) if pin is low(button is pressed)
	bcf		SNES_C_OUTPUT, 4  ;6us -set output pin low(button IS pressed)


;------------------------------------------------------------------------------------
	iorwf	PORTD,1;set NES+SNES data clock high for 6us by OR'ing PORTD, all pins should be low except LEDS prior to this
;SAT SELECT_00------------------------------------------
	movlw	b'00000000'; +1 = 2us
    movwf	PORTA;set Select to 00, +1 = 3us
	movf    PORTA,0;grab the data from the controller, +1 = 4us
    iorwf	SAT_B_OUTPUT,1;outputs the data to port B prep Current BYTE Format 1-1-1-1 Z-Y-X-R, +1 = 5us

	movlw	b'11100000';+1us = 6us
;-----------------------------------------------------------------------------------  (SNES BUTTON  R  -CYCLE 12-)
	andwf	PORTD,1;set SNES data clock low for 6us and sample data
	movlw	b'00100010';+1us = 2us  Prepare SNES + NES Clock To Go High

	btfss	PORTD, 3   ;2 cycle(3us & 4us) if pin is high(button not pressed), 1 cycle (3us) if pin is low(button is pressed)
	bcf		SNES_B_OUTPUT, 0;4us  set output pin low(button IS pressed)

	call	NULLBUTTONS ; 2 cycles (5us & 6us)
	iorwf	PORTD,1;set NES+SNES data clock high by OR'ing PORTD, all pins should be low except LEDS prior to this

	
;goto	SAT_APPEND_ALL_BITS_DONT ; Skip Saturn Routine

;SAT------------------------------------------------------------------
SAT_PLUGGED_IN_CHECK
	movf	SAT_SELECT_11_OUTPUT,0; Moves Register to W
	xorwf	SATDIGITAL_ID,0; XOR register and w, w will be zero if f == w
	btfsc	STATUS, Z ; Skip if Zero flag is clear AKA Saturn Digital Pad is connected, execute next line if it is
	goto	SAT_PLUGGED_IN_OK
;If a controlled is unplugged, prep the output ports to represent no button presses and trigger bit indicating controller is unplugged	
	bsf		C_OUTPUT,6;Make sure Mode B LED is not illuminated
	bcf		PORTE,0; Clear Saturn Plugged in LED
	bsf		SAT_OPTIONS_REGISTER,2; Set bit notifying that Saturn Controller is not present. This is important as when it is reconnected, a pause is implimented
	goto	SAT_APPEND_ALL_BITS_DONT

SAT_PLUGGED_IN_OK
	btfsc	SAT_OPTIONS_REGISTER,2;executes next line if Saturn controller has recently been reconnected. Skips if controller has been connected
	goto	SAT_RECONNECT

	btfss	SAT_C_OUTPUT, 0; executes next line if Start button is pressed. Skips if not AKA bit high, continuing to DATAOUT
	goto	SAT_COMBO

SAT_APPEND_ALL_BITS
	btfsc	SAT_OPTIONS_REGISTER,0;executes next line if Saturn Reset has recently been performed. Skips if not
	goto	SATRESETHELD

	;bsf		PORTE,0; Sets Saturn Plugged in LED

	movf	SAT_B_OUTPUT,0;Moves SAT B Output to W
	andwf	B_OUTPUT,1;ANDS with B Port data
	movf	SAT_C_OUTPUT,0;Moves SAT C Output to W
	andwf	C_OUTPUT,1;ANDS with C Port data

SAT_APPEND_ALL_BITS_DONT



;SNES-----------------------------------------------------------------
SNES_PLUGGED_IN_CHECK
;Checks if Controller is plugged in...If it is proceed to SNES_PLUGGED_IN_OK...	
	movf	SNES_CONNECTED_CHECK,0
	addlw	0x01
	movwf	SNES_CONNECTED_CHECK
	btfsc	SNES_CONNECTED_CHECK, 4   ;Checks in Bit 4 is set, exectue next line if it is, else skip
	goto	SNES_PLUGGED_IN_OK

;If a controlled is unplugged, prep the output ports to represent no button presses and trigger bit indicating controller is unplugged	
	bcf		PORTE,1; Clear SNES Plugged in LED
	bcf		PORTD,7; Clear SNES Mode B LED
	bsf		SNES_OPTIONS_REGISTER,2; Set bit notifying that SNES Controller is not present. This is important as when it is reconnected, a pause is implimented
	goto	SNES_APPEND_ALL_BITS_DONT
	
	
SNES_PLUGGED_IN_OK
	btfsc	SNES_OPTIONS_REGISTER,2;executes next line if controller recently was reconnected. Skips if controller has been connected
	goto	SNES_RECONNECT
	
	btfss	SNES_RESET_CHECK,7;executes next line if select button is pressed. Skips if not AKA bit high, continuing to SNES_APPEND_RESET_BITS
	goto	SNES_COMBO
	
SNES_APPEND_NON_RESET_BITS	
	movf	SNES_B_OUTPUT,0;Moves NES B Output to W
	andwf	B_OUTPUT,1;ANDS with B Port data
	movf	SNES_C_OUTPUT,0;Moves NES C Output to W
	andwf	C_OUTPUT,1;ANDS with C Port data

	btfsc	SNES_OPTIONS_REGISTER,0; If Reset had recently been performed, all buttons will need to be released before appending them. Executes next line until this happens.
	goto	SNESRESETHELD
	
SNES_APPEND_RESET_BITS
	movf	SNES_RESET_CHECK,0;movews SNES_RESET_CHECK to W
	andwf	C_OUTPUT,1; appends SNES_RESET_CHECK to C_OUTPUT

SNES_APPEND_RESET_BITS_DONT
SNES_APPEND_ALL_BITS_DONT
	
;NES------------------------------------------------------------------
NES_PLUGGED_IN_CHECK
	btfss	SNES_OPTIONS_REGISTER, 3;executes next line if NES controller is not connected. Skips if controller is connected
	goto	NES_APPEND_ALL_BITS_DONT

NES_PLUGGED_IN_OK
	btfsc	SNES_OPTIONS_REGISTER, 4;executes next line if NES controller has recently been reconnected. Skips if controller has been connected
	goto	NES_RECONNECT

	btfss	NES_C_OUTPUT, 7; executes next line if Select button is pressed. Skips if not AKA bit high, continuing to DATAOUT
	goto	NES_RESET_FUNCTION

NES_APPEND_ALL_BITS
	btfsc	SNES_OPTIONS_REGISTER, 5;executes next line if NES Reset has recently been performed. Skips if not
	goto	NESRESETHELD

	movf	NES_B_OUTPUT,0;Moves NES B Output to W
	andwf	B_OUTPUT,1;ANDS with B Port data
	movf	NES_C_OUTPUT,0;Moves NES C Output to W
	andwf	C_OUTPUT,1;ANDS with C Port data
	
NES_APPEND_ALL_BITS_DONT




DATAOUT
;Routine to Write To Output Ports-------------------------

;Ignore Incompatible D-Pad States-------------------------
	btfss	B_OUTPUT,5; If D-Pad Left is not pressed skip, else...
	bsf		B_OUTPUT,4; If D-Pad Left is pressed, ensure D-Pad Right will not be pressed

	btfss	B_OUTPUT,6; If D-Pad Down is not pressed skip, else...
	bsf		B_OUTPUT,7; If D-Pad Down is pressed, ensure D-Pad Up will not be pressed

;Actual Write Operations-----------------------------------
	comf    B_OUTPUT,0;inverts B_OUTPUT, moves to W
    movwf	PORTB;moves from W register to port B

	comf    C_OUTPUT,0;inverts C_OUTPUT, moves to W
    movwf	PORTC;moves from W register to port C

	;call	four_ms_Delay;Delay = 0.04 seconds AKA 4ms.

    goto    BEGIN;loop back to start




NULLBUTTONS

;------------------------------------------------------------------------------------
	iorwf	PORTD,1;set NES+SNES data clock high for 6us by OR'ing PORTD, all pins should be low except LEDS prior to this
;SELECT_01------------------------------------------
    movlw    b'01000000'; +1 = 2us
    movwf    PORTA;set Select to 01, +1 = 3us
    movf    PORTA,0;grab the data from the controller, +1 = 4us
    iorwf    SAT_B_OUTPUT_TEMP,1;appends the data to temp port B prep. Current BYTE Format 1-1-1-1 Du-Dd-Dl-Dr, +1 = 5us

	movlw	b'11100000';+1us = 6us
;-----------------------------------------------------------------------------------  (NULL -CYCLE 13-)
	andwf	PORTD,1;set SNES data clock low for 6us and sample bit 13

	btfsc	SAT_OPTIONS_REGISTER,7;If Saturn Mode B is enabled, make sure Saturn Mode B LED gets illuminated. ;2 cycle(2us & 3us)
	bcf		C_OUTPUT,6;+1us = 3us

	btfsc	PORTD, 3   ;2 cycle(4us & 5us) 
	bsf		SNES_CONNECTED_CHECK, 0  ;5us -set output pin low(button IS pressed)

	movlw	b'00100010';+1us = 6us  Prepare SNES + NES Clock To Go High
;------------------------------------------------------------------------------------
	iorwf	PORTD,1;set NES+SNES data clock high for 6us by OR'ing PORTD, all pins should be low except LEDS prior to this
;SELECT_10------------------------------------------
    movlw   b'00100000'; +1 = 2us
    movwf   PORTA;set Select to 10, +1 = 3us
	movf	PORTA,0;grab the data from the controller, moves to W register, +1 = 4us
	iorwf   SAT_C_OUTPUT,1;moves the data to port C prep. Current BYTE Format: 1-1-1-1 B-C-A-St, +1 = 5us

	movlw	b'11100000';+1us = 6us
;-----------------------------------------------------------------------------------  (NULL -CYCLE 14-)
	andwf	PORTD,1;set SNES data clock low for 6us and sample bit 14

	movf	SAT_C_OUTPUT,0;+1us = 2us
	movwf	SAT_RESET_BITS;+1us = 3us

	btfsc	PORTD, 3   ;2 cycle(4us & 5us)
	bsf		SNES_CONNECTED_CHECK, 1  ;5us -set output pin low(button IS pressed)
	movlw	b'00100010';+1us = 6us  Prepare SNES + NES Clock To Go High
;------------------------------------------------------------------------------------
	iorwf	PORTD,1;set NES+SNES data clock high for 6us by OR'ing PORTD, all pins should be low except LEDS prior to this
;SELECT_11------------------------------------------
    movlw   b'01100000'; +1 = 2us      
    movwf   PORTA;set Select to 11, +1 = 3us
    movf	PORTA,0;grab the data from the controller, +1 = 4us
	andwf   SAT_SELECT_11_OUTPUT,1;appends the data to temp port C prep. Current BYTE Format: 0-0-0-0 #-#-#-L, +1 = 5us

	movlw	b'11100000';+1us = 6us
;-----------------------------------------------------------------------------------  (NULL -CYCLE 15-)
	andwf	PORTD,1;set SNES data clock low for 6us and sample bit 15

	swapf	SAT_B_OUTPUT_TEMP,0; Swaps nibbles of temp B Output and places result into W, +1 = 2us
	andwf	SAT_B_OUTPUT,1; ANDs result with Saturn B Output, +1 = 3us

	btfsc	PORTD, 3   ;2 cycle(4us & 5us)
	bsf		SNES_CONNECTED_CHECK, 2  ;5us -set output pin low(button IS pressed)

	movlw	b'00100010';+1us = 6us  Prepare SNES + NES Clock To Go High
;------------------------------------------------------------------------------------
	iorwf	PORTD,1;set NES+SNES data clock high for 6us by OR'ing PORTD, all pins should be low except LEDS prior to this
;Prep Registers-------------------------------------
	nop;2us
	btfss	SAT_SELECT_11_OUTPUT,0; Skip if L Button is not pressed, else...., 2 cycle(3us & 4us) if bit is high(Button not pressed), 1 cycle (4us) if bit is low(Button is pressed)
	bcf		SAT_C_OUTPUT,4; set L Button low in C_OUTPUT +1 = 4us
	bcf		SAT_SELECT_11_OUTPUT,0; Clears bit 0, +1us = 5us
	movlw	b'11100000';+1us = 6us
;-----------------------------------------------------------------------------------  (NULL -CYCLE 16-)
	andwf	PORTD,1;set SNES data clock low for 6us and sample bit 16

	btfsc	PORTD, 3   ;2 cycle(2us & 3us)
	bsf		SNES_CONNECTED_CHECK, 3  ;3us -set output pin low(button IS pressed)
	movlw	b'00100010';+1us = 4us  Prepare SNES + NES Clock To Go High

	return ; 2 cycles (5us & 6us)




;==========================================================
SNES_COMBO
	btfsc	SNES_B_OUTPUT, 2 ; Skip if X Button is pressed, Moves to Mode Function otherwise, indicate X Button is released as well
	goto	SNES_X_RELEASED

;SNES Mode B Check
	btfss	SNES_OPTIONS_REGISTER,1; If SNES X Button is still held immediately after Mode Inversion, go to functions, else invert mode!
	goto	SNES_MODE_INVERT

	bsf		SNES_B_OUTPUT, 2;disables appending X Button Press


;==========================================================
SNES_RESET_FUNCTION


;--------------------------- Checks if Reset Buttons are held

	movf	SNES_RESET_CHECK,0; Moves reset check register to w
	xorwf	SNES_RESET_MASK,0; XOR register and w, w will be zero if f = w
	btfss	STATUS, Z ; Skip if zero flag is set, AKA execute next line if Reset had not been pressed
	goto	SNES_MODE_FUNCTION

;--------------------------- If Reset Buttons are held, execute code below 
	bcf		C_OUTPUT,5;If reset is set, set Reset/Utility Button low
	bsf		SNES_OPTIONS_REGISTER,0;sets bit to notify Reset has been checked
	goto	SNES_APPEND_RESET_BITS_DONT;Do not append Reset Bits

;==========================================================
SNES_MODE_FUNCTION
;SNES Mode B Functions
	btfss	SNES_OPTIONS_REGISTER,7; If SNES Mode B is NOT Active, move back to SNES_APPEND_NON_RESET_BITS, else continue
	goto	SNES_APPEND_NON_RESET_BITS	

;------------------------------------------------------------------------
	btfsc	SNES_OPTIONS_REGISTER,0; If Reset had recently been performed, all buttons will need to be released before continuing. Executes next line until this happens.
	goto	SNESRESETHELD

	;bsf		SNES_RESET_CHECK,7; Clear SNES Select Button 	
;------------------------------------------------------------------------
SNES_COMBO_BUTTON_1
	btfsc	SNES_C_OUTPUT,4; If SNES L Shoulder is NOT Pressed, check other combo button, else proceed....
	goto	SNES_COMBO_BUTTON_2
	
	;bsf		SNES_C_OUTPUT,4; Clear L Shoulder Button Press and...
	bcf		B_OUTPUT,3; Trigger Left Bumper Press
;------------------------------------------------------------------------
SNES_COMBO_BUTTON_2
	btfsc	SNES_B_OUTPUT,0; If SNES R Shoulder is NOT Pressed, check other combo button, else proceed....
	goto	SNES_COMBO_BUTTON_3
	
	;bsf		SNES_B_OUTPUT,0; Clear R Shoulder Button Press and...
	bcf		C_OUTPUT,2; Trigger Right Bumper Press
;------------------------------------------------------------------------
SNES_COMBO_BUTTON_3
	btfsc	SNES_RESET_CHECK,0; If SNES Start is NOT Pressed, Move to SNES_COMBO_FINISH, else proceed....
	goto	SNES_COMBO_FINISH
	
	;bsf		SNES_RESET_CHECK,0; Clear Start Button Press and...
	bcf		C_OUTPUT,7; Trigger Select Button Press
;------------------------------------------------------------------------
SNES_COMBO_FINISH
	goto	SNES_APPEND_ALL_BITS_DONT;Do Not Append any SNES Data bits to C_OUTPUT buffer


;==========================================================
SNESRESETHELD

	btfss	SNES_RESET_CHECK,0; If Start is Pressed, go straight to SNES_APPEND_RESET_BITS_DONT and do not append Reset buttons, continue to check other buttons if it is not pressed.
	goto	SNES_APPEND_RESET_BITS_DONT

	btfss	SNES_RESET_CHECK,1; If B is Pressed, go straight to SNES_APPEND_RESET_BITS_DONT and do not append Reset buttons, continue to check other buttons if it is not pressed.
	goto	SNES_APPEND_RESET_BITS_DONT

	btfss	SNES_RESET_CHECK,3; If A is Pressed, go straight to SNES_APPEND_RESET_BITS_DONT and do not append Reset buttons, continue to check other buttons if it is not pressed.
	goto	SNES_APPEND_RESET_BITS_DONT

	btfss	SNES_RESET_CHECK,7; If Select is Pressed, go straight to SNES_APPEND_RESET_BITS_DONT and do not append Reset buttons, continue to check other buttons if it is not pressed.
	goto	SNES_APPEND_RESET_BITS_DONT


	bcf		SNES_OPTIONS_REGISTER,0;clears bit to notify Reset Buttons no longer need to be not appended.
	
	goto	SNES_APPEND_RESET_BITS

;==========================================================
SNES_X_RELEASED
	bcf		SNES_OPTIONS_REGISTER,1; X Button is not held, do not continue to stop Inversion
	goto	SNES_RESET_FUNCTION
	
;==========================================================	
SNES_MODE_INVERT
	movlw	0x80
	xorwf	SNES_OPTIONS_REGISTER,1; Inverts SNES Mode
	bsf		SNES_B_OUTPUT, 2;disables appending X Button Press
	bsf		SNES_OPTIONS_REGISTER,1; Will Stay high until X is released

	btfsc	SNES_OPTIONS_REGISTER,7;If SNES Mode B is active, execute next line, else skip.
	bsf		PORTD,7;Sets SNES Mode B LED

	btfss	SNES_OPTIONS_REGISTER,7;If SNES Mode B is not active, execute next line, else skip.
	bcf		PORTD,7;Clears SNES Mode B LED
	
	goto	SNES_RESET_FUNCTION


;==========================================================	
SNES_RECONNECT

	btfsc	SNES_OPTIONS_REGISTER,7;If SNES Mode B is active, execute next line, else skip.
	bsf		PORTD,7;Sets SNES Mode B LED High

	bsf		PORTE,1; Set SNES Plugged in LED

	call	two_hundred_ms_Delay

	bcf		SNES_OPTIONS_REGISTER,2; Clear bit notifying that SNES Controller was recently reconnected. 
	goto	SNES_APPEND_ALL_BITS_DONT

;==========================================================	
SAT_RECONNECT

	bsf		PORTE,0; Set Saturn Plugged in LED

	call	two_hundred_ms_Delay

	bcf		SAT_OPTIONS_REGISTER,2; Clear bit notifying that Saturn Controller was recently reconnected. 
	goto	SAT_APPEND_ALL_BITS_DONT

;==========================================================	
NES_RECONNECT
	bsf		PORTE,2; Set NES Plugged in LED

	call	two_hundred_ms_Delay

	bcf		SNES_OPTIONS_REGISTER,4; Clear bit notifying that NES Controller is reconnected. 
	goto	NES_APPEND_ALL_BITS_DONT


;==========================================================
NES_RESET_FUNCTION
;A+B+Start+Select need to be held for reset. Will get here if Select is held. No need to check for it, would be redundant.

	btfsc	NES_B_OUTPUT, 1; If B is not Pressed, go straight to NES_APPEND_ALL_BITS.
	goto	NES_APPEND_ALL_BITS

	btfsc	NES_C_OUTPUT, 1; If A is not Pressed, go straight to NES_APPEND_ALL_BITS.
	goto	NES_APPEND_ALL_BITS

	btfsc	NES_C_OUTPUT, 0; If Start is not Pressed, go straight to NES_APPEND_ALL_BITS.
	goto	NES_APPEND_ALL_BITS

	bcf		C_OUTPUT,5;If reset is set, set Reset/Utility Button low
	bsf		SNES_OPTIONS_REGISTER,5;Sets bit to notify Reset Buttons need checked to be released

	goto	NES_APPEND_ALL_BITS_DONT; Don't append NES Buttons
	
	
;==========================================================
NESRESETHELD

	btfss	NES_C_OUTPUT,0; If Start is Pressed, go straight to NES_APPEND_ALL_BITS_DONT and do not append Reset buttons, continue to check other buttons if it is not pressed.
	goto	NES_APPEND_ALL_BITS_DONT

	btfss	NES_B_OUTPUT, 1; If B is Pressed, go straight to NES_APPEND_ALL_BITS_DONT and do not append Reset buttons, continue to check other buttons if it is not pressed.
	goto	NES_APPEND_ALL_BITS_DONT

	btfss	NES_C_OUTPUT, 1; If A is Pressed, go straight to NES_APPEND_ALL_BITS_DONT and do not append Reset buttons, continue to check other buttons if it is not pressed.
	goto	NES_APPEND_ALL_BITS_DONT

	btfss	NES_C_OUTPUT,7; If Select is Pressed, go straight to NES_APPEND_ALL_BITS_DONT and do not append Reset buttons, continue to check other buttons if it is not pressed.
	goto	NES_APPEND_ALL_BITS_DONT


	bcf		SNES_OPTIONS_REGISTER,5;clears bit to notify Reset Buttons no longer need to be not appended.
	
	goto	NES_APPEND_ALL_BITS
















;==========================================================
SAT_COMBO
	;goto	SAT_APPEND_ALL_BITS;Temporary....Shits not working.

	btfsc	SAT_B_OUTPUT, 3 ; Skip if Z Button is pressed, Moves to Mode Function otherwise, indicate Z Button is released as well
	goto	SAT_Z_RELEASED

;SAT Mode B Check
	btfss	SAT_OPTIONS_REGISTER,1; If SAT Z Button is still held immediately after Mode Inversion, go to functions, else invert mode!
	goto	SAT_MODE_INVERT

	bsf		SAT_B_OUTPUT, 3;disables appending Z Button Press


;==========================================================
SAT_RESET_FUNCTION


;--------------------------- Checks if Reset Buttons are held

	movf	SAT_RESET_BITS,0; Moves reset check register to w
	xorwf	SAT_RESET_MASK,0; XOR register and w, w will be zero if f = w
	btfss	STATUS, Z ; Skip if zero flag is set, AKA execute next line if Reset had not been pressed
	goto	SAT_MODE_FUNCTION

;--------------------------- If Reset Buttons are held, execute code below 
	bcf		C_OUTPUT,5;If reset is set, set Reset/Utility Button low
	bsf		SAT_OPTIONS_REGISTER,0;sets bit to notify Reset has been checked
	goto	SAT_APPEND_ALL_BITS_DONT;Do not append Saturn Bits

;==========================================================
SAT_MODE_FUNCTION
;SAT Mode B Functions
	btfss	SAT_OPTIONS_REGISTER,7; If SAT Mode B is NOT Active, move back to SAT_APPEND_ALL_BITS, else continue
	goto	SAT_APPEND_ALL_BITS	

;------------------------------------------------------------------------
	btfsc	SAT_OPTIONS_REGISTER,0; If Reset had recently been performed, all buttons will need to be released before continuing. Executes next line until this happens.
	goto	SATRESETHELD

;------------------------------------------------------------------------
SAT_COMBO_BUTTON_1
	btfsc	SAT_C_OUTPUT,4; If SAT L Shoulder is NOT Pressed, check other combo button, else proceed....
	goto	SAT_COMBO_BUTTON_2
	
	;bsf		SAT_C_OUTPUT,4; Clear L Shoulder Button Press and...
	bcf		C_OUTPUT,0; Trigger Start Button Press
;------------------------------------------------------------------------
SAT_COMBO_BUTTON_2
	btfsc	SAT_B_OUTPUT,0; If SAT R Shoulder is NOT Pressed, Move to SAT_COMBO_FINISH, else proceed....
	goto	SAT_COMBO_FINISH
	
	;bsf		SAT_B_OUTPUT,0; Clear R Shoulder Button Press and...
	bcf		C_OUTPUT,7; Trigger Select Button Press
;------------------------------------------------------------------------
SAT_COMBO_FINISH
	goto	SAT_APPEND_ALL_BITS_DONT;Do Not Append any SAT Data bits to C_OUTPUT buffer


;==========================================================
SATRESETHELD

	btfss	SAT_C_OUTPUT,0; If Start is Pressed, go straight to SAT_APPEND_RESET_BITS_DONT and do not append Reset buttons, continue to check other buttons if it is not pressed.
	goto	SAT_APPEND_ALL_BITS_DONT

	btfss	SAT_C_OUTPUT,1; If A is Pressed, go straight to SAT_APPEND_RESET_BITS_DONT and do not append Reset buttons, continue to check other buttons if it is not pressed.
	goto	SAT_APPEND_ALL_BITS_DONT

	btfss	SAT_C_OUTPUT,3; If B is Pressed, go straight to SAT_APPEND_RESET_BITS_DONT and do not append Reset buttons, continue to check other buttons if it is not pressed.
	goto	SAT_APPEND_ALL_BITS_DONT

	btfss	SAT_C_OUTPUT,2; If C is Pressed, go straight to SAT_APPEND_RESET_BITS_DONT and do not append Reset buttons, continue to check other buttons if it is not pressed.
	goto	SAT_APPEND_ALL_BITS_DONT


	bcf		SAT_OPTIONS_REGISTER,0;clears bit to notify Reset Buttons no longer need to be not appended.
	
	goto	SAT_APPEND_ALL_BITS

;==========================================================
SAT_Z_RELEASED
	bcf		SAT_OPTIONS_REGISTER,1; Z Button is not held, do not continue to stop Inversion
	goto	SAT_RESET_FUNCTION
	
;==========================================================	
SAT_MODE_INVERT
	movlw	0x80
	xorwf	SAT_OPTIONS_REGISTER,1; Inverts SAT Mode B Mode

	bsf		SAT_B_OUTPUT, 3;disables appending Z Button Press

	bsf		SAT_OPTIONS_REGISTER,1; Will Stay high until Z is released
	
	goto	SAT_RESET_FUNCTION












;==========================================================	
POWERUP_TEST
	bsf		PORTE,0; Set Saturn Plugged in LED
	call	five_hundred_ms_Delay
	bsf		PORTE,1; Set SNES Plugged in LED
	call	five_hundred_ms_Delay
	bsf		PORTD,7; Set SNES Mode B LED
	call	five_hundred_ms_Delay
	bsf		PORTC,6; Set Saturn Mode B LED
	call	five_hundred_ms_Delay

	bcf		PORTC,6; Set Saturn Mode B LED
	bcf		PORTD,7; Clear SNES Mode B LED
	bcf		PORTE,1; Clear SNES Plugged in LED

	call	five_hundred_ms_Delay
	call	five_hundred_ms_Delay

	bcf		PORTE,0; Clear Saturn Plugged in LED	

	return






four_microsec
; Delay = 4e-006 seconds
; Clock frequency = 4 MHz

; Actual delay = 4e-006 seconds = 4 cycles
; Error = 0 %


			;4 cycles (including call)
	return



six_microsec
			;2 cycles
	goto	$+1

			;4 cycles (including call)
	return


ten_microsec
			;6 cycles
	goto	$+1
	goto	$+1
	goto	$+1

			;4 cycles (including call)
	return


four_ms_Delay
; Delay = 0.004 seconds
; Clock frequency = 4 MHz

; Actual delay = 0.004 seconds = 4000 cycles
; Error = 0 %
			;3993 cycles
	movlw	0x1E
	movwf	d1
	movlw	0x04
	movwf	d2
four_ms_Delay_0
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	four_ms_Delay_0

			;3 cycles
	goto	$+1
	nop

			;4 cycles (including call)
	return


Delay
; Delay = 0.01667 seconds
; Clock frequency = 4 MHz

; Actual delay = 0.01667 seconds = 16670 cycles
; Error = 0 %


			;16663 cycles
	movlw	0x04
	movwf	d1
	movlw	0x0E
	movwf	d2
Delay_0
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	Delay_0

			;3 cycles
	goto	$+1
	nop

			;4 cycles (including call)
	return





two_hundred_ms_Delay
; Delay = 0.2 seconds
; Clock frequency = 4 MHz

; Actual delay = 0.2 seconds = 200000 cycles
; Error = 0 %

			;199993 cycles
	movlw	0x3E
	movwf	d1
	movlw	0x9D
	movwf	d2
two_hundred_ms_Delay_0
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	two_hundred_ms_Delay_0

			;3 cycles
	goto	$+1
	nop

			;4 cycles (including call)
	return

five_hundred_ms_Delay
; Delay = 0.5 seconds
; Clock frequency = 4 MHz

; Actual delay = 0.5 seconds = 500000 cycles
; Error = 0 %

			;499994 cycles
	movlw	0x03
	movwf	d1
	movlw	0x18
	movwf	d2
	movlw	0x02
	movwf	d3
five_hundred_ms_Delay_0
	decfsz	d1, f
	goto	$+2
	decfsz	d2, f
	goto	$+2
	decfsz	d3, f
	goto	five_hundred_ms_Delay_0

			;2 cycles
	goto	$+1

			;4 cycles (including call)
	return

    end        ;YOU MUST END!      