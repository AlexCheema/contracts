import random

# Function to calculate the sum of squares of digits
def sum_of_squares(n):
    sum_val = 0
    while n > 0:
        digit = n % 10
        sum_val += digit * digit
        n //= 10
    return sum_val

# Function to check if a number is a happy number
def is_happy_number(n):
    slow = n
    fast = n
    while True:
        slow = sum_of_squares(slow)
        fast = sum_of_squares(sum_of_squares(fast))
        if slow == fast:
            break
    return slow == 1


def count_happy_numbers(a, b):
   count = 0
   for i in range(a, b+1):
      if is_happy_number(i):
            count += 1
   return count

for i in range(10): # generate 10 random ranges
   a = random.randint(1, 10000) # start of range
   b = a + random.randint(1, 30) # end of range
   # print(f"[{a}, {b}]: {count_happy_numbers(a, b)}")
   print(f"IBenchmark happyNumbersBenchmark{i} = new CountingHappyNumbersBenchmark({a}, {b}, {count_happy_numbers(a, b)});")
