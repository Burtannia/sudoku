# Sudoku Solver

Presents 3 different methods for solving Sudoku.

## Brute Force
The first is a simple brute force method which filters valid solutions from a list of all possible grids for a given puzzle. Fair to say this is useless. It fails to terminate even on a simple puzzle.

## Recursive Filter
The second represents the puzzle as a list of choices for each square and then removes invalid choices i.e. those that already appear as solved spaces in the same row, column or sub-grid. Filtering often produces more solved spaces and as such more invalid choices that can be removed from other spaces. Filtering is performed recursively until it no longer changes the grid i.e. a fix point is found. For simple puzzles this produces a correct solution instantly however, more complex puzzles cannot be solved in this manner because they have fix points which still contain multiple possibilites. For these more complex puzzles the solver still terminates instantly but the resulting grid is still unsolved.

## Advanced Filter
This is quite similar to the previous solver with one small change. If filtering produces a fix point which is not a solution, then we simply expand the first space with multiple choices and then map the solver over the resulting grids. This solver now terminates instantly, even on the "World's Hardest Sudoku Puzzle"!

## Interesting Issue
As mentioned previously, the Advanced Filter solver expands the first space with multiple choices. My initial idea was to instead expand the space with the smallest number of choices in the grid. Unfortunately this caused the solver to run for a good few seconds before I gave up and killed the process. I remembered that one of the first lectures in a second year Haskell module I took at university had been making a sudoku solver so I had a look to see what I might have done wrong. Ironically at the bottom of the lecture notes there is a paragraph which reads:

"Exercise: modify the expand function to collapse a square with the smallest number of choices greater than one, and see what effect this change has on the performance of the solver."

I don't recall ever doing that particular exercise however, years later, I can answer that the effect on performance it has is "suboptimal".

Nevertheless after changing that one part of my solver it was able to produce solutions instantly. Of course credit goes to Prof. Graham Hutton for the solver he showed us in that lecture which gave me the final piece of the puzzle!

The question is, why is it so much less efficient to expand the space with the fewest choices versus the first space with multiple choices? My guess is that it has something to do with how much information can be gained from solving a certain square. If we consider a space with very few choices then we have in fact already gained most of the information available from that space. On the other hand, a space with 7 possible choices still contains a huge amount of information. It may turn out to be the case that expanding a space with very few choices doesn't actually bring the solver much closer to a solution and that what ensues is the repeated expansion of many spaces with few choices thus generating a very large number of potential grids to explore. Mathematically this makes some sense because if we solve a space with two choices we have halved the search space. Instead if we solve a space which still had all 9 choices then we have decreased the search space by a factor of 9! 
