%macro SYS_READ 3          ;;SYS_READ(file_descritor, endereco do buffer, tamanho do buffer)
    mov rax, 0
    mov rdi, %1
    mov rsi, %2
    mov rdx, %3
    syscall
%endmacro

%macro SYS_WRITE 3          ;;SYS_WRITE(file_descritor, endereco do buffer, tamanho do buffer)
    mov rax, 1
    mov rdi, %1
    mov rsi, %2
    mov rdx, %3
    syscall
%endmacro

%macro SYS_BRK 4
	mov	rax, 12                 ; brk sys_call convention 
    xor rdi, rdi				; Passa 0 como argumento brk(0) 
    syscall						; Retorna o endereco do program break
	mov [%1], rax     ;;Passando o endereco do primeiro elemento da matriz  		
	
	push rcx			;;Vamos substituir por left shift
	push rdx
	
	mov rcx, [%3]			;;Numero de linhas da matriz
	mov rdx, [%4]			;;Numero de colunas da matriz	
	
	imul rcx, rdx 
	
	shl rcx, %2				;;tamanho de cada elemento na matriz

	lea rdi, [%1+rcx]   ;;Alocando %2*%3*%4 bytes. O segundo argumento serve para passar o tipo de enderecamento. O terceiro e quarto servem sao as dimensoes da matriz
	mov rax, 12
	syscall
	pop rdx
	pop rcx
%endmacro

%macro EXIT 0
	mov rax, 60
	xor rdi, rdi
	syscall
%endmacro

%define ACUMULADOR r12
%define i r13
%define k r15
%define j r14


bits 64 

section .data
	msgNumeroLinhasColunasA: db `Digite o numero de linhas e o numero de colunas da primeira matriz \n`
	msgSize1 equ $-msgNumeroLinhasColunasA
	msgNumeroLinhasColunasB: db `Digite o numero de linhas e o numero de colunas da segunda matriz \n`
	msgSize2 equ $-msgNumeroLinhasColunasB

    pedeOperacao: db `Escolha a operacao que deseja performar (+) ou (*):\n`
	msgSize3 equ $-pedeOperacao

    pedeElementos: db `Insira elemento por elemento: \n`
    msgSize equ $-pedeElementos

section .bss 
	inputBuffer: resb 10
	tamanhoBuffer: resb 1
	operacaoEscolhida: resb 2
    printableMatrixSum: resb 200
    byteConverted: resb 1


section .matrizA read write
	numeroLinhasA: resq 1
	numeroColunasA: resq 1
    matriz1PtrInicio: resq 1
    matriz1PtrFim: resq 1

section .matrizB read write
	numeroLinhasB: resq 1
    numeroColunasB: resq 1
    matriz2PtrInicio: resq 1
    matriz2PtrFim: resq 1


section .text

global _start
_start:
	
	;;MATRIZ A
	
	SYS_WRITE 1, msgNumeroLinhasColunasA, msgSize1
	SYS_READ 0, inputBuffer, 10
	mov [tamanhoBuffer], al
	mov al, byte [inputBuffer]
	mov rcx, 0
	call toNumber					;;Input vem na codificacao ASCII
	mov [numeroLinhasA], al
	SYS_WRITE 1, numeroLinhasA, 1
	
	SYS_WRITE 1, msgNumeroLinhasColunasA, msgSize1
	SYS_READ 0, inputBuffer, 10
	mov [tamanhoBuffer], al
	mov al, byte [inputBuffer]
	mov rcx, 0
	call toNumber
	mov [numeroColunasA], al
	SYS_WRITE 1, numeroColunasA, 1

	;;MATRIZ B

	SYS_WRITE 1, msgNumeroLinhasColunasB, msgSize2
    SYS_READ 0, inputBuffer, 10
	mov [tamanhoBuffer], al
    mov al, byte [inputBuffer]
    mov rcx, 0
	call toNumber
	mov [numeroLinhasB], al
    SYS_WRITE 1, numeroLinhasB, 1
    
	SYS_WRITE 1, msgNumeroLinhasColunasB, msgSize2
    SYS_READ 0, inputBuffer, 10
    mov [tamanhoBuffer], al
	mov al, byte [inputBuffer]
    mov rcx, 0 
	call toNumber
	mov [numeroColunasB], al
    SYS_WRITE 1, numeroColunasB, 1

    ;;------------------------------------------------------------------------------------------------------------------------------------------------
    ;;------------------------------------------------------------------------------------------------------------------------------------------------


    ;;Alocando memoria para matriz A
    mov rcx, numeroLinhasA
	mov rdx, numeroColunasA
	SYS_BRK matriz1PtrInicio, 8, numeroLinhasA, numeroColunasA
	;;salvando o endereco do ultimo elemento da matriz
	mov [matriz1PtrFim], rax


	mov rcx, numeroLinhasB
    mov rdx, numeroColunasB
	;;Alocando memoria para matriz B
    SYS_BRK matriz2PtrInicio, 8, numeroLinhasB, numeroColunasB
	;;salvando o endereco do ultimo elemento da matriz
	mov [matriz2PtrFim], rax

    ;;-----Vamos inserir os elementos na matriz--------------------------------------------------------------------
    ;;--------------------------------------------------------------------------------------------------------------

	lea rax, [matriz1PtrInicio]			;;Em matriz1Ptr temos um ponteiro. Primeiro carregamos esse endereco em rax
	mov rax, [rax]						;;Carregamos o valor no endereco apontado por esse ponteiro em rax
	push rax

	xor i, i
	
	SYS_WRITE 1, pedeElementos, msgSize
	

	;;--MATRIZ-A--------
	mov rcx, [matriz1PtrInicio]
	mov rdx, [matriz1PtrFim] 
	push rcx
	push rdx
	
	call creatingMatrix

	;;--MATRIZ-B--------

    mov rcx, [matriz2PtrInicio]
    mov rdx, [matriz2PtrFim]
    push rcx
    push rdx

    call creatingMatrix

    ;;-----Qual operacao ira realizar nas matrizes?----------------------------------------------------------------
    ;;--------------------------------------------------------------------------------------------------------------
    SYS_READ 0, pedeOperacao, msgSize3

	SYS_WRITE 1, operacaoEscolhida, 2

	cmp byte [operacaoEscolhida], 0x2B			;;+ ascii
	je sumMatrix

	cmp byte [operacaoEscolhida], 0x2A			;;* ascii
	je multiplyMatrix


    ;;conversao:
		;;call toString      

	;;print:
		;;SYS_WRITE 1, printableMatrixSum, 200

    EXIT


