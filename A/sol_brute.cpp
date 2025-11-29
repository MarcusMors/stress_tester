#include <iostream>

using namespace std;

int main()
{
  cin.tie(nullptr);
  ios_base::sync_with_stdio(false);

  int t;
  cin >> t;
  while (t--) {
    int n;
    cin >> n;
    if (n <= 5) {
      cout << 1 << endl;
    } else if (n % 5 == 0) {
      cout << n / 5 << endl;
    } else {
      cout << n / 5 + 1 << endl;
    }
  }

  return 0;
}