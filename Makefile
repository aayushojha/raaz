# Do not edit this file unless you know what you are doing.

include Makefile.configure

PACKAGE_CLEAN=$(foreach pkg, ${PACKAGES}, ${pkg}-clean)
TEST_PATH=dist/build/tests/tests

ifdef GHC_VERSION	# For explicit ghc version

travis-install: travis-haskell-ppa
PATH:=/opt/ghc/${GHC_VERSION}/bin:${PATH}
CABAL=cabal-1.18

else
CABAL=cabal

endif			# For explicit ghc version



.PHONY: install clean ${PACKAGES} ${PACKAGES_UNREGISTER} cabal-update

install: ${PACKAGES} raaz
clean:   ${PACKAGE_CLEAN}

cabal-update:
	${CABAL} update

${PACKAGES}:
	cd $@;\
	${CABAL} install ${INSTALL_OPTS}

${PACKAGE_CLEAN}:
	cd $(patsubst %-clean,%,$@);\
	./Setup.lhs clean;\
	cd ..
	-ghc-pkg unregister  $(patsubst %-clean,%,$@) --force

.PHONY: travis-install travis-tests

.PHONY: fast-forward fast-forward-all merge release

##  Travis stuff here.

travis-haskell-ppa:
	sudo add-apt-repository -y ppa:hvr/ghc
	sudo apt-get update
	sudo apt-get install cabal-install-1.18 ghc-${GHC_VERSION} happy

travis-install: cabal-update
	make install \
		INSTALL_OPTS='-O0 --enable-documentation --enable-tests'

travis-tests:
	$(foreach pkg, ${PACKAGES},\
		cd ${pkg};\
		${CABAL} test;\
		cd ..;\
		)
