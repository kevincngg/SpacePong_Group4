########################################################################
# SPACE PONG - MIPS Assembly for MARS Simulator
# A space-themed Pong game with spaceship paddles and asteroid ball
# Features single-player (vs AI) and two-player modes
########################################################################

.data
# Display configuration (64x64 pixel display)
DISPLAY_WIDTH:  .word 64
DISPLAY_HEIGHT: .word 64

# Color palette for space background and stars
COLOR_SPACE:    .word 0x000510    # Dark blue space background
COLOR_STAR1:    .word 0xFFFFFF    # Bright white stars
COLOR_STAR2:    .word 0x808080    # Medium gray stars
COLOR_STAR3:    .word 0x404040    # Dim gray stars
COLOR_MENU_TEXT: .word 0x00FF00   # Green menu text

# Player 1 spaceship colors (blue theme)
COLOR_SHIP1_BODY:    .word 0x1E90FF    # Dodger blue body
COLOR_SHIP1_WING:    .word 0x4169E1    # Royal blue wings
COLOR_SHIP1_ENGINE:  .word 0x00FFFF    # Cyan engine glow
COLOR_SHIP1_WINDOW:  .word 0x87CEEB    # Sky blue window

# Player 2 spaceship colors (red/orange theme)
COLOR_SHIP2_BODY:    .word 0xFF4500    # Orange red body
COLOR_SHIP2_WING:    .word 0xDC143C    # Crimson wings
COLOR_SHIP2_ENGINE:  .word 0xFF6347    # Tomato engine glow
COLOR_SHIP2_WINDOW:  .word 0xFFD700    # Gold window

# Asteroid (ball) colors for textured appearance
COLOR_ASTEROID1:     .word 0x8B4513    # Saddle brown
COLOR_ASTEROID2:     .word 0xA0522D    # Sienna
COLOR_ASTEROID3:     .word 0x696969    # Dim gray

# Game state variables
game_mode:      .word 0    # 0=menu, 1=single player, 2=two player
paddle1_y:      .word 28   # Player 1 paddle vertical position
paddle2_y:      .word 28   # Player 2/AI paddle vertical position
ball_x:         .word 32   # Ball horizontal position
ball_y:         .word 32   # Ball vertical position
ball_dx:        .word 1    # Ball horizontal velocity (-1 or 1)
ball_dy:        .word 1    # Ball vertical velocity (-1 or 1)
score1:         .word 0    # Player 1 score
score2:         .word 0    # Player 2 score
frame_count:    .word 0    # Total frames elapsed (for timing)
ball_active:    .word 0    # 0=waiting for serve, 1=ball in play
ball_speed:     .word 3    # Frames to wait before moving ball (lower=faster)
ball_counter:   .word 0    # Counter for ball speed control
input_cooldown: .word 0    # Frames remaining before accepting next input

# AI behavior parameters
ai_speed:       .word 2    # Frames between AI decisions (lower=faster/harder)
ai_counter:     .word 0    # Counter for AI update timing
ai_reaction_zone: .word 4  # Pixels from paddle center before AI reacts
ai_error_chance: .word 15  # 1 in N chance AI makes a mistake each update

# Game constants
PADDLE_HEIGHT:  .word 6    # Height of each paddle in pixels
BALL_SIZE:      .word 3    # Size of ball/asteroid (3x3 pixels)
PADDLE_X1:      .word 3    # X position of left paddle
PADDLE_X2:      .word 58   # X position of right paddle
PADDLE_SPEED:   .word 20   # Movement speed (not currently used)

# Star field coordinates and types (20 stars for parallax effect)
star_x:         .word 10, 25, 45, 8, 55, 18, 38, 52, 14, 42, 30, 5, 60, 22, 48, 12, 35, 50, 20, 58
star_y:         .word 5, 12, 8, 20, 15, 28, 22, 35, 45, 40, 50, 55, 48, 60, 58, 38, 25, 18, 52, 10
star_type:      .word 0, 1, 2, 1, 0, 2, 1, 0, 2, 1, 0, 2, 1, 0, 1, 2, 0, 1, 2, 0

.text
.globl main

########################################################################
# MAIN - Program entry point
# Jumps to the main menu to start the game
########################################################################
main:
    j show_menu

########################################################################
# SHOW_MENU - Display the main menu screen
# Draws the space background, stars, game title, and mode options
########################################################################
show_menu:
    jal clear_to_space       # Fill screen with space background
    jal draw_stars           # Draw starfield
    jal draw_menu_title      # Draw "SPACE PONG" title
    jal draw_menu_options    # Draw "1-P1" and "2-P2" options
    
# Wait for player to press '1' or '2' to select game mode
menu_wait:
    lui $t0, 0xffff          # Load keyboard memory-mapped I/O address
    lw $t1, 0($t0)           # Check keyboard ready bit
    andi $t1, $t1, 0x0001    # Mask to check if key is pressed
    beq $t1, $zero, menu_wait # Loop until key pressed
    
    lw $t2, 4($t0)           # Read the pressed key
    sw $zero, 0($t0)         # Clear keyboard ready bit
    
    li $t3, 49               # ASCII '1'
    beq $t2, $t3, start_single # Start single player mode
    
    li $t3, 50               # ASCII '2'
    beq $t2, $t3, start_two  # Start two player mode
    
    j menu_wait              # Invalid key, keep waiting

