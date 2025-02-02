
CC = $(ARM_SDK_PREFIX)gcc
CP = $(ARM_SDK_PREFIX)objcopy
MCU := -mcpu=cortex-m0 -mthumb
LDSCRIPT := Mcu/g071/STM32G071GBUX_FLASH.ld
LIBS := -lc -lm -lnosys 
LDFLAGS := -specs=nano.specs -T$(LDSCRIPT) $(LIBS) -Wl,--gc-sections -Wl,--print-memory-usage
MAIN_SRC_DIR := Src
SRC_DIR := Mcu/g071/Startup \
	Src \
    Mcu/g071/Src \
	Mcu/g071/Drivers/STM32G0xx_HAL_Driver/Src
SRC := $(foreach dir,$(SRC_DIR),$(wildcard $(dir)/*.[cs]))
INCLUDES :=  \
	-IInc \
	-IMcu/g071/Inc \
	-IMcu/g071/Drivers/STM32G0xx_HAL_Driver/Inc \
	-IMcu/g071/Drivers/CMSIS/Include \
	-IMcu/g071/Drivers/CMSIS/Device/ST/STM32G0xx/Include 
VALUES :=  \
	-DUSE_MAKE \
	-DHSE_VALUE=8000000 \
	-DSTM32G071xx \
	-DHSE_STARTUP_TIMEOUT=100 \
	-DLSE_STARTUP_TIMEOUT=5000 \
	-DLSE_VALUE=32768 \
	-DDATA_CACHE_ENABLE=1 \
	-DINSTRUCTION_CACHE_ENABLE=0 \
	-DVDD_VALUE=3300 \
	-DLSI_VALUE=32000 \
	-DHSI_VALUE=16000000 \
	-DUSE_FULL_LL_DRIVER \
	-DPREFETCH_ENABLE=1
CFLAGS = $(MCU) $(VALUES) $(INCLUDES) -O2 -Wall -fdata-sections -ffunction-sections
CFLAGS += -D$(TARGET)
CFLAGS += -MMD -MP -MF $(@:%.bin=%.d)

TARGETS := G072ESC G071ENABLE G071_OPEN_DRAIN G071_OPEN_DRAIN_B

# Working directories
ROOT := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

IDENTIFIER    := AM32
VERSION_MAJOR := $(shell grep " VERSION_MAJOR" Src/main.c | awk '{print $$3}' )
VERSION_MINOR := $(shell grep " VERSION_MINOR" Src/main.c | awk '{print $$3}' )

FIRMWARE_VERSION := $(VERSION_MAJOR).$(VERSION_MINOR)

TARGET_BASENAME = $(BIN_DIR)/$(IDENTIFIER)_$(TARGET)_$(FIRMWARE_VERSION)

# Build tools, so we all share the same versions
# import macros common to all supported build systems
include $(ROOT)/make/system-id.mk

# configure some directories that are relative to wherever ROOT_DIR is located
BIN_DIR := $(ROOT)/obj

TOOLS_DIR ?= $(ROOT)/tools
DL_DIR := $(ROOT)/downloads

.PHONY : clean all
all : $(TARGETS)

clean :
	rm -rf $(BIN_DIR)/*

$(TARGETS) :
	$(MAKE) TARGET=$@ binary

binary : $(TARGET_BASENAME).bin

$(TARGET_BASENAME).bin : $(SRC)
	mkdir -p $(dir $@)
	$(CC) $(CFLAGS) $(LDFLAGS) -o $(TARGET_BASENAME).elf $(SRC)
	$(CP) -O binary $(TARGET_BASENAME).elf $(TARGET_BASENAME).bin
	$(CP) $(TARGET_BASENAME).elf -O ihex  $(TARGET_BASENAME).hex

# mkdirs
$(DL_DIR):
	mkdir -p $@

$(TOOLS_DIR):
	mkdir -p $@

# include the tools makefile
include $(ROOT)/make/tools.mk
