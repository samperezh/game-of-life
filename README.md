# Game of Life

This is an implementation of Conway's retro [Game of Life](https://en.wikipedia.org/wiki/Conway%27s_Game_of_Life) done for the purpose of McGill's Computer Organization course (ECSE 324). 

This project was done in ARM assembly. 
- To allow the user to move the cursor around the grid, I used polling to check if the user was pressing one of the WASD keys.
- To allow the user to update the grid, I used polling to check for a keypress on n. When n is pressed, it'll iterate across all grid locations in the playing field, and update their state based on the state of their 8 neighboring cells according to the game's rules.
- To allow the user to toggle the state of the grid location where the cursor is located, I used polling to check if the user was pressing the space bar.

Tools used:
- ARM Assembly
- emulator