# Initialize single player mode (player vs AI)
start_single:
    li $t0, 1
    sw $t0, game_mode        # Set game mode to 1
    jal init_game
    j game_loop

# Initialize two player mode (player vs player)
start_two:
    li $t0, 2
    sw $t0, game_mode        # Set game mode to 2
    jal init_game
    j game_loop

########################################################################
# DRAW_MENU_TITLE - Draw "SPACE PONG" title on menu screen
# Draws each letter pixel by pixel using block letter style
# Title is centered in upper portion of screen
########################################################################
draw_menu_title:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $a2, COLOR_MENU_TEXT  # Load green color for text
    
    # Draw 'S' at (x=10, y=20)
    li $a0, 10
    li $a1, 20
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 10
    li $a1, 21
    jal draw_pixel
    
    li $a0, 10
    li $a1, 22
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 12
    li $a1, 23
    jal draw_pixel
    
    li $a0, 10
    li $a1, 24
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    # Draw 'P' at (x=14, y=20)
    li $a0, 14
    li $a1, 20
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    
    li $a0, 15
    li $a1, 20
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 17
    li $a1, 21
    jal draw_pixel
    
    li $a0, 15
    li $a1, 22
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    # Draw 'A' at (x=19, y=20)
    li $a0, 19
    li $a1, 20
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 19
    li $a1, 21
    jal draw_pixel
    addi $a0, $a0, 2
    jal draw_pixel
    
    li $a0, 19
    li $a1, 22
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 19
    li $a1, 23
    jal draw_pixel
    addi $a0, $a0, 2
    jal draw_pixel
    
    li $a0, 19
    li $a1, 24
    jal draw_pixel
    addi $a0, $a0, 2
    jal draw_pixel
    
    # Draw 'C' at (x=23, y=20)
    li $a0, 23
    li $a1, 20
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 23
    li $a1, 21
    jal draw_pixel
    
    li $a0, 23
    li $a1, 22
    jal draw_pixel
    
    li $a0, 23
    li $a1, 23
    jal draw_pixel
    
    li $a0, 23
    li $a1, 24
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    # Draw 'E' at (x=27, y=20)
    li $a0, 27
    li $a1, 20
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 27
    li $a1, 21
    jal draw_pixel
    
    li $a0, 27
    li $a1, 22
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 27
    li $a1, 23
    jal draw_pixel
    
    li $a0, 27
    li $a1, 24
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    # Draw 'P' at (x=14, y=28)
    li $a0, 14
    li $a1, 28
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    
    li $a0, 15
    li $a1, 28
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 17
    li $a1, 29
    jal draw_pixel
    
    li $a0, 15
    li $a1, 30
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    # Draw 'O' at (x=19, y=28)
    li $a0, 19
    li $a1, 28
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 19
    li $a1, 29
    jal draw_pixel
    addi $a0, $a0, 2
    jal draw_pixel
    
    li $a0, 19
    li $a1, 30
    jal draw_pixel
    addi $a0, $a0, 2
    jal draw_pixel
    
    li $a0, 19
    li $a1, 31
    jal draw_pixel
    addi $a0, $a0, 2
    jal draw_pixel
    
    li $a0, 19
    li $a1, 32
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    # Draw 'N' at (x=23, y=28)
    li $a0, 23
    li $a1, 28
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    
    li $a0, 24
    li $a1, 29
    jal draw_pixel
    
    li $a0, 25
    li $a1, 30
    jal draw_pixel
    
    li $a0, 26
    li $a1, 28
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    
    # Draw 'G' at (x=28, y=28)
    li $a0, 28
    li $a1, 28
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 28
    li $a1, 29
    jal draw_pixel
    
    li $a0, 28
    li $a1, 30
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 28
    li $a1, 31
    jal draw_pixel
    addi $a0, $a0, 2
    jal draw_pixel
    
    li $a0, 28
    li $a1, 32
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

########################################################################
# DRAW_MENU_OPTIONS - Draw game mode selection options
# Displays "1-P1" (single player) and "2-P2" (two player) options
########################################################################
draw_menu_options:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $a2, COLOR_STAR1      # Use bright white for options
    
    # Draw "1" at (x=20, y=40) - First player indicator
    li $a0, 20
    li $a1, 40
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    
    li $a0, 19
    li $a1, 40
    jal draw_pixel
    
    li $a0, 19
    li $a1, 44
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    # Draw "-" at (x=23, y=42) - Separator
    li $a0, 23
    li $a1, 42
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    # Draw "P" at (x=27, y=40)
    li $a0, 27
    li $a1, 40
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    
    li $a0, 28
    li $a1, 40
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 30
    li $a1, 41
    jal draw_pixel
    
    li $a0, 28
    li $a1, 42
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    # Draw "1" at (x=32, y=40) - Player count
    li $a0, 32
    li $a1, 40
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    
    li $a0, 31
    li $a1, 40
    jal draw_pixel
    
    li $a0, 31
    li $a1, 44
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    # Draw "2" at (x=20, y=48) - Second option indicator
    li $a0, 20
    li $a1, 48
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 22
    li $a1, 49
    jal draw_pixel
    
    li $a0, 21
    li $a1, 50
    jal draw_pixel
    
    li $a0, 20
    li $a1, 51
    jal draw_pixel
    
    li $a0, 20
    li $a1, 52
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    # Draw "-" at (x=24, y=50) - Separator
    li $a0, 24
    li $a1, 50
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    # Draw "P" at (x=27, y=48)
    li $a0, 27
    li $a1, 48
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    
    li $a0, 28
    li $a1, 48
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 30
    li $a1, 49
    jal draw_pixel
    
    li $a0, 28
    li $a1, 50
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    # Draw "2" at (x=32, y=48) - Player count
    li $a0, 32
    li $a1, 48
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 34
    li $a1, 49
    jal draw_pixel
    
    li $a0, 33
    li $a1, 50
    jal draw_pixel
    
    li $a0, 32
    li $a1, 51
    jal draw_pixel
    
    li $a0, 32
    li $a1, 52
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

