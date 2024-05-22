"""Rules for libjpeg-turbo x86 assembly libraries."""

NASM_BIN = "@nasm//:nasm"

# Function for generating .o files from .asm files using nasm. The
# parameter 'x86_target_bits' is used to check if a .o file needs to be
# generated for the given .asm file.
#
# This is needed since there are 32-bit and 64-bit specific asm code files,
# and there is no way to specify here which src file to use depending
# on $(TARGET_CPU). So if 'x86_target_bits' does not match $(TARGET_CPU) it
# will create an empty file so the build dependency works.
def genasm(src, x86_target_bits, **kwargs):
    native.genrule(
        name = src.replace(".", "_").replace("/", "_"),
        srcs = [
            src,
            "simd/i386/jccolext-avx2.asm",
            "simd/i386/jccolext-mmx.asm",
            "simd/i386/jccolext-sse2.asm",
            "simd/i386/jcgryext-avx2.asm",
            "simd/i386/jcgryext-mmx.asm",
            "simd/i386/jcgryext-sse2.asm",
            "simd/i386/jdcolext-avx2.asm",
            "simd/i386/jdcolext-mmx.asm",
            "simd/i386/jdcolext-sse2.asm",
            "simd/i386/jdmrgext-avx2.asm",
            "simd/i386/jdmrgext-mmx.asm",
            "simd/i386/jdmrgext-sse2.asm",
            "simd/x86_64/jccolext-avx2.asm",
            "simd/x86_64/jccolext-sse2.asm",
            "simd/x86_64/jcgryext-avx2.asm",
            "simd/x86_64/jcgryext-sse2.asm",
            "simd/x86_64/jdcolext-avx2.asm",
            "simd/x86_64/jdcolext-sse2.asm",
            "simd/x86_64/jdmrgext-avx2.asm",
            "simd/x86_64/jdmrgext-sse2.asm",
            "simd/nasm/jcolsamp.inc",
            "simd/nasm/jdct.inc",
            "simd/nasm/jsimdcfg.inc",
            "simd/nasm/jsimdext.inc",
        ],
        tools = [NASM_BIN, "bazel/nasm_wrapper.bat"],
        outs = [src.replace(".asm", ".o").replace("/", "_")],
        cmd_bat = '$(location bazel/nasm_wrapper.bat) $(location ' + NASM_BIN + ') $(location ' + src + ') $@',
        cmd = 'if [ $(TARGET_CPU) == "k8" ] ||' +
              '   [ $(TARGET_CPU) == "x86_64" ] ||' +
              '   [ $(TARGET_CPU) == "haswell" ] ||' +
              '   [ $(TARGET_CPU) == "win_x64" ];' +
              'then TARGET_BITS="64";' +
              'elif [ $(TARGET_CPU) == "piii" ] ||' +
              '     [ $(TARGET_CPU) == "x86" ] ||' +
              '     [ $(TARGET_CPU) == "win_x86" ];' +
              'then TARGET_BITS="32";' +
              'else TARGET_BITS="0";' +
              "fi && " +
              "declare -a OPTS; " +
              "case $(TARGET_CPU) in " +
              "(win_*) OPTS+=(-f win$$TARGET_BITS -DWIN$$TARGET_BITS);;" +
              "(*) OPTS+=(-f elf$$TARGET_BITS -DELF -DPIC);; " +
              "esac;" +
              'if [ $$TARGET_BITS == "64" ];' +
              "then OPTS+=(-D__x86_64__ -DARCH_X86_64);" +
              "else OPTS+=(-DARCH_X86_32);" +
              "fi && " +
              "if [ $$TARGET_BITS == " + x86_target_bits + " ] ;" +
              "then $(location " + NASM_BIN + ") -DRGBX_FILLER_0XFF $${OPTS[@]} " +
              "-I`dirname $(location :" + src + ")`/ " +
              "-I`dirname $(location :" + src + ")`/../nasm " +
              "     $(location " + src + ") -o $@;" +
              "else touch $(@);" +
              "fi",
        **kwargs
    )

def asm_library(
        name,
        asm_srcs,
        cc_srcs,
        copts,
        x86_target_bits,
        **kwargs):
    """Rule for x86 assembly library, specific to libjpeg-turbo.

    Create asm library from given asm files. If 'x86_target_bits' does not
    match the x86-ness or number of bits in $(TARGET_CPU) it will create an
    empty library. If it matches $(TARGET_CPU) it will create the cc library.

    Args:
      name: Name of the library.
      asm_srcs: Source files with x86 assembly.
      cc_srcs: Source files with C++ code.
      copts: Any copts to pass to cc_library().
      x86_target_bits: Target number of bits for x86 (32 or 64).
      **kwargs: Any keyword arguments to be passed.
    """
    new_srcs = []
    for src in asm_srcs:
        genasm(src, x86_target_bits, **kwargs)
        new_srcs.append(src.replace(".asm", ".o").replace("/", "_"))
    if x86_target_bits == "64":
        new_srcs.append("simd/x86_64/jsimd.c")
    elif x86_target_bits == "32":
        new_srcs.append("simd/i386/jsimd.c")
    native.cc_library(
        name = name,
        srcs = cc_srcs + new_srcs,
        copts = copts,
        linkstatic = 1,
        includes = ["."],
        **kwargs
    )
