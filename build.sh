#!/bin/bash

function build_gcc() {
	ver="${1}"; shift
	maj="${ver%%.*}"

	curl -O https://ftp.gnu.org/gnu/gcc/gcc-${ver}/gcc-${ver}.tar.xz
	tar -xf gcc-${ver}.tar.xz

	# Build D "import" directory
	if test -d compilers/include/${maj}; then
		rm -rf compilers/include/${maj}
	fi
	mkdir -p compilers/include/${maj}

	for pkg in __builtins.di core __entrypoint.di etc gc gcc gcstub __main.di object.d rt std; do
		if test -f gcc-${ver}/libphobos/libdruntime/${pkg}; then
			cp -a gcc-${ver}/libphobos/libdruntime/${pkg} compilers/include/${maj}/${pkg}
		elif test -d gcc-${ver}/libphobos/libdruntime/${pkg}; then
			cp -a gcc-${ver}/libphobos/libdruntime/${pkg} compilers/include/${maj}/${pkg}
		elif test -d gcc-${ver}/libphobos/src/${pkg}; then
			cp -a gcc-${ver}/libphobos/src/${pkg} compilers/include/${maj}/${pkg}
		fi
	done

	find compilers/include/${maj} -name "*.c" -delete

	mv compilers/include/${maj}/gcc/libbacktrace.d.in compilers/include/${maj}/gcc/libbacktrace.d
	sed -e 's|@BACKTRACE_SUPPORTED@|true|' \
	    -e 's|@BACKTRACE_USES_MALLOC@|false|' \
	    -e 's|@BACKTRACE_SUPPORTS_THREADS@|false|' \
	    -i compilers/include/${maj}/gcc/libbacktrace.d

	mv compilers/include/${maj}/gcc/config.d.in compilers/include/${maj}/gcc/config.d
	sed -e 's|enum GNU_ARM_EABI_Unwinder = @DCFG_ARM_EABI_UNWINDER@|version (ARM) enum GNU_ARM_EABI_Unwinder = true; else enum GNU_ARM_EABI_Unwinder = false|' \
	    -e 's|enum ThreadModel GNU_Thread_Model = ThreadModel.@DCFG_THREAD_MODEL@|version (Posix) enum ThreadModel GNU_Thread_Model = ThreadModel.Posix; else version (Windows) enum ThreadModel GNU_Thread_Model = ThreadModel.Win32; else enum ThreadModel GNU_Thread_Model = ThreadModel.Single|' \
	    -e 's|@DCFG_DLPI_TLS_MODID@|true|' \
	    -e 's|@DCFG_HAVE_ATOMIC_BUILTINS@|true|' \
	    -e 's|@DCFG_HAVE_64BIT_ATOMICS@|true|' \
	    -e 's|@DCFG_HAVE_LIBATOMIC@|true|' \
	    -e 's|@DCFG_HAVE_QSORT_R@|true|' \
	    -e 's|@DCFG_ENABLE_CET@|false|' \
	    -i compilers/include/${maj}/gcc/config.d

	# Build all compiler targets
	for arg in ${@}; do
		arg="${arg//OPT/ -}"
		arg="${arg//SEP/\/}"
		name="${arg##*NAME}"
		arg="${arg%%NAME*}"

		configopts="--target=${arg}"
		target=${arg%% *}
		if test "${name}" = "${arg}"; then
			name=$target
		fi

		if test -f compilers/${name}/libexec/gcc/${target}/${ver}/d21; then
			continue
		fi

		mkdir -p compilers/${name}
		mkdir -p build
		pushd build
		../gcc-${ver}/configure ${configopts} --enable-languages=c,d,lto
		make -j$((`nproc`+1)) -l$((`nproc`+`nproc`/2)) all-gcc
		popd

		# Install the compiler if built successfully
		if test -f build/gcc/d21; then
			mkdir -p compilers/${name}/bin
			install --strip build/gcc/gdc compilers/${name}/bin/gdc-${maj}

			mkdir -p compilers/${name}/libexec/gcc/${target}/${ver}
			install --strip build/gcc/d21 compilers/${name}/libexec/gcc/${target}/${ver}/d21
			install --strip build/gcc/cc1 compilers/${name}/libexec/gcc/${target}/${ver}/cc1
			install --strip --mode=0644 build/gcc/liblto_plugin.so compilers/${name}/libexec/gcc/${target}/${ver}/liblto_plugin.so

			mkdir -p compilers/${name}/lib/gcc/${target}/${ver}/include
			ln -s ../../../../../../include/${maj} compilers/${name}/lib/gcc/${target}/${ver}/include/d
		else
			echo "../gcc-${ver}/configure ${configopts} --enable-languages=c,d,lto" \
				> compilers/${name}/failed.${ver}.log
		fi
		rm -rf build
	done

	rm -f gcc-${ver}.tar.xz
	rm -rf gcc-${ver}
}

