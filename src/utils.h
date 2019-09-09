#ifndef UTILS_H
#define UTILS_H

#include <string.h>
#include <stdlib.h>
#include <stdio.h>

void readMtxFile(char *filename, int **rowVec, int **colVec, int *N, int *nze);

double get_time();


#endif