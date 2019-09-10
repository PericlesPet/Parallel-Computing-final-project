#ifndef UTILS_H
#define UTILS_H

#include <string.h>
#include <stdlib.h>
#include <stdio.h>

void readMtxFile(char *filename, int **rowVec, int **colVec, int *N, int *nze);

void separateRows(int nze,int N,int *rowVec, int *colVec, int **rowIndex);

double get_time();


#endif