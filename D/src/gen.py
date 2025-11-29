from random import randrange
def rnd(x):
    return randrange(1,x+1)
N=1000
t=100
print(t)
for _ in range(t):
    print(rnd(N))
