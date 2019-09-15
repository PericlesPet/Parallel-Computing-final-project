#include <cudaTriangles.h>


__global__ void triangleSum(int *rowIndex_dev, int *colIndex_dev, pair *pairs_cm_dev, pair *pairs_rm_dev, int nze, int N, int *triangle_sum){
    extern __shared__ int sdata[];
    unsigned int tid = threadIdx.x;
    unsigned int i = blockIdx.x*blockDim.x + threadIdx.x;
    unsigned int stride = blockDim.x * gridDim.x;
    int sum_i;

    int minBlocks = ceilf((float) N / (float) blockDim.x);
    // int minBlocks = ceilf((float) nze / (float) blockDim.x);
    
    // printf("tid = %d, i = %d, stride = %d, N = %d, minBlocks = %d, blockDim = %d, minBlocks*blockDim = %d \n", tid,i,stride, N, minBlocks, blockDim.x, minBlocks*blockDim.x);
    // if(i<nze){
    // if(i==0){
        //     printf("minBlocks = %d")
    // }

    for(int index=i; index<minBlocks*blockDim.x;index+=stride){
        if(tid ==0){
            printf(" ---- tid = %d, i = %d, stride = %d, N = %d, rowIndex_dev[0] = %d \n", tid,i,stride, N, rowIndex_dev[0] );
        }
        
        if(index<N){
            sum_i = rowIndex_dev[index];
        }else{
            sum_i = 0;
        }
        printf("tid = %d, i = %d, stride = %d, N = %d, minBlocks = %d, blockDim = %d, index = %d, sum_i = %d \n", tid,i,stride, N, minBlocks, blockDim.x, index, sum_i);
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
            printf("TriangleSum[%d] = %d \n\n",blockIdx.x,triangle_sum[blockIdx.x]);
        }   
        
    }
        
}
    