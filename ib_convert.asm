.586
.MODEL flat, c
.STACK 4096

.CODE

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

; Converts the given binary number into its string representation
; Puts separation character(' ') every 4 digits
; Expects the variable to be stored in the Little Endian format
; Manages the stack frame
; 1st arg = variable address [EBP + 16]
; 2nd arg = variable size in bits [EBP + 12]
; 3rd arg = result string address [EBP + 8]
IbBinToStr proc
  push ebp
  mov ebp, esp

  ; If the size of the variable is 0 => we're done
  mov ecx, dword ptr[ebp + 12] ; variable size in bits
  cmp ecx, 0
  jle @IbBinToStr_end

  mov esi, dword ptr[ebp + 16] ; variable address
  ; Calculate in EDI the amount of separators we're gonna put
  mov edi, ecx 
  dec edi ; to properly calculate the amount of separators
  shr edi, 2 ; /= 4 (separator every 4 bits)
  add edi, dword ptr[ebp + 8] ; add the string address

  mov dl, byte ptr[esi] ; load the first byte
  mov ebx, 8 ; contains current amount of processed bits [1..8]
  ; Processing order: the first bit we read is placed at the end of the string
@IbBinToStr_loopBits:
  mov byte ptr[edi + ecx - 1], '0' ; put the '0' into memory
  shr dl, 1 ; get the next bit
  jnc @IbBinToStr_bitZero ; jump if the bit that fell out was 0
  inc byte ptr[edi + ecx - 1] ; otherwise the 1 fell out => replace '0' with '1' in memory  

@IbBinToStr_bitZero: 
  ; If no more bits => we're done
  dec ecx
  jz @IbBinToStr_end
  
  ; Put the separator if (ebx % 4 == 0)
  dec ebx
  mov eax, ebx
  and eax, 3 ; make it [0..3]
  jnz @IbBinToStr_noSeparator
  mov byte ptr[edi + ecx - 1], ' '
  dec edi
@IbBinToStr_noSeparator:
  or ebx, ebx ; to set the flags
  jnz @IbBinToStr_loopBits ; no need to load the next byte => keep processing  
  ; Reset the bits counter
  mov ebx, 8
  ; Load the next byte
  inc esi
  mov dl, byte ptr[esi]      
  jmp @IbBinToStr_loopBits


@IbBinToStr_end:
  mov esp, ebp
  pop ebp
  ret 12
IbBinToStr endp

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

; Converts the given hex number into its string representation
; Puts separation characters(' ') every 8 digits
; Expects the variable to be stored in the Little Endian format
; Manages the stack frame
; 1st arg = variable address [EBP + 16]
; 2nd arg = variable size in 4-bit chunks [EBP + 12]
; 3rd arg = result string address [EBP + 8]
IbHexToStr proc
  push ebp
  mov ebp, esp

  ; If the size of the variable is 0 => we're done
  mov ebx, dword ptr[ebp + 12] ; variable size in 4-bit chunks
  cmp ebx, 0
  jle @IbHexToStr_end

  mov esi, dword ptr[ebp + 16] ; variable address
  ; Calculate in EDI the amount of separators we're gonna put
  mov edi, ebx ; amount of 4-bit chunks
  dec edi ; to properly calculate the amount of separators
  shr edi, 3 ; /= 8 (separator every 8 4-bit chunks === every 8 digits)
  add edi, dword ptr[ebp + 8] ; add the string address

  mov dh, 0 ; contains current amount of 4-bit chunks that we wrote modulo 8 [1..8]  
  mov dl, byte ptr[esi] ; load the first byte
  mov cl, 0 ; contains the shift required to put the desired 4-bit chunk at the start of the register {0, 4}
  ; Processing order: the first 4-bit chunk we read is placed at the end of the string
@IbBinToStr_loopChunks:
  mov al, dl
  shr al, cl ; place the low or the high 4-bit chunk at the start
  call IbGetHexDigitCode
  mov byte ptr[edi + ebx - 1], al

  ; If no more bits => we're done
  dec ebx
  jz @IbHexToStr_end
  
  ; Put the separator if DH == 8
  inc dh
  cmp dh, 8
  jl @IbBinToStr_noSeparator
  mov byte ptr[edi + ebx - 1], ' '
  dec edi
  xor dh, dh
@IbBinToStr_noSeparator:
  ; Advance to the next byte if Cl == 8
  add cl, 4
  cmp cl, 8  
  jne @IbBinToStr_loopChunks ; no need to load the next byte => keep processing    
  xor cl, cl ; reset the required shift
  ; Load the next byte
  inc esi
  mov dl, byte ptr[esi]      
  jmp @IbBinToStr_loopChunks
  

@IbHexToStr_end:
  mov esp, ebp
  pop ebp
  ret 12
IbHexToStr endp

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

; Converts the given hex digit into its ASCII code
; Ignores everything but the low 4 bits
; 1st arg = hex digit [AL]
; result = ASCII code [AL]
IbGetHexDigitCode proc
    and al, 0Fh ; make it [0..15]
    add al, '0' ; add the code of '0'
    cmp al, '9' ; if we had digit <= 9 then we're done
    jle @IbGetHexDigitCode_end
    add al, 7 ; otherwise jump to the codes of letters (for [A..F])
@IbGetHexDigitCode_end:
    ret
IbGetHexDigitCode endp

; «««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««««

END