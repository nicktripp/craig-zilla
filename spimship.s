.data
.align 2
LEXICON:	.space 4096
PUZZLE:         .space 4104 # at least??
SOLUTION:       .space 804
PLANETS:        .space 64
DUST:           .space 256
STRATEGY:	.space 4
SCAN_COMPL:     .space 1

# movement memory-mapped I/O
VELOCITY            = 0xffff0010
ANGLE               = 0xffff0014
ANGLE_CONTROL       = 0xffff0018

# coordinates memory-mapped I/O
BOT_X               = 0xffff0020
BOT_Y               = 0xffff0024

# planet memory-mapped I/O
PLANETS_REQUEST     = 0xffff1014

# scanning memory-mapped I/O
SCAN_REQUEST        = 0xffff1010
SCAN_SECTOR         = 0xffff101c

# gravity memory-mapped I/O
FIELD_STRENGTH      = 0xffff1100

# bot info memory-mapped I/O
SCORES_REQUEST      = 0xffff1018
ENERGY              = 0xffff1104

# debugging memory-mapped I/O
PRINT_INT           = 0xffff0080

# interrupt constants
SCAN_MASK           = 0x2000
SCAN_ACKNOWLEDGE    = 0xffff1204
ENERGY_MASK         = 0x4000
ENERGY_ACKNOWLEDGE  = 0xffff1208

# puzzle interface locations
SPIMBOT_PUZZLE_REQUEST 		= 0xffff1000
SPIMBOT_SOLVE_REQUEST 		= 0xffff1004
SPIMBOT_LEXICON_REQUEST 	= 0xffff1008

# I/O used in competitive scenario
INTERFERENCE_MASK 	= 0x400
INTERFERENCE_ACK 	= 0xffff1304
SPACESHIP_FIELD_CNT  	= 0xffff110c

# timer
TIMER			= 0xffff001c
TIMER_MASK		= 0x8000
TIMER_ACKNOWLEDGE	= 0xffff006c

# strategies
IDLE		= 0
DRAG_DROP	= 1
PERTURBATION	= 2
TROLL		= 3

# the distance at which we can safely say the bot has "arrived" at a target
AT_DIST		= 5

DUST_RET_VEL    = 5	# the velocity the bot returns from a dust fetch
DUST_GET_VEL	= 10	# the velocity at which the bot travels to max dust sector
DUST_RET_FIELD  = 5	# the field strength of the return trip

STRAT_INTERVAL	= 1000	# how many cycles to wait till calculating a new strategy

.text

main:
        li      $t0, SCAN_MASK                  # enable scan interrupt
        or      $t0, $t0, ENERGY_MASK           # enable energy interrupt
        or      $t0, $t0, INTERFERENCE_MASK     # enable interference interrupt
	or	$t0, $t0, TIMER_MASK
	or      $t0, $t0, 1                     # enable interrupt handling
        mtc0    $t0, $12
	
	lw	$a0, TIMER
	add	$a0, $a0, STRAT_INTERVAL
	sw	$a0, TIMER
	sw	$zero, VELOCITY			# set velocity to 0

	li	$t0, IDLE
	sw	$t0, STRATEGY			# start off doing nothing

        li	$t0, 10
	sw	$t0, FIELD_STRENGTH		# start off doing nothing

infinite:
	lw      $t0, ENERGY
        bnez    $t0, strategy_dispatch
        jal     solve_puzzle			# solve puzzle
strategy_dispatch:
	lw	$t0, STRATEGY				# strategy dispatcher
	beq	$t0, IDLE, idle
	beq	$t0, DRAG_DROP, drag_drop
	beq	$t0, PERTURBATION, perturbation
	beq	$t0, TROLL, troll
	j	infinite

idle:
	sw	$zero, VELOCITY
	li	$t0, 1
	sw	$t0, ANGLE
	sw	$zero, ANGLE_CONTROL
	j	infinite

