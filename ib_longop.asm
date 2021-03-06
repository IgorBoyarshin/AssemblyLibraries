.586
.MODEL flat, c
.STACK 4096

.CODE

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

; Divides the given long integer by 10
; Performs division by 10 using the groups of bits(32) division method
; The long integer and the result can be the same memory
; Expects the variable to be stored in the Little Endian format
; Manages the stack frame
; Registers altered: EAX, EBX, ECX, EDX, ESI, EDI, EBP, ESP
; 1st arg = long integer address [EBP + 20]
; 2nd arg = long integer size in 32-bit chunks [EBP + 16]
; 3rd arg = result address [EBP + 12]
; 4th arg = remainder address [EBP + 8]
IbDiv10Long proc
  push ebp
  mov ebp, esp

  ; Retrieve args
  mov esi, [ebp + 20] ; long integer address
  mov edi, [ebp + 12] ; result address
  mov ecx, dword ptr[ebp + 16] ; long integer size in 32-bit chunks

  ; If the size of the long integer is 0 => we're done
  cmp ecx, 0
  jle @IbDiv10Long_end

  shl ecx, 2 ; *4. Will contain the shift in bytes and 4 times the amount of chunks
  xor edx, edx ; first remainder = 0
  mov ebx, 10 ; to divide by
@IbDiv10Long_loop:
  mov eax, dword ptr[esi + ecx - 4] ; the high chunk  
  ; the previous remainder is already stored in EDX

  div ebx ; EBX == 10

  mov dword ptr[edi + ecx - 4], eax ; result into memory
  sub ecx, 4
  jnz @IbDiv10Long_loop

  mov ebx, dword ptr[ebp + 8] ; remainder address
  mov dword ptr[ebx], edx ; move the remainder into memory

@IbDiv10Long_end:
  mov esp, ebp
  pop ebp
  ret 16
IbDiv10Long endp

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

; Multiplies two long integers
; Expects(in 32-bit chunks): length(result) = length(operand1) * length(operand2)
; Expects the result to be clean(filled with 0s)
; The two arguments can be the same memory, however not with the result
; Expects the variable to be stored in the Little Endian format
; Manages the stack frame
; Registers altered: EAX, EBX, ECX, EDX, ESI, EDI, EBP, ESP
; 1st arg = first operand address [EBP + 24]
; 2nd arg = first operand size in 32-bit chunks [EBP + 20]
; 3rd arg = second operand address [EBP + 16]
; 4th arg = second operand size in 32-bit chunks [EBP + 12]
; 5th arg = result address [EBP + 8]
IbMulLong proc
  push ebp
  mov ebp, esp

  ; Retrieve agrs
  mov esi, dword ptr[ebp + 24] ; first operand address  
  mov edi, dword ptr[ebp + 8] ; result address

  ; If the size of the first operand is 0 => we're done
  shl dword ptr[ebp + 20], 2 ; *4. Will contain the shift in bytes and 4 times the amount of chunks
  mov ecx, dword ptr[ebp + 20] ; first operand size in 32-bit chunks
  cmp ecx, 0
  jle @IbMulLong_end

  ; A little trick to achieve accessing the operands from the lowest chunks    
  add esi, ecx ; shift the address of the first operand (by 4*length(operand1))
  add edi, ecx ; shift the address of the result (by 4*length(operand1))
  neg dword ptr[ebp + 20]

  ; If the size of the second operand is 0 => we're done
  mov ecx, dword ptr[ebp + 12] ; second operand size in 32-bit chunks
  cmp ecx, 0  
  jle @IbMulLong_end

  ; A little trick to achieve accessing the operands from the lowest chunks
  shl ecx, 2 ; *4. Will contain the shift in bytes and 4 times the amount of chunks  
  add dword ptr[ebp + 16], ecx ; shift the address of the second operand (by 4*length(operand2))
  neg ecx  
