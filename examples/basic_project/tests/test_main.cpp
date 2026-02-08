#include <catch2/catch_test_macros.hpp>

TEST_CASE("Basic arithmetic", "[math]") {
    REQUIRE(1 + 1 == 2);
    REQUIRE(2 * 3 == 6);
}

TEST_CASE("String operations", "[strings]") {
    std::string hello = "Hello";
    std::string world = "World";
    
    REQUIRE(hello + " " + world == "Hello World");
    REQUIRE(hello.size() == 5);
}
