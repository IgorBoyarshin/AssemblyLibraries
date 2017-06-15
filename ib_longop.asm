.586
.MODEL flat, c
.STACK 4096

.CODE

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

; Multiplies two long integers
; Expects(in 32-bit chunks): length(result) = length(operand1) * length(operand2)
; Expects the result to be clean(filled with 0s)
; The two arguments can be the same memory, however not with the result
; Expects the variable to be stored in the Little Endian format
; Manages the stack frame
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

; Multiplies the given long integer by the given 32-bit value
; Expects the result to be one chunk longer than the long operand
; Expects the result to be clean(filled with 0s)
; The long operand can't be the same memory as the result
; Expects the variable to be stored in the Little Endian format
; Manages the stack frame
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