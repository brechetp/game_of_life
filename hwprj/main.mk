#
# Copyright (C) Telecom ParisTech
#
# This file must be used under the terms of the CeCILL.
# This source file is licensed as described in the file COPYING, which
# you should have received as part of this distribution.  The terms
# are also available at
# http://www.cecill.info/licences/Licence_CeCILL_V2.1-en.txt
#

#####################################################
######## Don't change anything in this file #########
#####################################################

# Common Makefile. This Makefile is included in others and depends on the proper
# definition of variable ROOTDIR which should contain the absolute or relative
# path to the directory containing this Makefile. Example of syntax of a
# Makefile including this one:
#
# ROOTDIR	= ../..
# include $(ROOTDIR)/Makefile.defs

SHELL	= /bin/bash

ifeq (,$(filter-out 3.80 3.80.%,$(MAKE_VERSION)))
fullpath=$(shell cd $(1); pwd)
else
fullpath=$(realpath $(1))
endif

## Ignore file name
IGNOREFILENAME	= ignore

## Directory definitions
## Absolute path of root directory
rootdir		= $(call fullpath,$(ROOTDIR))
## Scripts directory
SCRIPTSDIR	= hwprj
scriptsdir	= $(rootdir)/$(SCRIPTSDIR)
## Source root directory
SRCROOTDIR	= hdl
srcrootdir	= $(rootdir)/$(SRCROOTDIR)

.NOTPARALLEL:

.PHONY: help module ms-help pr-help rc-help vv-help clean ultraclean logclean

## List of modules
ALLMODS	= $(notdir $(wildcard $(srcrootdir)/*))
IGNORES	= $(notdir $(patsubst %/$(IGNOREFILENAME),%,$(wildcard $(srcrootdir)/*/$(IGNOREFILENAME))))
MODULES = $(filter-out $(IGNORES),$(ALLMODS))
LIBS		= $(patsubst %,%_lib,$(MODULES))
IGNORELIBS	= $(patsubst %,%_lib,$(IGNORES))
NOIGNORELIBS	= $(filter-out $(IGNORELIBS),$(LIBS))
NOIGNOREMODULES	= $(patsubst %_lib,%,$(NOIGNORELIBS))

ifeq ($(call fullpath,.),$(rootdir))

help:
	@echo '--------------------------------------------------------------------------------'
	@echo '"make module": create a new, empty module'
	@echo '"make ms-help": print Modelsim-related help'
	@echo '"make pr-help": print Precision RTL-related help'
	@echo '"make rc-help": print Cadence RC-related help'
	@echo '"make vv-help": print Xilinx Vivado-related help'
	@echo '"make clean": clean a bit'
	@echo '"make ultraclean": clean more but keeps regression test logfiles'
	@echo '"make logclean": delete all regression test logfiles'
	@echo '--------------------------------------------------------------------------------'

module:
	@echo -n "Module name: "; \
	read m; \
	if [ -d $(srcrootdir)/$$m ]; then \
		echo "Module $$m already exists."; \
	else \
		mkdir -p $(srcrootdir)/$$m; \
		cp $(scriptsdir)/Makefile.module.template $(srcrootdir)/$$m/Makefile; \
		cp $(scriptsdir)/dependencies.module.template $(srcrootdir)/$$m/dependencies.txt; \
		echo "Module $$m created. Please define its intra- and inter-dependencies in:"; \
		echo "  $(srcrootdir)/$$m/dependencies.txt"; \
		echo "and append its specific make rules to:"; \
		echo "  $(srcrootdir)/$$m/Makefile"; \
	fi

clean ultraclean logclean:
	@for m in $(MODULES); do $(MAKE) -C $(srcrootdir)/$$m $@; done

else

help:
	@echo '--------------------------------------------------------------------------------'
	@echo '"make ms-help": print Modelsim-related help'
	@echo '"make pr-help": print Precision RTL-related help'
	@echo '"make rc-help": print Cadence RC-related help'
	@echo '"make vv-help": print Xilinx Vivado-related help'
	@echo '"make tests": runs the non-regression tests'
	@echo '"make clean": clean a bit'
	@echo '"make ultraclean": clean more but keeps regression test logfiles'
	@echo '"make logclean": delete all regression test logfiles'
	@echo '--------------------------------------------------------------------------------'

ifeq ($(wildcard $(IGNOREFILENAME)),$(IGNOREFILENAME))

%:
	@echo "$@: found an $(IGNOREFILENAME) file"

else

tests: ms-tests ms-sim-tests rc-tests pr-tests

endif

endif

include $(scriptsdir)/ms.mk
include $(scriptsdir)/pr.mk
include $(scriptsdir)/rc.mk
include $(scriptsdir)/vv.mk
