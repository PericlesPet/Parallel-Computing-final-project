#ifndef CUDATRIANGLES_H
#define CUDATRIANGLES_H

#include <stdio.h>
#include <stdbool.h>
#include <string.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <sys/time.h>
#include <float.h>
#include <iostream>
#include "utils.h"

#include <stdint.h>

__global__ void triangleSum(int *rowIndex_dev, int *colIndex_dev, pair *pairs_cm_dev, pair *pairs_rm_dev, int nze, int N, int *triangle_sum);




#endif
