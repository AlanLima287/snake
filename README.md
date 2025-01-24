# Snake game in x86 Assembly

@Alan Barbosa Lima [AlanLima287](https://github.com/AlanLima287)

## Summary

This is a small project that features the classic snake game, it was developed in x86 Assembly, using the [Netwide Assembler (NASM)](https://www.nasm.org) to assemble the assembly code to a raw binary format.

## Defining the field

The main logic of the aplication will operate upon an array that represents the entire field whereas the snake can walk (or rather crawls). An important transformation that will be required is the transformation from actual coordinates (on the screen) to an index in the array. Given that the field is a rectangle with integer coordinates comprehended by the pairs $`[a, b] \times [c, d]`$, with $`a \le b`$ and $`c \le d`$, follows, for $`(y, x) \in [a, b] \times [c, d]`$:

```math
(y, x) \longmapsto (y - a) (d - c + 1) + (x - c)
```

The rather strange way of positioning the ordered pair ($`(y, x)`$ instead of $`(x, y)`$) is justified by the move cursor interrupt ([`int 10h, 2`](https://en.wikipedia.org/wiki/INT_10H#List_of_supported_functions)) is designed, amongst other things, the `dx` is used to pass the coordinate to move the cursor into its 8bit sub-registers, `dh` stores the row and `dl` stores the column, this way, since `dx` = `dh:dl`, it make sense for the ordered pair to be (y, x).

Now, about things that really matter, the mapping is a classical 2 by 2 matrix access, with that in mind, $`y - a`$ puts the row starting at zero, $`d - c + 1`$ is the row length and $`x - c`$ also puts the column starting at zero.

Since the default character grid in a x86 bootloader is $`25`$ ($`19_{16}`$) by $`80`$ ($`50_{16}`$), with $`(0, 0)`$, being a valid coordinate (the top left corner), we'll will use a field $`[1_{16}, 17_{16}] \times [1_{16}, 4\text{E}_{16}]`$ leaving a one character border.

## Defining the snake

The snake is defined by two important parts, its _head_ and its _tail_. The head will be the part of the snake that can collide with either the fruit (making the snake grow) or the body of the snake (triggering game over). The tail exists more for rendering porpose, this will be elaborated later.

```asm
.loop:
   mov al, 12
```

[...] WIP