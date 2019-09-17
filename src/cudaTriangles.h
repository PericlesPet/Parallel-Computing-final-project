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

// __global__ void triangleSum(int *rowIndex_dev, int *colIndex_dev, pair *pairs_cm_dev, pair *pairs_rm_dev, int nze, int N, int *triangle_sum);
// __global__ void triangleSum(int **row_arr_pointer, pair *pairs_rm_dev, int nze, int N, int *triangle_sum);
__global__ void triangleSum(int *allRowsArray_dev, int *nzeCummus_dev, pair *pairs_rm_dev, int nze, int N, int *triangle_sum);


// __device__ int sumForPair(int *rowIndex_dev, int *colIndex_dev, pair *pairs_cm_dev, pair *pairs_rm_dev, int nze, int N, int index);

__host__ __device__ void allRowNze(int row, int **row_arr,int *rowNzeCount,int *rowIndex_dev, int *colIndex_dev, pair *pairs_cm_dev, pair *pairs_rm_dev, int nze, int N);

__device__ int commonElementCount(int *row_arr, int rowNzeCount, int *col_arr,int colNzeCount, int row, int col);

#endif