@IbMulLong_loopRows:
  push ecx
  
  mov ebx, dword ptr[ebp + 16] ; second operand address
  mov ebx, dword ptr[ebx + ecx]

  mov ecx, dword ptr[ebp + 20] ; first operand size in 32-bit chunks(multiplied by -4)  
  @IbMulLong_loopPartials:
    ; Multiplication. The result is stored in EAX(low):EDX(high)
    mov eax, dword ptr[esi + ecx]
    mul ebx ; current 32-bit chunk of the second argument
    
    ; Add to the result according to the current shift    
    add dword ptr[edi + ecx], eax
    adc dword ptr[edi + ecx + 4], edx
  
    ; Drag the carry(if any) forward as many chunks as needed
    jnc @IbMulLong_nextChunkNoCarry
    lea edx, [edi + ecx + 8]
    mov eax, 0
  @IbMulLong_nextChunkDoCarry:    
    add dword ptr[edx + 4 * eax], 1 ; carry for the next 32-bit chunk
    inc eax
    jc @IbMulLong_nextChunkDoCarry
  @IbMulLong_nextChunkNoCarry:
  
    add ecx, 4
    jnz @IbMulLong_loopPartials
    
  add edi, 4 ; the next row is shifted one 32-bit chunk compared to the previous
  pop ecx
  add ecx, 4
  jnz @IbMulLong_loopRows


@IbMulLong_end:
  mov esp, ebp
  pop ebp
  ret 20
IbMulLong endp

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

; Replaces the given long integer with the result of multiplying it by the given 32-bit value
; The overflow from the highest chunk(if present) is discarded
; Expects the variable to be stored in the Little Endian format
; Manages the stack frame
; Registers altered: EAX, EBX, ECX, EDX, ESI, EDI, EBP, ESP
; 1st arg = long operand address [EBP + 16]
; 2nd arg = long operand size in 32-bit chunks [EBP + 12]
; 3rd arg = 32-bit operand [EBP + 8]
IbMulSelf32Long proc
  push ebp
  mov ebp, esp

  ; If the size of the operands is 0 => we're done
  mov ecx, dword ptr[ebp + 12] ; long operand size in 32-bit chunks
  cmp ecx, 0
  jle @IbMulSelf32Long_end  

  ; Retrieve args
  mov esi, dword ptr[ebp + 16] ; long operand address
  mov ebx, dword ptr[ebp + 8] ; 32-bit operand

  ; A little trick to achieve accessing the operands from the lowest chunks
  shl ecx, 2 ; *4. Will contain the shift in bytes and 4 times the amount of chunks
  add esi, ecx
  neg ecx
  
  ; Will store the EDX result from the previous iteration
  xor edi, edi ; the first iteration has now predecessor => == 0

@IbMulSelf32Long_loopChunk:
  ; Multiplication. The result is stored in EAX(low):EDX(high)
  mov eax, dword ptr[esi + ecx] ; current 32-bit chunk of the long operand  
  mul ebx ; 32-bit operand

  ; Add the result and write into memory
  add eax, edi ; low_new += (high_prev + carry_prev)
  mov dword ptr[esi + ecx], eax ; res[i] = low_new
  adc edx, 0 ; generate carry_new from the addition
  mov edi, edx  ; save high_new for the next iteration
  
  add ecx, 4
  jnz @IbMulSelf32Long_loopChunk


@IbMulSelf32Long_end:
  mov esp, ebp
  pop ebp
  ret 12
IbMulSelf32Long endp

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

; Multiplies the given long integer by the given 32-bit value
; Expects the result to be one chunk longer than the long operand
; Expects the result to be clean(filled with 0s)
; The long operand can't be the same memory as the result
; Expects the variable to be stored in the Little Endian format
; Manages the stack frame
; Registers altered: EAX, EBX, ECX, EDX, ESI, EDI, EBP, ESP
; 1st arg = long operand address [EBP + 20]
; 2nd arg = long operand size in 32-bit chunks [EBP + 16]
; 3rd arg = 32-bit operand [EBP + 12]
; 4th arg = result address [EBP + 8]
IbMul32Long proc
  push ebp
  mov ebp, esp

  ; If the size of the operands is 0 => we're done
  mov ecx, dword ptr[ebp + 16] ; long operand size in 32-bit chunks
  cmp ecx, 0
  jle @IbMul32Long_end  

  ; Retrieve args
  mov esi, dword ptr[ebp + 20] ; long operand address
  mov ebx, dword ptr[ebp + 12] ; 32-bit operand  
  mov edi, dword ptr[ebp + 8] ; result address

  ; A little trick to achieve accessing the operands from the lowest chunks
  shl ecx, 2 ; *4. Will contain the shift in bytes and 4 times the amount of chunks
  add esi, ecx
  add edi, ecx  
  neg ecx
  
