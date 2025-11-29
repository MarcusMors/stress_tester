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
    cout << 1 << " " << n - 1 << endl;
  }

  return 0;
}