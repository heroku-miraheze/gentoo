# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit fcaps toolchain-funcs

DESCRIPTION="Advanced PC speaker beeper"
HOMEPAGE="https://github.com/spkr-beep"
SRC_URI="https://github.com/spkr-beep/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~alpha amd64 ~arm ppc ppc64 sparc ~x86"

# Tests require a speaker
RESTRICT="test"

src_prepare() {
	default

	sed -i -e "s#-D_FORTIFY_SOURCE=2##g;" GNUmakefile || die
}

src_compile() {
	emake \
		COMPILERS=gcc \
		COMPILER_gcc="$(tc-getCC)" \
		LINKER_gcc="$(tc-getCC)" \
		CFLAGS_gcc="${CFLAGS}" \
		LDFLAGS="${LDFLAGS}" \
		CPPFLAGS_gcc="" \
		all
}

src_test() {
	emake \
		COMPILERS=gcc \
		COMPILER_gcc="$(tc-getCC)" \
		LINKER_gcc="$(tc-getCC)" \
		CFLAGS_gcc="${CFLAGS}" \
		LDFLAGS="${LDFLAGS}" \
		check
}

src_install() {
	dobin beep
	doman "${PN}.1"

	fperms 0711 /usr/bin/beep

	einstalldocs
}

pkg_postinst() {
	fcaps cap_dac_override,cap_sys_tty_config "${EROOT}/usr/bin/beep"
}