drag_drop:
	jal	get_max_sector
	and	$s0, $v0, 0x7		# s0 = sector%8 = X
	mul	$s0, $s0, 300		# s0:X *= 300
	srl	$s0, $s0, 3		# s0 /= 8
	add	$s0, $s0, 19		# s0 = xTarget
	srl	$s1, $v0, 3		# s1 = sector/8 = Y
	mul	$s1, $s1, 300		# s1:Y *= 300
	srl	$s1, $s1, 3		# s1 /= 8
	add	$s1, $s1, 19		# s1 = yTarget
 get_dust_loop:	
	lw	$t0, STRATEGY
	bne	$t0, DRAG_DROP, infinite	# if strategy change, restart
	move    $a0, $s0
	move	$a1, $s1
	jal	at_target
	beq	$v0, 1, end_get_dust		# if at target end_get_dust
	move    $a0, $s0
	move	$a1, $s1
	jal	face_target			# face target
	li	$t0, DUST_GET_VEL		# set velocity
	sw	$t0, VELOCITY
	j	get_dust_loop
 end_get_dust:
	lw	$t0, STRATEGY
	bne	$t0, DRAG_DROP, infinite	# if strategy change then leave
	li	$t0, DUST_RET_FIELD
	sw	$t0, FIELD_STRENGTH		# switch on field
	li	$t0, DUST_RET_VEL
	sw	$t0, VELOCITY			# modify velocity
 go_planet_loop:
	jal	update_planet_data
	la	$t0, PLANETS
	lw	$s0, 0($t0)			# s0 = planetX
	lw	$s1, 4($t0)			# s1 = planetY
	move	$a0, $s0
	move	$a1, $s1
	jal	at_target
	beq	$v0, 1, end_go_planet		# end loop if reached planet
	move	$a0, $s0
	move	$a1, $s1
	jal	face_target			# change dir to face planet
	j	go_planet_loop
 end_go_planet:
	sw	$zero, FIELD_STRENGTH		# switch field off
	sw	$zero, VELOCITY			# stop moving
	j	infinite

perturbation:
 perturbation_loop:
	lw	$t0, STRATEGY
	bne	$t0, PERTURBATION, end_perturbation
	# while strategy is perturbation
	#
	#   if at planet front
	#     if field off and sufficient dust in curr sector
	#       switch field on
	#     else switch field off
	#   else
	#     modify dir to planet
	j	perturbation_loop
 end_perturbation:
	j	infinite

troll:
	# do stuff
	j	infinite

strategy_4:
	# do stuff
	j	infinite

######################
# helper subroutines #
######################
update_planet_data: # t0 modified
        la      $t0, PLANETS
        sw      $t0, PLANETS_REQUEST
        jr      $ra

# returns the index of the sector with the most dust
get_max_sector:
	li	$v0, 0			# v0:max  max = 0
	li	$t0, 0			# t0:i  i = 0
 max_sector_for:
	bge	$t0, 64, max_sector_endfor

	li	$t1, 0
	sw	$t1, SCAN_COMPL		# complete = false;
	sw	$t0, SCAN_SECTOR	# scan_sector = i;
	la	$t1, DUST		# 
	sw	$t1, SCAN_REQUEST	# scan request sent, will take time to complete
 max_sector_while:
	lw	$t1, SCAN_COMPL
	beq	$t1, 1, max_sector_endwhile	# break when complete
	j	max_sector_while	
 max_sector_endwhile:
	la	$t3, DUST		# t3 = dust
	mul	$t1, $t0, 4		# t1 = 4*i
	add	$t1, $t1, $t3		# t1 = &dust[i]
	lw	$t1, 0($t1)		# t1 = dust[i]
	mul	$t2, $v0, 4		# t2 = 4*max
	add	$t2, $t2, $t3		# t2 = &dust[max]
	lw	$t2, 0($t2)		# t2 = dust[max]
	ble	$t1, $t2, max_sector_endif	# skip if dust[i] <= dust[max]
	move	$v0, $t0		# max = i
 max_sector_endif:
	add	$t0, $t0, 1		# i++
	j	max_sector_for
 max_sector_endfor:
	jr	$ra

scan_sector:
	la	$t1, DUST
	li	$t0, 0
	sw	$t0, SCAN_COMPL			# complete = false;
	sw	$a0, SCAN_SECTOR	
	sw	$t1, SCAN_REQUEST
 scan_sector_while:
	lw	$t0, SCAN_COMPL
	beq	$t0, 1, scan_sector_endwhile	# break when complete
	j	scan_sector_while
 scan_sector_endwhile:
	mul	$v0, $a0, 4			# v0 = a0*4
	add	$v0, $v0, $t1			# v0 = &dust[a0]
	lw	$v0, 0($v0)			# v0 = dust[a0]
	jr	$ra