# gcc-9 baseline targets
TARGETS=(
  aarch64-elf
  aarch64-linux-gnu
  aarch64-rtems
  alpha64-dec-vms
  alpha-dec-vms
  alpha-linux-gnu
  alpha-netbsd
  alpha-openbsd
  amdgcn-amdhsaOPT-with-build-time-tools=SEPusrSEPamdgcn-amdhsaSEPbin
  arceb-linux-uclibcOPT-with-cpu=arc700
  arc-elf32OPT-with-cpu=arc600NAMEarc600-elf32
  arc-elf32OPT-with-cpu=arc700NAMEarc700-elf32
  arc-linux-uclibcOPT-with-cpu=arc700
  arm-eabi
  arm-linux-androideabi
  arm-netbsdelf
  arm-rtems
  arm-symbianelf
  arm-uclinux_eabi
  arm-wrs-vxworks
  avr-elf
  bfin-elf
  bfin-linux-uclibc
  bfin-openbsd
  bfin-rtems
  bfin-uclinux
  c6x-elf
  c6x-uclinux
  cr16-elf
  cris-elf
  cris-linux
  crisv32-elf
  crisv32-linux
  csky-elf
  csky-linux-gnu
  epiphany-elf
  epiphany-elfOPT-with-stack-offset=16NAMEepiphany-elf-stack-offset-16
  fido-elf
  fr30-elf
  frv-elf
  frv-linux
  ft32-elf
  h8300-elf
  hppa2.0-hpux10.1
  hppa2.0-hpux11.9
  hppa64-hpux11.0OPT-enable-sjlj-exceptions=yes
  hppa64-hpux11.3
  hppa64-linux-gnu
  hppa-linux-gnu
  hppa-linux-gnuOPT-enable-sjlj-exceptions=yesNAMEhppa-linux-gnu-sjlj-exceptions
  i486-freebsd4
  i686-apple-darwin
  i686-apple-darwin10
  i686-apple-darwin9
  i686-cygwinOPT-enable-threads=yes
  i686-elf
  i686-freebsd6
  i686-kfreebsd-gnu
  i686-kopensolaris-gnu
  i686-lynxos
  i686-mingw32crt
  i686-netbsdelf9
  i686-nto-qnx
  i686-openbsd
  i686-pc-linux-gnu
  i686-pc-msdosdjgpp
  i686-rtems
  i686-solaris2.11
  i686-symbolics-gnu
  i686-wrs-vxworks
  i686-wrs-vxworksae
  ia64-elf
  ia64-freebsd6
  ia64-hpux
  ia64-hp-vms
  ia64-linux
  iq2000-elf
  lm32-elf
  lm32-rtems
  lm32-uclinux
  m32c-elf
  m32c-rtems
  m32r-elf
  m32rle-elf
  m32rle-linux
  m32r-linux
  m68k-elf
  m68k-linux
  m68k-netbsdelf
  m68k-openbsd
  m68k-rtems
  m68k-uclinux
  mcore-elf
  microblaze-elf
  microblaze-linux
  mips64-elf
  mips64el-st-linux-gnu
  mips64octeon-linux
  mips64orion-elf
  mips64vr-elf
  mipsel-elf
  mipsisa32-elfoabi
  mipsisa32r2-linux-gnu
  mipsisa64-elfoabi
  mipsisa64r2el-elf
  mipsisa64r2-linux
  mipsisa64r2-sde-elf
  mipsisa64sb1-elf
  mipsisa64sr71k-elf
  mips-netbsd
  mips-rtems
  mipstx39-elf
  mips-wrs-vxworks
  mmix-knuth-mmixware
  mn10300-elf
  moxie-elf
  moxie-rtems
  moxie-uclinux
  msp430-elf
  nds32be-elf
  nds32le-elf
  nios2-elf
  nios2-linux-gnu
  nios2-rtems
  nvptx-none
  pdp11-aout
  powerpc64-darwin
  powerpc64-linux_altivec
  powerpc-darwin7
  powerpc-darwin8
  powerpc-eabi
  powerpc-eabialtivec
  powerpc-eabisim
  powerpc-eabisimaltivec
  powerpc-freebsd6
  powerpcle-eabi
  powerpcle-eabisim
  powerpcle-elf
  powerpc-lynxos
  powerpc-netbsd
  powerpc-rtems
  powerpc-wrs-vxworks
  powerpc-wrs-vxworksae
  powerpc-wrs-vxworksmils
  powerpc-xilinx-eabi
  ppc-elf
  riscv32-unknown-linux-gnu
  riscv64-unknown-linux-gnu
  rl78-elf
  rs6000-ibm-aix6.1
  rs6000-ibm-aix7.1
  rx-elf
  s390-linux-gnu
  s390x-ibm-tpf
  s390x-linux-gnu
  sh-elf
  shle-linux
  sh-netbsdelf
  sh-rtems
  sh-superh-elf
  sh-wrs-vxworks
  sparc64-elf
  sparc64-freebsd6
  sparc64-linux
  sparc64-netbsd
  sparc64-openbsd
  sparc64-rtems
  sparc64-sun-solaris2.11OPT-with-gnu-ldOPT-with-gnu-asOPT-enable-threads=posix
  sparc-elf
  sparc-leon3-linux-gnuOPT-enable-target=all
  sparc-leon-elf
  sparc-linux-gnu
  sparc-netbsdelf
  sparc-rtems
  sparc-wrs-vxworks
  spu-elfOPT-enable-obsolete
  tilegxbe-linux-gnuOPT-enable-obsolete
  tilegx-linux-gnuOPT-enable-obsolete
  tilepro-linux-gnuOPT-enable-obsolete
  v850e-elf
  v850-elf
  v850-rtems
  vax-linux-gnu
  vax-netbsdelf
  visium-elf
  x86_64-apple-darwin
  x86_64-elfOPT-with-fpmath=sse
  x86_64-freebsd6
  x86_64-mingw32OPT-enable-sjlj-exceptions=yes
  x86_64-netbsd
  x86_64-pc-linux-gnuOPT-with-fpmath=avx
  x86_64-rtems
  x86_64-w64-mingw32
  xstormy16-elf
  xtensa-elf
  xtensa-linux
)
build_gcc "9.5.0" "${TARGETS[@]}"