########################################################################
# INIT_GAME - Initialize/reset game state for a new game
# Resets scores to 0, centers paddles and ball, sets initial velocities
########################################################################
init_game:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Reset scores to zero
    sw $zero, score1
    sw $zero, score2
    sw $zero, ball_active    # Ball starts inactive (wait for player input)
    
    # Center both paddles vertically
    li $t0, 28
    sw $t0, paddle1_y
    sw $t0, paddle2_y
    
    # Center ball in middle of screen
    li $t0, 32
    sw $t0, ball_x
    sw $t0, ball_y
    
    # Set initial ball velocity (moving right and down)
    li $t0, 1
    sw $t0, ball_dx
    sw $t0, ball_dy
    
    jal clear_to_space       # Clear screen and prepare for game
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

########################################################################
# GAME_LOOP - Main game loop that runs until someone reaches 3 points
# Handles input, updates AI, moves ball, checks collisions, and renders
########################################################################
game_loop:
    # Check if either player has won (score >= 3)
    lw $t0, score1
    lw $t1, score2
    bge $t0, 3, game_over
    bge $t1, 3, game_over
    
    # Increment frame counter for timing purposes
    lw $t0, frame_count
    addi $t0, $t0, 1
    sw $t0, frame_count
    
    # Process keyboard input for paddle movement
    jal handle_input
    
    # Update AI paddle if in single player mode
    lw $t0, game_mode
    li $t1, 1
    bne $t0, $t1, skip_ai
    jal update_ai
    
skip_ai:
    # Update ball position if it's active (in play)
    lw $t0, ball_active
    beq $t0, $zero, skip_ball
    jal update_ball
    jal check_collisions
    
skip_ball:
    # Draw everything on screen
    jal render_frame
    
    # Pause for ~16ms (approximately 60 FPS)
    li $a0, 16
    li $v0, 32
    syscall
    
    j game_loop              # Continue looping

########################################################################
# GAME_OVER - Display winner and return to menu
# Shows which player won with "P1 WINS" or "P2 WINS" message
########################################################################
game_over:
    jal clear_to_space       # Clear screen
    jal draw_stars           # Draw starfield background
    jal draw_winner_text     # Display winner message
    
    # Wait 3 seconds before returning to menu
    li $a0, 3000
    li $v0, 32
    syscall
    
    # Reset game mode and return to main menu
    sw $zero, game_mode
    j show_menu

########################################################################
# UPDATE_AI - Control AI paddle movement (Player 2 in single player mode)
# AI tracks the ball's Y position and moves to intercept it
# Includes intentional imperfection: reaction zone and random mistakes
########################################################################
update_ai:
    # Throttle AI updates based on ai_speed 
    lw $t0, ai_counter
    addi $t0, $t0, 1
    sw $t0, ai_counter
    
    lw $t1, ai_speed
    blt $t0, $t1, ai_done    # Skip update if not enough frames passed
    
    sw $zero, ai_counter     # Reset counter
    
    # AI makes random mistakes to be more human-like
    li $v0, 42               # Random number syscall
    lw $a1, ai_error_chance
    syscall
    beq $a0, 0, ai_done      # 1 in 15 chance to skip this update (mistake)
    
    # Calculate ball and paddle positions
    lw $t2, ball_y           # Ball's Y position
    lw $t3, paddle2_y        # AI paddle's Y position
    lw $t4, PADDLE_HEIGHT
    
    # Calculate center of AI paddle
    srl $t5, $t4, 1          # Divide paddle height by 2
    add $t5, $t3, $t5        # Add to paddle Y to get center
    
    # Check if ball is within reaction zone 
    lw $t6, ai_reaction_zone
    sub $t7, $t2, $t5        # Distance from ball to paddle center
    abs $t7, $t7             # Absolute distance
    blt $t7, $t6, ai_done    # Don't move if already close enough
    
    # Move paddle toward ball
    bgt $t2, $t5, ai_move_down
    blt $t2, $t5, ai_move_up
    j ai_done

ai_move_up:
    lw $t0, paddle2_y
    addi $t0, $t0, -3        # Move up by 3 pixels
    blt $t0, 0, ai_done      # Don't move past top edge
    sw $t0, paddle2_y
    j ai_done