# a0: targetX, a1: targetY
# makes spimbot face the target direction
face_target:
	sub	$sp, $sp, 4
	sw	$s0, 0($sp)

	lw	$t0, BOT_X
	sub	$a0, $a0, $t0		# a0 = targetX - botX
	lw	$t0, BOT_Y
	sub	$a1, $a1, $t0		# a1 = targetY - botY

	move	$s0, $ra
	jal	sb_arctan
	move	$ra, $s0

	sw	$v0, ANGLE
	li	$t0, 1
	sw	$t0, ANGLE_CONTROL

	lw	$s0, 0($sp)
	add	$sp, $sp, 4

	jr	$ra

# a0: targetX, a1: targetY
# returns 1 if it's sufficiently close to target, otherwise 0
at_target:
	sub	$sp, $sp, 4
	sw	$s0, 0($sp)

	lw	$t0, BOT_X
	sub	$a0, $a0, $t0		# a0 = targetX - botX
	lw	$t0, BOT_Y
	sub	$a1, $a1, $t0		# a1 = targetY - botY

	move	$s0, $ra
	jal	euclidean_dist
	move	$ra, $s0

	ble	$v0, AT_DIST, target_near	# if target is close, v0 = 1, else v0 = 0
	li	$v0, 0
	j	end_at_target
 target_near:
	li	$v0, 1
 end_at_target:
	lw	$s0, 0($sp)
	add	$sp, $sp, 4
	jr	$ra
##########################
# end helper subroutines #
##########################

################################################################################
#                               PUZZLE SOLVER                                  #
################################################################################

solve_puzzle:

        sub     $sp, $sp, 4
        sw      $ra  0($sp)

        la      $t0, LEXICON
        sw      $t0, SPIMBOT_LEXICON_REQUEST

        la      $t0, PUZZLE
        sw      $t0, SPIMBOT_PUZZLE_REQUEST

        li      $t0, 0
        sw      $t0, SOLUTION

        lw      $a1, LEXICON

        la      $t0, LEXICON
        add     $a0, $t0, 4

        jal     find_words

        la      $t0, SOLUTION
        sw      $t0, SPIMBOT_SOLVE_REQUEST

        lw      $ra  0($sp)
        add     $sp, $sp, 4

        jr      $ra

## RETURNS -1 IF WORD IS NOT FOUND IN PUZZLE
##
## int
## vert_strncmp(const char* word, int start_i, int j) {
##     int word_iter = 0;
##
##     for (int i = start_i; i < num_rows; i++, word_iter++) {
##         if (get_character(i, j) != word[word_iter]) {
##             return -1;
##         }
##
##         if (word[word_iter + 1] == '\0') {
##             // return ending address within array
##             return i * num_columns + j;
##         }
##     }
##
##     return -1;
## }
vert_strncmp:
	sub	$sp, $sp, 24
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)

	move	$s0, $a0		# word
	move	$s1, $a1		# i = start_i
	move	$s2, $a2		# j
	li	$s3, 0			# word_iter
	lw	$s4, PUZZLE($zero)      # s4 = num_rows

  vs_for:
	bge	$s1, $s4, vs_nope	# !(i < num_rows)

	move	$a0, $s1
	move	$a1, $s2
	jal	get_character		# get_character(i, j)
	add	$t0, $s0, $s3		# &word[word_iter]
	lbu	$t1, 0($t0)		# word[word_iter]
	bne	$v0, $t1, vs_nope

	lbu	$t1, 1($t0)		# word[word_iter + 1]
	bne	$t1, 0, vs_next
        la      $t7, PUZZLE             # t7 = &PUZZLE
	lw	$v0, 4($t7)             # v0 = num_columns
	mul	$v0, $s1, $v0		# i * num_columns
	add	$v0, $v0, $s2		# i * num_columns + j
	j	vs_return

  vs_next:
	add	$s1, $s1, 1		# i++
	add	$s3, $s3, 1		# word_iter++
	j	vs_for

  vs_nope:
	li	$v0, -1

  vs_return:
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	lw	$s4, 20($sp)
	add	$sp, $sp, 24
	jr	$ra



