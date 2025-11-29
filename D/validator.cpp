#include <iostream>
#include <fstream>
#define int long long
using namespace std;

int gcd (int a, int b) { return b ? gcd (b, a % b) : a; }
int lcm (int a, int b) { return a / gcd(a, b) * b; }

signed main() {
	cin.tie(0)->sync_with_stdio(0);
	ifstream fin("data.in", ifstream::in);
	int t;
	fin>>t;
	while(t--) {
		int x,a,b;
		fin>>x;
		if(!(cin>>a>>b)) {
			cout<<0.0<<'\n';
			return 0;
		}
		if(gcd(a,b)+lcm(a,b)!=x) {
			cout<<0.0<<'\n';
			return 0;
		}
	}
	cout<<1.0<<'\n';
}