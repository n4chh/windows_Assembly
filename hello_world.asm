bits    64
default rel

segment .data
msg     db "Hello world! %d %f %d", 0xd, 0xa, 0

segment .text
global  main
extern  ExitProcess

extern printf
extern _CRT_INIT

main:
	push rbp
	mov  rbp, rsp
	sub  rsp, 32

	call _CRT_INIT; CRT initialization
	lea  rcx, [msg]
	mov  rdx, 1
	mov  r8, 2
	mov  r9, 3

	; push 4

	call printf

	xor  rax, rax
	call ExitProcess