creatingMatrix:

	pop rdx ;;ponteiro para o inicio
	pop rcx	;;ponteiro para o fim

	.loop:
		SYS_READ 0, inputBuffer, 10

    	mov [tamanhoBuffer], rax                ;;SYS_READ retorna a quantidade de caracteres efetivamente lidos

    	lea rdi, [rcx+i*8]

    	;;nao ta atualizando o endereco

    	call toNumber

    	;;Temos quad word para cada elemento. Devemos incrementar 8 bytes

		inc i
		;;Checka se o endereco percorrido eh igual ao endereco final da matriz
    	cmp rdi, rdx
    	jne .loop
	ret

toNumber:

	;;Condicao de parada = enquanto tamanho for maior ou igual a zero
	;;"numeroFormatoString"
	;;aponta pro final da string (ultimo byte)
	;;subtrai '0'
	;;empilha
    push rcx
	mov rcx, [tamanhoBuffer]
	dec rcx
	dec rcx
	mov rsi, inputBuffer			
    add rsi, rcx						;;Apontando pro final do buffer
	mov al, [rsi]						;;Passando o valor no endereco de rsi para rax

	mov rbx, 10                     ;;Valor de multiplicacao definido
    
	xor r8, r8
    xor r9, r9
	.converterLoop:
        
        sub al, '0'         ;;Converte para ascii
       
        push rax    ;;Empilhando os algorismos para ordena-los
        inc r8      ;;Contando o numero de empilhamentos
        		    ;;armazena em byteConverted printableMatrixSu

		cmp rcx, 0
        je .desempilhar
        dec rsi
        dec rcx
		mov al, [rsi] ;;rsi aponta pro final do buffer - 1
		jmp .converterLoop
			
	.desempilhar:
		mov r10, r8				;;Salvando a potencia	
		dec r10                     ;;Quantas vezes iremos multiplicar rax por 10?

        pop rax                  ;;Vamos desempilhar os valores na pilha em r9
        xor r11, r11
	
        cmp r11, r10
        je .notElevate			;;Seleciona se 
						

		.elevar:
		;;Como eu nao executo a primeira multiplicacao
			mul rbx					;;rax = rax*10^(r8-1)
			inc r11
			cmp r11, r10
			jne .elevar
		;;.naoElevar:

	
	.notElevate:
		pop rcx
		cmp rcx, 0
		je .exit

		add [rdi], rax
		dec r8					;;Decrementa o contador de valores empilhados

		cmp r8, 0               ;;0 - r8
        jne .desempilhar

        inc rcx
	.exit:
		ret

