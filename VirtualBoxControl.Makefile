SSH_PORT ?= 2222
SSH_USER ?= root


VBOX := VBoxManage

machine_state=`$(VBOX) showvminfo --machinereadable $(VM_NAME) | grep VMState= | cut -d'"' -f2`

import-machine:
	@$(VBOX) showvminfo $(VM_NAME) &> /dev/null || ( \
		$(VBOX) import $(OUTPUT_DIR)/$(VM_NAME).ovf && \
		$(VBOX) modifyvm $(VM_NAME) --natpf1 "guestssh,tcp,,$(SSH_PORT),,22" \
	)

halt-machine:
	[ $(machine_state) == 'running' ] && $(VBOX) controlvm $(VM_NAME) poweroff || true



remove-machine: halt-machine
	$(VBOX) unregistervm $(VM_NAME) -delete || true

start-machine: import-machine
	[ $(machine_state) != "running" ] && $(VBOX) startvm --type=headless $(VM_NAME) || true

ssh-machine: start-machine
	ssh -oPort=$(SSH_PORT) $(SSH_USER)@localhost

.PHONY: remove-machine import-machine start-machine ssh-machine
