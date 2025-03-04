# Copyright 1999-2021 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools db-use flag-o-matic toolchain-funcs

DESCRIPTION="Bayesian spam filter designed with fast algorithms, and tuned for speed"
HOMEPAGE="http://bogofilter.sourceforge.net/"
SRC_URI="mirror://sourceforge/${PN}/${P}.tar.xz"

LICENSE="GPL-3+"
SLOT="0"
KEYWORDS="~alpha amd64 ~arm ~arm64 ~hppa ~ia64 ppc ppc64 ~riscv ~sparc ~x86"
IUSE="berkdb +sqlite tokyocabinet"

# pax needed for bf_tar
DEPEND="
	app-arch/pax
	sci-libs/gsl:=
	virtual/libiconv
	berkdb?  ( >=sys-libs/db-3.2:* )
	!berkdb? (
		sqlite?  ( >=dev-db/sqlite-3.6.22 )
		!sqlite? (
			tokyocabinet? ( dev-db/tokyocabinet )
			!tokyocabinet? ( >=sys-libs/db-3.2:* )
		)
	)
"
RDEPEND="${DEPEND}"

pkg_setup() {
	has_version mail-filter/bogofilter || return 0
	if  (   use berkdb && ! has_version 'mail-filter/bogofilter[berkdb]' ) || \
		( ! use berkdb &&   has_version 'mail-filter/bogofilter[berkdb]' ) || \
		(   use sqlite && ! has_version 'mail-filter/bogofilter[sqlite]' ) || \
		( ! use sqlite &&   has_version 'mail-filter/bogofilter[sqlite]' ) || \
		( has_version '>=mail-filter/bogofilter-1.2.1-r1' && \
			(   use tokyocabinet && ! has_version 'mail-filter/bogofilter[tokyocabinet]' ) || \
			( ! use tokyocabinet &&   has_version 'mail-filter/bogofilter[tokyocabinet]' )
		) ; then
		ewarn
		ewarn "If you want to switch the database backend, you must dump the wordlist"
		ewarn "with the current version (old use flags) and load it with the new version!"
		ewarn
	fi
}

src_prepare() {
	default

	# bug 445918
	sed -i -e 's/ -ggdb//' configure.ac || die

	# bug 421747
	chmod +x src/tests/t.{ctype,leakfind,lexer.qpcr,lexer.eoh,message_id,queue_id} || die

	# bug 654990
	sed -i -e 's/t.bulkmode//' \
		-e 's/t.dump.load//' \
		-e 's/t.nonascii.replace//' \
		src/tests/Makefile.am || die

	eautoreconf
}

src_configure() {
	local myconf="" berkdb=true
	myconf="--without-included-gsl"

	# determine backend: berkdb *is* default
	if use berkdb && use sqlite ; then
		elog "Both useflags berkdb and sqlite are in USE:"
		elog "Using berkdb as database backend."
	elif use berkdb && use tokyocabinet ; then
		elog "Both useflags berkdb and tokyocabinet are in USE:"
		elog "Using berkdb as database backend."
	elif use sqlite && use tokyocabinet ; then
		elog "Both useflags sqlite and tokyocabinet are in USE:"
		elog "Using sqlite as database backend."
		myconf="${myconf} --with-database=sqlite"
		berkdb=false
	elif use sqlite ; then
		myconf="${myconf} --with-database=sqlite"
		berkdb=false
	elif use tokyocabinet ; then
		myconf="${myconf} --with-database=tokyocabinet"
		berkdb=false
	elif ! use berkdb ; then
		elog "Neither berkdb nor sqlite nor tokyocabinet are in USE:"
		elog "Using berkdb as database backend."
	fi

	# Include the right berkdb headers for FreeBSD
	if ${berkdb} ; then
		append-cppflags "-I$(db_includedir)"
	fi

	econf ${myconf}
}

src_test() {
	emake -C src/ check
}

src_install() {
	emake DESTDIR="${D}" install

	exeinto /usr/share/${PN}/contrib
	doexe contrib/{bogofilter-qfe,parmtest,randomtrain}.sh \
		contrib/{bfproxy,bogominitrain,mime.get.rfc822,printmaildir}.pl \
		contrib/{spamitarium,stripsearch}.pl

	insinto /usr/share/${PN}/contrib
	doins contrib/{README.*,dot-qmail-bogofilter-default} \
		contrib/{bogogrep.c,bogo.R,bogofilter-milter.pl,*.example} \
		contrib/vm-bogofilter.el \
		contrib/{trainbogo,scramble}.sh

	dodoc AUTHORS NEWS README RELEASE.NOTES* TODO GETTING.STARTED \
		doc/integrating-with-* doc/README.{db,sqlite}

	dodoc -r doc/*.html

	dodir /usr/share/doc/${PF}/samples
	mv "${D}"/etc/bogofilter.cf.example "${D}"/usr/share/doc/${PF}/samples/ || die
	rmdir "${D}"/etc || die
}