ai_move_down:
    lw $t0, paddle2_y
    lw $t2, PADDLE_HEIGHT
    addi $t0, $t0, 3         # Move down by 3 pixels
    add $t3, $t0, $t2        # Calculate bottom edge
    bgt $t3, 64, ai_done     # Don't move past bottom edge
    sw $t0, paddle2_y

ai_done:
    jr $ra

########################################################################
# HANDLE_INPUT - Process keyboard input for paddle movement and ball serve
# Controls: A/Z for player 1 (up/down), K/M for player 2 (up/down)
# First keypress after reset also serves the ball
########################################################################
handle_input:
    # Handle input cooldown to prevent input flooding
    lw $t8, input_cooldown
    beq $t8, $zero, check_input
    addi $t8, $t8, -1
    sw $t8, input_cooldown
    
    # Clear any buffered inputs during cooldown period
    lui $t0, 0xffff
clear_buffer_loop:
    lw $t1, 0($t0)
    andi $t1, $t1, 0x0001
    beq $t1, $zero, input_done
    lw $t2, 4($t0)           # Read and discard key
    j clear_buffer_loop
    
check_input:
    # Check if a key is pressed
    lui $t0, 0xffff          # Keyboard memory-mapped I/O address
    lw $t1, 0($t0)           # Read status register
    andi $t1, $t1, 0x0001    # Check ready bit
    beq $t1, $zero, input_done # No key pressed, exit
    
    lw $t2, 4($t0)           # Read the key value
    
    # Set cooldown to prevent multiple inputs per frame
    li $t8, 2
    sw $t8, input_cooldown
    
    # If ball is inactive, activate it on first input (serve)
    lw $t9, ball_active
    bne $t9, $zero, ball_already_active
    li $t9, 1
    sw $t9, ball_active
    
ball_already_active:
    # Check for player 1 controls (A=up, Z=down)
    li $t3, 97               # ASCII 'a'
    beq $t2, $t3, p1_up
    li $t3, 122              # ASCII 'z'
    beq $t2, $t3, p1_down
    
    # Check for player 2 controls in two-player mode (K=up, M=down)
    lw $t4, game_mode
    li $t5, 2
    bne $t4, $t5, input_done # Skip P2 input if not in 2-player mode
    
    li $t3, 107              # ASCII 'k'
    beq $t2, $t3, p2_up
    li $t3, 109              # ASCII 'm'
    beq $t2, $t3, p2_down
    j input_done

# Player 1 movement handlers
p1_up:
    lw $t0, paddle1_y
    addi $t0, $t0, -3        # Move up by 3 pixels
    blt $t0, 0, input_done   # Prevent moving above screen
    sw $t0, paddle1_y
    j input_done

p1_down:
    lw $t0, paddle1_y
    lw $t2, PADDLE_HEIGHT
    addi $t0, $t0, 3         # Move down by 3 pixels
    add $t3, $t0, $t2        # Calculate paddle bottom edge
    bgt $t3, 64, input_done  # Prevent moving below screen
    sw $t0, paddle1_y
    j input_done

# Player 2 movement handlers
p2_up:
    lw $t0, paddle2_y
    addi $t0, $t0, -3        # Move up by 3 pixels
    blt $t0, 0, input_done   # Prevent moving above screen
    sw $t0, paddle2_y
    j input_done

p2_down:
    lw $t0, paddle2_y
    lw $t2, PADDLE_HEIGHT
    addi $t0, $t0, 3         # Move down by 3 pixels
    add $t3, $t0, $t2        # Calculate paddle bottom edge
    bgt $t3, 64, input_done  # Prevent moving below screen
    sw $t0, paddle2_y
    j input_done

input_done:
    jr $ra

########################################################################
# UPDATE_BALL - Move ball based on velocity and speed control
# Uses ball_speed counter to control how fast ball moves
# Lower ball_speed = faster ball movement
########################################################################
update_ball:
    # Increment ball movement counter
    lw $t0, ball_counter
    addi $t0, $t0, 1
    sw $t0, ball_counter
    
    # Check if enough frames have passed to move ball
    lw $t1, ball_speed
    blt $t0, $t1, ball_no_move
    
    sw $zero, ball_counter   # Reset counter
    
    # Move ball horizontally by ball_dx (-1 or 1)
    lw $t0, ball_x
    lw $t1, ball_dx
    add $t0, $t0, $t1
    sw $t0, ball_x
    
    # Move ball vertically by ball_dy (-1 or 1)
    lw $t0, ball_y
    lw $t1, ball_dy
    add $t0, $t0, $t1
    sw $t0, ball_y
    
ball_no_move:
    jr $ra

########################################################################
# CHECK_COLLISIONS - Detect and handle ball collisions
# Checks for:
#   - Top/bottom wall bounces
#   - Left/right scoring (ball off screen)
#   - Paddle hits
########################################################################
check_collisions:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Check top wall collision
    lw $t0, ball_y
    blt $t0, 0, bounce_top
    
    # Check bottom wall collision
    lw $t2, BALL_SIZE
    add $t3, $t0, $t2        # Ball bottom edge
    bgt $t3, 64, bounce_bottom
    
    # Check left edge (player 2 scores)
    lw $t0, ball_x
    blt $t0, 0, score_p2
    
    # Check right edge (player 1 scores)
    add $t3, $t0, $t2        # Ball right edge
    bgt $t3, 64, score_p1
    
    # Check paddle collisions
    jal check_paddles
    j coll_done

