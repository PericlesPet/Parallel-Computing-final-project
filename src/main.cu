
#include "test.h"
#include "args.h"
#include "utils.h"
#include "cudaTriangles.h"

#include <assert.h>
#include <cuda.h>
#include <cuda_runtime.h>

// Convenience function for checking CUDA runtime API results
// can be wrapped around any runtime API call. No-op in release builds. 
// reference: https://github.com/NVIDIA-developer-blog/code-samples/blob/master/series/cuda-cpp/coalescing-global/coalescing.cu
// e.g.: checkCuda( cudaMalloc(&d_a, n * 33 * sizeof(T)) );
// e.g.: kernel<<< x,y >>>()
//       checkCuda( cudaGetLastError() );
inline
cudaError_t checkCuda(cudaError_t result)
{
#if defined(DEBUG) || defined(_DEBUG)
  if (result != cudaSuccess) {
    fprintf(stderr, "CUDA Runtime Error: %s\n", cudaGetErrorString(result));
    assert(result == cudaSuccess);
  }
#endif
  return result;
}


int main(void)
{
  
  // PARAMETERS
  int blockMultiplier = 1;
  int threadMultiplier = 1;


  //VAR DECLARATIONS
  int *rowVec;
  int *colVec;
  int N;
  int nze;
  int *rowIndex;
  int *colIndex;
  char *filepath = "graphs/chesapeake.mtx";
  

  // READ SPARSE MATRIX FROM FILE
  readMtxFile(filepath, &rowVec, &colVec, &N, &nze);
    
  //  STORE ROWS  : from rowVec, colVec --> pairs_rm, rowIndex

  // Find indeces of separate sparse rows --> assigns rowIndex array
  separateRows(nze, N, rowVec, colVec, &rowIndex);
  //row major pair array
  struct pair *pairs_rm;
  struct pair *pairs_rm_dev;
  cudaMallocHost(&pairs_rm,sizeof(pair)*nze);
  cudaMalloc(&pairs_rm_dev,sizeof(pair)*nze);
  // unify vectors into pair array
  arraysToPairs(rowVec, colVec, nze, pairs_rm);
  
  // Sort vectors Column-wise
  pairsort(colVec, rowVec, nze);
  
  // COLUMNS
  // Find indeces of separate sparse columns --> assigns colIndex array
  separateRows(nze,N, colVec, rowVec, &colIndex);
  //column major pair array
  struct pair *pairs_cm;
  struct pair *pairs_cm_dev;
  cudaMallocHost(&pairs_cm,sizeof(pair)*nze);
  cudaMalloc(&pairs_cm_dev, sizeof(pair)*nze);
  // unify vectors into pair array
  arraysToPairs(rowVec, colVec, nze, pairs_cm);


  // struct pair *pairs_cm_dev, *pairs_rm_dev;
  int *colIndex_dev, *rowIndex_dev;

  cudaMalloc(&colIndex_dev, sizeof(int)*N);
  cudaMalloc(&rowIndex_dev, sizeof(int)*N);

  // declare pair arrays directly for device use
  cudaMemcpy(pairs_cm_dev,pairs_cm, sizeof(pair)*nze,cudaMemcpyHostToDevice);
  cudaMemcpy(pairs_rm_dev,pairs_rm, sizeof(pair)*nze,cudaMemcpyHostToDevice);
  cudaMemcpy(colIndex_dev,colIndex, sizeof(int)*N,cudaMemcpyHostToDevice);
  cudaMemcpy(rowIndex_dev,rowIndex, sizeof(int)*N,cudaMemcpyHostToDevice);

  // colVec & rowVec no longer needed
  free(colVec);
  free(rowVec);
  
  // Get Device Properties 
  int deviceId;
  cudaGetDevice(&deviceId);
  cudaDeviceProp props;
  cudaGetDeviceProperties(&props, deviceId);
  int warpsize = props.warpSize;         // Warp Size
  int SMs = props.multiProcessorCount;  //Streaming Multiprocessors

  int blocks = blockMultiplier * SMs;
  int threads = threadMultiplier * warpsize; 

  printf("blocks = %d, threads = %d \n",blocks,threads);
  
  // triangleSum array will have ceil(nze/blockDim.x) / blocks size
  int *triangleSum_host;
  cudaMallocHost(&triangleSum_host, sizeof(int)*blocks);
  int *triangleSum_dev;
  cudaMalloc(&triangleSum_dev,sizeof(int)*blocks);


  triangleSum<<<blocks,threads,sizeof(int)*threads>>>(rowIndex_dev, colIndex_dev, pairs_cm_dev, pairs_rm_dev, nze, N, triangleSum_dev);

  checkCuda( cudaGetLastError() );
  checkCuda(cudaDeviceSynchronize());
  checkCuda(cudaMemcpy(triangleSum_host, triangleSum_dev,sizeof(int)*blocks,cudaMemcpyDeviceToHost));  
  checkCuda(cudaFree(triangleSum_dev));

  // printf(" --> sum is: \n");
  for(int i=0;i<blocks;i++){
    printf(" ooo array = %d\n",triangleSum_host[i]);
  }
  int cudaSum = quickSum(triangleSum_host, blocks);

  int *quickArr = (int *)malloc(sizeof(int)*nze);
  for(int i=0;i<nze;i++){
    quickArr[i] = pairs_cm[i].row;
  }
  int realSum = quickSum(quickArr, nze);
  // int realSum = quickSum(rowIndex, N);
  printf(" --> sum is: %d , realSum is: %d\n",cudaSum,realSum);
  // for(int i=0;i<N;i++){
  //   printf("%d. (%d) \n",i,rowIndex[i]);
  //   // printf("%d. (%d , %d) \n\n",i,pairs_cm[i].col,pairs_cm[i].row);
  // }
  



  // cudaFree(x);
  // cudaFree(y);
  
  return 0;
}


