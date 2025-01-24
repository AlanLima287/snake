# Snake game in x86 Assembly

@Alan Barbosa Lima [AlanLima287](https://github.com/AlanLima287)

## Summary

This is a small project that features the classic snake game, it was developed in x86 Assembly, using the [Netwide Assembler (NASM)](https://www.nasm.org) to assemble the assembly code to a raw binary format.

## Requirements

To assemble, the [Netwide Assembler (NASM)](https://www.nasm.org) has already been mentioned, to run the generated binary, [QEMU](https://www.qemu.org/) is recommended, more specifically the x86_64 system emulator.

## Defining the field

The main logic of the application will operate upon an array that represents the entire field whereas the snake can walk (or rather crawls). An important transformation that will be required is the transformation from actual coordinates (on the screen) to an index in the array. Given that the field is a rectangle with integer coordinates comprehended by the pairs $`[a, b] \times [c, d]`$, with $`a \le b`$ and $`c \le d`$, follows, for $`(y, x) \in [a, b] \times [c, d]`$:

```math
(y, x) \longmapsto (y - a) (d - c + 1) + (x - c)
```

The rather strange way of positioning the ordered pair ($`(y, x)`$ instead of $`(x, y)`$) is justified by the move cursor interrupt ([`int 10h, 2`](https://en.wikipedia.org/wiki/INT_10H#List_of_supported_functions)) is designed, amongst other things, the `dx` is used to pass the coordinate to move the cursor into its 8bit sub-registers, `dh` stores the row and `dl` stores the column, this way, since `dx` = `dh:dl`, it make sense for the ordered pair to be (y, x).

Now, about things that really matter, the mapping is a classical 2 by 2 matrix access, with that in mind, $`y - a`$ puts the row starting at zero, $`d - c + 1`$ is the row length and $`x - c`$ also puts the column starting at zero.

Since the default character grid in a x86 bootloader is $`25`$ ($`19_{16}`$) by $`80`$ ($`50_{16}`$), with $`(0, 0)`$, being a valid coordinate (the top left corner), we'll will use a field $`[1_{16}, 17_{16}] \times [1_{16}, 4\text{E}_{16}]`$ leaving a one character border.

## Defining the snake

The snake is defined by two important parts, its _head_ and its _tail_. The head will be the part of the snake that can collide with either the fruit (making the snake grow) or the body of the snake (triggering game over). The tail exists more for rendering purpose, this will be elaborated later.

### The body of the snake

The body of the snake will be in the array and will account for directionality, that is, the direction the head has moved to will be marked as that direction, the head itself won't have a direction associated with it. The directionality will serve for the tail so it knows where to move after filling the tail, where it was, with zero. Considering the head as `o` and the tail the not ingoing arrow, the following is a valid snake:

|   |   |   |   |   |   |
| - | - | - | - | - | - |
| . | . | . | . | . | . |
| ↓ | . | . | . | → | o |
| ↓ | . | . | . | ↑ | . |
| → | → | ↓ | . | ↑ | . |
| . | . | → | → | ↑ | . |

Moving the snake is simply erasing the tail, following the tail arrow and moving the head according to user input.

## Fruits

Fruits are very simple, they are just a different value put in the array, the head will every frame check whether it is over a fruit, if so, the tail doesn't get erased that frame (and a new fruit is place somewhere else randomly), and the head moves normally. Not erasing the tail effectively makes the snake grow.

<!-- [...] WIP -->