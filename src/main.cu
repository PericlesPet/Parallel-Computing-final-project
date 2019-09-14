
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



// Kernel function to add the elements of two arrays
__global__
void add(int n, float *x, float *y)
{
  for (int i = 0; i < n; i++)
    y[i] = x[i] + y[i];
}

int main(void)
{
  
  // PARAMETERS
  int blockMultiplier = 4;
  int threadMultiplier = 4;


  //VAR DECLARATIONS
  int *rowVec;
  int *colVec;
  int N;
  int nze;
  int *rowIndex;
  int *colIndex;
  char *filepath = "graphs/chesapeake.mtx";
  
  readMtxFile(filepath, &rowVec, &colVec, &N, &nze);
  printf("hi");
    
  // ROWS
  // Find indeces of separate sparse rows --> assigns rowIndex array
  separateRows(nze, N, rowVec, colVec, &rowIndex);
  //row major pair array
  struct pair *pairs_rm;
  cudaMallocHost(&pairs_rm,sizeof(pair)*nze);
  // unify vectors into pair array
  arraysToPairs(rowVec, colVec, nze, pairs_rm);
  
  // Sort vectors Column-wise
  pairsort(colVec, rowVec, nze);
  
  // COLUMNS
  // Find indeces of separate sparse columns --> assigns colIndex array
  separateRows(nze,N, colVec, rowVec, &colIndex);
  //column major pair array
  struct pair *pairs_cm;
  cudaMallocHost(&pairs_cm,sizeof(pair)*nze);
  // unify vectors into pair array
  arraysToPairs(rowVec, colVec, nze, pairs_cm);


  struct pair *pairs_cm_dev, *pairs_rm_dev;
  int *colIndex_dev, *rowIndex_dev;

  // declare pair arrays directly for device use
  cudaMemcpy(pairs_cm_dev,pairs_cm, sizeof(pair)*nze,cudaMemcpyHostToDevice);
  cudaMemcpy(pairs_rm_dev,pairs_rm, sizeof(pair)*nze,cudaMemcpyHostToDevice);
  cudaMemcpy(colIndex_dev,colIndex, sizeof(int)*nze,cudaMemcpyHostToDevice);
  cudaMemcpy(rowIndex_dev,rowIndex, sizeof(int)*nze,cudaMemcpyHostToDevice);

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

  // triangle-sum<<<blocks,threads>>>(rowIndex_dev, colIndex_dev, pairs_cm_dev, pairs_rm_dev, nze, N);

  // for(int i=0;i<nze;i++){
  //   printf("%d. (%d , %d) \n",i,colVec[i],rowVec[i]);
  //   printf("%d. (%d , %d) \n\n",i,pairs_cm[i].col,pairs_cm[i].row);
  // }
  



  // // Allocate Unified Memory – accessible from CPU or GPU
  // cudaMallocManaged(&x, N*sizeof(float));
  // cudaMallocManaged(&y, N*sizeof(float));

  // // initialize x and y arrays on the host
  // for (int i = 0; i < N; i++) {
  //   x[i] = 1.0f;
  //   y[i] = 2.0f;
  // }

  // // Run kernel on 1M elements on the GPU
  // add<<<1, 1>>>(N, x, y);

  // // Wait for GPU to finish before accessing on host
  // cudaDeviceSynchronize();

  // // Check for errors (all values should be 3.0f)
  // float maxError = 0.0f;
  // for (int i = 0; i < N; i++)
  //   maxError = fmax(maxError, fabs(y[i]-3.0f));
  // std::cout << "Max error: " << maxError << std::endl;

  // // Free memory
  // cudaFree(x);
  // cudaFree(y);
  
  return 0;
}


