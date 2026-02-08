#include <fmt/core.h>
#include <spdlog/spdlog.h>
#include <nlohmann/json.hpp>

using json = nlohmann::json;

int main() {
    // Using fmt
    fmt::print("Hello from fmt!\n");
    
    // Using spdlog (which uses fmt internally)
    spdlog::info("Hello from spdlog!");
    spdlog::warn("This is a warning");
    
    // Using nlohmann/json
    json config = {
        {"name", "my_app"},
        {"version", "1.0.0"},
        {"features", {"logging", "json", "formatting"}}
    };
    
    fmt::print("Config: {}\n", config.dump(2));
    
    spdlog::info("Application {} v{} started successfully", 
        config["name"].get<std::string>(),
        config["version"].get<std::string>());
    
    return 0;
}