# Bounce off top wall
bounce_top:
    lw $t0, ball_dy
    neg $t0, $t0             # Reverse Y direction
    sw $t0, ball_dy
    li $t0, 0                # Reset to edge
    sw $t0, ball_y
    j coll_done

# Bounce off bottom wall
bounce_bottom:
    lw $t0, ball_dy
    neg $t0, $t0             # Reverse Y direction
    sw $t0, ball_dy
    li $t0, 61               # Reset to edge
    sw $t0, ball_y
    j coll_done

# Player 1 scores (ball went past right edge)
score_p1:
    lw $t0, score1
    addi $t0, $t0, 1
    sw $t0, score1
    jal reset_ball
    j coll_done

# Player 2 scores (ball went past left edge)
score_p2:
    lw $t0, score2
    addi $t0, $t0, 1
    sw $t0, score2
    jal reset_ball
    j coll_done

coll_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

########################################################################
# CHECK_PADDLES - Check if ball collides with either paddle
# If collision detected, reverse ball's X direction and reposition ball
########################################################################
check_paddles:
    # Check left paddle (player 1)
    lw $t0, ball_x
    lw $t1, PADDLE_X1
    blt $t0, $t1, check_right # Ball too far left
    addi $t3, $t1, 4
    bgt $t0, $t3, check_right # Ball too far right
    
    # Ball is in paddle's X range, check Y range
    lw $t4, ball_y
    lw $t5, paddle1_y
    blt $t4, $t5, check_right # Ball above paddle
    
    lw $t6, PADDLE_HEIGHT
    add $t7, $t5, $t6        # Paddle bottom
    bgt $t4, $t7, check_right # Ball below paddle
    
    # Collision! Reverse ball direction and reposition
    lw $t0, ball_dx
    neg $t0, $t0
    sw $t0, ball_dx
    lw $t0, PADDLE_X1
    addi $t0, $t0, 5         # Move ball away from paddle
    sw $t0, ball_x

# Check right paddle (player 2 or AI)
check_right:
    lw $t0, ball_x
    lw $t1, PADDLE_X2
    blt $t0, $t1, paddle_done # Ball too far left
    addi $t3, $t1, 4
    bgt $t0, $t3, paddle_done # Ball too far right
    
    # Ball is in paddle's X range, check Y range
    lw $t4, ball_y
    lw $t5, paddle2_y
    blt $t4, $t5, paddle_done # Ball above paddle
    
    lw $t6, PADDLE_HEIGHT
    add $t7, $t5, $t6        # Paddle bottom
    bgt $t4, $t7, paddle_done # Ball below paddle
    
    # Collision! Reverse ball direction and reposition
    lw $t0, ball_dx
    neg $t0, $t0
    sw $t0, ball_dx
    lw $t0, PADDLE_X2
    addi $t0, $t0, -1        # Move ball away from paddle
    sw $t0, ball_x

paddle_done:
    jr $ra

########################################################################
# RESET_BALL - Reset ball to center after a score
# Deactivates ball (requires keypress to serve)
# Randomizes initial direction for fairness
########################################################################
reset_ball:
    # Center ball on screen
    li $t0, 32
    sw $t0, ball_x
    sw $t0, ball_y
    
    # Deactivate ball until next serve
    sw $zero, ball_active
    sw $zero, ball_counter
    
    # Randomize horizontal direction
    li $v0, 42               # Random syscall
    li $a1, 2                # Range 0-1
    syscall
    beq $a0, 0, ball_left
    li $t0, 1                # Move right
    sw $t0, ball_dx
    j ball_y_dir
ball_left:
    li $t0, -1               # Move left
    sw $t0, ball_dx

# Randomize vertical direction
ball_y_dir:
    li $v0, 42
    li $a1, 2
    syscall
    beq $a0, 0, ball_up
    li $t0, 1                # Move down
    sw $t0, ball_dy
    jr $ra
ball_up:
    li $t0, -1               # Move up
    sw $t0, ball_dy
    jr $ra

########################################################################
# RENDER_FRAME - Draw complete game screen
# Clears screen, draws stars, spaceships (paddles), asteroid (ball), 
# and scores at top of screen
########################################################################
render_frame:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    jal clear_to_space       # Clear screen to space background
    jal draw_stars           # Draw starfield
    
    # Draw left spaceship (player 1)
    lw $a0, PADDLE_X1
    lw $a1, paddle1_y
    li $a2, 1
    jal draw_spaceship_left
    
    # Draw right spaceship (player 2/AI)
    lw $a0, PADDLE_X2
    lw $a1, paddle2_y
    li $a2, 0
    jal draw_spaceship_right
    
    # Draw asteroid (ball)
    lw $a0, ball_x
    lw $a1, ball_y
    jal draw_asteroid
    
    # Draw score indicators at top
    jal draw_scores
    
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