## RETURNS -1 IF WORD IS NOT FOUND IN PUZZLE
##
## int
## horiz_strncmp(const char* word, int start, int end) {
##     int word_iter = 0;
##
##     while (start <= end) {
##         if (puzzle[start] != word[word_iter]) {
##             return -1;
##         }
##
##         if (word[word_iter + 1] == '\0') {
##             return start;
##         }
##
##         start++;
##         word_iter++;
##     }
##
##     return -1;
## }
horiz_strncmp:
	li	$t0, 0			# word_iter = 0

        la      $t1, PUZZLE             # t1 = &puzzle
	add	$t1, $t1, 8             # t1 = &puzzle

  hs_while:
	bgt	$a1, $a2, hs_end	# !(start <= end)

	add	$t2, $t1, $a1		# &puzzle[start]
	lbu	$t2, 0($t2)		# puzzle[start]
	add	$t3, $a0, $t0		# &word[word_iter]
	lbu	$t4, 0($t3)		# word[word_iter]
	beq	$t2, $t4, hs_same	# !(puzzle[start] != word[word_iter])
	li	$v0, -1			# return -1
	jr	$ra

  hs_same:
	lbu	$t4, 1($t3)		# word[word_iter + 1]
	bne	$t4, 0, hs_next		# !(word[word_iter + 1] == '\0')
	move	$v0, $a1		# return start
	jr	$ra

  hs_next:
	add	$a1, $a1, 1		# start++
	add	$t0, $t0, 1		# word_iter++
	j	hs_while

  hs_end:
	li	$v0, -1			# return -1
	jr	$ra


## RETURNS -1 IF WORD IS NOT FOUND IN PUZZLE
##    In this case, start must be > end
##
## int
## back_horiz_strncmp(const char* word, int start, int end)
## {
##     int word_iter = 0;
##
##     while (start >= end)
##     {
##         if (puzzle[start] != word[word_iter])
##         {
##             return -1;
##         }
##
##         if (word[word_iter + 1] == '\0')
##         {
##             return end;
##         }
##
##         start--;
##         word_iter++;
##     }
##
##     return -1;
## }
back_horiz_strncmp:
	li	$t0, 0			# word_iter = 0

        la      $t1, PUZZLE             # t1 = &puzzle
	add	$t1, $t1, 8             # t1 = &puzzle

  bhs_while:
	blt	$a1, $a2, bhs_end	# !(start >= end)

	add	$t2, $t1, $a1		# &puzzle[start]
	lbu	$t2, 0($t2)		# puzzle[start]
	add	$t3, $a0, $t0		# &word[word_iter]
	lbu	$t4, 0($t3)		# word[word_iter]
	beq	$t2, $t4, bhs_same	# !(puzzle[start] != word[word_iter])
	li	$v0, -1			# return -1
	jr	$ra

  bhs_same:
	lbu	$t4, 1($t3)		# word[word_iter + 1]
	bne	$t4, 0, bhs_next		# !(word[word_iter + 1] == '\0')
	move	$v0, $a1		# return start
	jr	$ra

  bhs_next:
	sub	$a1, $a1, 1		# start--
	add	$t0, $t0, 1		# word_iter++
	j	bhs_while

  bhs_end:
	li	$v0, -1			# return 0
	jr	$ra


