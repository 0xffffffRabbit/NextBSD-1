# $FreeBSD$

PACKAGE=	tests
FILESGROUPS=	TESTS
TESTSPACKAGE=	${PACKAGE}
TESTSDIR=	${TESTSBASE}/sys/mac/portacl
BINDIR=		${TESTSDIR}

FILES+=		misc.sh

TAP_TESTS_SH+=	nobody_test
TAP_TESTS_SH+=	root_test

.for t in ${TAP_TESTS_SH}
TEST_METADATA.$t+=	required_user="root"
TEST_METADATA.$t+=	timeout="450"
.endfor

.include <bsd.test.mk>
