1. Requirements

To run SPACE PONG, you need:

MARS 4.5 or later

Bitmap Display Tool

Keyboard MMIO Simulator

Java Runtime (for MARS)

2. Folder Structure
SpacePong_Code/
    pong.asm

3. How to Run the Game
Step 1 — Open MARS

Run mars.jar normally.

Step 2 — Load the Program

File → Open

Select pong.asm

Step 3 — Configure Bitmap Display

In MARS:

Tools → Bitmap Display

Set:

Setting	Value
Unit Width in Pixels	8
Unit Height in Pixels	8
Display Width	512
Display Height	512
Base Address	0x10008000 ($gp)	

Click Connect to MIPS.

Step 4 — Configure Keyboard

Tools → Keyboard and Display MMIO Simulator

Click Connect to MIPS.

Step 5 — Assemble & Run

Press F3 to assemble

Press F5 to run

The SPACE PONG menu appears

4. Controls
Menu

Press 1 → Single Player (vs AI)

Press 2 → Two Player

Gameplay

Player 1:

A = Move up

Z = Move down

Player 2 (two-player mode only):

K = Move up

M = Move down

First key press serves the ball.

5. Testing Instructions
A. Menu Testing

Ensure “SPACE PONG” title appears

Ensure options “1-P1” and “2-P2” appear

Pressing other keys does nothing

Pressing 1 or 2 starts game

B. Paddle Movement Testing

Press A/Z → P1 moves

Press K/M → P2 moves (two-player only)

Verify paddles do NOT move off screen

C. Ball Physics Testing

Ball bounces off walls

Ball bounces off paddles

Ball resets after scoring

D. AI Testing

In single-player mode:

AI follows ball

AI makes random “mistakes”

AI throttles based on frame counter

E. Win Condition Testing

First player to 3 wins

“P1 WINS” or “P2 WINS” text appears

After 3 seconds → return to menu

6. Code Comments

The code includes comments describing:

Purpose of each function

Parameter usage

Register usage

Drawing logic

Game physics logic