## RETURNS -1 IF WORD IS NOT FOUND IN PUZZLE
##
## int
## back_vert_strncmp(const char* word, int start_i, int j)
## {
##     int word_iter = 0;
##
##     for (int i = start_i; i >= 0; i--, word_iter++)
##     {
##         if (get_character(i, j) != word[word_iter])
##         {
##             return -1;
##         }
##
##         if (word[word_iter + 1] == '\0')
##         {
##             // return ending address within array
##             return i * num_columns + j;
##         }
##     }
##
##     return -1;
## }
back_vert_strncmp:
	sub	$sp, $sp, 24
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)

	move	$s0, $a0		# word
	move	$s1, $a1		# i = start_i
	move	$s2, $a2		# j
	li	$s3, 0			# word_iter
        lw	$s4, PUZZLE($zero)      # s4 = num_rows

  bvs_for:
	bltz	$s1, bvs_nope	        # !(i >= 0)

	move	$a0, $s1
	move	$a1, $s2
	jal	get_character		# get_character(i, j)
	add	$t0, $s0, $s3		# &word[word_iter]
	lbu	$t1, 0($t0)		# word[word_iter]
	bne	$v0, $t1, bvs_nope

	lbu	$t1, 1($t0)		# word[word_iter + 1]
	bne	$t1, 0, bvs_next
        la      $t7, PUZZLE             # t7 = &PUZZLE
	lw	$v0, 4($t7)             # v0 = num_columns
	mul	$v0, $s1, $v0		# i * num_columns
	add	$v0, $v0, $s2		# i * num_columns + j
	j	bvs_return

  bvs_next:
	sub	$s1, $s1, 1		# --i
	add	$s3, $s3, 1		# word_iter++
	j	bvs_for

  bvs_nope:
	li	$v0, -1

  bvs_return:
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	lw	$s4, 20($sp)
	add	$sp, $sp, 24
	jr	$ra


## void
## find_words(const char** dictionary, int dictionary_size)
## {
##     for (int k = 0; k < dictionary_size; k++)
##     {
##         for (int i = 0; i < num_rows; i++)
##         {
##             for (int j = 0; j < num_columns; j++)
##             {
##                 int start = i * num_columns + j;
##                 int end = (i + 1) * num_columns - 1;
##
##                 const char* word = dictionary[k];
##                 int word_end = horiz_strncmp(word, start, end);
##                 if (word_end > 0)
##                 {
##                     record_word(word, start, word_end);
##		       break;
##                 }
##
##                 word_end = vert_strncmp(word, i, j);
##                 if (word_end > 0)
##                 {
##                     record_word(word, start, word_end);
##		       break;
##                 }
##
##                 word_end = back_horiz_strncmp(word, start, i*num_columns);
##                 if (word_end >= 0)
##                 {
##                     record_word(word, start, word_end);
##		       break;
##                 }
##
##                 word_end = back_vert_strncmp(word, i, j);
##                 if (word_end >= 0)
##                 {
##                     record_word(word, start, word_end);
##		       break;
##                 }
##
##             }
##         }
##     }
## }

.globl find_words
find_words:
	sub	$sp, $sp, 40
	sw	$ra, 0($sp)
	sw	$s0, 4($sp)
	sw	$s1, 8($sp)
	sw	$s2, 12($sp)
	sw	$s3, 16($sp)
	sw	$s4, 20($sp)
	sw	$s5, 24($sp)
	sw	$s6, 28($sp)
	sw	$s7, 32($sp)
	sw	$s8, 36($sp)

	move	$s0, $a0		# dictionary
	move	$s1, $a1		# dictionary_size
        la      $t7, PUZZLE             # t7 = &PUZZLE
	lw	$s2, 4($t7)             # s2 = num_columns


	li	$s7, 0			# k = 0

  fw_k:
      	bge	$s7, $s1, fw_done	# !(k < dictionary_size)
      	mul	$t0, $s7, 4		# k * 4
      	add	$t0, $s0, $t0		# &dictionary[k]
      	lw	$s8, 0($t0)		# word = dictionary[k]

      	li	$s3, 0			# i = 0

  fw_i:
        lw	$t0, PUZZLE($zero)      # t0 = num_rows
      	bge	$s3, $t0, fw_k_next	# !(i < num_rows)
      	li	$s4, 0			# j = 0

  fw_j:
      	bge	$s4, $s2, fw_i_next	# !(j < num_columns)
      	mul	$t0, $s3, $s2		# i * num_columns
      	add	$s5, $t0, $s4		# start = i * num_columns + j
      	add	$t0, $t0, $s2		# equivalent to (i + 1) * num_columns
      	sub	$s6, $t0, 1		# end = (i + 1) * num_columns - 1


  fw_horiz:
	move	$a0, $s8		# word
	move	$a1, $s5		# start
	move	$a2, $s6		# end
	jal	horiz_strncmp
	ble	$v0, 0, fw_vert		# !(word_end > 0)
	move	$a0, $s8		# word
	move	$a1, $s5		# start
	move	$a2, $v0		# word_end
	jal	record_word
	j 	fw_k_next

  fw_vert:
	move	$a0, $s8		# word
	move	$a1, $s3		# i
	move	$a2, $s4		# j
	jal	vert_strncmp
	ble	$v0, 0, fw_back_horiz	# !(word_end > 0)
	move	$a0, $s8		# word
	move	$a1, $s5		# start
	move	$a2, $v0		# word_end
	jal	record_word
	j 	fw_k_next

  fw_back_horiz:
        move	$a0, $s8		# word
	move	$a1, $s5		# start
        sub     $t0, $s5, $s4           # t0 = i*num_columns + j - j
	move	$a2, $t0		# i*num_columns
	jal	back_horiz_strncmp
	blt	$v0, 0, fw_back_vert	# !(word_end >= 0)
	move	$a0, $s8		# word
	move	$a1, $s5		# start
	move	$a2, $v0		# word_end
	jal	record_word
	j 	fw_k_next

  fw_back_vert:
	move	$a0, $s8		# word
	move	$a1, $s3		# i
	move	$a2, $s4		# j
	jal	back_vert_strncmp
        blt	$v0, 0, fw_j_next	# !(word_end >= 0)
	move	$a0, $s8		# word
	move	$a1, $s5		# start
	move	$a2, $v0		# word_end
	jal	record_word

  fw_j_next:
	add	$s4, $s4, 1		# j++
	j	fw_j

  fw_i_next:
	add	$s3, $s3, 1		# i++
	j	fw_i

  fw_k_next:
	add	$s7, $s7, 1		# k++
	j	fw_k

  fw_done:
	lw	$ra, 0($sp)
	lw	$s0, 4($sp)
	lw	$s1, 8($sp)
	lw	$s2, 12($sp)
	lw	$s3, 16($sp)
	lw	$s4, 20($sp)
	lw	$s5, 24($sp)
	lw	$s6, 28($sp)
	lw	$s7, 32($sp)
	lw	$s8, 36($sp)
	add	$sp, $sp, 40
	jr	$ra


