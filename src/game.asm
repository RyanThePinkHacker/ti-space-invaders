spriteWidthSmall .equ 8
spriteWidthBig .equ 16
playerHeight .equ 8
enemyHeight .equ 8
enemyCollisionWidth .equ 11
enemyCollisionHeight .equ enemyHeight
enemyMoveDistance .equ 4
projectileHeight .equ 8
projectileMoveDistance .equ 2
playerScreenMargin .equ 8
playerStartingY .equ lcdHeight - playerHeight - playerScreenMargin
playerStartingX .equ (lcdWidth - spriteWidthBig) / 2
playerXMin .equ playerScreenMargin
playerXMax .equ lcdWidth - spriteWidthBig - playerScreenMargin
totalEnemies .equ 11 * 4
enemyMemorySize .equ 5

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
_game_loop:
  ld hl, GameCounter
  inc (hl)

  ; Set enemy move flag
  ld a, (hl) ; a=0 -> 1/256 frames
  sla a ; a=0 -> 1/128 frames
  sla a ; a=0 -> 1/64 frames
  ld hl, GameFlags
  jr z, _game_loop_set_enemy_move

  res gameFlagEnemyMove, (hl) ; Reset flag
  jr _game_loop_enemy_move_skip

_game_loop_set_enemy_move:
  set gameFlagEnemyMove, (hl) ; Set flag

_game_loop_enemy_move_skip:
  xor a ; Sets to black ($00)
  call fill_screen

  call update_player_projectile
  call update_enemies

  ld a, playerHeight
  ld b, playerStartingY
  ld de, (PlayerPosition)
  ld ix, SpritePlayer
  call put_sprite_16

  call swap_vbuffer

; Check for input
  di

  ld hl, inputLeftRow
  bit inputLeftBit, (hl)
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
  dec hl
  dec hl
  ld (PlayerPosition), hl
  ret

player_right:
  ld hl, (PlayerPosition)
  ld bc, playerXMax
  push hl
  sbc hl, bc
  pop hl
  ret p
  inc hl
  inc hl
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

  ld a, (GameFlags)
  bit gameFlagEnemyMove, a
  jr z, _update_enemies_loop

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
  push bc
  ld a, (ix + 4) ; Type
  or a
  jr z, _update_enemies_loop_skip ; Enemy is dead

  ld hl, (ix) ; Enemy x

  ld a, (GameFlags)
  bit gameFlagEnemyMove, a
  jr z, _update_enemies_move_skip ; Jump if not move
  
  ld bc, enemyMoveDistance

  bit gameFlagEnemyDirection, a
  jr nz, _update_enemies_move_right  

  sbc hl, bc ; Move left
  jr _update_enemies_move_skip

_update_enemies_move_right:
  add hl, bc ; Move right
_update_enemies_move_skip:
  ld (ix), hl ; Update x

  ld a, (PlayerProjectileSpawned)
  or a
  jr z, _update_enemies_loop_collision_skip ; Projectile not spawned
  ld a, (PlayerProjectileY)
  ld hl, (PlayerProjectileX)
  ld de, (spriteWidthSmall / 2) + 1 ; Center of projectile
  add hl, de
  call collision_enemy
  jr nc, _update_enemies_loop_collision_skip ; Didn't collide
  xor a
  ld (ix + 4), a ; Kill enemy
  ld (PlayerProjectileSpawned), a ; Despawn projectile
  jr _update_enemies_loop_skip
_update_enemies_loop_collision_skip:
  ld de, (ix) ; X
  ld hl, EnemySpriteTable
  ld bc, 0
  ld c, (ix + 4) ; Type
  add hl, bc
  ld b, (ix + 3) ; Y
  push ix
  ld ix, (hl) ; *Sprite
  ld a, 8 ; Height
  call put_sprite_16
  pop ix
_update_enemies_loop_skip:
  pop bc
  ld de, enemyMemorySize
  add ix, de
  djnz _update_enemies_loop
  ret

update_player_projectile:
  ld hl, PlayerProjectileSpawned
  xor a
  cp (hl)
  ret z ; Return if not spawned

  ld a, (PlayerProjectileY)
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

collision_enemy:
; Input:
;   ix = *enemy
;   hl = projectile_x
;   a = projectile_y
; Output:
;   carry = Collision
; Destorys:
;   a
;   hl
;   bc
  ld bc, (ix) ; enemy_left
  inc bc ; Left offset
  inc bc
  inc bc
  sbc hl, bc
  jr c, _collision_failed ; Left bounds

  ld bc, enemyCollisionWidth
  sbc hl, bc
  ret nc ; Right bounds

  ld b, (ix + 3) ; enemy_top
  sbc a, b
  jr c, _collision_failed ; Top bounds

  ld b, enemyCollisionHeight
  sbc a, b
  ret ; Bottom bounds
_collision_failed:
  or a ; Reset carry
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
; First frame is 0.
GameCounter:
  .db $FF

;;; Game Flags ;;;
; Is turned on for frames where the enemies should move.
; 0: Don't move (default)
; 1: Move
gameFlagEnemyMove .equ 0
; Toggles every move.
; 0: Left
; 1: Right (default)
gameFlagEnemyDirection .equ 1

GameFlags:
  .db %00000010

;;; Enemy States ;;;
;   Used for score and death check
enemyStateDead      .equ 3 * 0
enemyStateExplosion .equ 3 * 1
enemyState1         .equ 3 * 2
enemyState2         .equ 3 * 3
enemyState3         .equ 3 * 4

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
