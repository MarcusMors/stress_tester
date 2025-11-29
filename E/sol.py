b=[False]*3000
n,k=map(int,input().split())
a=list(map(int,input().split()))
for x in a:
    b[x]=True
for i in range(3000):
    if k<=0: break
    if not b[i]:
        b[i]=True
        k-=1
for i in range(3000):
    if not b[i]:
        print(i)
        break