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
	lw	$s4, num_rows

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
	lw	$v0, num_columns
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
	lw	$t1, puzzle

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
	lw	$t1, puzzle

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
	lw	$s4, num_rows

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
	lw	$v0, num_columns
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
##     for (int i = 0; i < num_rows; i++)
##     {
##         for (int j = 0; j < num_columns; j++)
##         {
##             int start = i * num_columns + j;
##             int end = (i + 1) * num_columns - 1;
##
##             for (int k = 0; k < dictionary_size; k++)
##             {
##                 const char* word = dictionary[k];
##                 int word_end = horiz_strncmp(word, start, end);
##                 if (word_end > 0)
##                 {
##                     record_word(word, start, word_end);
##                 }
##
##                 word_end = vert_strncmp(word, i, j);
##                 if (word_end > 0)
##                 {
##                     record_word(word, start, word_end);
##                 }
##
##                 word_end = back_horiz_strncmp(word, start, i*num_columns);
##                 if (word_end > 0)
##                 {
##                     record_word(word, start, word_end);
##                 }
##
##                 word_end = back_vert_strncmp(word, i, j);
##                 if (word_end > 0)
##                 {
##                     record_word(word, start, word_end);
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
	lw	$s2, num_columns
	li	$s3, 0			# i = 0

fw_i:
	lw	$t0, num_rows
	bge	$s3, $t0, fw_done	# !(i < num_rows)
	li	$s4, 0			# j = 0

fw_j:
	bge	$s4, $s2, fw_i_next	# !(j < num_columns)
	mul	$t0, $s3, $s2		# i * num_columns
	add	$s5, $t0, $s4		# start = i * num_columns + j
	add	$t0, $t0, $s2		# equivalent to (i + 1) * num_columns
	sub	$s6, $t0, 1		# end = (i + 1) * num_columns - 1
	li	$s7, 0			# k = 0

fw_k:
	bge	$s7, $s1, fw_j_next	# !(k < dictionary_size)
	mul	$t0, $s7, 4		# k * 4
	add	$t0, $s0, $t0		# &dictionary[k]
	lw	$s8, 0($t0)		# word = dictionary[k]

	move	$a0, $s8		# word
	move	$a1, $s5		# start
	move	$a2, $s6		# end
	jal	horiz_strncmp
	ble	$v0, 0, fw_vert		# !(word_end > 0)
	move	$a0, $s8		# word
	move	$a1, $s5		# start
	move	$a2, $v0		# word_end
	jal	record_word

fw_vert:
	move	$a0, $s8		# word
	move	$a1, $s3		# i
	move	$a2, $s4		# j
	jal	vert_strncmp
	ble	$v0, 0, fw_k_next	# !(word_end > 0)
	move	$a0, $s8		# word
	move	$a1, $s5		# start
	move	$a2, $v0		# word_end
	jal	record_word

fw_k_next:
	add	$s7, $s7, 1		# k++
	j	fw_k

fw_j_next:
	add	$s4, $s4, 1		# j++
	j	fw_j

fw_i_next:
	add	$s3, $s3, 1		# i++
	j	fw_i

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




## ??
record_word:
	move	$t0, $a0
	li	$v0, SBRK
	li	$a0, 16
	syscall
	sw	$t0, 0($v0)
	sw	$a1, 4($v0)
	sw	$a2, 8($v0)
	sw	$zero, 12($v0)
	lw	$t0, words_end
	sw	$v0, 0($t0)
	la	$t0, 12($v0)
	sw	$t0, words_end
	jr	$ra
