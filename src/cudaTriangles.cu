#include "cudaTriangles.h"


__global__ void triangleSum(int *rowIndex_dev, int *colIndex_dev, pair *pairs_cm_dev, pair *pairs_rm_dev, int nze, int N, int *triangle_sum){
    extern __shared__ int sdata[];
    unsigned int tid = threadIdx.x;
    unsigned int i = blockIdx.x*blockDim.x + threadIdx.x;
    unsigned int stride = blockDim.x * gridDim.x;
    int sum_i;


    // int minBlocks = ceilf((float) N / (float) blockDim.x);
    int minBlocks = ceilf((float) nze / (float) blockDim.x);
    
    // printf("tid = %d, i = %d, stride = %d, N = %d, minBlocks = %d, blockDim = %d, minBlocks*blockDim = %d \n", tid,i,stride, N, minBlocks, blockDim.x, minBlocks*blockDim.x);
    // if(i<nze){
    // if(i==0){
        //     printf("minBlocks = %d")
    // }

    for(int index=i; index<minBlocks*blockDim.x;index+=stride){
        
        if(tid ==0){
            // printf(" ---- tid = %d, i = %d, stride = %d, N = %d, rowIndex_dev[0] = %d \n", tid,i,stride, N, rowIndex_dev[0] );
        }
        
        // if(index==8){
            // printf("lololol \n");
            if(index<nze){
            // sum_i = 1;
            // sum_i = pairs_cm_dev[index].row;
            sum_i = sumForPair(rowIndex_dev, colIndex_dev, pairs_cm_dev, pairs_rm_dev, nze, N, index);
            // sum_i = rowIndex_dev[index];
        }else{
            sum_i = 0;
        }
        // printf("tid = %d, i = %d, stride = %d, nze = %d, minBlocks = %d, blockDim = %d, index = %d, sum_i = %d \n", tid,i,stride, nze, minBlocks, blockDim.x, index, sum_i);
        // }
        
        
        
        
        
        
        // map reduce the sums of each pair 
        // sdata[tid] = rowIndex_dev[index];
        // printf(" <<>> tid = %d, i = %d, stride = %d, N = %d \n", tid,i,stride, N );
        sdata[tid] = sum_i;
        __syncthreads();
        
        for (unsigned int s=blockDim.x/2; s>0; s>>=1) {
            if (tid < s) {
                sdata[tid] += sdata[tid + s];
            }
            __syncthreads();
        }
        // write result for this block to global mem
        if (tid == 0){
            triangle_sum[blockIdx.x] += sdata[0];
            // printf("TriangleSum[%d] = %d \n\n",blockIdx.x,triangle_sum[blockIdx.x]);
        }   
        
    }
        
}
    


//returns the final result of matrix A*A.*A for position (pair[index].row , pair[index].col)
__device__ int sumForPair(int *rowIndex_dev, int *colIndex_dev, pair *pairs_cm_dev, pair *pairs_rm_dev, int nze, int N, int index){
    int row = pairs_rm_dev[index].row-1;
    int col = pairs_rm_dev[index].col-1;
    // printf(" XyXyX -- row = %d , col = %d \n",row,col);
    int *row_arr;
    int *col_arr;
    // int *row_arr = row_arr_p[row];
    // int *col_arr = row_arr_p[col];
    
    int rowNzeCount = 0;// = row_arr[0];
    int colNzeCount = 0; //= col_arr[0];
    // int rowNzeCount = row_arr[0];
    // int colNzeCount = col_arr[0];

    // printf("rowNzeCount & col = %d, %d \n", rowNzeCount, colNzeCount);
    allRowNze(row, &row_arr, &rowNzeCount, rowIndex_dev, colIndex_dev, pairs_cm_dev, pairs_rm_dev, nze, N);
    allRowNze(col, &col_arr, &colNzeCount, rowIndex_dev, colIndex_dev, pairs_cm_dev, pairs_rm_dev, nze, N);

    int pairResult = commonElementCount(row_arr, rowNzeCount, col_arr,colNzeCount, row, col); 

    free(row_arr);
    free(col_arr);
    //  = (int*)malloc(sizeof(int)*10);
    // printf("<---> sum for pair (%d, %d) = %d \n", col,row,pairResult);
    return pairResult;
}

