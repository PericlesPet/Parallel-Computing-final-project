#ifndef UTILS_H
#define UTILS_H

#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <sys/time.h>

void readMtxFile(char *filename, int **rowVec, int **colVec, int *N, int *nze);

void separateRows(int nze,int N,int *rowVec, int *colVec, int **rowIndex);

double get_time();

struct pair {
    int row;
    int col;
};

void pairsort(int a[], int b[], int n);

int comparator(const void *p, const void *q);

void arraysToPairs(int *rowVec, int* colVec, int nze, pair *pairs);


int quickSum(int *arr, int N);

#endif