from math import gcd, lcm
for _ in range(int(input())):
    x=int(input())
    print(1,x-1)
    assert gcd(1,x-1)+lcm(1,x-1)==x