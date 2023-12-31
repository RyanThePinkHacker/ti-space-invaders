; Sprites

#include "src/generated/sprites/player.asm"
;#include "src/generated/sprites/debug.asm"
#include "src/generated/sprites/projectile.asm"
#include "src/generated/sprites/enemy_death.asm"
#include "src/generated/sprites/enemy_1.asm"
#include "src/generated/sprites/enemy_2.asm"
#include "src/generated/sprites/enemy_3.asm"
#include "src/generated/sprites/enemy_4.asm"
#include "src/generated/sprites/characters.asm"
#include "src/generated/sprites/shield_1.asm"
#include "src/generated/sprites/shield_2.asm"
#include "src/generated/sprites/shield_3.asm"
#include "src/generated/sprites/shield_4.asm"

spriteEnemy1BitmaskMs .equ ((SpriteEnemy1a & $00FF00) >> 8) ^ ((SpriteEnemy1b & $00FF00) >> 8)
spriteEnemy1BitmaskLs .equ (SpriteEnemy1a & $0000FF) ^ (SpriteEnemy1b & $0000FF)
spriteEnemy2BitmaskMs .equ ((SpriteEnemy2a & $00FF00) >> 8) ^ ((SpriteEnemy2b & $00FF00) >> 8)
spriteEnemy2BitmaskLs .equ (SpriteEnemy2a & $0000FF) ^ (SpriteEnemy2b & $0000FF)
spriteEnemy3BitmaskMs .equ ((SpriteEnemy3a & $00FF00) >> 8) ^ ((SpriteEnemy3b & $00FF00) >> 8)
spriteEnemy3BitmaskLs .equ (SpriteEnemy3a & $0000FF) ^ (SpriteEnemy3b & $0000FF)

; Text
#include "src/generated/texts.asm"