get_character:
        la      $t7, PUZZLE             # t7 = &PUZZLE
        lw	$t0, 4($t7)             # v0 = num_columns
	mul	$t0, $a0, $t0		# i * num_columns
	add	$t0, $t0, $a1		# i * num_columns + j
        la	$t1, PUZZLE             # t1 = &puzzle
	add	$t1, $t1, 8             # t1 = &puzzle
	add	$t1, $t1, $t0		# &puzzle[i * num_columns + j]
	lbu	$v0, 0($t1)		# puzzle[i * num_columns + j]
	jr	$ra


##
## record_word(word, start, word_end)
## {
##     positions[numWords] = start;
##     positions[numWords+1] = word_end;
##     numWords += 2;
## }
record_word:
        lw      $t0, SOLUTION          # t0 = numWords
        la      $t1, SOLUTION          #
        add     $t1, $t1, 4            # t1 = &positions

        mul     $t2, $t0, 8            # t2 = 4*numWords*2
        add     $t1, $t1, $t2          # t1 = &positions[numWords]
        sw      $a1, 0($t1)
        sw      $a2, 4($t1)
        add     $t0, $t0, 1            #  numWords++

        sw      $t0, SOLUTION

	jr	$ra




################################################################################
#                           PUZZLE SOLVER - END                                #
################################################################################


###########################
# interrupt handler start #
###########################
.kdata
chunkIH:        .space 8

.ktext 0x80000180
interrupt_handler:
.set noat
        move    $k1, $at
.set at
        # save a0 and v0
        la      $k0, chunkIH
        sw      $a0, 0($k0)
        sw      $v0, 4($k0)
        # k0 can be recycled

        mfc0    $k0, $13		# Get cause register
        srl     $a0, $k0, 2		#
        and     $a0, $a0, 0xf		# ExcCode field
        bne     $a0, 0, finished        # if not an interrupt then exit the handler

interrupt_dispatch:
        mfc0    $k0, $13		# get cause register again
        beq     $k0, 0, finished

        # send interrupts to their sub handlers
        and     $a0, $k0, SCAN_MASK	# handle scan interrupt
        bne     $a0, 0, scan_interrupt

        and     $a0, $k0, ENERGY_MASK	# handle energy interrupt
        bne     $a0, 0, energy_interrupt

        and     $a0, $k0, INTERFERENCE_MASK
        bne     $a0, 0, interference_interrupt

	and	$a0, $k0, TIMER_MASK
	bne	$a0, 0, timer_interrupt

        # other interrupts

        j       finished                # if interrupt isn't handled then exit the handler


