#include <cmath>
#include <fstream>
#include <iostream>
#include <limits>
#include <print>
#include <random>
#include <sstream>
#include <string>

// user made libs
#include "src/App/App.hpp"
#include "src/Parameter/Parameter.hpp"

using namespace std;
using namespace stress;

template<class OutStreamType = std::ostream> void print_sinoidal_random_data(OutStreamType &out_stream)
{
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

class Arguments
{
  Arguments(vector<string> args_raw)
  {
    // solution brute (expression or output_file)
    int implicit_c = 0;

    // map<Flag, bool> m[]

    bool third_param_is_expression = false;
    bool prev = false;
    vector<bool> normal_params(3, false);
    Flag flag{};
    for (int i = 0; i < args_raw.size(); i++) {
      const std::string argument = args_raw[i];
      if (argument[0] == '-' and argument.size() == 2) {
        if (prev) {
          // error
        }
        flag = argument[1];
        prev = true;
        continue;
      }

      if (prev) {
        // Error error{};
        Parameter p{ .flag = flag, .value = argument };

        // auto

        switch (p.flag) {
        case Flag::solution:
          if (not arguments[0].empty()) {
            // already specified, error
          } else {
            arguments[0] = argument;
          }
          break;
        case Flag::brute:
          if (not arguments[1].empty()) {
            // already specified, error
          } else {
            arguments[1] = argument;
          }
          break;
        case Flag::expression:
          if (not arguments[2].empty()) {
            // already specified, error
          } else {
            arguments[2] = argument;
          }
          break;

        default: break;
        }
        prev = false;
      } else {
        for (auto &&arg : arguments) {
          if (not arg.empty()) {
            arg = argument;
            break;
          }
        }
      }
    }
  }

private:
  string arguments[3]{};
  z string &solution_file = arguments[0];
  string &brute_file = arguments[1];
  string &expression = arguments[2];
  string declaration{};
  string format{};
};


void manage_error(Error e)
{
  switch (e) {
    using enum Error;
  case inexistant_file: break;
  case invalid_file_extension: break;
  case no_file_extension: break;
  case none: break;
  case invalid_flag:
    println("invalid flag");
    print_help();
    //
    break;
  case invalid_expression: break;

  default: break;
  }
}

void parse_one_args(vector<string> args_raw)
{
  const string arg = args_raw.front();
  if (arg.front() == '-' and arg.size() == 2) {
    switch (arg[1]) {
    case Flag::version: println("{0}", version); break;

    case Flag::help: print_help(); break;

    default:
      // error
      break;
    }
  } else {
    // error
  }
}

void parse_two_args(vector<string> args_raw)
{
  //
}

void parse_three_or_mor_args(vector<string> args_raw)
{
  //
}

void print_help()
{
  println("Ways to use this binary");
  println("implicit");
  println("{0} <input_file> \"<expresion>\"", bin_name);
  println("{0} <input_file> <output_file> \"<expresion>\"", bin_name);
  println("verbose or explicit");
  println("{0} -i <input_file> -o <output_file> -f <file>", bin_name);
  println("{0} -i <input_file> -o <output_file> -e \"<expression>\"", bin_name);
  println("ALL paramenter in a file");
  println("{0} -f <param_file>", bin_name);
  println("{0} -v #version", bin_name);
  println("{0} -h #help, this guide", bin_name);
}

void parse_args(vector<string> args_raw)
{
  auto sz = args_raw.size();
  if (sz == 0) {
    println("{0} can't be used without parameters", bin_name);
    print_help();
  } else if (sz == 1) {
    parse_one_args(args_raw);
  } else if (sz == 2) {
    parse_two_args(args_raw);
  } else {
    parse_three_or_mor_args(args_raw);
  }
}

int main(int argc, char *argv[])
{
  App app{ argc, argv };
  parse_args(args_raw);

  // print_random_data(cout);

  // std::ofstream out{ "" };
  // print_random_data(out);

  print_random_data(cout);

  return 0;
}

// {
//   cout << "The number of arguments is:" << argc << endl;
//   cout << "The arguments are:";
//   for(unsigned i = 1; i < argc; i++)
//   {
//   cout << argv[i];
//   }
//   cout << endl;

//   return 0;
// }