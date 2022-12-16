-- Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
-- SPDX-License-Identifier: Apache-2.0
(
resetMaxFile #noprompt
theCount = 7
theTP = teapot segs:16 radius:10
for z = 1 to theCount do for y = 1 to theCount do for x = 1 to theCount do
(
			theClone = instance theTP
			theClone.pos = [x,y,z] * 20
			theClone.wirecolor = [x,y,z]*10
)
delete theTP	
viewport.setTM (matrix3 [0.707107,0.353553,-0.612372] [-0.707107,0.353553,-0.612372] [0,0.866025,0.5] [-0.76635,-101.591,-341.077])
)

--5: 19MB	19sec.	1,032,250
--6: 34MB	34sec.  1,783,728
--7: 54MB	55sec.	2,832,494