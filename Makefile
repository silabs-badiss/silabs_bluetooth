#TBD add the license

################################################################################
#                               PROJECT CONFIG                                 #
################################################################################
include .config

################################################################################
#                              EXPORTS TO SUBMK                                #
################################################################################
export CC = $(CONFIG_CROSS_CC)
export LD = $(CONFIG_CROSS_LD)
export OBJCPY = $(CONFIG_CROSS_OBJCPY)
export DUMP = $(CONFIG_CROSS_OBJDUMP)
export PRJROOT = $(CONFIG_PRJROOT)
export MAKE = $(CONFIG_MAKE)

ifeq ($(CONFIG_BOARD_EFR32BG22_SLTB010A),y)
	export LIBS = libs/efr32bg22
	export BOARD = boards/thunderboard_bg22
	export SOC = soc/efr32bg22
	CHIP := EFR32BG22C224F512IM40
	LINKER_SCRIPT := efr32bg22c224f512im40
	RADIO_LIB := rail_efr32xg22_gcc_release
endif

ifeq ($(CONFIG_BOARD_EFR32BGM220_EXP_KIT),y)
	export LIBS = libs/bgm220
	export BOARD = boards/bgm220_explorer_kit
	export SOC = soc/bgm220
	CHIP := BGM220PC22HNA
	LINKER_SCRIPT := bgm220pc22hna
	RADIO_LIB := rail_module_efr32xg22_gcc_release rail_config_bgm220pc22hna_gcc
endif

ifeq ($(CONFIG_BOARD_EFR32MG21_BRD4181A01),y)
	export LIBS = libs/efr32mg21
	export BOARD = boards/brd4181a01
	export SOC = soc/efr32bg21
	CHIP := EFR32MG21A020F1024IM32
	LINKER_SCRIPT := efr32bg21
	RADIO_LIB := rail_efr32xg21_gcc_release
endif

ifeq ($(CONFIG_APP_LED),y)
	TARGET = led
endif

ifeq ($(CONFIG_APP_BLE_ADV),y)
	TARGET = ble_adv
endif

# include/lib path
export IPATH = -I$(PRJROOT)/include -I$(PRJROOT)/include/CMSIS/include -I$(PRJROOT)/drivers/emlib -I$(PRJROOT)/drivers/emdrv/gpiointerrupt -I$(PRJROOT)/$(LIBS)/RF/radio -I$(PRJROOT)/$(LIBS)/RF/bluetooth -I$(PRJROOT)/$(SOC) -I$(PRJROOT)/$(BOARD)  
export LPATH = -L$(PRJROOT)/$(LIBS)/RF/bluetooth -L$(PRJROOT)/$(LIBS)/RF/radio -L$(PRJROOT)/drivers/emdrv/nvm3

# compilation/linking flag
export CFLAGS = -g -gdwarf-2 -mcpu=cortex-m33 -mthumb -std=c99 -DNVM3_DEFAULT_NVM_SIZE=24576 -DHAL_CONFIG=1 -D__StackLimit=0x20000000 -D__HEAP_SIZE=0xD00 -D__STACK_SIZE=0x800 -D$(CHIP)=1 -mfpu=fpv5-sp-d16 -mfloat-abi=hard
export LDFLAGS = -g -gdwarf-2 -mcpu=cortex-m33 -mthumb -T $(PRJROOT)/$(SOC)/$(LINKER_SCRIPT).ld -Xlinker --gc-sections -Xlinker -Map="system.map" -mfpu=fpv5-sp-d16 -mfloat-abi=hard --specs=nano.specs -lm 

################################################################################
#                               directories layout                             #
################################################################################
CLEAN_DIRS = $(SOC) $(BOARD) drivers applications

################################################################################
#                           APP TARGET DEFINITIONS                             #
################################################################################
default : usage

all : $(TARGET)

menuconfig : 
	@echo -e "\033[1;35m[Menuconfig $@]\033[0m"
	python3.exe menuconfig.py Kconfig
	@echo -e  "\033[1;32m[Finished $@]\033[0m"

$(TARGET) : $(TARGET)_compile
	@echo -e "\033[1;35m[Linking $@]\033[0m"
	$(CC) $(LDFLAGS) $(LPATH) *.o -lbluetooth $(addprefix -l,$(RADIO_LIB)) -lmbedtls $(PRJROOT)/$(LIBS)/RF/bluetooth/binapploader.o -lnvm3_CM33_gcc -o $@.elf -lgcc -lc -lnosys

	@echo -e "\033[1;35m[OBJCPY ->> HEX & SREC images $@]\033[0m"
	$(OBJCPY) -O ihex $@.elf $@.hex
	$(OBJCPY) -O srec $@.elf $@.srec
	@echo -e  "\033[1;32m[Finished $@]\033[0m"

################################################################################
#                             BUILD TARGETS                                    #
################################################################################
$(TARGET)_compile : dev drv
	@echo -e "\033[1;32m[Compiling $@]\033[0m"
	$(MAKE) -C applications $(TARGET)_app
	@echo -e  "\033[1;32m[Finished $@]\033[0m"

dev :
	@echo -e "\033[1;32m[Compiling $@]\033[0m"
	$(MAKE) -C $(SOC) all
	@echo -e  "\033[1;32m[Finished $@]\033[0m"

drv :
	@echo -e "\033[1;32m[Compiling $@]\033[0m"
	$(MAKE) -C $(BOARD) all
	$(MAKE) -C drivers all
	@echo -e  "\033[1;32m[Finished $@]\033[0m"

################################################################################
#                          CLEAN/USAGE TARGETS                                 #
################################################################################

usage list help:
	@echo -e "\033[1;36m[Listing available target for build : ]\033[0m"
	@echo -e "\033[1;36m[	all             - builds all applications ]\033[0m"
	@echo -e "\033[1;36m[	led             - builds the LED app      ]\033[0m"
	@echo -e "\033[1;36m[	ble_adv         - builds the apps         ]\033[0m"
	@echo -e "\033[1;36m[	accelerometer   - builds the apps         ]\033[0m"
	@echo -e "\033[1;36m[	clean           - clean all built files   ]\033[0m"

PHONY := clean mrproper all
clean:
	$(foreach DIR,$(CLEAN_DIRS),cd $(DIR) && make clean && cd $(PRJROOT) &&) true
	rm *.a *.o *~ *.hex *.srec *.elf *.map

mrproper: clean
	rm .config .config.old

#Black        0;30     Dark Gray     1;30
#Red          0;31     Light Red     1;31
#Green        0;32     Light Green   1;32
#Brown/Orange 0;33     Yellow        1;33
#Blue         0;34     Light Blue    1;34
#Purple       0;35     Light Purple  1;35
#Cyan         0;36     Light Cyan    1;36
#Light Gray   0;37     White         1;37
