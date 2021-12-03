;***********************************************************
; File Header
;***********************************************************
    list p=18F25k50, r=hex, n=0
    #include <p18f25k50.inc>	; file to provide register definitions for the specific processor (a lot of equ)

; File registers
TESTVAR	equ 0x01;variabele om testresultaat in te steken
;***********************************************************
; Reset Vector
;***********************************************************

    ORG     0x1000	; Reset Vector
			; When debugging:0x0000; when loading: 0x1000
    GOTO    START

;***********************************************************
; Interrupt Vector
;***********************************************************

    ORG     0x1008	; Interrupt Vector HIGH priority
    GOTO    inter_high	; When debugging:0x008; when loading: 0x1008
    ORG     0x1018	; Interrupt Vector LOW priority
    GOTO    inter_low	; When debugging:0x0008; when loading: 0x1018

;***********************************************************
    ;File register
;DAVAL equ 0x20; variable to store digital analog conversion
;***********************************************************
; Program Code Starts Here
;***********************************************************

    ORG     0x1020	; When debugging:0x020; when loading: 0x1020

START
    movlw   0x80	; load value 0x80 in work register
    movwf   OSCTUNE		
    movlw   0x70	; load value 0x70 in work register
    movwf   OSCCON		
    movlw   0x10	; load value 0x10 to work register
    movwf   OSCCON2		
    clrf    LATA 	; Initialize PORTA by clearing output data latches
    movlw   0x00 	; Value used to initialize data direction, only RA2 moet als output worden gebruikt used to be 0xFF
    movwf   TRISA 	; Set PORTA as output
    ;movlw   b'00000100' 	; Configure A/D for digital inputs 0000 1111, onlry RA2 needs to be analog (used to be 0x00)
    ;movwf   ANSELA	
    clrf    LATA	; clear A output latch
    movlw   0x00	; Configure comparators for digital input
    movwf   CM1CON0
    clrf    LATB	; Initialize PORTB by clearing output data latches
    movlw   0x00	; Value used to initialize data direction
    movwf   TRISB	; Set PORTB as output
    clrf    LATC	; Initialize PORTC by clearing output data latches
    movlw   0x01	; Value used to initialize data direction
    movwf   TRISC	; Set RC0 as input
    
    

    bcf     UCON,3	; to be sure to disable USB module
    bsf     UCFG,3	; disable internal USB transceiver
    
    goto main		;goto main and start the code

main
    call    init_lut
    call    init_tmr0
    call    init_tmr1
    call    init_dac
    goto    loop
    ;call    init_lut

init_dac    
    movlw   b'11100000'; enable DAC, DACOUT is RA2
    movwf   VREFCON1 
    bsf	    INTCON,GIE 
    setf    TESTVAR,0;set the testvar variable high cus it'll trigger on 0
    return
    
init_tmr0
    ;enable timer0 interrupts
    movlw   b'11100000'	;enables timer0 interrupts
    movwf   INTCON
    movlw   b'10000101';timer 0 geeft een interrupt met een frequentie van 0.7Hz
    movwf   T0CON
    return
    
init_tmr1
    ;we willen dat de tmr1 met een frequentie van 62.5 interrupt -> op elke trigger nieuwe DA waarde nemen
    movlw    b'00100111';stel de waardes van de timer1 in
    movwf   T1CON
    bsf	    INTCON2,2;set bit 2, this set TMR0 interrupt to high priority
    bsf	    PIE1,0; enable tmr1 interrupt
    bsf	    PIE1,0; enable tmr2 interrupt(just to be sure)
    return
    
    
loop
    goto    loop

;***********************************************************
; subroutines
;***********************************************************
init_lut
    ; FSR1: will go though table of sine samples; starts at address 0x010
    lfsr    1, 0x010
    movlw   D'15'	
    movwf   0x10
    movlw   D'21'	
    movwf   0x11
    movlw   D'26'	
    movwf   0x12
    movlw   D'29'	
    movwf   0x13
    movlw   D'30'	
    movwf   0x14
    movlw   D'29'	
    movwf   0x15
    movlw   D'26'	
    movwf   0x16
    movlw   D'21'	
    movwf   0x17
    movlw   D'15'	
    movwf   0x18
    movlw   D'9'	
    movwf   0x19
    movlw   D'4'	
    movwf   0x1A
    movlw   D'1'	
    movwf   0x1B
    movlw   D'0'	
    movwf   0x1C
    movlw   D'1'	
    movwf   0x1D
    movlw   D'4'	
    movwf   0x1E
    movlw   D'9'	
    movwf   0x1F
    
    ; FSR0: song
    ;complete me
    
    return
    
;***********************************************************
; interrupt handling
;***********************************************************

inter_high
    btfsc   INTCON,2	;will be high if timer0 has given interrupt
    call ih_tmr0
    btfsc   PIR1,0  ;will be high when tmr1 has given an interrupt
    call ih_tmr1
    retfie
    
reset_sin_wave
    lfsr    1, 0x010
    goto    schrijf_op_dac
schrijf_op_dac
    movf    POSTINC1,0; zet de waarde van de de sfr1 pointer in de work register en increment hem
    movwf   VREFCON2;start de dac met de waarde uit de pointer
    return
ih_tmr1
    ;per tmr1 interrupt moet ge een nieuwe analoge waarde neerpoten in de geluid
    ;haal de gewenste waarde op
    movf    FSR1L,0;zet het adress waar de pointer naar wijst in de working register
    xorlw   0x20; wanneer we voorbij 0x20 zitten moeten we terug in het begin beginnen
    movwf   TESTVAR
    tstfsz  TESTVAR;als 0, de volgende instructie discarded
    goto    schrijf_op_dac
    goto    reset_sin_wave;zet de sinus terug naar 0
    return

ih_tmr0
    btg	    LATC,1; toggle RC1 led
    bcf	    INTCON,2;clear the flag bit
    return
    
inter_low
    nop
    retfie
;***********************************************************
; table
;***********************************************************
    
NOTES ;TMR1H TM1L
    DB 0x00, 0x00   ;Silence?
    ;calculate the correct values
    DB 0xFF, 0xEE   ;C = do
    ;...
    
    END