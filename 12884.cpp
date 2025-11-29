#include <bits/stdc++.h>
#include <cmath>
#include <iostream>
#include <vector>

using namespace std;
// using ii = std::pair<int, int>;
using us = unsigned short;
using ii = std::pair<us, us>;

template<class T, class U> std::ostream &operator<<(ostream &os, pair<T, U> v)
{
  return os << "(" << v.first << "," << v.second << ")";
}
template<class T> std::ostream &operator<<(ostream &os, vector<T> v)
{
  for (auto &&e : v) { os << e << " "; }
  return os;
}

short prshort_arr(short arr[], short sz)
{
  for (short i = 0; i < sz; i++) { cout << arr[i] << ","; }
  cout << endl;
  return 0;
}

int main()
{

  short area_total;
  cin >> area_total;
  short lado_max = sqrt(area_total);
  // short M[lado_max + 1][lado_max][2];// M[lado_inicial_a_considerar][lado_final_a_considerar][n_terrenos,residuo]
  // vector<vector<short[2]>> M(lado_max, vector<short[2]>(0, { 0, 0 }));
  // vector<vector<ii> M(lado_max);
  std::vector<std::vector<ii>> M(lado_max);
  // for (short i = 0; i < lado_max; i++) { M[i].push_back({}); }

  // 32'000'000
  // 32'000'000
  // 8,392,000
  // 245*245*4 = 960,400

  us min_terrenos = 32766;
  for (short i = 0; i < lado_max; i++) {
    us lado = lado_max - i;
    us terreno = lado * lado;
    // lo que aporto en base al area total
    ii terrenos_y_residuos{ area_total / terreno, area_total % terreno };
    // vector<us> terrenos_y_residuos{ area_total / terreno, area_total % terreno };
    M[i].push_back(terrenos_y_residuos);
    // us mis_terrenos = M[i][0][0];
    us mis_terrenos = M[i][0].first;
    // us mi_residuo = M[i][0][1];
    us mi_residuo = M[i][0].second;
    if (mi_residuo == 0) {
      if (mis_terrenos < min_terrenos) { min_terrenos = mis_terrenos; }
    }

    // lo que aporto en base al residuo de los anteriores
    for (short k = 0; k < i; k++) {
      us kj_terrenos;
      us kj_residuo;
      us kj_terrenos_min = 1000;
      us kj_residuo_min = 32766;

      for (short j = 0; j < M[k].size(); j++) {
        // us kj_terrenos = M[k][j][0];
        kj_terrenos = M[k][j].first;
        // us kj_residuo = M[k][j][1];
        kj_residuo = M[k][j].second;

        if (kj_terrenos <= kj_terrenos_min) {
          if (kj_terrenos == kj_terrenos_min && kj_residuo_min <= kj_residuo) { continue; }
          kj_terrenos_min = kj_terrenos;
          kj_residuo_min = kj_residuo;
        }
      }

      if (terreno <= kj_residuo) {
        ii terrenos_y_residuos2 = { kj_terrenos + kj_residuo / terreno, kj_residuo % terreno };
        // vector<us> terrenos_y_residuos2 = { kj_terrenos + kj_residuo / terreno, kj_residuo % terreno };
        M[i].push_back(terrenos_y_residuos2);
        // if (terrenos_y_residuos2[1] == 0) {
        if (terrenos_y_residuos2.second == 0) {
          // if (terrenos_y_residuos2[0] < min_terrenos) { min_terrenos = terrenos_y_residuos2[0]; }
          if (terrenos_y_residuos2.first < min_terrenos) { min_terrenos = terrenos_y_residuos2.first; }
        }
      }
    }
  }

  // for (auto v : M) {
  //   cout << lado_max * lado_max << " -> ";
  //   // for (auto p : v) { cout << "[" << p[0] << "," << p[1] << "] "; }
  //   for (auto [terrenos, residuo] : v) { cout << "[" << terrenos << "," << residuo << "] "; }
  //   cout << endl;
  //   lado_max--;
  // }

  cout << min_terrenos << endl;
  return 0;
}