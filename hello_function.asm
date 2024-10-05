bits 64

global  main
extern  ExitProcess
extern  printf
extern  _CRT_INIT
default rel

segment .data
str1    db "Hello from function", 0xd, 0xa, 0
str2    db "Hello from main", 0xd, 0xa, 0

segment .text

func:
	push rbp
	mov  rbp, rsp
	sub  rsp, 32

	call _CRT_INIT
	lea  rcx, [str1]
	call printf
	mov  rax, 0
	mov  rsp, rbp
	pop  rbp
	ret

main:
	push rbp
	mov  rbp, rsp
	sub  rsp, 32
	call func
	lea  rcx, [str2]
	call printf
	xor  rax, rax
	call ExitProcess