;;Como eu coloco parametros para chamar a função?
sumMatrix:
    ;Vamos iterar nos enderecos de memoria e somar os valores
    ; Carregando os enderecos de memoria nos registradores
    ;Origem dos dados
    mov rsi, [matriz1PtrInicio]
    mov r8, [matriz2PtrInicio]
    ;Destino dos dados
    mov rdi, [matriz1PtrInicio] 

    
    ;;loop de somar

    ;;Condicao de parada tamanho da matriz
    mov rcx, 0      ;;Counter
    
    .loop: 
        mov rax, [rsi+rcx*8]
        mov r9, [r8+rcx*8]
    
		lea rdi, [rdi+rcx*8]
        mov [rdi], rax
        add [rdi], r9

        inc rcx
        cmp [matriz1PtrFim], rdi
        jne .loop

    ret


;;Serve para matrizes com elementos entre 0 e 2^64 incluso
;;Devemos estabeler um intervalo de elementos printaveis e cobrir os casos
;;Por exemplo, se tivermos um elemento com 3 algarismo deveremos arrumar uma forma de carregar cada algarismo em 1 byte 
;;Fazemos isso pegando o numero e divindo por 10. O resto da divisao vai para rdx. Pegamos esse valor e somamos '0' para termos o valor ascii correspondente.  
toString:
	;;PARAMETROS DA FUNCAO toString()

    mov rsi, [matriz1PtrInicio]
    mov rdi, printableMatrixSum  
    mov rbx, 10                     ;;Valor de divisao definido
    ;;add rdi, 200                     ;;rdi aponta pro final do buffer
    xor rcx, rcx
    xor r8, r8
	;;mov rcx, rdi                    ;;Final do buffer armazenado em rcx

    .converterLoop:
        ;SYS_WRITE 1, rcx, 4 
        xor rdx, rdx
        cmp rax, 10			;;Checkando se rax eh maior
        jge $+2 			;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;Gambiarra - Por que funciona?
		div rbx             ;;Dividindo o valor por 10, jogando o quociente em rax e o resto em rdx 
		add dl, '0'         ;;Converte para ascii
        ;;mov byte [byteConverted], dl
        ;;SYS_WRITE 1, byteConverted, 1
        push rdx	;;Empilhando os algorismos para ordena-los
		inc r8		;;Contando o numero de empilhamentos
		;;mov [rdi], dl     ;;armazena em byteConverted printableMatrixSu
		
		;;inc rdi                     ;;rdi aponta pro final do buffer - 1 
        cmp rax, 0
        jne .converterLoop


	.desempilhar:
		pop r9					;;Vamos desempilhar os valores na pilha em r9
		mov [rdi], r9b			;;Pega o byte menos significativo de r9 e taca nesse endereco 
		inc rdi					;;incrementa o addr em 1
		dec r8					;;Decrementa o contador de valores empilhados
		cmp r8, 0				;;0 - r8
		jne .desempilhar

		inc rcx
        mov rax, [rsi+rcx*8]	;;Temos quad word para cada elemento. Devemos incrementar 8 bytes
        cmp rcx, 9
        jne .converterLoop
    
    ;;mov rcx, rdi                            ;;rcx aponta pro inicio da string
    ;;mov rdi, printableMatrixSum              ;;rdi aponta pro inicio dos elementos da matriz

    ret

multiplyMatrix:
	xor r12, r12
	xor i, i
	xor j, j
	xor k, k

	while1:
		cmp i, 5
		je break
		while2:
			cmp j, 4 
			je while1
			
			mov rax, i
            mov r11, [numeroColunasB]
            mul r11             ;;i*numeroColunas
            add rax, j          ;;i*numeroColunasB + j
            ;;push rax
            mov r8, rax
	
			push r12
			lea r12, [matriz1PtrInicio]
			mov [r12+r8], ACUMULADOR
			pop r12

			xor ACUMULADOR, ACUMULADOR		;;sum = 0
			while3:
				cmp k, 3
				je acumular
				
				mov rax, i
				mov r10, [numeroColunasA]
				mul r10				;;i*numeroColunasA
				add rax, k			;;i*numeroColunasA + k
				;;push rax
				mov r8, rax		

				mov rax, k			;;rax = k
				mov r11, [numeroColunasB]	;;
				mul r11						;;k*numeroColunasB
				add rax, j					;;k*numeroColunasB + j
				mov r9, rax
				

				push r12
				push r13
				lea r12, [matriz1PtrInicio]
				lea r13, [matriz2PtrInicio]
				mov rax, [r12+r8]		
				mov rbx, [r13+r9]
				pop r13
				pop r12

				mul rbx					;;rax = a_ik*b_kj
				add ACUMULADOR, rax		;;ACUMULADOR += a_ik*b_kj	
				inc k
			
				jmp while3
			
		acumular:
			mov rax, i
           	mov r11, [numeroColunasB]
           	mul r11             ;;i*numeroColunas
           	add rax, j          ;;i*numeroColunasB + j
           	;;push rax
           	mov r8, rax
			
			push r12
			lea r12, [matriz1PtrInicio]
			mov [r12+r8], ACUMULADOR
			jmp while2
	break:
		ret
