.org 000000000

;simple ALU ins one after another -- normal case! it MUST work
;with forwarding and RAW
ldi $1, 0x10000000


addi $0, $0, 5	;$0 = 5
addi $1, $1, 2	;$1 = 2 
addi $3, $0, -1 ;$3 = 4  -- RAW with 1 ins in between
addi $4, $4, 1 	;$4 = 1
addi $0, $1, 5	;$0 = 7
sub $3, $3, $4  ;$3 = 3   -- RAW with 1 ins in between
and $5, $3, $4  ;$5 = 1 -- RAW with NO ins in between
or  $6, $4, $1  ;$6 = 3
not $7, $3 	;$7 = fffffffc -- RAW with 2 ins in between
sari $8, $7, 2	;$8 = ffffffff --RAW with NO ins
sal $9,$4,$3 	;$9 = 8
sar $10,$0,$5	;$10 = 3


; Load store

ldil $1, 0x0000	;1st LSB, then MSB
nop
nop
ldih $1, 0x1000	;$1 = 10000000

ldih $2, 0x1000 ;1st MSB then LSB
nop
nop
ldil $2, 0x0000 ;$2 = 10000000

;load store with RAW with simple ALU ins

add $11, $2, $5 ; $11 = 10000001 --NO ins in between
addi $12, $2, 5 ;$12 = 10000005 -- 1 ins in between
addi $13, $2, 5 ;$12 = 10000005 -- 2 ins in between

; store operation

st.w $0, 0($2)    ; 0($2) = 7
ld.w $14, 0($2)	  ; $14 = 7


st.w $0, 0($2)    ; 0($2) = 7
add $16, $0, $5	  ; $16 = 8  
ld.w $15, 0($2)	  ; $15 = 7 ;

; ALL PASS TILL HERE

addi $17, $15, 10 ;$17 = 17	;this should check for bubble

st.w $0, 0($2)    ; 0($2) = 10
st.w $1, 0($2)    ; 0($2) = 10000000
st.w $2, 0($2)    ; 0($2) = 10000001
st.w $3, 0($2)    ; 0($2) = 4
ld.w $18, 0($2)    ; $18 = 4

;branch operations

bra next	;$18 should be 4 before this branch is taken

loop : sub $18, $18, $5 ; $18 = $18 - 1
bnz loop,$18 		; the loop should run 4 times also checks RAW
add $19, $19, $5	; $19 = 1

next :
bnz loop, $18 ;this branch should be taken once
add $19, $19, $5	; $19 = 2

ldil $19, 0
nop
nop
ldih $19, 0 	; $19 = 0

bz next2, $19	;this branch should be taken
label: add $20, $5, $5 ; $20 should be unchanged due to invalidation
jmp $22

next2: 
addi $21, $21, 1 ;$21 = 1
bl $22, label	;$22 should update to PC + 4

bnz next3,$20 ; this branch should be taken -- $22 contains this instruction's addr
nop		; $22 + 4
nop		; $22 + 8

next3 :
ld.w $23, 0($2)    ; $23 = 4	 $22 + 12
bnz next4,$23	   ; this should be taken once ; $22 + 16	

nop	; $22 + 20
nop	; $22 + 24

next4 :  addi $23, $22, 36 ; $23 = $22 + 36 -- $23 contains addr of next to next ins	
bl $24, next5	;$24 = $22 + 36	--this branch should be taken

next5 : nop ;remove WAW hazard ;$24 contains this addr
	nop	
	addi $24, $24, 12	

end : call $24, $24	;infinitely loop here ??
nop
nop
addi $25, $22, 72	; address of nxt to nxt ins
nop	; remove waw
nop
bl $25, brl_test
brl_test : bl $26,brl_test ;stay here for ever 

nop
nop

jmp $30 ; if the above infinite loop doesnt work, start again



 