########################################################################
# DRAW_WINNER_TEXT - Display "P1 WINS" or "P2 WINS" on game over screen
# Shows complete winner message centered on screen
########################################################################
draw_winner_text:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    lw $a2, COLOR_MENU_TEXT  # Green color for text
    
    # Check which player won
    lw $t0, score1
    lw $t1, score2
    bge $t0, 3, draw_p1_wins # Player 1 reached 3 first
    
    # Player 2 wins - draw "P2 WINS"
    # Draw 'P' at (x=15, y=24)
    li $a0, 15
    li $a1, 24
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    
    li $a0, 16
    li $a1, 24
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 18
    li $a1, 25
    jal draw_pixel
    
    li $a0, 16
    li $a1, 26
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    # Draw '2' at (x=20, y=24)
    li $a0, 20
    li $a1, 24
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 22
    li $a1, 25
    jal draw_pixel
    
    li $a0, 21
    li $a1, 26
    jal draw_pixel
    
    li $a0, 20
    li $a1, 27
    jal draw_pixel
    
    li $a0, 20
    li $a1, 28
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    # Draw 'W' at (x=25, y=24)
    li $a0, 25
    li $a1, 24
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    
    li $a0, 26
    li $a1, 28
    jal draw_pixel
    
    li $a0, 27
    li $a1, 27
    jal draw_pixel
    
    li $a0, 28
    li $a1, 28
    jal draw_pixel
    
    li $a0, 29
    li $a1, 24
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    
    # Draw 'I' at (x=31, y=24)
    li $a0, 31
    li $a1, 24
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 32
    li $a1, 25
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    
    li $a0, 31
    li $a1, 28
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    # Draw 'N' at (x=35, y=24)
    li $a0, 35
    li $a1, 24
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    
    li $a0, 36
    li $a1, 25
    jal draw_pixel
    
    li $a0, 37
    li $a1, 26
    jal draw_pixel
    
    li $a0, 38
    li $a1, 24
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    
    # Draw 'S' at (x=40, y=24)
    li $a0, 40
    li $a1, 24
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 40
    li $a1, 25
    jal draw_pixel
    
    li $a0, 40
    li $a1, 26
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 42
    li $a1, 27
    jal draw_pixel
    
    li $a0, 40
    li $a1, 28
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    j winner_text_done
    
# Player 1 wins - draw "P1 WINS"
draw_p1_wins:
    # Draw 'P' at (x=15, y=24)
    li $a0, 15
    li $a1, 24
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    
    li $a0, 16
    li $a1, 24
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 18
    li $a1, 25
    jal draw_pixel
    
    li $a0, 16
    li $a1, 26
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    # Draw '1' at (x=20, y=24)
    li $a0, 20
    li $a1, 24
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    
    li $a0, 19
    li $a1, 24
    jal draw_pixel
    
    li $a0, 19
    li $a1, 28
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    # Draw 'W' at (x=25, y=24)
    li $a0, 25
    li $a1, 24
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    
    li $a0, 26
    li $a1, 28
    jal draw_pixel
    
    li $a0, 27
    li $a1, 27
    jal draw_pixel
    
    li $a0, 28
    li $a1, 28
    jal draw_pixel
    
    li $a0, 29
    li $a1, 24
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    
    # Draw 'I' at (x=31, y=24)
    li $a0, 31
    li $a1, 24
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 32
    li $a1, 25
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    
    li $a0, 31
    li $a1, 28
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    # Draw 'N' at (x=35, y=24)
    li $a0, 35
    li $a1, 24
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    
    li $a0, 36
    li $a1, 25
    jal draw_pixel
    
    li $a0, 37
    li $a1, 26
    jal draw_pixel
    
    li $a0, 38
    li $a1, 24
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    addi $a1, $a1, 1
    jal draw_pixel
    
    # Draw 'S' at (x=40, y=24)
    li $a0, 40
    li $a1, 24
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 40
    li $a1, 25
    jal draw_pixel
    
    li $a0, 40
    li $a1, 26
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
    li $a0, 42
    li $a1, 27
    jal draw_pixel
    
    li $a0, 40
    li $a1, 28
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    addi $a0, $a0, 1
    jal draw_pixel
    
winner_text_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra

########################################################################
# CLEAR_TO_SPACE - Fill entire screen with space background color
# Overwrites all 4096 pixels (64x64) with dark blue space color
########################################################################
clear_to_space:
    lw $t0, COLOR_SPACE      # Load space background color
    li $t1, 4096             # Total pixels (64 * 64)
    move $t2, $gp            # Start at display memory base

clear_space_loop:
    beq $t1, $zero, clear_space_done
    sw $t0, 0($t2)           # Write color to current pixel
    addi $t2, $t2, 4         # Move to next pixel (4 bytes per pixel)
    addi $t1, $t1, -1        # Decrement counter
    j clear_space_loop

clear_space_done:
    jr $ra

########################################################################
# DRAW_STARS - Draw starfield background
# Draws 20 stars at predefined positions with varying brightness levels
# Creates depth illusion with different star colors
########################################################################
draw_stars:
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    
    li $s0, 0                # Star index counter
    li $s1, 20               # Total number of stars

