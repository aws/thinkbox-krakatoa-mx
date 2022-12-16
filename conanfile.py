# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0
from typing import Any
from conans import ConanFile, CMake

import os
import posixpath
import shutil

import version_gen

VALID_MAX_CONFIGS: dict[tuple[str, str], set[str]] = {
    ('Visual Studio', '15'): { '2022' },
    ('Visual Studio', '16'): { '2023' },
}

SETTINGS: dict[str, Any] = {
    'os': ['Windows'],
    'compiler': {
        'Visual Studio': {'version': ['15', '16']},
    },
    'build_type': None,
    'arch': 'x86_64'
}

TOOL_REQUIRES: list [str] = [
    'cmake/3.24.1',
    'thinkboxcmlibrary/1.0.0'
]

REQUIRES: list[str] = [
    'thinkboxlibrary/1.0.1',
    'maxsdk/1.0.0',
    'thinkboxmxlibrary/1.0.0',
    'krakatoa/1.0.0',
    'magma/1.0.1',
    'magmamx/1.0.0',
    # 'nodeview/1.0.0',
    'krakatoamxsdk/1.0.0',
    'openimageio/2.3.7.2'
]

NO_LICENSE_ALLOWLIST: set[str] = {
    # ThinkboxCMLibrary is not distributed with this package
    'thinkboxcmlibrary',
    # The 3ds Max SDK is not open source and we do not distribute it
    'maxsdk',
    # We do not distribute OpenGL
    'opengl',
    # We do not distribute CMake
    'cmake'
}

UNUSED_LICENSE_DENYLIST: set[str] = {
    # Parts of Eigen are licensed under GPL or LGPL
    # Eigen provides an option to disable these parts such
    # that a compiler error will be generated if they are used.
    # We do not use these parts, and enable this option.
    'licenses/eigen/licenses/COPYING.GPL',
    'licenses/eigen/licenses/COPYING.LGPL',
    # Freetype is dual licensed under it's own BSD style license, FTL
    # as well as GPLv2. We are licensing it under FTL so we will not
    # include GPLv2 in our attributions document.
    'licenses/freetype/licenses/GPLv2.txt'
}


