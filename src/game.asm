spriteWidthSmall .equ 8
spriteWidthBig .equ 16
playerHeight .equ 8
enemyHeight .equ 8
projectileHeight .equ 8
playerMoveDistance .equ 4
projectileMoveDistance .equ 4
playerScreenMargin .equ 8
playerStartingY .equ lcdHeight - playerHeight - playerScreenMargin
playerStartingX .equ (lcdWidth - spriteWidthBig) / 2
playerXMin .equ playerScreenMargin
playerXMax .equ lcdWidth - spriteWidthBig - playerScreenMargin
totalEnemies .equ 11 * 4
enemyMemorySize .equ 5

; Enemy States
;   Used for score and death check
enemyStateDead      .equ 3 * 0
enemyStateExplosion .equ 3 * 1
enemyState1         .equ 3 * 2
enemyState2         .equ 3 * 3
enemyState3         .equ 3 * 4

; Hotkeys
inputLeftRow  .equ kbdG7
inputLeftBit  .equ kbitLeft
inputRightRow .equ kbdG7
inputRightBit .equ kbitRight
inputFireRow  .equ kbdG1
inputFireBit  .equ kbit2nd
inputExitRow  .equ kbdG6
inputExitBit  .equ kbitClear

game_loop:
  ;call _ClrLCDAll
  ;xor a
_game_loop:
  ld hl, GameCounter
  inc (hl)

  xor a ; Sets to black ($00)
  call fill_screen

  call update_player_projectile
  call update_enemies

  ld a, playerHeight
  ld b, playerStartingY
  ld de, (PlayerPosition)
  ld ix, SpritePlayer
  call put_sprite_16

  ld hl, TextAlpha
  ld b, 128
  ld de, 0
  call put_string
  call put_string

  call swap_vbuffer

; Check for input
  di

  ld hl, inputLeftRow
  bit inputLeftBit, (hl)
  ld de, playerMoveDistance
  call nz, player_left

  ld hl, inputRightRow
  bit inputRightBit, (hl)
  call nz, player_right

  ld hl, inputFireRow
  bit inputFireBit, (hl)
  call nz, player_fire

  ld hl, inputExitRow
  bit inputExitBit, (hl)
  ei
  jr z, _game_loop
  ret

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

player_fire:
  ld hl, PlayerProjectileSpawned
  xor a
  cp (hl) ; Check if projectile is spawned
  ret nz  ; Return if already spawned
  ld (hl), 1 ; Set spawned
  ld hl, (PlayerPosition)
  ld bc, (spriteWidthBig - spriteWidthSmall) / 2 ; Center to player
  add hl, bc
  ld (PlayerProjectileX), hl
  ld hl, PlayerProjectileY
  ld (hl), playerStartingY ; Set y
  ret

update_enemies:
  ld ix, EnemyTable
  ld b, totalEnemies

  ld a, (GameCounter)
  sla a
  or a
  jr nz, _update_enemies_loop

  ld hl, EnemySpriteTable + enemyState1
  ld a, (hl)
  xor spriteEnemy1BitmaskLs
  ld (hl), a
  inc hl
  ld a, (hl)
  xor spriteEnemy1BitmaskMs
  ld (hl), a

  ld hl, EnemySpriteTable + enemyState2
  ld a, (hl)
  xor spriteEnemy2BitmaskLs
  ld (hl), a
  inc hl
  ld a, (hl)
  xor spriteEnemy2BitmaskMs
  ld (hl), a

  ld hl, EnemySpriteTable + enemyState3
  ld a, (hl)
  xor spriteEnemy3BitmaskLs
  ld (hl), a
  inc hl
  ld a, (hl)
  xor spriteEnemy3BitmaskMs
  ld (hl), a
_update_enemies_loop:
  ld a, (ix + 4) ; Type
  or a
  jr z, _update_enemies_loop_skip ; Enemy is dead
  ld de, (ix) ; X
  ld hl, EnemySpriteTable
  push bc
  ld bc, 0
  ld c, a
  add hl, bc
  ld b, (ix + 3) ; Y
  push ix
  ld ix, (hl) ; *Sprite
  ld a, 8 ; Height
  call put_sprite_16
  pop ix
  pop bc
