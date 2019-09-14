#include <cudaTriangles.h>


template <unsigned int blockSize>
__device__ void warpReduce(volatile int *sdata, unsigned int tid) {
if (blockSize >= 64) sdata[tid] += sdata[tid + 32];
if (blockSize >= 32) sdata[tid] += sdata[tid + 16];
if (blockSize >= 16) sdata[tid] += sdata[tid + 8];
if (blockSize >= 8) sdata[tid] += sdata[tid + 4];
if (blockSize >= 4) sdata[tid] += sdata[tid + 2];
if (blockSize >= 2) sdata[tid] += sdata[tid + 1];
}

template <unsigned int blockSize>
// __global__ void reduce6(int *g_idata, int *g_odata, unsigned int n)
__global__ void triangleSum(int *rowIndex_dev, int *colIndex_dev, pair *pairs_cm_dev, pair *pairs_rm_dev, int nze, int N, int *triangle_sum){
    extern __shared__ sdata[];
    unsigned int tid = threadIdx.x;
    unsigned int i = blockIdx.x*blockDim.x + threadIdx.x;






    // map reduce the sums of each pair 
    sdata[tid] = sum_i;
    __syncthreads();

    for (unsigned int s=blockDim.x/2; s>0; s>>=1) {
        if (tid < s) {
            sdata[tid] += sdata[tid + s];
        }
        __syncthreads();
    }
    // write result for this block to global mem

    if (tid == 0) (*triangle_sum) = sdata[0];


}
