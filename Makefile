# We use a branch of Speckle (https://github.com/ccelio/Speckle) to cross
# compile the binaries for SPEC2026. These can be compiled locally on a machine
# with the Spec installation, and the overlay directories
# ($SPECKLE_DIR/build/overlay) can be moved to the run machine.

# Default to the submodule
SPECKLE_DIR ?= speckle
# Default to ref input size for SPEC26
INPUT ?= ref
# Thread/hart count baked into the generated benchmark commands (see
# speckle/README.md); match it to the target machine.
THREADS ?= 4

#TODO: Provide runscripts for fp{speed, rate}
spec26_suites = intrate intspeed
spec26_rootfs_dirs = $(patsubst %, spec26-%, $(spec26_suites))

$(SPECKLE_DIR)/build/overlay/%/$(INPUT): \
	marshal-configs/spec26-settings.sh \
	$(SPECKLE_DIR)/gen_binaries.sh \
	$(SPECKLE_DIR)/riscv.cfg \
	$(SPECKLE_DIR)/host.cfg
	cd $(SPECKLE_DIR) && ./gen_binaries.sh --compile --suite $* --input $(INPUT) --threads $(THREADS)

# NB: static pattern rule, not 'spec26-%:' — implicit pattern rules are
# never applied to .PHONY targets, so a plain pattern rule silently no-ops
$(spec26_rootfs_dirs): spec26-%: $(SPECKLE_DIR)/build/overlay/%/$(INPUT)
	echo $^

clean:
	rm -rf $(SPECKLE_DIR)/build

.PHONY: $(spec26_rootfs_dirs) clean
.PRECIOUS: $(SPECKLE_DIR)/build/overlay/%/$(INPUT)
