;***********************************************************
; File Header
;***********************************************************
    list p=18F25k50, r=hex, n=0
    #include <p18f25k50.inc>	; file to provide register definitions for the specific processor (a lot of equ)


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
TESTVAR	equ 0x01;variabele om testresultaat in te steken
TMR1HVAR	equ 0x02;variabele voor de tmr1 high bit in op te slaan
TMR1LVAR	equ 0x03;variabele voor de tmr1 low bit in op te slaan
STARTSONG	equ 0x04;variable which is 1 if we want to start the music
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
    movlw   0x00 	; Configure A/D for digital inputs 0000 1111, onlry RA2 needs to be analog (used to be 0x00)
    movwf   ANSELA	
    clrf    LATA	; clear A output latch
    movlw   0x00	; Configure comparators for digital input
    movwf   CM1CON0
    clrf    LATB	; Initialize PORTB by clearing output data latches
    movlw   0x00	; Value used to initialize data direction
    movwf   TRISB	; Set PORTB as output
    clrf    LATC	; Initialize PORTC by clearing output data latches
    movlw   0x01	; Value used to initialize data direction
    movwf   TRISC	; Set RC0 as input
    bcf	    STARTSONG,0 ; clear the start song bit
    
    

    bcf     UCON,3	; to be sure to disable USB module
    bsf     UCFG,3	; disable internal USB transceiver
    
    goto main		;goto main and start the code

main
    call    init_lut
    call    init_tmr0
    call    init_tmr1
    call    init_dac
    call    init_tblptr
    goto    loop

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
    movlw    b'01000111';stel de waardes van de timer1 in
    movwf   T1CON
    bsf	    INTCON2,2;set bit 2, this set TMR0 interrupt to high priority
    bsf	    PIE1,0; enable tmr1 interrupt
    bsf	    PIE1,0; enable tmr2 interrupt(just to be sure)
    return
    
init_tblptr
    ;we zetten de table pointer op de juiste plaats, wordt gecalled na elke read en helemaal in het begin
    movlw   upper NOTES
    movwf   TBLPTRU
    movlw   high NOTES
    movwf   TBLPTRH
    movlw   low NOTES
    movwf   TBLPTRL
    return
    
    
loop
    btfss   PORTC,0;als RC0 is ingedrukt zet variabele om nummer te starten hoog(dus slaag hoog zetten niet over)
    bsf     STARTSONG ,0
    movff   STARTSONG,LATB;
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
    lfsr    0,0x20
    
    movlw   D'1';C laat in work register hoeveel plekken we achter notes de juite node kunnen vinden
    movwf   0x20;C
    movlw   D'2' ;D
    movwf   0x21;D
    movlw   D'3';E
    movwf   0x22;E
    movff   0x20,0x23;C
    movwf   0x23,0x24;C
    movff   0x24,0x25;Dzelfde noot twee keer achter elkaar
    movff   0x22,0x26;E
    movff   0x20,0x27;C
    movff   0x22,0x28;E
    movlw   D'4';F
    movwf   0x29;F
    movlw   D'5';G
    movwf   0x30;G
    movlw   D'0'
    movwf   0x31;Silence
    movff   0x22,0x32;E
    movff   0x29,0x33;F
    movff   0x30,0x34;G
    movff   0x31,0x35;Silence
	
    
    
    
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
    bcf	    PIR1,TMR1IF;clear de timer1 bit nog
    return
ih_tmr1
    bcf	    PIR1,TMR1IF;clear de timer1 bit nog
    ;als de song bit hoog is -> skip
    btfss   STARTSONG,0
    return
    ;per tmr1 interrupt moet ge een nieuwe analoge waarde neerpoten in de dac zodat we pracht sinus krijgen
    movff   TMR1HVAR,TMR1H;terug de tmr1 op de juiste waarde zetten zodat we de juitse frequentie aanhouden
    movff   TMR1LVAR,TMR1L
    ;haal de gewenste waarde op
    movf    FSR1L,0;zet het adress waar de pointer naar wijst in de working register
    xorlw   0x20; wanneer we voorbij 0x20 zitten moeten we terug in het begin beginnen
    movwf   TESTVAR
    tstfsz  TESTVAR;als 0, de volgende instructie discarded
    goto    schrijf_op_dac
    goto    reset_sin_wave;zet de sinus terug naar 0
    return

ih_tmr0
    bcf	    INTCON,2;clear the flag bit
    btfss   STARTSONG,0;als de start variabele hoog is gezet skippen we de volgende return instructie die ervoor zorgt dat er niks wordt gedaan
    return
    btg	    LATC,1; toggle RC1 led
    ;make tm1 play a different frequency according to the correct note
    call init_tblptr
    ;een while loop die elke keer een tblread doet enzo naar de juiste plaats beweegt tot we in table lat de juiste waarde hebben staan
    movf    POSTINC0,0;zet de hoeveelheid aan noten dat we moeten skippen in de WREG
    tstfsz  WREG,0;als wreg al nu is moeten we geen noten overslaan
    goto loop_table_read 
    goto read_from_table
    
loop_table_read
    tblrd*+;skip een noot
    tblrd*+
    decfsz  WREG,0;we gaan naar beneden tot we genoeg noten hebben geskipped
    goto loop_table_read
    goto read_from_table

read_from_table;we zitten aan de juiste noot, lees deze uit en pas tmr1 aan
    tblrd*+;  lees de waardes op de plaats van de noot
    movff   TABLAT,TMR1HVAR;zet de waarde van de lat de high bit van tmr1
    tblrd*+; lees de high bit
    movff   TABLAT,TMR1LVAR; zet de waarde van de lat in de low bit van tmr1
      
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
    ;calculate the correct values WAARDES KLOPPEN NOG NIET, gewoon willekeurig voor te testen
    DB 0x30, 0xEE   ;C = do (65518) zou 1046,5 Hz moeten zijn
    DB 0x60, 0xF0   ;D 1174,66 Hz
    DB 0x80, 0xF8   ;E 1318,51 Hz
    DB 0xA0, 0xFA   ;F 1396,91 Hz
    DB 0xD0, 0xFF   ;G 1567,98 Hz
    DB 0xFF, 0xDE   ;A 1760 Hz
    
    ;STER ASSIGNMENT
;    NOTES ;TMR0H TMR1H TM1L
;    DB  0x00, 0x00, 0x00   ;Silence?
;    ;calculate the correct values WAARDES KLOPPEN NOG NIET, gewoon willekeurig voor te testen
;    DB 0x00,0xFF, 0x00   ;C = do (65518) zou 1046,5 Hz moeten zijn
;    DB 0x00,0xFF, 0xA0   ;D 1174,66 Hz
;    DB 0x00,0xFF, 0x00   ;E 1318,51 Hz
;    DB 0x00,0xFF, 0xA0   ;F 1396,91 Hz
;    DB 0x00,0xFF, 0x00   ;G 1567,98 Hz
;    DB 0x00,0xFF, 0xA0   ;A 1760 Hz
;    ;halve noten
;    DB 0x80, 0xFF, 0xEE   ;C = do	7
;    DB 0x80, 0xFF, 0xF0   ;D 1174,66 Hz	8
;    DB 0x80, 0x80, 0xF8   ;E 1318,51 Hz	9
;    DB 0x80, 0xA0, 0xFA   ;F 1396,91 Hz	10
;    DB 0x80, 0xD0, 0xFF   ;G 1567,98 Hz	11
;    DB 0x80, 0xFF, 0xDE   ;A 1760 Hz	12
    
    END