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
RoverMux.lss \

FLASH_IMAGE += \
RoverMux.hex \

EEPROM_IMAGE += \
RoverMux.eep \

SIZEDUMMY += \
sizedummy \


# All Target
all: RoverMux.elf secondary-outputs

# Tool invocations
RoverMux.elf: $(OBJS) $(USER_OBJS)
	@echo 'Building target: $@'
	@echo 'Invoking: AVR C Linker'
	avr-gcc -Wl,-Map,RoverMux.map -mmcu=attiny13 -o "RoverMux.elf" $(OBJS) $(USER_OBJS) $(LIBS)
	@echo 'Finished building target: $@'
	@echo ' '

RoverMux.lss: RoverMux.elf
	@echo 'Invoking: AVR Create Extended Listing'
	-avr-objdump -h -S RoverMux.elf  >"RoverMux.lss"
	@echo 'Finished building: $@'
	@echo ' '

RoverMux.hex: RoverMux.elf
	@echo 'Create Flash image (ihex format)'
	-avr-objcopy -R .eeprom -O ihex RoverMux.elf  "RoverMux.hex"
	@echo 'Finished building: $@'
	@echo ' '

RoverMux.eep: RoverMux.elf
	@echo 'Create eeprom image (ihex format)'
	-avr-objcopy -j .eeprom --no-change-warnings --change-section-lma .eeprom=0 -O ihex RoverMux.elf  "RoverMux.eep"
	@echo 'Finished building: $@'
	@echo ' '

sizedummy: RoverMux.elf
	@echo 'Invoking: Print Size'
	-avr-size --format=berkeley -t RoverMux.elf
	@echo 'Finished building: $@'
	@echo ' '

# Other Targets
clean:
	-$(RM) $(OBJS)$(C_DEPS)$(ASM_DEPS)$(EEPROM_IMAGE)$(FLASH_IMAGE)$(ELFS)$(LSS)$(S_DEPS)$(SIZEDUMMY)$(S_UPPER_DEPS) RoverMux.elf
	-@echo ' '

secondary-outputs: $(LSS) $(FLASH_IMAGE) $(EEPROM_IMAGE) $(SIZEDUMMY)

.PHONY: all clean dependents
.SECONDARY:

-include ../makefile.targets