// assign to *row_arr matrix all non-zero-elements of A's "row" row.
__device__ void allRowNze(int row, int **row_arr,int *rowNzeCount, int *rowIndex_dev, int *colIndex_dev, pair *pairs_cm_dev, pair *pairs_rm_dev, int nze, int N){
    int colElems = colIndex_dev[row+1]-colIndex_dev[row];
    int rowElems = rowIndex_dev[row+1]-rowIndex_dev[row];
    
    // to avoid extreme situations for out of bounds behavior... 
    int kappa = N;
    if(row==kappa-1){
        // printf("")
        colElems = nze-colIndex_dev[row];
        rowElems = nze-rowIndex_dev[row];   
    }

    int staticCol = colElems;
    int staticrow = rowElems;

    // printf("row = %d, colElems = %d, rowElems = %d \n", row, colElems, rowElems);
    //total elements =  col elems + row elems
    (*row_arr) = (int *)malloc(sizeof(int)*(colElems+rowElems+1));
    (*row_arr)[0] = colElems + rowElems;
    (*rowNzeCount) = (*row_arr)[0];
    // need 2 pairs to calculate distance between them
    struct pair prevElem;
    
    prevElem.row = 1;
    prevElem.col = row;   // ok thats a little mindfuck but its correct
    
    struct pair nextElem;

    int count = 0;
    int dist = 0;
    int totalDist = 0;
    
    while(colElems>0){

        nextElem = pairs_cm_dev[colIndex_dev[row]+count];  // get from 'row'-th column the 'count'-th nz element
        dist = (nextElem.row - prevElem.row) + (nextElem.col - prevElem.col);
        totalDist += dist;
        (*row_arr)[count+1] = totalDist;
        
        count ++;
        prevElem = nextElem;
        colElems--;
    }
    
    while(rowElems>0){
        
        nextElem = pairs_rm_dev[rowIndex_dev[row] + count - staticCol];  // get from 'row'-th rowumn the 'count-colElems'-th nz element
        dist = (nextElem.row - prevElem.row) + (nextElem.col - prevElem.col);
        totalDist += dist;
        (*row_arr)[count+1] = totalDist;
        
        count ++;
        prevElem = nextElem;
        rowElems--;
    }
    
    // if(count == (colElems+rowElems)){
        // printf("- - - YES: row = %d, rowNzeCount = %d, colElems = %d, rowElems = %d , count = %d\n",row,(*rowNzeCount),(staticCol),(staticrow),count);
    // }else{
        // printf("^ ^ ^ NO: row = %d, rowNzeCount = %d, colElems = %d, rowElems = %d , count = %d\n",row,(*rowNzeCount),(staticCol),(staticrow),count);
        // printf("nooooo\n");
    // }
    
    
    // *row_arr = (int *)malloc(sizeof(int)*10);
    // (*row_arr)[i] = 5;
}


__device__ int commonElementCount(int *row_arr, int rowNzeCount, int *col_arr,int colNzeCount, int row, int col){
    
    int rowCount = 0;
    int colCount = 0;
    int commonElements = 0;
    int intex = threadIdx.x;

    while(rowCount<rowNzeCount && colCount<colNzeCount){

        if(row_arr[rowCount+1]==col_arr[colCount+1]){
            commonElements++;
            rowCount++;
            colCount++;
    
        }else if(row_arr[rowCount+1]>col_arr[colCount+1]){        
            colCount++;
        }else if(row_arr[rowCount+1]<col_arr[colCount+1]){
            rowCount++;
        }

    }
    // int rowCount = rowNzeCount;
    // int colCount = colNzeCount;

    printf(">>>Row %d : elems = %d [", row, row_arr[0]);

    for(int i=1;i<=rowNzeCount;i++){
        printf(" %d",row_arr[i]);
        // if(intex ==0){
        // }
    }    
    printf("\n");
    // printf(" ]\n");

    printf(">>>Col %d : elems = %d [", col, col_arr[0]);
    for(int i=1;i<=colNzeCount;i++){
        printf("%d ",col_arr[i]);
    }    
    printf("\n");
    printf(">>> (%d X %d) common: %d \n", col+1, row+1, commonElements );

    // printf("")
    return commonElements;
}