
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
  // int N = 1<<20;
  // float *x, *y;

  int *rowVec;
  int *colVec;
  int N;
  int nze;

  int *rowIndex;
  int *colIndex;

  char *filepath = "graphs/chesapeake.mtx";
  
  readMtxFile(filepath, &rowVec, &colVec, &N, &nze);
  separateRows(nze, N, rowVec, colVec, &rowIndex);
  // printf("main: nze = %d, N = %d \n rowVec[0] = %d, colVec[0] = %d\n",nze,N,rowVec[0],colVec[0]);

  pairsort(colVec, rowVec, nze);
  
  separateRows(nze,N, colVec, rowVec, &colIndex);

  // for(int i=0;i<nze;i++){
  //   printf("%d. (%d , %d) \n",i,colVec[i],rowVec[i]);
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


