//
//  CubeMap.h
//  ComplexFilters
//
//  Created by ZhangAo on 27/09/2017.
//  Copyright © 2017 zhangao. All rights reserved.
//

#ifndef CubeMap_h
#define CubeMap_h

#include <stdio.h>
#include <stdlib.h>
#include <math.h>

struct CubeMap {
    int length;
    float dimension;
    float *data;
};

struct CubeMap createCubeMap(float h, float s, float v);
struct CubeMap createCubeMapWithHueRange(float minHueAngle, float maxHueAngle);
void rgbToHSV(float *rgb, float *hsv);

#endif /* CubeMap_h */
