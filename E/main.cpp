#include <bits/stdc++.h>
using namespace std;


bool existe(vector<int>& arr, int valor) {
    for (int i = 0; i < arr.size(); ++i) {
        if (arr[i] == valor) return true;
    }
    return false;
}


void append(vector<int>& arr, int valor) {
    arr.push_back(valor);
}

int main() {
    ios::sync_with_stdio(false);
    cin.tie(nullptr);

    int N, K;
    cin>>N;
    cin>>K;
    
    vector<int> arr(N);
    for (int i = 0; i < N; ++i) cin >> arr[i];
    
    int mex = 0;
    while (true) {
        if (existe(arr, mex)) {
            ++mex;
        } else {
            if (K > 0) {
                append(arr, mex);
                --K;
                ++mex;
            } else {
                break;
            }
        }
    }

    cout << mex << '\n';
    return 0;
}