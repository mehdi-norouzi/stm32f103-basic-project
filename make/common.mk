# Check to make sure that the required variables are set
ifndef DEVICE
    $(error Please set the required DEVICE variable in your makefile.)
endif

ifndef FLASH
    $(error Please set the required FLASH variable in your makefile.)
endif

# STM32-base sub-folders
BASE_LINKER   = ./linker
BASE_MAKE     = ./make
BASE_STARTUP  = ./startup

BUILD_DIR ?= ./build


# Standard values for project folders
BIN_FOLDER ?= $(BUILD_DIR)/bin
OBJ_FOLDER ?= $(BUILD_DIR)/obj
SRC_FOLDER ?= ./src
INC_FOLDER ?= ./inc

# Determine the series folder name
include $(BASE_MAKE)/series-folder-name.mk

# Include the series-specific makefile
include $(BASE_MAKE)/$(SERIES_FOLDER)/common.mk
MAPPED_DEVICE ?= $(DEVICE)

# The toolchain path, defaults to using the globally installed toolchain
PREFIX = arm-none-eabi-

CC      = $(PREFIX)gcc
CXX     = $(PREFIX)g++
LD      = $(PREFIX)ld -v
AR      = $(PREFIX)ar
AS      = $(PREFIX)gcc
OBJCOPY = $(PREFIX)objcopy
OBJDUMP = $(PREFIX)objdump
SIZE    = $(PREFIX)size


# Flags - Overall Options
CPPFLAGS += -specs=nano.specs

# Flags - C Language Options
#CFLAGS += -ffreestanding

# Flags - C++ Language Options
CXXFLAGS += -fno-threadsafe-statics
CXXFLAGS += -fno-rtti
CXXFLAGS += -fno-exceptions
CXXFLAGS += -fno-unwind-tables

# Flags - Warning Options
CPPFLAGS += -Wall
CPPFLAGS += -Wextra

# Flags - Debugging Options
CPPFLAGS += -g -gdwarf-2

# Flags - Optimization Options
CPPFLAGS += -ffunction-sections
CPPFLAGS += -fdata-sections

# Flags - Preprocessor options
CPPFLAGS += -D $(MAPPED_DEVICE)

# Flags - Assembler Options
ifneq (,$(or USE_ST_CMSIS, USE_ST_HAL))
    CPPFLAGS += -Wa,--defsym,CALL_ARM_SYSTEM_INIT=1
endif

# Flags - Linker Options
LDFLAGS += -lc -lm -lnosys 
# CPPFLAGS += -nostdlib
CPPFLAGS += -Wl,-L$(BASE_LINKER),-T$(BASE_LINKER)/$(SERIES_FOLDER)/$(DEVICE).ld $(LDFLAGS)

# Flags - Directory Options
CPPFLAGS += -I$(INC_FOLDER)
CPPFLAGS += -I$(BASE_STARTUP)

# Flags - Machine-dependant options
CPPFLAGS += -mcpu=$(SERIES_CPU)
CPPFLAGS += -march=$(SERIES_ARCH)
CPPFLAGS += -mlittle-endian
CPPFLAGS += -mthumb
#CPPFLAGS += -masm-syntax-unified

# Output files
ELF_FILE_NAME ?= stm32_executable.elf
BIN_FILE_NAME ?= stm32_bin_image.bin
OBJ_FILE_NAME ?= startup_$(MAPPED_DEVICE).o

ELF_FILE_PATH = $(BIN_FOLDER)/$(ELF_FILE_NAME)
BIN_FILE_PATH = $(BIN_FOLDER)/$(BIN_FILE_NAME)
OBJ_FILE_PATH = $(OBJ_FOLDER)/$(OBJ_FILE_NAME)

# Input files
SRC ?=
SRC += $(SRC_FOLDER)/*.c

# Startup file
DEVICE_STARTUP = $(BASE_STARTUP)/$(SERIES_FOLDER)/$(MAPPED_DEVICE).s

# Include the CMSIS files
CPPFLAGS += -I./Drivers/CMSIS/Include
CPPFLAGS += -I./Drivers/CMSIS/Device/ST/STM32F1xx/Include

# Include the HAL files
ifdef USE_ST_HAL
    CPPFLAGS += -D USE_HAL_DRIVER
    CPPFLAGS += -I$(STM32_CUBE_PATH)/HAL/$(SERIES_FOLDER)/inc

    # A simply expanded variable is used here to perform the find command only once.
    HAL_SRC := $(shell find $(STM32_CUBE_PATH)/HAL/$(SERIES_FOLDER)/src/*.c ! -name '*_template.c')
    SRC += $(HAL_SRC)
endif


# Generate dependency information
CFLAGS += -MMD -MP -MF"$(@:%.o=%.d)"

# Make all
all:$(BIN_FILE_PATH)

$(BIN_FILE_PATH): $(ELF_FILE_PATH)
	$(OBJCOPY) -O binary $^ $@

$(ELF_FILE_PATH): $(SRC) $(OBJ_FILE_PATH) | $(BIN_FOLDER)
	$(CC) $(CPPFLAGS) $^ -o $@
	$(SIZE) $@

$(OBJ_FILE_PATH): $(DEVICE_STARTUP) | $(OBJ_FOLDER)
	$(CC) -c $(CPPFLAGS) $(CXXFLAGS) $^ -o $@

$(BUILD_DIR):
	mkdir $(BUILD_DIR)

$(BIN_FOLDER): $(BUILD_DIR)
	mkdir $(BIN_FOLDER)

$(OBJ_FOLDER): $(BUILD_DIR)
	mkdir $(OBJ_FOLDER)


# Make clean
clean:
	rm -f $(ELF_FILE_PATH)
	rm -f $(BIN_FILE_PATH)
	rm -f $(OBJ_FILE_PATH)

# Make flash
flash: $(BIN_FOLDER)/$(BIN_FILE_NAME)
	st-flash write $(BIN_FOLDER)/$(BIN_FILE_NAME) $(FLASH)

.PHONY: all clean flash
