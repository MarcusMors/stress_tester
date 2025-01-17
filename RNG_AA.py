import random
import string


def my_print(*args,separator=", ", end="\n"):
    parts = []
    for arg in args:
        if isinstance(arg, (list,tuple)):
            parts.extend(map(str, arg))
        else:
            parts.append(str(arg))

    print(separator.join(parts), end=end)

def cprint(*args, end="\n"): my_print(*args,separator=",",end=end)
def sprint(*args, end="\n"): my_print(*args,separator=" ",end=end)
def csprint(*args, end="\n"): my_print(*args,separator=", ",end=end)
def scprint(*args, end="\n"): my_print(*args,separator=" ,",end=end)

#n_list
n = random.randint(3, 15)
sprint(n)

for i in range(n):
    sprint(random.randint(0, 10), " " ,end="")
    sprint(random.randint(0, 10), " " ,end="")
    sprint(random.randint(1, 10), " " ,end="")
    print()
print()

# -------------------------------------------------------------------------
# DO NOT TOUCH THESE LINES
# -------------------------------------------------------------------------

my_sol="A.cpp"
brute_sol="A_brute.cpp"

