# Advanced Evolution Settings Explained

This guide explains the advanced settings in the Evolution Chamber. Understanding these settings will allow you to fine-tune the algorithm to discover new and interesting patterns more effectively.

---

## Fitness Function: Defining a "Good" Pattern

The fitness function is how the algorithm scores each pattern. By default, it only cares about the distance a pattern travels. These settings allow you to define what "good" means in a more sophisticated way.

### Use Mass Conservation

-   **What it does:** This setting penalizes patterns that lose cells during their journey. A pattern that ends with fewer cells than it started with will have its score reduced.
-   **Why use it:** It strongly encourages the evolution of robust, self-sustaining spaceships that don't fall apart or shed pieces as they move. This is key to finding high-quality, stable patterns.

### Use Purity Check

-   **What it does:** This setting gives a massive score bonus to patterns that are "pure" spaceships—patterns that return to their exact starting shape after a certain number of generations.
-   **Why use it:** This is the best way to specifically hunt for true, stable spaceships. It tells the algorithm to prioritize patterns that are not just travelers, but perfect, repeating travelers.

### Use Size Incentive

-   **What it does:** This setting gives a small score bonus to patterns based on the number of cells they contain. A larger pattern will get a slightly higher score than a smaller one that travels the same distance.
-   **Why use it:** If your goal is to find large, complex spaceships, this setting provides a gentle nudge in that direction. It encourages the algorithm to explore bigger patterns instead of just settling on the smallest, most efficient ones.

---

## Crossover Strategy: How Patterns Breed

Crossover, or breeding, is how the algorithm combines the traits of two successful parent patterns to create a new child pattern.

### Random Mix

-   **What it does:** This strategy creates a child by taking the two parent patterns and randomly mixing their cells. For every cell that is unique to one parent, there's a 50/50 chance the child will inherit it.
-   **Why use it:** It's very fast, but not very smart. It often creates non-functional patterns, but its chaotic nature can sometimes lead to unexpected and creative results. Think of it as a low-quality, high-speed breeding program.

### Simulated Collision

-   **What it does:** This is a more organic approach. It places the two parent patterns near each other on a temporary grid and lets them interact for a few generations. The stable pattern that emerges from this collision becomes the child.
-   **Why use it:** This is a much more intelligent way to breed. It uses the game's own physics to create new patterns. The children it produces are much more likely to be stable and functional. This is the recommended strategy for finding high-quality patterns.

---

## Mutation Strategy: How Patterns Change

Mutation is how the algorithm introduces brand new, random ideas into the gene pool. It's essential for creativity and for preventing the evolution from getting stuck.

### Random Box

-   **What it does:** This strategy draws a box around a pattern and randomly flips cells on or off anywhere inside that box. 
-   **Why use it:** This is a high-risk, high-reward strategy. It's very likely to break a working pattern, but it can also make big, creative leaps that might lead to a completely new type of solution. It's useful for when the evolution seems to have stalled completely.

### Growth

-   **What it does:** This is a more conservative and careful strategy. It only makes random changes to cells that are directly touching an existing live cell. It focuses on "growing" or "trimming" the edges of a pattern.
-   **Why use it:** This is the best default strategy. It's much less likely to destroy a good pattern, making it very efficient at refining and improving upon existing solutions. It encourages steady, incremental progress.

---

## Population Size: The Number of Organisms

-   **What it does:** This setting controls how many different patterns (organisms) are simulated and evolved in parallel during each generation of the evolutionary process.
-   **Why use it:** A larger population introduces more genetic diversity, allowing the algorithm to explore a wider range of solutions and potentially avoid getting stuck in local optima. However, a larger population also means each evolutionary generation takes longer to compute. A smaller population is faster but might limit the algorithm's ability to find diverse or complex solutions.

---

## Max Cell Count: Preventing Runaway Growth

-   **What it does:** This sets an upper limit on the number of live cells any single pattern can have during its test run. If a pattern exceeds this count, it is immediately disqualified and given a score of zero.
-   **Why use it:** This is a crucial safety mechanism. Some random mutations can cause patterns to explode into a massive, chaotic number of cells, which can severely slow down or even freeze the simulation. By setting a reasonable cap, you prevent the algorithm from wasting time and computational power on these unproductive, runaway patterns. It helps focus the evolution on finding efficient and manageable patterns.
