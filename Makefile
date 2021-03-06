# standard Python project Makefile
progname = $(shell awk '/^Source/ {print $$2}' debian/control)
name=

prefix = /usr/local
PATH_BIN = $(prefix)/bin
PATH_ETC = $(destdir)/etc
PATH_INSTALL_LIB = $(prefix)/lib/$(progname)
PATH_UDEV_RULES = $(destdir)/lib/udev/rules.d

all: help

debug:
	$(foreach v, $V, $(warning $v = $($v)))
	@true

### Extendable targets

# target: help
help:
	@echo '=== Targets:'
	@echo 'install   [ prefix=path/to/usr ] # default: prefix=$(value prefix)'
	@echo 'uninstall [ prefix=path/to/usr ]'
	@echo
	@echo 'clean'

# DRY macros
truepath = $(shell echo $1 | sed -e 's/^debian\/$(progname)//')
libpath = $(call truepath,$(PATH_INSTALL_LIB))/$$(basename $1)
subcommand = $(progname)-$$(echo $1 | sed 's|.*/||; s/^cmd_//; s/_/-/g; s/.py$$//')
echo-do = echo $1; $1

# first argument: code we execute if there is just one executable module
# second argument: code we execute if there is more than on executable module
define with-py-executables
	@modules=$$(find -maxdepth 1 -type f -name '*.py' -perm -100); \
	modules_len=$$(echo $$modules | wc -w); \
	if [ $$modules_len = 1 ]; then \
		module=$$modules; \
		$(call echo-do, $1); \
	elif [ $$modules_len -gt 1 ]; then \
		for module in $$modules; do \
			$(call echo-do, $2); \
		done; \
	fi;
endef

# set path bin in udev rules
%.rules: %.rules.in
	sed "s|@PATH_BIN@|$(call truepath,$(PATH_BIN))|g" $< > $@

# target: install
install: 85-ebsmount.rules
	@echo
	@echo \*\* CONFIG: prefix = $(prefix) \*\*
	@echo 

	install -d $(PATH_BIN) $(PATH_ETC) $(PATH_INSTALL_LIB) $(PATH_UDEV_RULES)
	cp *.conf $(PATH_ETC)
	cp *.py $(PATH_INSTALL_LIB)
	cp *.rules $(PATH_UDEV_RULES)

	$(call with-py-executables, \
	  ln -fs $(call libpath, $$module) $(PATH_BIN)/$(progname), \
	  ln -fs $(call libpath, $$module) $(PATH_BIN)/$(call subcommand, $$module))

# target: uninstall
uninstall:
	rm -rf $(PATH_INSTALL_LIB)
	rm -f $(PATH_ETC)/ebsmount.conf
	rm -f $(PATH_UDEV_RULES)/85-ebsmount.rules

	$(call with-py-executables, \
	  rm -f $(PATH_BIN)/$(progname), \
	  rm -f $(PATH_BIN)/$(call subcommand, $$module))

# target: clean
clean:
	rm -f *.pyc *.pyo *.rules _$(progname)
