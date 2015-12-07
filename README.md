# RetroControllerBreakout
SATURN TO PARALLEL
;(C) 2010 Ted Wahrburg 
For use with Microchip PIC16F747

;---------------------------------------------------------------------------------------------------------------------
Delay Routine generated from "http://www.piclist.com/techref/piclist/codegen/delay.htm" Generated in 2009/2010.
;---------------------------------------------------------------------------------------------------------------------

This Program comes with no warranty. USE AT YOUR OWN RISK. Free for all non-commercial use. Plese provide proper credit if code is used in future project.

Converts Saturn, NES, and SNES Standard Game Pad protocol to Individual Button Outputs, with a pin for each button.
Default Pin state is low. Pins go high with button presses

SNES mode B Combos:
Code Allows for a Mode B to be activated when the user presses X while holding Select on an SNES controller. 
Pressing these two buttons in Mode B causes Mode A to become active again

When in Mode B, Start+L causes RC0(Start Button) to go high. Start+R causes RC7(Select Button) to go high. 
When in both Modes A & B, Start+A+B+C causes RC5 to go high. This combo is useful to trigger a utility button, such as the Xbox 360 Guide Button

;####################################
Change Log:
 V.1.0) Implemented Saturn Controller Routine with coresponding status LEDs.
 V.2.0) Completely Rewrote Saturn Controller Routine, added support for SNES & NES Controllers. Saturn Mode B routines are broken in this version.
 V.2.1) Fixed Timing with SNES/NES Latch. Impliment Saturn Mode B Routines, it is not working correctly.....
 V.2.2) Fixed bug with SNES Mode B that would cause SAT Mode B Routine to be run instead..
 V.2.3) Uncommented Saturn Code. It works with Mode B Routine still commented out.
 V.2.4) Uncommented Saturn Mode B Code. Saturn controllers don't seem to be reading as detected as all..SNES Code + Mode B seems find.
 V.2.5) Saturn Mode B Routine works now. Problem seems to have stemmed from SAT_OPTIONS_REGISTER. 
         The register resided @ address 0x33, and it's bits would always read high. Created psuedo "REGISTER_THIRTYTHREE" to reside @ 0x33. 
         SAT_OPTIONS_REGISTER seems to work fine now in memeory address 0x34, at this time I do not understand why register 0x33 is giving me problems.
 V.2.6) Sets Saturn Reconnected bit as high on power up. Disabling Power Up Test. Changing Reconnect delay from 500ms to 200ms.
 V.2.7) Fixed SNES Left Bumper & Right Bumper inversion. L Button in Mode B is now tied to RB3, R Button is tied to RC2. Setting RA7 as an input, to be used as default output state select. 

PIC(pin) : Saturn(pin: Input)
RA0(02) : D3(7)
RA1(03) : D2(8)
RA2(04) : D1(2)
RA3(05) : D0(3)
PIC(pin) : Saturn(pin: Output)
RA5(07) : S0(4)
RA6(14) : S1(5)

RA7(13) : Output Logic Level Select Input. Hold pin low to select Active High for button presses, Active Low for non-presses. Holding Pin high will inverse this.


PIC(pin) : SNES(pin)
RD0(19) : SNES Data Latch (SNES PIN 3) 'Orange'
RD1(20) : SNES Data Clock (SNES PIN 2) 'Yellow'

RD2(21) : NES Serial Data
RD3(22) : SNES Serial Data(SNES PIN 4) 'Red'

RD4(27) : NES Data Latch <--- Will be redundant as RD0 should work fine.
RD5(28) : NES Data Clock

RD7(30) : "SNES Mode B LED"

RE0(08) : Saturn Contoller Plugged In LED
RE1(09) : SNES Contoller Plugged In LED
RE2(10) : NES Contoller Plugged In LED

PIC(PIN) : Button Output
RB0(33) : "R"
RB1(34) : "X"
RB2(35) : "Y"
RB3(36) : "Z"
RB4(37) : "D-RIGHT"
RB5(38) : "D-LEFT"
RB6(39) : "D-DOWN"
RB7(40) : "D-UP"
RC0(15) : "START"
RC1(16) : "A"
RC2(17) : "C"
RC3(18) : "B"
RC4(23) : "L"
RC5(24) : "RESET CHECK, USE TO ATTACH TO RIGHT THUMSTICK BUTTON OR XBOX 360 GUIDE CONTROL FOR EXAMPLE"
RC6(25) : "Saturn Mode B LED"
RC7(26) : "SELECT"
