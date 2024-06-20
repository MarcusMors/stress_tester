#include <filesystem>
#include <stack>
#include <string>

namespace stress {

using std::string;
using std::stack;
using std::filesystem;


enum Flag : char {
  version = 'v',
  help = 'h',
  file = 'f',

  solution = 's',
  brute = 'b',

  expression = 'e',
  invalid = '0',
};

enum class Error {
  inexistant_file,
  invalid_file_extension,
  no_file_extension,
  none,
  invalid_flag,
  invalid_expression,
};

const string valid_extension = "json";


struct Parameter
{
  Flag flag{};
  string value{};
  // Parameter(string t_flag)
  // {
  //   using enum Flag;
  //   if (t_flag.size() > 2 or t_flag != '-') {
  //     flag = invalid;
  //     return;
  //   }

  //   flag = t_flag[1];

  //   using enum Flag;
  //   switch (flag) {
  //   case version: break;
  //   case help: break;
  //   default: flag = invalid; break;
  //   }

  //   return true;
  // }

  // Parameter(string t_flag, string t_value, Error &error)
  // {
  //   using enum Flag;
  //   error = Error::none;

  //   if (t_flag.size() > 2 or t_flag[0] != '-') {
  //     flag = invalid;
  //     error = Error::invalid_flag;
  //     return;
  //   }
  //   Flag flag = t_flag[1];

  //   using enum Flag;
  //   switch (flag) {
  //   case file:
  //     value = t_value;
  //     filesystem::path file_path(value);

  //     if (not filesystem::exists(file_path)) {
  //       error = Error::inexistant_file;
  //     } else if (filePath.extension().empty()) {
  //       error = Error::no_file_extension;
  //     } else if (filePath.extension() != valid_extension) {
  //       error = Error::invalid_file_extension;
  //     }
  //     // should i filter, parse the value?
  //     // fuck, now i need a json reader? fuck c++

  //     break;


  //   case solution:
  //   case brute:

  //     value = t_value;
  //     if (not filesystem::exists(file_path)) {
  //       error = Error::inexistant_file;
  //     } else if (filePath.extension().empty()) {
  //       error = Error::no_file_extension;
  //     }

  //     break;

  //   case expression:
  //     value = t_value;
  //     // check if two braces
  //     // check if one brace

  //     stack<char> s;
  //     int brace_count = 0;
  //     for (auto &&ch : value) {
  //       //
  //       if (ch == '{') {
  //         s.push(ch);
  //         brace_count++;
  //         continue;
  //       }

  //       if (ch == '}') {
  //         if (ch.empty()) {
  //           error = Error::invalid_expression;
  //           brace_count = -1;
  //           break;
  //         }
  //         s.pop();
  //       }
  //     }

  //     if (brace_count != -1) {
  //       if (brace_count == 1) {
  //         // no decl, just format
  //       } else if (brace_count == 2) {
  //         // check decl and format
  //       } else {
  //         error = Error::invalid_expression;
  //       }
  //     }

  //     // should i filter, parse the value?
  //     // well, i'll be creating my own language? f dis, if i solve json, perhaps i should put the expresion in json.
  //     break;

  //   default:
  //     flag = invalid;
  //     error = Error::invalid_flag;
  //     break;
  //   }


  //   return true;
  // }


  bool valid() { return flag != Flag::invalid; }
  bool invalid() { return flag == Flag::invalid; }
};

}// namespace stress
