# Generated Cmake Pico project file

cmake_minimum_required(VERSION 3.13)

set(CMAKE_C_STANDARD 11)
set(CMAKE_CXX_STANDARD 17)

# initalize pico_sdk from installed location
# (note this can come from environment, CMake cache etc)
set(PICO_SDK_PATH "D:/Program/pico/pico-sdk")

# Pull in Raspberry Pi Pico SDK (must be before project)
include(pico_sdk_import.cmake)

project(rpi_note C CXX ASM)

set(PICO_CXX_ENABLE_EXCEPTIONS 1)

set(PICO_CXX_ENABLE_RTTI 1)

# Initialise the Raspberry Pi Pico SDK
pico_sdk_init()

# Add executable. Default name is the project name, version 0.1

add_executable(rpi_note rpi_note.cpp )

pico_set_program_name(rpi_note "rpi_note")
pico_set_program_version(rpi_note "0.1")

pico_enable_stdio_uart(rpi_note 1)
pico_enable_stdio_usb(rpi_note 0)

# Add the standard library to the build
target_link_libraries(rpi_note pico_stdlib)

# Add any user requested libraries
target_link_libraries(rpi_note
        hardware_i2c
        )

pico_add_extra_outputs(rpi_note)