scan_interrupt:
        sw      $a1, SCAN_ACKNOWLEDGE
        li	$a0, 1
	sw	$a0, SCAN_COMPL		# mark scan as complete
        j       interrupt_dispatch      # there may still be interrupts

energy_interrupt:
        sw      $a1, ENERGY_ACKNOWLEDGE
        j       interrupt_dispatch      # there may still be interrupts

interference_interrupt:
        sw	$a1, INTERFERENCE_ACK
	j	interrupt_dispatch

timer_interrupt:
	sw	$a1, TIMER_ACKNOWLEDGE
	# do strategy calculation
	li	$a0, DRAG_DROP
	sw	$a0, STRATEGY
	lw	$a0, TIMER
	add	$a0, $a0, STRAT_INTERVAL
	sw	$a0, TIMER
	j	interrupt_dispatch

finished:
        # restore saved registers
        la      $k0, chunkIH
	lw      $a0, 0($k0)
	lw      $v0, 4($k0)
.set noat
        move    $at, $k1
.set at
        eret
#########################
# interrupt handler end #
#########################

###############
# euclidean.s #
###############
.data
three:	.float	3.0
five:	.float	5.0
PI:	.float	3.141592
F180:	.float  180.0

.text

# -----------------------------------------------------------------------
# sb_arctan - computes the arctangent of y / x
# $a0 - x
# $a1 - y
# returns the arctangent
# -----------------------------------------------------------------------

sb_arctan:
	li	$v0, 0		# angle = 0;

	abs	$t0, $a0	# get absolute values
	abs	$t1, $a1
	ble	$t1, $t0, no_TURN_90

	## if (abs(y) > abs(x)) { rotate 90 degrees }
	move	$t0, $a1	# int temp = y;
	neg	$a1, $a0	# y = -x;
	move	$a0, $t0	# x = temp;
	li	$v0, 90		# angle = 90;

no_TURN_90:
	bgez	$a0, pos_x 	# skip if (x >= 0)

	## if (x < 0)
	add	$v0, $v0, 180	# angle += 180;

pos_x:
	mtc1	$a0, $f0
	mtc1	$a1, $f1
	cvt.s.w $f0, $f0	# convert from ints to floats
	cvt.s.w $f1, $f1

	div.s	$f0, $f1, $f0	# float v = (float) y / (float) x;

	mul.s	$f1, $f0, $f0	# v^^2
	mul.s	$f2, $f1, $f0	# v^^3
	l.s	$f3, three	# load 5.0
	div.s 	$f3, $f2, $f3	# v^^3/3
	sub.s	$f6, $f0, $f3	# v - v^^3/3

	mul.s	$f4, $f1, $f2	# v^^5
	l.s	$f5, five	# load 3.0
	div.s 	$f5, $f4, $f5	# v^^5/5
	add.s	$f6, $f6, $f5	# value = v - v^^3/3 + v^^5/5

	l.s	$f8, PI		# load PI
	div.s	$f6, $f6, $f8	# value / PI
	l.s	$f7, F180	# load 180.0
	mul.s	$f6, $f6, $f7	# 180.0 * value / PI

	cvt.w.s $f6, $f6	# convert "delta" back to integer
	mfc1	$t0, $f6
	add	$v0, $v0, $t0	# angle += delta

	jr 	$ra

# -----------------------------------------------------------------------
# euclidean_dist - computes sqrt(x^2 + y^2)
# $a0 - x
# $a1 - y
# returns the distance
# -----------------------------------------------------------------------

euclidean_dist:
	mul	$a0, $a0, $a0	# x^2
	mul	$a1, $a1, $a1	# y^2
	add	$v0, $a0, $a1	# x^2 + y^2
	mtc1	$v0, $f0
	cvt.s.w	$f0, $f0	# float(x^2 + y^2)
	sqrt.s	$f0, $f0	# sqrt(x^2 + y^2)
	cvt.w.s	$f0, $f0	# int(sqrt(...))
	mfc1	$v0, $f0
	jr	$ra
