.586
.MODEL flat, c
.STACK 4096

.CODE

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

; Multiplies two long integers
; Expects the result to be twice as long as the operands
; Expects the variable to be stored in the Little Endian format
; Manages the stack frame
; 1st arg = first operand address [EBP + 20]
; 2nd arg = second operand address [EBP + 16]
; 3rd arg = result address [EBP + 12]
; 4th arg = operands' size in 32-bit chunks [EBP + 8]
IbMulLong proc
  push ebp
  mov ebp, esp

  ; If the size of the operands is 0 => we're done
  mov ecx, dword ptr[ebp + 8] ; operands' size in 32-bit chunks
  cmp ecx, 0
  jle @IbMulLong_end


@IbMulLong_end:
  mov esp, ebp
  pop ebp
  ret 16
IbMulLong endp

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

; Multiplies the given long integer by the given 32-bit value
; Expects the result to be one chunk longer than the long operand
; Expects the result to be clean(filled with 0s)
; Expects the variable to be stored in the Little Endian format
; Manages the stack frame
; 1st arg = long operand address [EBP + 20]
; 2nd arg = 32-bit operand [EBP + 16]
; 3rd arg = result address [EBP + 12]
; 4th arg = operands' size in 32-bit chunks [EBP + 8]
IbMul32Long proc
  push ebp
  mov ebp, esp

  ; If the size of the operands is 0 => we're done
  mov ecx, dword ptr[ebp + 8] ; operands' size in 32-bit chunks
  cmp ecx, 0
  jle @IbMul32Long_end  

  ; Retrieve args
  mov esi, dword ptr[ebp + 20] ; long operand address
  mov ebx, dword ptr[ebp + 16] ; 32-bit operand  
  mov edi, dword ptr[ebp + 12] ; result address

  ; A little trick to achieve accessing the operands from the lowest chunks
  shl ecx, 2 ; *4. Will contain the shift in bytes and 4 times the amount of chunks
  add esi, ecx
  add edi, ecx  
  neg ecx
  
@IbMul32Long_loopChunk:
  ; Multiplication. The result will be stored in EAX(low):EDX(high)
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

; Subtracts two long integers
; Neglects the carry bit(if present) from the highest chunk
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

; Adds two long integers
; Neglects the carry bit(if present) from the highest chunk
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

END