star_loop:
    bge $s0, $s1, stars_done
    
    # Load star X coordinate from array
    la $t0, star_x
    sll $t1, $s0, 2          # Index * 4 (word size)
    add $t0, $t0, $t1
    lw $a0, 0($t0)           # X position
    
    # Load star Y coordinate from array
    la $t0, star_y
    add $t0, $t0, $t1
    lw $a1, 0($t0)           # Y position
    
    # Load star type (determines brightness)
    la $t0, star_type
    add $t0, $t0, $t1
    lw $t2, 0($t0)
    
    # Select color based on star type
    beq $t2, 0, star_bright
    beq $t2, 1, star_medium
    lw $a2, COLOR_STAR3      # Type 2: Dim star
    j draw_this_star
star_bright:
    lw $a2, COLOR_STAR1      # Type 0: Bright star
    j draw_this_star
star_medium:
    lw $a2, COLOR_STAR2      # Type 1: Medium star

draw_this_star:
    jal draw_pixel
    
    addi $s0, $s0, 1         # Move to next star
    j star_loop

stars_done:
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    addi $sp, $sp, 12
    jr $ra

########################################################################
# DRAW_SPACESHIP_LEFT - Draw player 1's blue spaceship facing right
# Input: $a0 = x position, $a1 = y position
# Draws a detailed pixel-art spaceship with body, wings, engine, window
########################################################################
draw_spaceship_left:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    
    move $s0, $a0            # Save base X position
    move $s1, $a1            # Save base Y position
    
    # Draw engine glow (left side)
    move $a0, $s0
    addi $a1, $s1, 1
    lw $a2, COLOR_SHIP1_ENGINE
    jal draw_pixel
    
    move $a0, $s0
    addi $a1, $s1, 2
    lw $a2, COLOR_SHIP1_ENGINE
    jal draw_pixel
    
    move $a0, $s0
    addi $a1, $s1, 4
    lw $a2, COLOR_SHIP1_ENGINE
    jal draw_pixel
    
    # Draw wing and body column (middle-left)
    addi $a0, $s0, 1
    move $a1, $s1
    lw $a2, COLOR_SHIP1_WING
    jal draw_pixel
    
    addi $a0, $s0, 1
    addi $a1, $s1, 1
    lw $a2, COLOR_SHIP1_BODY
    jal draw_pixel
    
    addi $a0, $s0, 1
    addi $a1, $s1, 2
    lw $a2, COLOR_SHIP1_BODY
    jal draw_pixel
    
    addi $a0, $s0, 1
    addi $a1, $s1, 3
    lw $a2, COLOR_SHIP1_BODY
    jal draw_pixel
    
    addi $a0, $s0, 1
    addi $a1, $s1, 4
    lw $a2, COLOR_SHIP1_BODY
    jal draw_pixel
    
    addi $a0, $s0, 1
    addi $a1, $s1, 5
    lw $a2, COLOR_SHIP1_WING
    jal draw_pixel
    
    # Draw body with window (middle-right)
    addi $a0, $s0, 2
    addi $a1, $s1, 1
    lw $a2, COLOR_SHIP1_BODY
    jal draw_pixel
    
    addi $a0, $s0, 2
    addi $a1, $s1, 2
    lw $a2, COLOR_SHIP1_WINDOW   # Cockpit window
    jal draw_pixel
    
    addi $a0, $s0, 2
    addi $a1, $s1, 3
    lw $a2, COLOR_SHIP1_BODY
    jal draw_pixel
    
    addi $a0, $s0, 2
    addi $a1, $s1, 4
    lw $a2, COLOR_SHIP1_BODY
    jal draw_pixel
    
    # Draw nose (right side)
    addi $a0, $s0, 3
    addi $a1, $s1, 2
    lw $a2, COLOR_SHIP1_BODY
    jal draw_pixel
    
    addi $a0, $s0, 3
    addi $a1, $s1, 3
    lw $a2, COLOR_SHIP1_BODY
    jal draw_pixel
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra

########################################################################
# DRAW_SPACESHIP_RIGHT - Draw player 2's red/orange spaceship facing left
# Input: $a0 = x position, $a1 = y position
# Mirror image of left spaceship with different color scheme
########################################################################
draw_spaceship_right:
    addi $sp, $sp, -16
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    sw $s2, 12($sp)
    
    move $s0, $a0            # Save base X position
    move $s1, $a1            # Save base Y position
    
    # Draw nose (left side)
    move $a0, $s0
    addi $a1, $s1, 2
    lw $a2, COLOR_SHIP2_BODY
    jal draw_pixel
    
    move $a0, $s0
    addi $a1, $s1, 3
    lw $a2, COLOR_SHIP2_BODY
    jal draw_pixel
    
    # Draw body with window (middle-left)
    addi $a0, $s0, 1
    addi $a1, $s1, 1
    lw $a2, COLOR_SHIP2_BODY
    jal draw_pixel
    
    addi $a0, $s0, 1
    addi $a1, $s1, 2
    lw $a2, COLOR_SHIP2_WINDOW   # Cockpit window
    jal draw_pixel
    
    addi $a0, $s0, 1
    addi $a1, $s1, 3
    lw $a2, COLOR_SHIP2_BODY
    jal draw_pixel
    
    addi $a0, $s0, 1
    addi $a1, $s1, 4
    lw $a2, COLOR_SHIP2_BODY
    jal draw_pixel
    
    # Draw wing and body column (middle-right)
    addi $a0, $s0, 2
    move $a1, $s1
    lw $a2, COLOR_SHIP2_WING
    jal draw_pixel
    
    addi $a0, $s0, 2
    addi $a1, $s1, 1
    lw $a2, COLOR_SHIP2_BODY
    jal draw_pixel
    
    addi $a0, $s0, 2
    addi $a1, $s1, 2
    lw $a2, COLOR_SHIP2_BODY
    jal draw_pixel
    
    addi $a0, $s0, 2
    addi $a1, $s1, 3
    lw $a2, COLOR_SHIP2_BODY
    jal draw_pixel
    
    addi $a0, $s0, 2
    addi $a1, $s1, 4
    lw $a2, COLOR_SHIP2_BODY
    jal draw_pixel
    
    addi $a0, $s0, 2
    addi $a1, $s1, 5
    lw $a2, COLOR_SHIP2_WING
    jal draw_pixel
    
    # Draw engine glow (right side)
    addi $a0, $s0, 3
    addi $a1, $s1, 1
    lw $a2, COLOR_SHIP2_ENGINE
    jal draw_pixel
    
    addi $a0, $s0, 3
    addi $a1, $s1, 2
    lw $a2, COLOR_SHIP2_ENGINE
    jal draw_pixel
    
    addi $a0, $s0, 3
    addi $a1, $s1, 4
    lw $a2, COLOR_SHIP2_ENGINE
    jal draw_pixel
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    lw $s2, 12($sp)
    addi $sp, $sp, 16
    jr $ra