# gcc-10 addition/removals
TARGETS+=(bpf-unknown-none)
TARGETS+=(msp430-elfbare)
TARGETS+=(cris-linuxOPT-enable-obsolete)
TARGETS+=(crisv32-elfOPT-enable-obsolete)
TARGETS+=(crisv32-linuxOPT-enable-obsolete)
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<arm-wrs-vxworks\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<cris-linux\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<crisv32-elf\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<crisv32-linux\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<spu-elfOPT-enable-obsolete\>")
build_gcc "10.5.0" "${TARGETS[@]}"

# gcc-11 addition/removals
TARGETS+=(or1k-elf)
TARGETS+=(or1k-linux-uclibc)
TARGETS+=(or1k-linux-musl)
TARGETS+=(or1k-rtems)
TARGETS+=(pru-elf)
TARGETS+=(v850e1-elf)
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<cris-linuxOPT-enable-obsolete\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<crisv32-elfOPT-enable-obsolete\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<crisv32-linuxOPT-enable-obsolete\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<rs6000-ibm-aix5.3.0\>")
build_gcc "11.4.0" "${TARGETS[@]}"

# gcc-12 addition/removals
TARGETS+=(hppa2.0-hpux10.1OPT-enable-obsolete)
TARGETS+=(hppa2.0-hpux11.9OPT-enable-obsolete)
TARGETS+=(loongarch64-linux-gnuf64)
TARGETS+=(loongarch64-linux-gnuf32)
TARGETS+=(loongarch64-linux-gnusf)
TARGETS+=(m32c-rtemsOPT-enable-obsolete)
TARGETS+=(powerpc-ibm-aix7.1)
TARGETS+=(powerpc-ibm-aix7.2)
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<cr16-elf\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<hppa2.0-hpux10.1\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<hppa2.0-hpux11.9\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<m32c-rtems\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<m32r-linux\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<m32rle-linux\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<m68k-openbsd\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<rs6000-ibm-aix6.1\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<rs6000-ibm-aix7.1\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<vax-openbsd\>")
build_gcc "12.3.0" "${TARGETS[@]}"

# gcc-13 addition/removals
TARGETS+=(aarch64-freebsd13)
TARGETS+=(i686-freebsd13)
TARGETS+=(i686-gnu)
TARGETS+=(powerpc-freebsd13)
TARGETS+=(x86_64-gnu)
TARGETS+=(x86_64-freebsd13)
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<hppa2.0-hpux10.1OPT-enable-obsolete\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<hppa2.0-hpux11.9OPT-enable-obsolete\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<i486-freebsd4\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<i686-symbolics-gnu\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<ia64-freebsd6\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<m32c-rtemsOPT-enable-obsolete\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<powerpc-freebsd6\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<sparc64-freebsd6\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<tilegx-linux-gnuOPT-enable-obsolete\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<tilegxbe-linux-gnuOPT-enable-obsolete\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<tilepro-linux-gnuOPT-enable-obsolete\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<x86_64-freebsd6\>")
build_gcc "13.2.0" "${TARGETS[@]}"

exit 0
### FUTURE ###

# gcc-14 addition/removals
TARGETS+=(i686-apple-darwin13)
TARGETS+=(i686-apple-darwin17)
TARGETS+=(powerpc-apple-darwin9)
TARGETS+=(powerpc64-apple-darwin9)
TARGETS+=(powerpc-apple-darwin8)
TARGETS+=(x86_64-apple-darwin15)
TARGETS+=(x86_64-apple-darwin21)
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<i686-apple-darwin\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<i686-apple-darwin10\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<powerpc-darwin8\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<powerpc-darwin7\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<powerpc64-darwin\>")
mapfile -d $'\0' -t TARGETS < <(printf '%s\0' "${TARGETS[@]}" | grep -zv "\<x86_64-apple-darwin\>")
build_gcc "14.1.0" "${TARGETS[@]}"
