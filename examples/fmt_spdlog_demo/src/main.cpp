#include <fmt/core.h>
#include <fmt/color.h>
#include <fmt/chrono.h>
#include <spdlog/spdlog.h>
#include <spdlog/sinks/stdout_color_sinks.h>

#include <chrono>
#include <thread>
#include <vector>

int main() {
    // =========================================================================
    // Using fmt directly
    // =========================================================================
    fmt::print("=== fmt examples ===\n\n");
    
    // Basic formatting
    fmt::print("Hello, {}!\n", "World");
    
    // Positional arguments
    fmt::print("{1} comes before {0}\n", "second", "first");
    
    // Named arguments
    fmt::print("Name: {name}, Age: {age}\n", 
        fmt::arg("name", "Alice"), 
        fmt::arg("age", 30));
    
    // Number formatting
    fmt::print("Integer: {:>10d}\n", 42);
    fmt::print("Float:   {:>10.2f}\n", 3.14159);
    fmt::print("Hex:     {:#x}\n", 255);
    fmt::print("Binary:  {:#b}\n", 42);
    
    // Colored output
    fmt::print(fg(fmt::color::green), "This is green!\n");
    fmt::print(fg(fmt::color::red) | fmt::emphasis::bold, "This is bold red!\n");
    
    // Time formatting
    auto now = std::chrono::system_clock::now();
    fmt::print("Current time: {:%Y-%m-%d %H:%M:%S}\n", now);
    
    fmt::print("\n");

    // =========================================================================
    // Using spdlog (built on fmt)
    // =========================================================================
    fmt::print("=== spdlog examples ===\n\n");
    
    // Default logger
    spdlog::info("Welcome to spdlog!");
    spdlog::warn("This is a warning message");
    spdlog::error("This is an error message");
    
    // With formatting (uses fmt under the hood)
    spdlog::info("Formatted: {} + {} = {}", 1, 2, 3);
    spdlog::info("Float value: {:.4f}", 3.14159265359);
    
    // Change log level
    spdlog::set_level(spdlog::level::debug);
    spdlog::debug("This debug message is now visible!");
    spdlog::trace("But trace is still hidden");
    
    // Create a colored console logger
    auto console = spdlog::stdout_color_mt("console");
    console->info("This is from a named logger");
    console->set_pattern("[%H:%M:%S.%e] [%^%l%$] [%n] %v");
    console->info("With custom pattern!");
    
    // Log with source location (C++20)
    SPDLOG_INFO("Macro-based logging with source location");
    
    // Simulate some work with progress
    fmt::print("\n=== Simulated processing ===\n\n");
    std::vector<std::string> tasks = {"Loading config", "Connecting", "Processing", "Saving"};
    
    for (size_t i = 0; i < tasks.size(); ++i) {
        spdlog::info("[{}/{}] {}...", i + 1, tasks.size(), tasks[i]);
        std::this_thread::sleep_for(std::chrono::milliseconds(200));
    }
    
    spdlog::info("All tasks completed!");
    
    return 0;
}
