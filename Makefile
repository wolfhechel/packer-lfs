LFS_BOOK := svn://svn.linuxfromscratch.org/LFS/branches/systemd/
XSL := lfs.xsl

SOURCES_DIR := source_cache
BOOK_DIR := BOOK
COMMANDS_DIR := commands
OUTPUT_DIR := output

VERSION = $(shell xmllint --noent BOOK/prologue/bookinfo.xml 2>/dev/null | grep subtitle | sed -e 's/^.*ion //'  -e 's/<\/.*//')
VM_NAME = lfs-$(VERSION)

PACKER := packer
PACKERFLAGS ?=
SVN := svn
SVNFLAGS ?=
VBOX := VBoxManage

all: $(OUTPUT_DIR)/$(VM_NAME).ovf
	@echo Finished building Linux From Scratch SVN-$(VERSION) in $</$(VM_NAME).ovf

$(OUTPUT_DIR)/$(VM_NAME).ovf: $(COMMANDS_DIR)/ $(SOURCES_DIR)
	$(PACKER) build $(PACKERFLAGS) -var='version=$(VERSION)' build.json

$(SOURCES_DIR):
	mkdir $@

$(COMMANDS_DIR)/: $(XSL) $(BOOK_DIR)/index.xml
	xsltproc --nonet --xinclude -o $@/ $(XSL) $?

$(BOOK_DIR)/index.xml:
	$(SVN) co $(SVNFLAGS) $(LFS_BOOK) $(dir $@)

update:
	cd $(BOOK_DIR); $(SVN) update
	rm -rf $(COMMANDS_DIR)

clean: removevm
	rm -rf $(OUTPUT_DIR)

distclean: clean
	rm -rf $(SOURCES_DIR) $(BOOK_DIR) $(COMMANDS_DIR)

removevm:
	$(VBOX) controlvm $(VM_NAME) poweroff || true
	$(VBOX) unregistervm $(VM_NAME) -delete || true

importvm:
	$(VBOX) import $(OUTPUT_DIR)/$(VM_NAME).ovf
	$(VBOX) modifyvm $(VM_NAME) --natpf1 "guestssh,tcp,,2222,,22"
	$(VBOX) startvm $(VM_NAME)

.PHONY: update clean distclean removevm importvm
