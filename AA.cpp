// Copyright (C) 2025 José Enrique Vilca Campana
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as
// published by the Free Software Foundation, either version 3 of the
// License, or (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

/*
problem: https://omegaup.com/arena/problem/Chiliando-con-Walter/#problems
 */

#include <bits/stdc++.h>
#define fastio()                         \
  std::ios_base::sync_with_stdio(false); \
  std::cin.tie(NULL);                    \
  std::cout.tie(NULL)

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
// #define type typename

using namespace std;
using ui = unsigned;
using cui = const unsigned;
using strs = std::stringstream;
using vii = std::vector<std::pair<int, int>>;
using vi = std::vector<int>;
using ii = std::pair<int, int>;

template<class T, class U> std::ostream &operator<<(ostream &os, pair<T, U> v)
{
  return os << "(" << v.first << "," << v.second << ")";
}
template<class T> std::ostream &operator<<(ostream &os, vector<T> v)
{
  for (auto &&e : v) { os << e << " "; }
  return os;
}

// 4'294'967'296
const int INF = 1'000'000'000;

void solve()
{
  int n;
  cin >> n;

  vector<pair<int, ii>> bears;// x, {y,p}

  int reduce = 0;

  rep(i, 0, n)
  {
    int x;
    cin >> x;
    int y;
    cin >> y;
    int p;
    cin >> p;
    if (abs(y) > x) {
      reduce++;
      continue;
    }

    bears.push_back({ x, { y, p } });
  }

  int sz = n - reduce;
  sort(all(bears));

  if (sz == 0) {
    cout << 0 << endl;
    return;
  }

  vector<pair<int, ii>> DP(sz);
  // DP[0] = bears[0].second.second;
  {
    auto [x, yp] = bears[0];
    auto [y, p] = yp;
    DP[0] = { p, { x, y } };
  }

  for (int i = 1; i < sz; i++) {
    auto [xi, ypi] = bears[i];
    auto [yi, pi] = ypi;

    int max = 0;
    ii max_xy{ 0, 0 };
    for (int j = 0; j < i; j++) {
      auto [pj, xyj] = DP[j];
      auto [xj, yj] = xyj;

      const bool possible = (xi - xj) >= abs(yi - yj);
      if (possible and pj > max) {
        max = pj;
        max_xy = { xj, yj };
      }
    }
    // DP[i] = max + pi;
    DP[i] = { max + pi, { xi, yi } };
  }

  int max = 0;
  for (int i = 0; i < sz; i++) {
    auto [p, xy] = DP[i];
    if (p > max) { max = p; }
  }

  cout << max << "\n";
}

/*
3
2 7 8
8 7 2
7 5 5
 */

signed main()
{
  // fastio();

  solve();

  return 0;
}