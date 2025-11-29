#include <bits/stdc++.h>
#define fastio()                         \
  std::ios_base::sync_with_stdio(false); \
  std::cin.tie(NULL);                    \
  std::cout.tie(NULL)

#define debugging

#ifdef debugging
#define DEBUG(x) cout << (x) << std::flush
#define DEBUGLN(x) cout << (x) << endl
#else
#define DEBUG(x)
#define DEBUGLN(x)
#endif

// __gcd(value1, value2)
// append ll to get the long long version
// __builtin_ffs(x)// returns 1+ index of least significant bit else returns cero.
// __builtin_ffs(10) = 2 // because 10: "1010", 2 is 1 + the index of the least significant bit from right to left
// __builtin_clz(x) // returns number of leading 0-bits of x which starts from most significant bit position.
// __builtin_clz(16) = 27// int has 32 bits, because 16: "1 0000", has 5 bits, 32 - 5 = 27.
// __builtin_popcount(x) // returns number of 1-bits of x. x is unsigned int
// __builtin_popcount(14) = 3// because 14: "1110", has three 1-bits.

// #define int long long
#define rep(i, begin, end) \
  for (__typeof(end) i = (begin) - ((begin) > (end)); i != (end) - ((begin) > (end)); i += 1 - 2 * ((begin) > (end)))
#define pb push_back
#define all(x) (x).begin(), (x).end()
#define rall(x) (x).rbegin(), (x).rend()
// #define token_to_replace token_replacing

using namespace std;
using ui = unsigned;
using stream = std::stringstream;
using ii = std::pair<int, int>;
using vi = std::vector<int>;
using vii = std::vector<ii>;
using vvii = std::vector<vii>;
using vvi = std::vector<vi>;

template<class T, class U> std::ostream &operator<<(ostream &os, pair<T, U> v)
{
  return os << "(" << v.first << "," << v.second << ")";
}
template<class T> std::ostream &operator<<(ostream &os, vector<T> v)
{
  for (auto &&e : v) { os << e << " "; }
  return os;
}

signed main()
{
  fastio();

  int n;
  cin >> n;
  int k;
  cin >> k;

  vector<int> arr(1002);
  for (int i = 0; i < 1002; i++) { arr[i] = false; }

  int m = -1;
  for (int i = 0; i < n; i++) {
    int e;
    cin >> e;
    arr[e] = true;
    if (e > m) { m = e; }
  }
  int vacio = k;
  // cout << endl;
  // for (int i = 0; i <= m + 1; i++) { cout << i << " "; }
  // cout << endl;
  // for (int i = 0; i <= m + 1; i++) { cout << arr[i] << " "; }
  // cout << endl;

  for (int i = 0; i <= m; i++) {
    if (arr[i] == false) {
      if (k == 0) {
        cout << i << endl;
        return 0;
      }
      k--;
    }
  }
  cout << m + k + 1 << endl;

  return 0;
}