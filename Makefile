all:	setup
	./Build

setup:	manifest
	perl Build.PL

manifest: bin lib t Build.PL Makefile
	find . -type f | grep -vE 'DS_Store|git|_build|META.yml|Build|cover_db|svn|blib|\~|\.old|CVS|Text-Sass|build.tap|tap.harness' | sed 's/^\.\///' | sort > MANIFEST
	[ -f Build.PL ] && echo "Build.PL" >> MANIFEST

clean:	setup
	./Build clean
	[ ! -e build.tap ]  || rm -f build.tap
	[ ! -e MYMETA.yml ] || rm -f MYMETA.yml
	[ ! -d _build ]     || rm -rf _build
	[ ! -e Build ]      || rm -f Build
	[ ! -e blib ]       || rm -rf blib
#	[ ! -e tap-harness-junit.xml ] || rm -f tap-harness-junit.xml
	touch cover_db
	rm -rf cover_db

test:	all
	TEST_AUTHOR=1 ./Build test verbose=1

cover:	clean setup
	HARNESS_PERL_SWITCHES=-MDevel::Cover prove -Ilib t -MDevel::Cover
	cover -ignore_re t/

install:	setup
	./Build install

dist:	setup
	./Build dist

pardist:	setup
	./Build pardist
