NibbleBuffer:
  .db $00

number_to_string:
; Input:
;   hl = *number (24-bit)
;   ix = *output (8-bytes)
; Output:
;   String is placed at *output
  ld bc, 0
  ld de, 0

  ld a, (hl)
  bit 0, a
  jr z, _number_to_string_1_1

  ld a, $01 ; daa unnecessary.
            ; Always valid BCD.
  ld e, a

_number_to_string_1_1:
  ld a, (hl)
  bit 1, a
  jr z, _number_to_string_1_2

  ld a, e
  add a, $02 ; daa unnecessary.
             ; Always valid BCD.
	     
  ld e, a
_number_to_string_1_2:
  ld a, (hl)
  bit 2, a
  jr z, _number_to_string_1_3

  ld a, e
  add a, $04 ; daa unnecessary.
             ; Always valid BCD.
	     
  ld e, a
_number_to_string_1_3:
  ld a, (hl)
  bit 3, a
  jr z, _number_to_string_1_4

  ld a, e
  add a, $08
  daa
  ld e, a
_number_to_string_1_4:
  ld a, (hl)
  bit 4, a
  jr z, _number_to_string_1_5

  ld a, e
  add a, $16
  daa
  ld e, a
_number_to_string_1_5:
  ld a, (hl)
  bit 5, a
  jr z, _number_to_string_1_6

  ld a, e
  add a, $32
  daa
  ld e, a
_number_to_string_1_6:
  ld a, (hl)
  bit 6, a
  jr z, _number_to_string_1_7

  ; Add 64.

  ; Add 4.
  ld a, e
  add a, $04
  daa
  ld e, a

  ; Add 60.
  push hl
  ld hl, NibbleBuffer
  ld (hl), e
  ld a, d
  rrd
  push af
  ld a, (hl)
  add a, $06
  daa

  ld (hl), a
  pop af
  rld
  ld d, a
  ld e, (hl)
  pop hl
_number_to_string_1_7:
  ld a, (hl)
  bit 7, a
  jr z, _number_to_string_2_0

  ; Add 128.

  ; Add 8.
  ld a, e
  add a, 8
  daa
  ld e, a

  ; Add 120.
  push hl
  ld hl, NibbleBuffer
  ld (hl), e
  ld a, d
  rrd
  push af
  ld a, (hl)
  add a, $12
  daa

  ld (hl), a
  pop af
  rld
  ld d, a
  ld e, (hl)
  pop hl
_number_to_string_2_0:
  inc hl
  ld a, (hl)
  bit 0, a
  jr z, _number_to_string_2_1

  ; Add 256.

  ; Add 6.
  ld a, e
  add a, 6
  daa
  ld e, a

  ; Add 250.
  push hl
  ld hl, NibbleBuffer
  ld (hl), e
  ld a, d
  rrd
  push af
  ld a, (hl)
  add a, $25
  daa

  ld (hl), a
  pop af
  rld
  ld d, a
  ld e, (hl)
  pop hl
_number_to_string_2_1:
_number_to_string_end:
  ld a, $0F
  and b
  ld (ix + 1), a

  srl b
  srl b
  srl b
  srl b
  ld (ix), b

  ld a, $0F
  and c
  ld (ix + 3), a

  srl c
  srl c
  srl c
  srl c
  ld (ix + 2), c

  ld a, $0F
  and d
  ld (ix + 5), a

  srl d
  srl d
  srl d
  srl d
  ld (ix + 4), d

  ld a, $0F
  and e
  ld (ix + 7), a

  srl e
  srl e
  srl e
  srl e
  ld (ix + 6), e

  ret