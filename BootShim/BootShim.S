_Head:
  adr   x1, _Payload    /* Set _Entry address */
  b     _Start          /* Jump to the real code */

_StackBase:
  .quad UEFI_BASE       /* Text Offset */

_StackSize:
  .quad UEFI_SIZE       /* Image Size */
  .quad 0               /* Flags */
  .quad 0               /* Reserved */
  .quad 0               /* Reserved */
  .quad 0               /* Reserved */
  .ascii "ARM\x64"      /* ARM64 Magic */
  .long 0               /* Reserved */

_Start:
  mov   x11, CREATE_FDT_POINTER
  cmp   x11, 1
  b.ne  skip_dtb
  mov   x10, FDT_POINTER_ADDRESS
  str   x0, [x10]

skip_dtb:
  mov   x4, x1
  ldr   x5, _StackBase
  cmp   x4, x5
  beq   _Entry
  ldr   x6,  _StackSize

_CopyLoop:
  ldp   x2, x3, [x4], #16
  stp   x2, x3, [x5]
  dc    civac, x5
  add   x5, x5, #16
  subs  x6, x6, #16
  b.ne  _CopyLoop

#ifdef PAYLOAD_BASE
  /* x4 now points just past the FD: an optional "XNUP" payload may follow */
  ldr   w2, [x4]
  movz  w3, #0x4E58
  movk  w3, #0x5055, lsl #16
  cmp   w2, w3
  b.ne  _NoPayload
  ldr   w6, [x4, #4]    /* Payload Size */
  add   x6, x6, #23     /* Header + Round Up to 16 */
  and   x6, x6, #~15
  movz  x5, #(PAYLOAD_BASE >> 16), lsl #16

_PayloadLoop:
  ldp   x2, x3, [x4], #16
  stp   x2, x3, [x5]
  dc    civac, x5
  add   x5, x5, #16
  subs  x6, x6, #16
  b.ne  _PayloadLoop

_NoPayload:
#endif
  dsb   sy
  isb
  ldr   x5, _StackBase

_Entry:
  br    x5

_Dead:
  b     _Dead           /* We should never get here */

.text
.align 4

_Payload:
  /* Your code will get ran right after this binary */
