# MIPS32 Image Pattern Recognition (SAD Algorithm)

A high-performance pattern recognition tool written completely in MIPS Assembly. It performs Template Matching on raw grayscale images by calculating the Sum of Absolute Differences (SAD) across every pixel coordinate.

## Showcase
![Original 512x256 Image](pxlcon512x256cropgs.png)
![Search Template 8x8](template8x8gs.png)
*(Run the program in MARS and replace this placeholder with a screenshot of the green box highlight!)*
![Matched Result Screenshot](placeholder_result.png)

## Algorithm Details

This repository includes two variations of the algorithm in a single file to demonstrate low-level architectural efficiency:
1. `matchTemplate`: A standard, nested looped approach (template-y, template-x, image-y, image-x) for clear, readable iteration logic.
2. **`matchTemplateFast`**: A highly optimized routine incorporating loop unrolling and memory access reordering. It reorganizes loops to minimize cache miss penalties, limits branching overhead, and actively caches an entire row of template pixels inside processor registers ($t0 to $t7) before iterating across image columns, maximizing Instruction-Level Parallelism.

## Performance Benchmarks
By optimizing memory access patterns and unrolling loops, `matchTemplateFast` achieves a massive reduction in latency and cache misses over the standard approach. As measured in MARS profiling (512x16 image run, 8x8 template):

| Algorithm | Cache Architecture | Instruction Count | Memory Access | Cache Misses | Time (µs) |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Naive** | Fully Associative | 7,866,991 | 1,181,737 | 181,762 | 26,043 |
| **Naive** | 2-Way Set Assoc. | 7,866,991 | 1,181,737 | 268,315 | 34,698 |
| **Naive** | Direct Mapped | 7,866,991 | 1,181,737 | 466,189 | 54,485 |
| | | | | | |
| **Fast** | Fully Associative | 1,994,847 | 368,539 | 19,638 | 3,958 |
| **Fast** | 2-Way Set Assoc. | 1,994,847 | 368,539 | 19,638 | 3,958 |
| **Fast** | Direct Mapped | 1,994,847 | 368,539 | 92,288 | 11,223 |

The optimized algorithm executes nearly **75% fewer instructions**, requires **68% fewer memory accesses**, and runs up to **6.5x faster**!

## How to Run
This program was built and tested for the MARS MIPS Simulator (`pMARS.jar`).
You will need `.raw` grayscale image files defined in the `.data` section to act as the Image Buffer and Template Buffer.

1. Launch MARS (e.g. `java -jar pMARS.jar`).
2. Open `templatematch.asm`.
3. Go to **Tools &#8594; Bitmap Display**.
4. Configure the Bitmap Display to match the memory layout:
   - **Unit Width/Height in Pixels**: 1
   - **Display Width in Pixels**: 512
   - **Display Height in Pixels**: 16 (or 256 depending on the defined buffer)
   - **Base Address for Display**: Ensure it matches the location of `displayBuffer`, which inherently maps to `0x10010000 (global data)` in MIPS/MARS.
5. Click **Connect to MIPS**.
6. Assemble and Run the file. 

### How to Switch Algorithms
The `main` driver is currently configured to execute the optimized version. To see the speed difference and run the naive version instead:
1. Open `templatematch.asm`.
2. Find the instruction `jal matchTemplateFast` (around line 26).
3. Change it to `jal matchTemplate`.
4. Assemble and Run again to observe the difference in MIPS instruction cycles!

The screen will display the image reading process, perform the search simulation, and visually block out the best match found. A heat-mapped representation of the algorithm's confidence errors (`errorBuffer`) is computed as a visual debugging step via `processError`.
