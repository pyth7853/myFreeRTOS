PROJECT = usart1

EXECUTABLE = $(PROJECT).elf
BIN_IMAGE = $(PROJECT).bin
HEX_IMAGE = $(PROJECT).hex

# Toolchain configurations
CROSS_COMPILE ?= /home/STM32/toolchain/gcc-arm-none-eabi-4_8-2014q2/bin/arm-none-eabi-
CC = $(CROSS_COMPILE)gcc
LD = $(CROSS_COMPILE)ld
OBJCOPY = $(CROSS_COMPILE)objcopy
OBJDUMP = $(CROSS_COMPILE)objdump
SIZE = $(CROSS_COMPILE)size

# Cortex-M4 implements the ARMv7E-M architecture
CPU = cortex-m4
CFLAGS = -mcpu=$(CPU) -march=armv7e-m -mtune=cortex-m4
CFLAGS += -mlittle-endian -mthumb
# Need study
CFLAGS += -mfpu=fpv4-sp-d16 -mfloat-abi=softfp -O0

define get_library_path
    $(shell dirname $(shell $(CC) $(CFLAGS) -print-file-name=$(1)))
endef
LDFLAGS += -L $(call get_library_path,libc.a)
LDFLAGS += -L $(call get_library_path,libgcc.a)

# Basic configurations
CFLAGS += -g -std=c99
CFLAGS += -Wall

# Optimizations
CFLAGS += -g -std=c99 -O3 -ffast-math
CFLAGS += -ffunction-sections -fdata-sections
CFLAGS += -Wl,--gc-sections
CFLAGS += -fno-common
CFLAGS += --param max-inline-insns-single=1000

# specify STM32F429
CFLAGS += -DSTM32F429_439xx

# to run from FLASH
CFLAGS += -DVECT_TAB_FLASH
LDFLAGS += -T $(PWD)/CORTEX_M4F_STM32_DISCOVERY/stm32f429zi_flash.ld

# STARTUP FILE
OBJS += $(PWD)/CORTEX_M4F_STM32_DISCOVERY/startup_stm32f429_439xx.o

# STM32F4xx_StdPeriph_Driver
CFLAGS += -DUSE_STDPERIPH_DRIVER
CFLAGS += -D"assert_param(expr)=((void)0)"

#My own config
OBJS += \
      $(PWD)/CORTEX_M4F_STM32_DISCOVERY/main.o \
      $(PWD)/CORTEX_M4F_STM32_DISCOVERY/startup/system_stm32f4xx.o \
      $(PWD)/CORTEX_M4F_STM32_DISCOVERY/stm32f4xx_it.o \

OBJS += \
      $(PWD)/croutine.o \
      $(PWD)/event_groups.o \
      $(PWD)/list.o \
      $(PWD)/queue.o \
      $(PWD)/tasks.o \
      $(PWD)/timers.o \
      $(PWD)/portable/GCC/ARM_CM4F/port.o \
      $(PWD)/portable/MemMang/heap_1.o \

OBJS += \
    $(PWD)/CORTEX_M4F_STM32_DISCOVERY/Libraries/STM32F4xx_StdPeriph_Driver/src/misc.o \
    $(PWD)/CORTEX_M4F_STM32_DISCOVERY/Libraries/STM32F4xx_StdPeriph_Driver/src/stm32f4xx_gpio.o \
    $(PWD)/CORTEX_M4F_STM32_DISCOVERY/Libraries/STM32F4xx_StdPeriph_Driver/src/stm32f4xx_rcc.o \
    $(PWD)/CORTEX_M4F_STM32_DISCOVERY/Libraries/STM32F4xx_StdPeriph_Driver/src/stm32f4xx_usart.o \
    $(PWD)/CORTEX_M4F_STM32_DISCOVERY/Libraries/STM32F4xx_StdPeriph_Driver/src/stm32f4xx_syscfg.o \
    $(PWD)/CORTEX_M4F_STM32_DISCOVERY/Libraries/STM32F4xx_StdPeriph_Driver/src/stm32f4xx_i2c.o \
    $(PWD)/CORTEX_M4F_STM32_DISCOVERY/Libraries/STM32F4xx_StdPeriph_Driver/src/stm32f4xx_dma.o \
    $(PWD)/CORTEX_M4F_STM32_DISCOVERY/Libraries/STM32F4xx_StdPeriph_Driver/src/stm32f4xx_spi.o \
    $(PWD)/CORTEX_M4F_STM32_DISCOVERY/Libraries/STM32F4xx_StdPeriph_Driver/src/stm32f4xx_exti.o \
    $(PWD)/Utilities/STM32F429I-Discovery/stm32f429i_discovery.o \
    #$(PWD)/CORTEX_M4F_STM32_DISCOVERY/stm32f4xx_it.o

CFLAGS += -DUSE_STDPERIPH_DRIVER
CFLAGS += -I $(PWD)/CORTEX_M4F_STM32_DISCOVERY \
	  -I $(PWD)/include \
	  -I $(PWD)/portable/GCC/ARM_CM4F \
	  -I $(PWD)/CORTEX_M4F_STM32_DISCOVERY/board \
	  -I $(PWD)/CORTEX_M4F_STM32_DISCOVERY/Libraries/CMSIS/Device/ST/STM32F4xx/Include \
	  -I $(PWD)/CORTEX_M4F_STM32_DISCOVERY/Libraries/CMSIS/Include \
	  -I $(PWD)/CORTEX_M4F_STM32_DISCOVERY/Libraries/STM32F4xx_StdPeriph_Driver/inc \
	  -I $(PWD)/Utilities/STM32F429I-Discovery

all: $(BIN_IMAGE)

$(BIN_IMAGE): $(EXECUTABLE)
	@echo "    OBJCOPY   "$(notdir $@)
	@$(OBJCOPY) -O binary $^ $@
	@$(OBJCOPY) -O ihex $^ $(HEX_IMAGE)
	@echo "    OBJDUMP   "$(notdir $@)
	@$(OBJDUMP) -h -S -D $(EXECUTABLE) > $(PROJECT).lst
	@echo "    SIZE      "$(notdir $@)
	@$(SIZE) $(EXECUTABLE)
	
$(EXECUTABLE): $(OBJS)
	@echo "    LD      "$(notdir $@)
	@$(LD) -o $@ $(OBJS) \
		--start-group $(LIBS) --end-group \
		$(LDFLAGS)

%.o: %.c
	@echo "    CC      "$(notdir $@)
	@$(CC) $(CFLAGS) -c $< -o $@

%.o: %.S
	@echo "    CC      "$(notdir $@)
	@$(CC) $(CFLAGS) -c $< -o $@

flash:
	st-flash write $(BIN_IMAGE) 0x8000000

.PHONY: clean
clean:
	rm -rf $(EXECUTABLE)
	rm -rf $(BIN_IMAGE)
	rm -rf $(HEX_IMAGE)
	rm -f $(OBJS)
	rm -f $(PROJECT).lst
