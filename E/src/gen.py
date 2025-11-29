from random import randrange,shuffle
N=1000
n=randrange(N//2, N+1)
k=randrange(N//2, N+1)
a=set()
print(n,k)
while len(a)<n:
    a.add(randrange(N+1))
a=sorted(a)
shuffle(a)
print(*a)
