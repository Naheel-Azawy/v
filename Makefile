CC ?= cc
CFLAGS ?=
LDFLAGS ?=
TMPDIR ?= /tmp

VCFILE := v.c
TMPVC  := $(TMPDIR)/vc
TMPTCC := /var/tmp/tcc
VCREPO := https://github.com/vlang/vc
TCCREPO := https://github.com/vlang/tccbin
GITCLEANPULL := git clean -xf && git pull --quiet
GITFASTCLONE := git clone --depth 1 --quiet

#### Platform detections and overrides:
_SYS := $(shell uname 2>/dev/null || echo Unknown)
_SYS := $(patsubst MSYS%,MSYS,$(_SYS))
_SYS := $(patsubst MINGW%,MinGW,$(_SYS))

ifneq ($(filter $(_SYS),MSYS MinGW),)
WIN32 := 1
endif

ifeq ($(_SYS),Linux)
LINUX := 1
endif

ifeq ($(_SYS),Darwin)
MAC := 1
endif

ifeq ($(_SYS),FreeBSD)
LDFLAGS += -lexecinfo
endif

ifdef ANDROID_ROOT
ANDROID := 1
undefine LINUX
endif
#####

ifdef WIN32
TCCREPO := https://github.com/vlang/tccbin_win
VCFILE := v_win.c
endif

all: old_vc latest_tcc
ifdef WIN32
	$(CC) $(CFLAGS) -g -std=c99 -municode -w -o v.exe $(TMPVC)/$(VCFILE) $(LDFLAGS)
	./v.exe self
else
	$(CC) $(CFLAGS) -g -std=gnu11 -w -o v $(TMPVC)/$(VCFILE) $(LDFLAGS) -lm -lpthread
ifdef ANDROID
	chmod 755 v
endif
	./v self
ifndef ANDROID
	$(MAKE) modules
endif
endif
ifdef V_ALWAYS_CLEAN_TMP
	$(MAKE) clean_tmp
endif
	@echo "V has been successfully built"
	@./v -version

#clean: clean_tmp
#git clean -xf

clean:
	rm -rf $(TMPTCC)
	rm -rf $(TMPVC)

latest_vc: $(TMPVC)/.git/config
	cd $(TMPVC) && $(GITCLEANPULL)

fresh_vc:
	rm -rf $(TMPVC)
	$(GITFASTCLONE) $(VCREPO) $(TMPVC)

old_vc:
	rm -rf $(TMPVC)
	mkdir -p $(TMPVC)
	cd $(TMPVC) && curl 'https://raw.githubusercontent.com/vlang/vc/f46b34ef0e77bb03e7f935a452915077fae6c0c6/v.c' > $(TMPVC)/v.c

latest_tcc: $(TMPTCC)/.git/config
ifndef ANDROID
ifndef MAC
	cd $(TMPTCC) && $(GITCLEANPULL)
endif
endif

fresh_tcc:
ifndef ANDROID
ifndef MAC
	rm -rf $(TMPTCC)
	$(GITFASTCLONE) $(TCCREPO) $(TMPTCC)
endif
endif

$(TMPTCC)/.git/config:
ifndef MAC
	$(MAKE) fresh_tcc
endif

$(TMPVC)/.git/config:
	$(MAKE) fresh_vc

selfcompile:
	./v -keepc -cg -o v cmd/v

selfcompile-static:
	./v -keepc -cg -cflags '--static' -o v-static cmd/v

modules: module_builtin module_strings module_strconv
module_builtin:
	#./v build module vlib/builtin > /dev/null
module_strings:
	#./v build module vlib/strings > /dev/null
module_strconv:
	#./v build module vlib/strconv > /dev/null
