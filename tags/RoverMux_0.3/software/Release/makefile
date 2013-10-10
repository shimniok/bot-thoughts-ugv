################################################################################
# Automatically-generated file. Do not edit!
################################################################################

-include ../makefile.init

RM := rm -rf

# All of the sources participating in the build are defined here
-include sources.mk
-include subdir.mk
-include objects.mk

ifneq ($(MAKECMDGOALS),clean)
ifneq ($(strip $(C_DEPS)),)
-include $(C_DEPS)
endif
ifneq ($(strip $(ASM_DEPS)),)
-include $(ASM_DEPS)
endif
ifneq ($(strip $(S_DEPS)),)
-include $(S_DEPS)
endif
ifneq ($(strip $(S_UPPER_DEPS)),)
-include $(S_UPPER_DEPS)
endif
endif

-include ../makefile.defs

# Add inputs and outputs from these tool invocations to the build variables 
LSS += \
RC_MUX.lss \

FLASH_IMAGE += \
RC_MUX.hex \

EEPROM_IMAGE += \
RC_MUX.eep \

SIZEDUMMY += \
sizedummy \


# All Target
all: RC_MUX.elf secondary-outputs

# Tool invocations
RC_MUX.elf: $(OBJS) $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: AVR C Linker'
	avr-gcc -Wl,-Map,RC_MUX.map -mmcu=attiny13 -o "RC_MUX.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

RC_MUX.lss: RC_MUX.elf
	@echo 'Invoking: AVR Create Extended Listing'
	-avr-objdump -h -S RC_MUX.elf  >"RC_MUX.lss"
	@echo 'Finished building: $@'
	@echo ' '

RC_MUX.hex: RC_MUX.elf
	@echo 'Create Flash image (ihex format)'
	-avr-objcopy -R .eeprom -O ihex RC_MUX.elf  "RC_MUX.hex"
	@echo 'Finished building: $@'
	@echo ' '

RC_MUX.eep: RC_MUX.elf
	@echo 'Create eeprom image (ihex format)'
	-avr-objcopy -j .eeprom --no-change-warnings --change-section-lma .eeprom=0 -O ihex RC_MUX.elf  "RC_MUX.eep"
	@echo 'Finished building: $@'
	@echo ' '

sizedummy: RC_MUX.elf
	@echo 'Invoking: Print Size'
	-avr-size --format=berkeley -t RC_MUX.elf
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(OBJS)$(C_DEPS)$(ASM_DEPS)$(EEPROM_IMAGE)$(FLASH_IMAGE)$(ELFS)$(LSS)$(S_DEPS)$(SIZEDUMMY)$(S_UPPER_DEPS) RC_MUX.elf
	-@echo ' '

secondary-outputs: $(LSS) $(FLASH_IMAGE) $(EEPROM_IMAGE) $(SIZEDUMMY)

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
