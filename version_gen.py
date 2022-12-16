# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: Apache-2.0

"""
Generate Version Files for KrakatoaMX
"""

import argparse

RC_FILE_TEMPLATE: str = """
VS_VERSION_INFO VERSIONINFO
 FILEVERSION {major},{minor},{patch}
 PRODUCTVERSION {major},{minor},{patch}
 FILEFLAGSMASK 0x17L
#ifdef _DEBUG
 FILEFLAGS 0x1L
#else
 FILEFLAGS 0x0L
#endif
 FILEOS 0x4L
 FILETYPE 0x2L
 FILESUBTYPE 0x0L
BEGIN
	BLOCK "StringFileInfo"
	BEGIN
		BLOCK "040904b0"
		BEGIN
			VALUE "Comments", "Thinkbox KrakatoaMX"
			VALUE "CompanyName", "Thinkbox Software"
			VALUE "FileDescription", "KrakatoaMX Dynamic Link Library"
			VALUE "FileVersion", "{major}.{minor}.{patch}"
			VALUE "InternalName", "KrakatoaMX"
			VALUE "LegalCopyright", "Copyright (C) 2022"
			VALUE "OriginalFilename", "MaxKrakatoa.dlr"
			VALUE "ProductName", "KrakatoaMX"
			VALUE "ProductVersion", "{major}.{minor}.{patch}"
		END
	END
	BLOCK "VarFileInfo"
	BEGIN
		VALUE "Translation", 0x409, 1200
	END
END
"""

HEADER_FILE_TEMPLATE: str = """
#pragma once
/////////////////////////////////////////////////////
// AWS Thinkbox auto generated version include file.
/////////////////////////////////////////////////////

#define FRANTIC_VERSION "{version}"
#define FRANTIC_MAJOR_VERSION {major}
#define FRANTIC_MINOR_VERSION {minor}
#define FRANTIC_PATCH_NUMBER {patch}
#define FRANTIC_DESCRIPTION "Thinkbox Krakatoa for 3ds Max"
"""

def write_version_header(version: str, filename: str='KrakatoaMXVersion.h') -> None:
    """
    Write a header file with the version data.
    """
    major, minor, patch = version.split('.')
    with open(filename, 'w', encoding='utf8') as version_header:
        version_header.write(HEADER_FILE_TEMPLATE.format(
            version=version,
            major=major,
            minor=minor,
            patch=patch
        ))


def write_version_resource(version: str, filename: str='KrakatoaMXVersion.rc') -> None:
    """
    Write an rc file with the version data.
    """
    major, minor, patch = version.split('.')
    with open(filename, 'w', encoding='utf8') as version_resource:
        version_resource.write(RC_FILE_TEMPLATE.format(
            major=major,
            minor=minor,
            patch=patch
        ))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument(dest='version', required=True, type=str, help='The version number to use.')
    args = parser.parse_args()
    write_version_header(args.version)
    write_version_resource(args.version)
