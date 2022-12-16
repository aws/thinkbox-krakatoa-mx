// Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
// SPDX-License-Identifier: Apache-2.0
#pragma once

#include <max.h>

#define IMaxKrakatoaPRTSource_ID Interface_ID( 0x49104da2, 0x4f19799f )

/**
 * Objects supporting this interface are expected to expose particles via a Stream containing data in the PRT
 * specification.
 *
 * \note The particle data portion of the stream is NOT expected to be compressed in any way.
 */
class IMaxKrakatoaPRTSource : public BaseInterface {
  public:
    /**
     * This class defines the interface for a read-only stream of data.
     */
    class Stream {
      public:
        enum { eof = -1 };

        /**
         * Reads the next 'numBytes' bytes from the stream into the supplied buffer.
         * \param pDest Pointer to a writable buffer of at least 'numBytes' bytes.
         * \param numBytes The number of bytes to read from the stream.
         * \return If non-negative, the number of bytes read by the operation. Returns eof (-1) when exhausted.
         */
        virtual int Read( char* pDest, int numBytes ) = 0;

        /**
         * Standard Max-like DeleteThis() for deleting objects across DLL boundaries.
         */
        virtual void DeleteThis() = 0;
    };

  public:
    virtual Interface_ID GetID() { return IMaxKrakatoaPRTSource_ID; }

    /**
     * Creates a new stream object at the specified time.
     * \param t The scene time to create the stream.
     * \param outValidity Will be set to the interval that this stream is valid for.
     * \return A new Stream object. It is assumed that this stream contains a PRT file.
     */
    virtual Stream* CreateStream( TimeValue t, Interval& outValidity ) = 0;
};
