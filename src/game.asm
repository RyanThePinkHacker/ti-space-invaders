playerHeight .equ 8
playerMoveDistance .equ 4
playerScreenMargin .equ 8
playerStartingY .equ lcdHeight - playerHeight - playerScreenMargin
playerXMin .equ playerScreenMargin
playerXMax .equ lcdWidth - 16 - playerScreenMargin

inputLeftRow .equ kbdG3
inputLeftBit .equ kbit4
inputRightRow .equ kbdG5
inputRightBit .equ kbit6
inputFireRow .equ kbdG4
inputFirebit .equ kbit5
inputExitRow .equ kbdG6
inputExitBit .equ kbitClear

game_loop:
  call _ClrLCDAll
  call init_lcd
_game_loop:
; Render the screen
  xor a, a ; Sets to black ($00)
  call fill_screen
  ld a, playerHeight
  ld b, playerStartingY
  ld de, (PlayerPosition)
  ld ix, SpritePlayer
  call put_sprite
  call swap_vbuffer
; Check for input
  di
  ld hl, DI_MODE
  ld (hl), 2
  xor a, a
_game_loop_input_wait:
  cp (hl)
  jr nz, _game_loop_input_wait
  ld hl, inputLeftRow
  bit inputLeftBit, (hl)
  ld de, playerMoveDistance
  call nz, player_left

  ld hl, inputRightRow
  bit inputRightBit, (hl)
  call nz, player_right

  ld hl, inputExitRow
  bit inputExitBit, (hl)
  ei
  ret nz
  jr _game_loop

player_left:
  ld hl, (PlayerPosition)
  ld bc, playerXMin
  push hl
  sbc hl, bc
  pop hl
  ret c
  sbc hl, de
  ld (PlayerPosition), hl
  ret

player_right:
  ld hl, (PlayerPosition)
  ld bc, playerXMax
  push hl
  sbc hl, bc
  pop hl
  ret p
  add hl, de
  ld (PlayerPosition), hl
  ret

PlayerPosition:
  .dl (lcdWidth - spriteWidth) / 2