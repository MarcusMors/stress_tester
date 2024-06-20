#include <string>
#include <vector>

namespace stress {
//
using std::string;
using std::vector;

class App
{
private:
  string version{ "0.0.1" };
  string bin_name{};
  vector<string> args_raw;

public:
  App([[__attribute_maybe_unused__]] int argc, char *argv[]) : bin_name{ arv[0] }, args_raw(argv + 1, argv + argc) {}
  // ~App();
};


}// namespace stress
