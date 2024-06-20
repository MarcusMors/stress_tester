#include <cmath>
#include <fstream>
#include <iostream>
#include <limits>
#include <random>
#include <sstream>
#include <string>

template<typename T> T bit_number(unsigned Bytes)
{
  // static_assert(sizeof(T) < Bytes, "the type isn't able to hold that much Bytes");
  if (sizeof(T) < Bytes) {
    std::cerr << "the type isn't able to hold " << Bytes << " Bytes\n";
    std::cerr << "sizeof(T)\t: " << sizeof(T) << "\n";
    std::cerr << "Bytes\t\t: " << Bytes << " \n";
    return 0;
  }
  T n{ 1 };
  for (unsigned i = 0; i <= Bytes; i++) { n <<= 3; }

  return n;
}

template<typename T> std::string to_str(const T &number)
{
  std::stringstream ss;
  ss << number;
  std::string str;
  ss >> str;
  return str;
}

template<class OutStreamType = std::ostream> void print_sinoidal_random_data(OutStreamType &out_stream)
{
  using std::endl;
  using Seed = std::random_device;
  using Engine = std::mt19937;
  using Distribution = std::normal_distribution<double>;
  using Distribution_sign = std::normal_distribution<int>;

  Seed seed;
  Engine engine(seed());
  Distribution dist(0.0, 1.0);
  Distribution sign_dist(0, 2);
  auto gen_rand = [&]() { return dist(engine) - 0.5; };
  auto gen_rand_sign = [&]() { return dist(engine); };

  const int numSamples = 200;
  const double amplitude = 10.0;// Amplitude of the sine wave
  const double frequency = 0.1;// Frequency of the sine wave

  for (int i = 0; i < numSamples; ++i) {
    const int sign = gen_rand_sign() == 1 ? 1 : -1;
    const double raw_val = sign * (amplitude * sin(2.0 * M_PI * frequency * i / numSamples)) + gen_rand();
    const int val = static_cast<int>(raw_val + 0.5);
    out_stream << val << endl;
  }
}

template<class OutStreamType = std::ostream> void print_random_data(OutStreamType &out_stream)
{
  using Seed = std::random_device;
  using Engine = std::default_random_engine;
  // supported int Types // check https://en.cppreference.com/w/cpp/header/random
  // short, int, long, long long,
  // unsigned short, unsigned int, unsigned long, or unsigned long long
  using intType = int;
  using Distribution = std::uniform_int_distribution<intType>;

  Seed seed;
  Engine engine{ seed() };
  /**
   * n_max = 10^5 = 100'000
   * i_max = 10^9 = 1'000'000
   */
  const intType n_max = 6;
  const intType n_min = 3;
  Distribution n_distribution(n_min, n_max);
  auto generate_n = [&]() { return n_distribution(engine); };

  const intType i_max = 10;
  const intType i_min = 1;
  Distribution i_distribution(i_min, i_max);
  auto generate_i = [&]() { return i_distribution(engine); };

  // cout << data_size << ",";

  using std::endl;
  // out_stream << 1 << endl;
  const intType data_size = generate_n();
  out_stream << data_size << "\n";
  for (intType i = 0; i < data_size; i++) { out_stream << generate_i() << ' '; }
  out_stream << "\n";
}

int main()
{
  using std::cout;
  // print_random_data(cout);

  // std::ofstream out{ "" };
  // print_random_data(out);

  print_random_data(cout);

  return 0;
}