
;====================================================================
; DEFINITIONS
;====================================================================

;====================================================================

;====================================================================

;====================================================================
; RESET and INTERRUPT VECTORS
;====================================================================

      ; Reset Vector
      org   0000h
      jmp   Start
      
      ORG	000BH ; ngat timer 0
      LJMP T0_ISR
      
      ORG	0003H ; ngat itr 0
      LJMP INT0_ISR
      

DELAY:
      MOV R7, #25
      DL1:
	 DJNZ R7, DL1
RET

      org   0100h
Start:
      TGXANH EQU 7
      TGVANG EQU 3
      TGDO EQU 10
      MOV TMOD, #01H
      MOV TH0, #0EEH
      MOV TL0, #06H
      MOV IE, #87H
      
      SETB TR0
      SETB IT0
      
      MOV R0, #0 ; CHU KÌ
      MOV R1, #7 ; GIAY 7-3-10
      MOV R2, #1
      
      MOV R3, #10
      MOV R4, #1
      
      MOV R5, #0 ; quan ly C
      
      CLR P3.0
      CLR P3.7
      
Loop:	
      ;quet led den 1
      CLR	P2.1
      MOV	A, R1
      MOV	B, #0AH
      DIV	AB
      MOV	P0, B
      CALL DELAY
      SETB	P2.1
      CLR	P2.0
      MOV	P0, A
      CALL DELAY
      SETB	P2.0
      jmp Loop

INT0_ISR:
      RETI

T0_ISR:
      CPL	P2.7
      MOV TH0, #0EEH
      MOV TL0, #06H
      SETB TR0
      INC R0
      CJNE R0, #200, END_T0_ISR
      ;xu ly thoi gian den 1
      GIAY_1: 
	    DEC R1
	    MOV	R0, #0 
	    XANH:
	       CJNE R2, #1, VANG
	       CJNE R1, #0, CON_X
		  MOV R1, #TGVANG
		  INC R2
		  JMP VANG
	       CON_X:
	       CLR P3.7
	       SETB P3.5
	    VANG:
	       CJNE R2, #2, DO
	       CJNE R1, #0, CON_V
		  MOV R1, #TGDO
		  INC R2
		  JMP DO
	       CON_V:
	       CLR P3.6
	       SETB P3.7
	    DO:
	       CJNE R2, #3, GIAY_2
	       CJNE R1, #0, CON_DO
		  MOV R1, #TGXANH
		  MOV R2, #1
		  SETB P3.5
		  JMP XANH
	       CON_DO:
	       CLR P3.5
	       SETB P3.6
      ;xu ly thoi gian den 2
      GIAY_2: 
	    DEC R3
	    DO_2:
	       CJNE R4, #1, XANH_2
	       CJNE R3, #0, CON_DO_2
		  MOV R3, #TGXANH
		  INC R4
		  JMP XANH_2
	       CON_DO_2:
	       CLR P3.0
	       SETB P3.1
	    XANH_2:
	       CJNE R4, #2, VANG_2
	       CJNE R3, #0, CON_X_2
		  MOV R3, #TGVANG
		  INC R4
		  JMP VANG_2
	       CON_X_2:
	       CLR P3.4
	       SETB P3.0
	    VANG_2:
	       CJNE R4, #3, END_T0_ISR
	       CJNE R3, #0, CON_V_2
		  MOV R3, #TGDO
		  MOV R4, #1
		  SETB P3.1
		  JMP DO_2
	       CON_V_2:
	       CLR P3.1
	       SETB P3.4
      END_T0_ISR:
RETI

KEYPAD:
      MOV P1, #0F0H ; cho hang co tin hieu 0 va cot o muc 1
      KIEMTRACOT:;xu dung quet nut, 4 bit dau port1 dung de quet, 4 bit cuoi dung de nhan biet nut bam
	 MOV P1, #0F7H ; cho hang D = 0 1111 0111
	 MOV A, P1; lay tin hieu cua nut nhan
	 ANL A, #0F0H; and de lay nhung bit nut bam
	 CJNE A, #0F0H, SCAN_R0 ; kiem tra co su thay doi nut chua noi co nhay toi scan_r0
	 
	 MOV P1, #0FBH ; hang C 1111 1011
	 MOV A, P1
	 ANL A, #0F0H
	 CJNE A, #0F0H, SCAN_R1
	
	 MOV P1, #0FDH ; hang B 1111 1101
	 MOV A, P1
	 ANL A, #0F0H
	 CJNE A, #0F0H, SCAN_R2
	 
	 MOV P1, #0FEH ; hang A 1111 1110
	 MOV A, P1
	 ANL A, #0F0H
	 CJNE A, #0F0H, SCAN_R3
RET 


SCAN_R0: ;kiem tra cac cot o hang D - hang chuc nang
	 MOV DPTR, #MAHANGD ; gan thanh ghi dia chi mahang0
	 MOV B, #16 
	 DIV AB ; A luu 4 bit lon, B luu 4 bit nho
	 CJNE A, #0EH, END_CN ; neu A != 1110 tuc khong la nut C/ON
	    CJNE R5, #0, RESUME ; NEU R5 = 0 => RESUME
	    PAUSE:
	       INC R5
	       CLR TR0	; neu A == 1110 thi cho ngung timer
	       JMP END_SCAN0
	    RESUME:
	       DEC R5
	       ;CAPNHAT TGXANH DO VANG
	       SETB TR0	;neu A == 1011 tuc la nut = thi bat timer
	       JMP END_SCAN0
	 END_CN:
	 LCALL SCAN; neu khong phai c THI DUYET
	 END_SCAN0:
	 RET
SCAN_R1:
	 MOV DPTR, #MAHANGC
	 MOV B, #16
	 DIV AB
	 LCALL SCAN
	 RET
SCAN_R2:
	 MOV DPTR, #MAHANGB
	 MOV B, #16
	 DIV AB
	 LCALL SCAN
	 RET
SCAN_R3:
	 MOV DPTR, #MAHANGA
	 MOV B, #16
	 DIV AB
	 LCALL SCAN
	 RET

SCAN:
	 RRC A ;quay phai a voi co nho c
	 JNC MATCH; neu co nho C = 0 thi nhay toi MATCH
	 INC DPTR; tang dia chi DPTR len 1 TUC LA SANG NUT KE TIEP
	 SJMP SCAN
	 MATCH:
	    MOV A, #0
	    MOVC A, @A + DPTR	;gan A = gtri cua mang tai dia chi DPTR
	    JB TR0, END_SCAN; neu timer dang bat thi nhay toi end_scan
	    
	    CALL SETTING_TIME; neu timer dang tat thi co the setting time
	    END_SCAN:
RET
      
SETTING_TIME:; ham setting Time
	 SUBB A, #48
	 MOV R1, A
RET      
   
ORG 300H; dia chi cac mang
MAHANGD: DB 'C', 0,'=','0'
MAHANGC: DB 1, 2, 3,'0'
MAHANGB: DB 4, 5, 6,'0'
MAHANGA: DB 7, 8, 9,'0'

;====================================================================
      END