
LUA     := luajit
VERSION := $(shell cd src && $(LUA) -lbogus -e "m = require [[linenoise]]; print(m._VERSION)")
TARBALL := ljlinenoise-$(VERSION).tar.gz
REV     := 1

LUAVER  := 5.1
PREFIX  := /usr/local
DPREFIX := $(DESTDIR)$(PREFIX)
BINDIR  := $(DPREFIX)/bin
LIBDIR  := $(DPREFIX)/share/lua/$(LUAVER)
INSTALL := install

all:
	@echo "Nothing to build here, you can just make install"

install:
	$(INSTALL) -m 644 -D src/linenoise.lua                  $(LIBDIR)/linenoise.lua
	$(INSTALL) -m 755 -D src/lrepl                          $(BINDIR)/lrepl
	$(INSTALL) -m 755 -D src/ljrepl                         $(BINDIR)/ljrepl

uninstall:
	rm -f $(LIBDIR)/linenoise.lua
	rm -f $(BINDIR)/lrepl
	rm -f $(BINDIR)/ljrepl

manifest_pl := \
use strict; \
use warnings; \
my @files = qw{MANIFEST}; \
while (<>) { \
    chomp; \
    next if m{^\.}; \
    next if m{^debian/}; \
    next if m{^rockspec/}; \
    push @files, $$_; \
} \
print join qq{\n}, sort @files;

rockspec_pl := \
use strict; \
use warnings; \
use Digest::MD5; \
open my $$FH, q{<}, q{$(TARBALL)} \
    or die qq{Cannot open $(TARBALL) ($$!)}; \
binmode $$FH; \
my %config = ( \
    version => q{$(VERSION)}, \
    rev     => q{$(REV)}, \
    md5     => Digest::MD5->new->addfile($$FH)->hexdigest(), \
); \
close $$FH; \
while (<>) { \
    s{@(\w+)@}{$$config{$$1}}g; \
    print; \
}

version:
	@echo $(VERSION)

CHANGES: dist.info
	perl -i.bak -pe "s{^$(VERSION).*}{q{$(VERSION)  }.localtime()}e" CHANGES

dist.info:
	perl -i.bak -pe "s{^version.*}{version = \"$(VERSION)\"}" dist.info

tag:
	git tag -a -m 'tag release $(VERSION)' $(VERSION)

MANIFEST:
	git ls-files | perl -e '$(manifest_pl)' > MANIFEST

$(TARBALL): MANIFEST
	[ -d ljlinenoise-$(VERSION) ] || ln -s . ljlinenoise-$(VERSION)
	perl -ne 'print qq{ljlinenoise-$(VERSION)/$$_};' MANIFEST | \
	    tar -zc -T - -f $(TARBALL)
	rm ljlinenoise-$(VERSION)

dist: $(TARBALL)

rockspec: $(TARBALL)
	perl -e '$(rockspec_pl)' rockspec.in > rockspec/ljlinenoise-$(VERSION)-$(REV).rockspec

rock:
	luarocks pack rockspec/ljlinenoise-$(VERSION)-$(REV).rockspec

deb:
	echo "lua-ljlinenoise ($(shell git describe --dirty)) unstable; urgency=medium" >  debian/changelog
	echo ""                         >> debian/changelog
	echo "  * UNRELEASED"           >> debian/changelog
	echo ""                         >> debian/changelog
	echo " -- $(shell git config --get user.name) <$(shell git config --get user.email)>  $(shell date -R)" >> debian/changelog
	fakeroot debian/rules clean binary

ifdef LUA_PATH
  export LUA_PATH:=$(LUA_PATH);../test/?.lua
else
  export LUA_PATH=;;../test/?.lua
endif

check: test

test:
	cd src && prove --exec="$(LUA) -lbogus" ../test/*.t

luacheck:
	luacheck --std=max --codes src --ignore 542 --ignore 211/seq4 --ignore seq
	luacheck --std=max --codes src/ljrepl --ignore 122/arg --ignore 211/r --ignore 542
	luacheck --std=max --codes src/lrepl --ignore 122/arg --ignore 211/r
	luacheck --std=max --codes eg --ignore 211/r --ignore 11.
	luacheck --std=max --config .test.luacheckrc test/*.t

coverage:
	rm -f src/luacov.stats.out src/luacov.report.out
	cd src && prove --exec="$(LUA) -lluacov" ../test/*.t
	cd src && luacov

README.html: README.md
	Markdown.pl README.md > README.html

gh-pages:
	mkdocs gh-deploy --clean

clean:
	rm -f MANIFEST *.bak src/luacov.*.out *.rockspec README.html *.txt src/*.txt eg/*.txt

realclean: clean

.PHONY: test rockspec deb CHANGES dist.info

