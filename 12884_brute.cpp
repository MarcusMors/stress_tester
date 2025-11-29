#include <cmath>
#include <iostream>
// #include <print>
// #include <print>


using namespace std;


int print_arr(int arr[], int sz)
{
  for (int i = 0; i < sz; i++) { cout << arr[i] << ","; }
  cout << endl;
  return 0;
}

int cuadrados(int area_total, int profundidad = 0)
{
  if (area_total == 0) { return 0; }
  if (area_total == 1) { return 1; }
  if (area_total < 4) { return area_total; }

  int sz = sqrt(area_total);
  // println("sz:{}", sz);
  int terrenitos[sz];
  for (int i = sz - 1; i >= 0; i--) { terrenitos[i] = 0; }

  for (int lado = sz; lado > 0; lado--) {
    int i = lado - 1;
    int area_terreno = lado * lado;
    terrenitos[i] = area_total / area_terreno + cuadrados(area_total % area_terreno, profundidad + 1);
  }

  int minimo = 1000000;
  for (int i = 0; i < sz; i++) {
    if (terrenitos[i] < minimo) { minimo = terrenitos[i]; }
  }
  // println("profundidad: {}\t area_total:{}\t minimo:{}", profundidad, area_total, minimo);
  // print_arr(terrenitos, sz);
  return minimo;
}

int main()
{

  int n;
  cin >> n;

  cout << cuadrados(n) << endl;
  return 0;
}
