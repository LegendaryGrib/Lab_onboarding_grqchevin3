# Разбор кода

Код складывает числа от 1 до 10. Сумма равна 55.
Первая ячейка хранит сумму, вторая счётчик. Цикл повторяется,
пока счётчик не станет больше 10.

```python
def sum_one_to_ten():
    total = 0
    counter = 1

    while counter <= 10:
        total += counter
        counter += 1

    return total
```
