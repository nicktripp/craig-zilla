.data
LEXICON:
small_dict_size: .word 5
.align 2
small_dict:
	.word word_yes
	.word word_corn
	.word word_no
	.word word_up
	.word word_indronil

.align 2
word_yes:      	.asciiz "YES"
word_corn:     	.asciiz "CORN"
word_no:        .asciiz "NO"
word_up:        .asciiz "UP"
word_indronil: 	.asciiz "INDRONIL"

PUZZLE:
#  3 row 3 cols
.align 2
.word  3,3
.align 2
puzzle_small:
	.ascii "YES"  # answer int[] = {0,2, 5,4, 6,3,} - 3
	.ascii "PON"
	.ascii "UFE"

.align 2
SOLUTION:       .space 804


# 17 rows, 22 col
.align 2
puzzle_spimbot:
	.ascii "YZHARRYRHVTQLUAGTSVTQL"
	.ascii "FFEEGNAHCXEBCOSNBPEPQN"
	.ascii "ESCMANUFACTURINGHLKFUZ"
	.ascii "GYNOCCASIONALLYHEQSONC"
	.ascii "AMLFHELLOZKCQRXKLODHHE"
	.ascii "RAAJYLWNOISSIMTFMRQPCX"
	.ascii "ANCEOLTSESOHCDHFXALICF"
	.ascii "GUOYFABAWINCREASEDGCUU"
	.ascii "SFNBFIWXZDEINDEPENDENT"
	.ascii "DASDICAWMFSZUGXYEHOKLK"
	.ascii "RCTOCIBNEOUVZAXTXITSDJ"
	.ascii "MTAOIFRLBEWUZZJIWNJHKY"
	.ascii "NUNGAFEAECSGVCGEDIPIDK"
	.ascii "HRTOLOENFEQLPRBCYYQVVY"
	.ascii "CILQZSZANLRTRWDOWBWOQN"
	.ascii "VNYPWBECSMNDIVLYNBCCDN"
	.ascii "ZGYDDNKLSYNXAXJPUSESMF"
# ACRES.ADULT.BRICK.CANAL.CASEY.CHOSE.CLAWS.COACH.DANNY.DEPTH.EGYPT.ELLEN.EXIST.FOLKS.HABIT.HARRY.HELLO.IMAGE.LABEL.LUNGS.MOUNT.OBAMA.ADVICE.AUGUST.AUTUMN.BARELY.BIEBER.BORDER.BREEZE.DAMAGE.DEEPLY.DONKEY.FACING.FINEST.GARAGE.HUNTER.JUSTIN.MARTIN.MELTED.MEMORY.MONKEY.NORWAY.ATTEMPT.COOKIES.CRITICS.CUSTOMS.ENGLISH.GOODBYE.GRABBED.HAPPILY.HEADING.INSTANT.JANUARY.MISSION.CONTRAST.EVERYONE.EXCHANGE.FLOATING.ILLINOIS.LANGUAGE.MAGAZINE.OFFICIAL.ESSENTIAL.FIREPLACE.FREQUENCY.INCREASED.CONSTANTLY.DISCUSSION.HORIZONTAL.MYSTERIOUS.ACCOMPANIED.ARRANGEMENT.CELEBRITIES.EXPLANATION.GRANDMOTHER.INDEPENDENT.MATHEMATICS.NEIGHBORHOOD.OCCASIONALLY.MANUFACTURING.

# 17 rows, 22 col
#    . . . . . . . . Y Z H A R R Y R
#    H V T Q L U A G T S V T Q L F F
#    E E G N A H C X E B C O S N B P
#    E P Q N E S C M A N U F A C T U
#    R I N G H L K F U Z G Y N O C C
#    A S I O N A L L Y H E Q S O N C
#    A M L F H E L L O Z K C Q R X K
#    L O D H H E R A A J Y L W N O I
#    S S I M T F M R Q P C X A N C E
#    O L T S E S O H C D H F X A L I
#    C F G U O Y F A B A W I N C R E
#    A S E D G C U U S F N B F I W X
#    Z D E I N D E P E N D E N T D A
#    S D I C A W M F S Z U G X Y E H
#    O K L K R C T O C I B N E O U V
#    Z A X T X I T S D J M T A O I F
#    R L B E W U Z Z J I W N J H K Y
#    N U N G A F E A E C S G V C G E
#    D I P I D K H R T O L O E N F E
#    Q L P R B C Y Y Q V V Y C I L Q
#    Z S Z A N L R T R W D O W B W O
#    Q N V N Y P W B E C S M N D I V
#    L Y N B C C D N Z G Y D D N K L
#    S Y N X A X J P U S E S M F . .


.text
################################################################################
#                               PUZZLE SOLVER                                  #
################################################################################

main:
solve_puzzle:

        sub     $sp, $sp, 4
        sw      $ra  0($sp)

        # la      $t0, LEXICON
        # sw      $t0, SPIMBOT_LEXICON_REQUEST
	#
        # la      $t0, PUZZLE
        # sw      $t0, SPIMBOT_PUZZLE_REQUEST

        li      $t0, 0
        sw      $t0, SOLUTION

        la      $t0, LEXICON
	add     $a0, $t0, 4

        lw      $a1, LEXICON

        jal     find_words

        la      $t0, SOLUTION
        # sw      $t0, SPIMBOT_SOLVE_REQUEST

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
        add     $t1, $t1, $t2          # t1 = &positions[numWords*2]
        sw      $a1, 0($t1)
        sw      $a2, 4($t1)
        add     $t0, $t0, 1            #  =  +

        sw      $t0, SOLUTION

	jr	$ra




################################################################################
#                           PUZZLE SOLVER - END                                #
################################################################################