########################################################################
# DRAW_ASTEROID - Draw the ball as a textured asteroid
# Input: $a0 = x position, $a1 = y position
# Draws a 3x3 pixel asteroid with multiple brown shades for texture
########################################################################
draw_asteroid:
    addi $sp, $sp, -12
    sw $ra, 0($sp)
    sw $s0, 4($sp)
    sw $s1, 8($sp)
    
    move $s0, $a0            # Save base X position
    move $s1, $a1            # Save base Y position
    
    # Top row of asteroid
    addi $a0, $s0, 1
    move $a1, $s1
    lw $a2, COLOR_ASTEROID2
    jal draw_pixel
    
    # Middle row (3 pixels wide)
    move $a0, $s0
    addi $a1, $s1, 1
    lw $a2, COLOR_ASTEROID1
    jal draw_pixel
    
    addi $a0, $s0, 1
    addi $a1, $s1, 1
    lw $a2, COLOR_ASTEROID3
    jal draw_pixel
    
    addi $a0, $s0, 2
    addi $a1, $s1, 1
    lw $a2, COLOR_ASTEROID2
    jal draw_pixel
    
    # Bottom row (3 pixels wide)
    move $a0, $s0
    addi $a1, $s1, 2
    lw $a2, COLOR_ASTEROID2
    jal draw_pixel
    
    addi $a0, $s0, 1
    addi $a1, $s1, 2
    lw $a2, COLOR_ASTEROID1
    jal draw_pixel
    
    addi $a0, $s0, 2
    addi $a1, $s1, 2
    lw $a2, COLOR_ASTEROID3
    jal draw_pixel
    
    lw $ra, 0($sp)
    lw $s0, 4($sp)
    lw $s1, 8($sp)
    addi $sp, $sp, 12
    jr $ra

########################################################################
# DRAW_PIXEL - Draw a single pixel at specified coordinates
# Input: $a0 = x coordinate (0-63)
#        $a1 = y coordinate (0-63)
#        $a2 = color value (32-bit RGB)
# Converts 2D coordinates to display memory address and writes color
########################################################################
draw_pixel:
    sll $t0, $a1, 6          # Multiply Y by 64 (screen width)
    add $t0, $t0, $a0        # Add X coordinate
    sll $t0, $t0, 2          # Multiply by 4 (bytes per pixel)
    add $t0, $gp, $t0        # Add display base address
    sw $a2, 0($t0)           # Write color to calculated address
    jr $ra

########################################################################
# DRAW_SCORES - Draw score indicators at top of screen
# Displays asteroids at the top to represent each player's score
# Left side = player 1 score, right side = player 2 score
########################################################################
draw_scores:
    addi $sp, $sp, -4
    sw $ra, 0($sp)
    
    # Draw player 1 score (left side)
    lw $t3, score1           # Load current score
    li $t4, 5                # Starting X position
    li $t5, 2                # Y position

score1_loop:
    beq $t3, 0, score2_start # Done when counter reaches 0
    
    move $a0, $t4
    move $a1, $t5
    jal draw_asteroid        # Draw one asteroid per point
    
    addi $t4, $t4, 4         # Space asteroids 4 pixels apart
    addi $t3, $t3, -1        # Decrement counter
    j score1_loop

# Draw player 2 score (right side)
score2_start:
    lw $t3, score2           # Load current score
    li $t4, 52               # Starting X position (right side)
    li $t5, 2                # Y position

score2_loop:
    beq $t3, 0, scores_done  # Done when counter reaches 0
    
    move $a0, $t4
    move $a1, $t5
    jal draw_asteroid        # Draw one asteroid per point
    
    addi $t4, $t4, 4         # Space asteroids 4 pixels apart
    addi $t3, $t3, -1        # Decrement counter
    j score2_loop

scores_done:
    lw $ra, 0($sp)
    addi $sp, $sp, 4
    jr $ra