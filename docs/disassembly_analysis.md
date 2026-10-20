# Disassembly Analysis

The first stack slot (`-4(%rbp)`) is initialized as an accumulator with zero.
The second (`-8(%rbp)`) is initialized as a counter with one. The unconditional
`jmp .L2` enters the condition check before the loop body. The comparison and
`jle .L3` repeat the body while the counter is less than or equal to 10.

The body adds the counter to the accumulator and increments the counter. After
the counter becomes 11, execution leaves the loop and places the accumulated
sum in `%eax`. The function therefore calculates the sum of integers 1 through
10, which is 55.

```python
def sum_one_to_ten():
    total = 0
    counter = 1

    while counter <= 10:
        total += counter
        counter += 1

    return total
```