class KrakatoaMXConan(ConanFile):
    name: str = 'krakatoamx'
    version: str = '2.12.4'
    license: str = 'Apache-2.0'
    description: str = 'The Krakatoa Plugin for 3ds Max'
    settings: dict[str, Any] = SETTINGS
    requires: list[str] = REQUIRES
    tool_requires: list[str] = TOOL_REQUIRES
    generators: str | list[str] = 'cmake_find_package'
    options: dict[str, Any] = {
        'max_version': ['2022', '2023']
    }
    default_options: dict[str, Any] = {
        'openimageio:with_libjpeg': 'libjpeg',
        'openimageio:with_libpng': True,
        'openimageio:with_freetype': False,
        'openimageio:with_hdf5': False,
        'openimageio:with_opencolorio': False,
        'openimageio:with_opencv': False,
        'openimageio:with_tbb': False,
        'openimageio:with_dicom': False,
        'openimageio:with_ffmpeg': False,
        'openimageio:with_giflib': False,
        'openimageio:with_libheif': False,
        'openimageio:with_raw': False,
        'openimageio:with_openjpeg': False,
        'openimageio:with_openvdb': False,
        'openimageio:with_ptex': False,
        'openimageio:with_libwebp': False,
        'libtiff:lzma': False,
        'libtiff:jpeg': 'libjpeg',
        'libtiff:zlib': True,
        'libtiff:libdeflate': False,
        'libtiff:zstd': False,
        'libtiff:jbig': False,
        'libtiff:webp': False
    }

    def configure(self) -> None:
        if self.options.max_version == None:
            self.options.max_version = '2023'
        self.options['maxsdk'].max_version = self.options.max_version
        self.options['thinkboxmxlibrary'].max_version = self.options.max_version
        self.options['magmamx'].max_version = self.options.max_version
        self.options['krakatoamxsdk'].max_version = self.options.max_version

    def validate(self) -> None:
        if self.options.max_version != self.options['maxsdk'].max_version:
            raise Exception('Option \'max_version\' must be the same as maxsdk')
        if self.options.max_version != self.options['thinkboxmxlibrary'].max_version:
            raise Exception('Option \'max_version\' must be the same as thinkboxmxlibrary')
        if self.options.max_version != self.options['magmamx'].max_version:
            raise Exception('Option \'max_version\' must be the same as magmamx')
        if self.options.max_version != self.options['krakatoamxsdk'].max_version:
            raise Exception('Option \'max_version\' must be the same as krakatoamxsdk')
        compiler = str(self.settings.compiler)
        compiler_version = str(self.settings.compiler.version)
        compiler_tuple = (compiler, compiler_version)
        max_version = str(self.options.max_version)
        if max_version not in VALID_MAX_CONFIGS[compiler_tuple]:
            raise Exception(f'{str(compiler_tuple)} is not a valid configuration for 3ds Max {max_version}')

    def imports(self) -> None:
        self.copy("license*", dst="licenses", folder=True, ignore_case=True)
        self.generate_attributions_doc()
                
    def build(self) -> None:
        version_gen.write_version_resource(self.version, os.path.join(self.source_folder, 'KrakatoaMXVersion.rc'))
        version_gen.write_version_header(self.version, os.path.join(self.source_folder, 'KrakatoamXVersion.h'))
        shutil.copyfile('attributions.txt', os.path.join(self.source_folder, 'third_party_licenses.txt'))

        cmake = CMake(self)
        cmake.configure(defs={
            'MAX_VERSION': self.options.max_version
        })
        cmake.build()

    def export_sources(self) -> None:
        self.copy('**.h', src='', dst='')
        self.copy('**.hpp', src='', dst='')
        self.copy('**.cpp', src='', dst='')
        self.copy('**.rc', src='', dst='')
        self.copy('**.def', src='', dst='')
        self.copy('**.MagmaBLOP', src='', dst='')
        self.copy('CMakeLists.txt', src='', dst='')
        self.copy('version_gen.py', src='', dst='')
        self.copy('*', dst='Icons', src='Icons')
        self.copy('*', dst='Scripts', src='Scripts')

    def package(self) -> None:
        cmake = CMake(self)
        cmake.install()
        self.copy('*', dst='Icons', src='Icons')
        self.copy('*', dst='Scripts', src='Scripts')
        self.copy('*', dst='BlackOps', src='BlackOps')
        self.copy('third_party_licenses.txt', dst='Legal', src='')

    def deploy(self) -> None:
        self.copy('*', dst='bin', src='bin')
        self.copy('*', dst='lib', src='lib')
        self.copy('*', dst='include', src='include')
        self.copy('*', dst='Icons', src='Icons')
        self.copy('*', dst='Scripts', src='Scripts')
        self.copy('*', dst='BlackOps', src='BlackOps')
        self.copy('*', dst='Legal', src='Legal')

    def generate_attributions_doc(self) -> None:
        dependencies = [str(dependency[0].ref).split('/') for dependency in self.dependencies.items()]
        with open('attributions.txt', 'w', encoding='utf8') as attributions_doc:
            for name, version in dependencies:
                if name not in NO_LICENSE_ALLOWLIST:
                    attributions_doc.write(f'######## {name} {version} ########\n\n')
                    licensedir = posixpath.join('licenses', name, 'licenses')
                    if not os.path.exists(licensedir):
                        raise Exception(f'Could not find license files for package {name} {version}.') 
                    for licensefile in os.listdir(licensedir):
                        licensefilepath = posixpath.join(licensedir, licensefile)
                        if licensefilepath not in UNUSED_LICENSE_DENYLIST:
                            with open(licensefilepath, 'r', encoding='utf8') as lic:
                                attributions_doc.writelines(lic.readlines())
                                attributions_doc.write('\n')
