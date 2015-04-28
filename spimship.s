.data
.align 2
LEXICON:	.space 4096
PUZZLE:         .space 4104 # at least??
PLANETS:        .space 64
DUST:           .space 256
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
INTERFERENCE_MASK 	= 0x8000
INTERFERENCE_ACK 	= 0xffff1304
SPACESHIP_FIELD_CNT  	= 0xffff110c
.text

main:
        li      $t0, SCAN_MASK                  # enable scan interrupt
        or      $t0, $t0, ENERGY_MASK           # enable energy interrupt
        or      $t0, $t0, INTERFERENCE_MASK     # enable interference interrupt
        or      $t0, $t0, 1                     # enable interrupt handling
        mtc0    $t0, $12

        la      $t0, LEXICON
	sw      $t0, SPIMBOT_LEXICON_REQUEST



infinite:
        jal     update_planet_data              # keep updating planet positions
	j	infinite

# t0 modified
update_planet_data:
        la      $t0, PLANETS
        sw      $t0, PLANETS_REQUEST
        jr      $ra


solve_puzzle:
        la      $t0, PUZZLE
        sw      $t0, SPIMBOT_PUZZLE_REQUEST
        



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

        # other interrupts

        j       finished                # if interrupt isn't handled then exit the handler

#handle scan interrupt
scan_interrupt:
        sw      $a1, SCAN_ACKNOWLEDGE
        # do stuff
        j       interrupt_dispatch      # there may still be interrupts
#energy interrupt handler
energy_interrupt:
        sw      $a1, ENERGY_ACKNOWLEDGE
        # do stuff
        j       interrupt_dispatch      # there may still be interrupts

interference_interrupt:
	sw	$a1, INTERFERENCE_ACKNOWLEDGE
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

# euclidean.s
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