_update_enemies_loop_skip:
  ld de, enemyMemorySize
  add ix, de
  djnz _update_enemies_loop
  ret

update_player_projectile:
  ld hl, PlayerProjectileSpawned
  xor a
  cp (hl)
  ret z ; Return if not spawned

  ld a, (PlayerProjectileY) ; 19
  sbc a, projectileMoveDistance ; Move projectile up
  jr c, _update_player_projectile_despawn

  ld hl, PlayerProjectileY
  ld (hl), a ; Update Y

  ld b, a ; Y
  ld a, projectileHeight
  ld de, (PlayerProjectileX)
  ld ix, SpriteProjectile
  jp put_sprite_8

_update_player_projectile_despawn:
  ld (hl), 0
  ret

PlayerPosition:
  .dl playerStartingX

PlayerProjectileSpawned:
  .db $00
PlayerProjectileX:
  .dl $000000
PlayerProjectileY:
  .db $00

; Counts up each frame.
; Overflow expected.
GameCounter:
  .db $FF

EnemySpriteTable:
  .dl SpriteEnemyDeath ; Offset: 0
  .dl SpriteEnemyDeath ; Offset: 3
  .dl SpriteEnemy1a    ; Offset: 6
  .dl SpriteEnemy2a    ; Offset: 9
  .dl SpriteEnemy3a    ; Offset: 12

; 11x4     Size: 220
; Enemy    Size: 5
;   X      Size: 3, Offset: 0
;   Y      Size: 1, Offset: 3
;   Type   Size: 1, Offset: 4
EnemyTable:
  .db  72, 0, 0,  8, enemyState1
  .db  88, 0, 0,  8, enemyState1
  .db 104, 0, 0,  8, enemyState1
  .db 120, 0, 0,  8, enemyState1
  .db 136, 0, 0,  8, enemyState1
  .db 152, 0, 0,  8, enemyState1
  .db 168, 0, 0,  8, enemyState1
  .db 184, 0, 0,  8, enemyState1
  .db 200, 0, 0,  8, enemyState1
  .db 216, 0, 0,  8, enemyState1
  .db 232, 0, 0,  8, enemyState1
  .db  72, 0, 0, 24, enemyState2
  .db  88, 0, 0, 24, enemyState2
  .db 104, 0, 0, 24, enemyState2
  .db 120, 0, 0, 24, enemyState2
  .db 136, 0, 0, 24, enemyState2
  .db 152, 0, 0, 24, enemyState2
  .db 168, 0, 0, 24, enemyState2
  .db 184, 0, 0, 24, enemyState2
  .db 200, 0, 0, 24, enemyState2
  .db 216, 0, 0, 24, enemyState2
  .db 232, 0, 0, 24, enemyState2
  .db  72, 0, 0, 40, enemyState3
  .db  88, 0, 0, 40, enemyState3
  .db 104, 0, 0, 40, enemyState3
  .db 120, 0, 0, 40, enemyState3
  .db 136, 0, 0, 40, enemyState3
  .db 152, 0, 0, 40, enemyState3
  .db 168, 0, 0, 40, enemyState3
  .db 184, 0, 0, 40, enemyState3
  .db 200, 0, 0, 40, enemyState3
  .db 216, 0, 0, 40, enemyState3
  .db 232, 0, 0, 40, enemyState3
  .db  72, 0, 0, 56, enemyState3
  .db  88, 0, 0, 56, enemyState3
  .db 104, 0, 0, 56, enemyState3
  .db 120, 0, 0, 56, enemyState3
  .db 136, 0, 0, 56, enemyState3
  .db 152, 0, 0, 56, enemyState3
  .db 168, 0, 0, 56, enemyState3
  .db 184, 0, 0, 56, enemyState3
  .db 200, 0, 0, 56, enemyState3
  .db 216, 0, 0, 56, enemyState3
  .db 232, 0, 0, 56, enemyState3
