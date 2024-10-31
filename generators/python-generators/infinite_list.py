def infinite_list():
    """Generate an infinite list of numbers starting from 0."""
    n = 0
    while n < 100:
        yield n
        n += 10

all_numbers = infinite_list()
for i in all_numbers:
    print(i) # Prints the first 10 numbers: 0, 1, 2, ..., 9