@IbMul32Long_loopChunk:
  ; Multiplication. The result is stored in EAX(low):EDX(high)
  mov eax, dword ptr[esi + ecx] ; current 32-bit chunk of the long operand  
  mul ebx ; 32-bit operand

  ; Add to the result according to the current shift
  add dword ptr[edi + ecx], eax
  adc dword ptr[edi + ecx + 4], edx ; (0 + EDX + carry)
  
  add ecx, 4
  jnz @IbMul32Long_loopChunk


@IbMul32Long_end:
  mov esp, ebp
  pop ebp
  ret 16
IbMul32Long endp

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

; Adds two long integers
; Neglects the carry bit(if present) from the highest chunk
; All three variables(args and result) can be the same memory
; Expects the variable to be stored in the Little Endian format
; Manages the stack frame
; Registers altered: EAX, EBX, ECX, EDX, ESI, EDI, EBP, ESP
; 1st arg = first operand address [EBP + 20]
; 2nd arg = second operand address [EBP + 16]
; 3rd arg = result address [EBP + 12]
; 4th arg = operands' size in 32-bit chunks [EBP + 8]
IbAddLong proc
  push ebp
  mov ebp, esp

  ; If the size of the operands is 0 => we're done
  mov ecx, dword ptr[ebp + 8] ; operands' size in 32-bit chunks
  cmp ecx, 0
  jle @IbAddLong_end

  ; Retrieve args  
  mov esi, dword ptr[ebp + 20] ; first operand address
  mov ebx, dword ptr[ebp + 16] ; second operand address
  mov edi, dword ptr[ebp + 12] ; result address

  ; Main loop
  clc
  xor edx, edx ; iterator from 0
@IbAddLong_chunksLoop:
  mov eax, dword ptr[esi + 4 * edx]
  adc eax, dword ptr[ebx + 4 * edx]
  mov dword ptr[edi + 4 * edx], eax

  inc edx
  dec ecx
  jnz @IbAddLong_chunksLoop


@IbAddLong_end:
  mov esp, ebp
  pop ebp
  ret 16
IbAddLong endp

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

; Subtracts two long integers
; Neglects the carry bit(if present) from the highest chunk
; All three variables(args and result) can be the same memory
; Expects the variable to be stored in the Little Endian format
; Manages the stack frame
; Registers altered: EAX, EBX, ECX, EDX, ESI, EDI, EBP, ESP
; 1st arg = first operand address [EBP + 20]
; 2nd arg = second operand address [EBP + 16]
; 3rd arg = result address [EBP + 12]
; 4th arg = operands' size in 32-bit chunks [EBP + 8]
IbSubLong proc
  push ebp
  mov ebp, esp

  ; If the size of the operands is 0 => we're done
  mov ecx, dword ptr[ebp + 8] ; operands' size in 32-bit chunks
  cmp ecx, 0
  jle @IbSubLong_end

  ; Retrieve args  
  mov esi, dword ptr[ebp + 20] ; first operand address
  mov ebx, dword ptr[ebp + 16] ; second operand address
  mov edi, dword ptr[ebp + 12] ; result address

  ; Main loop
  clc
  xor edx, edx ; iterator from 0
@IbSubLong_chunksLoop:
  mov eax, dword ptr[esi + 4 * edx]
  sbb eax, dword ptr[ebx + 4 * edx]
  mov dword ptr[edi + 4 * edx], eax

  inc edx
  dec ecx
  jnz @IbSubLong_chunksLoop


@IbSubLong_end:
  mov esp, ebp
  pop ebp
  ret 16
IbSubLong endp

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

END