
#include "test.h"
// #include "args.h"
#include "utils.h"
#include "cudaTriangles.h"

#include <unistd.h>
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
#if defined(DEBUG) || !defined(DEBUG)
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
  int blockMultiplier = 32;
  int threadMultiplier = 2;
  
  // char *filepath = "graphs/chesapeake.mtx";
  char *filepath = "graphs/auto.mtx";
  // char *filepath = "graphs/great-britain_osm.mtx";
  // char *filepath = "graphs/delaunay_n22.mtx";
  // char *filepath = "graphs/delaunay_n10.mtx";

  //VAR DECLARATIONS
  int *rowVec;
  int *colVec;
  int N;
  int nze;
  int *rowIndex;
  int *colIndex;
  
  double time_start, time_end;

  printf("preprocessing...\n");
  time_start = get_time();
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
  
  printf("nze = %d, colVec[nze] = %d, colVec[nze] = %d\n", nze, colVec[nze-1], rowVec[nze-1]);

  // Sort vectors Column-wise
  pairsort(colVec, rowVec, nze);
  printf("\n\n");
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
  checkCuda(cudaGetDevice(&deviceId));
  cudaDeviceProp props;
  checkCuda(cudaGetDeviceProperties(&props, deviceId));
  int warpsize = props.warpSize;         // Warp Size
  int SMs = props.multiProcessorCount;  //Streaming Multiprocessors

  int blocks = blockMultiplier * SMs;
  int threads = threadMultiplier * warpsize; 

  
  // triangleSum array will have ceil(nze/blockDim.x) / blocks size
  int *triangleSum_host;
  cudaMallocHost(&triangleSum_host, sizeof(int)*blocks);
  int *triangleSum_dev;
  cudaMalloc(&triangleSum_dev,sizeof(int)*blocks);
  
  
  int **row_arr_pointer_device;
  int **row_arr_pointer_host = (int **)malloc(sizeof(int*)*N);
  
  checkCuda(cudaMalloc(&row_arr_pointer_device, sizeof(int)*N));

  
  int *row_arr_dev;
  
  int rowNzeCount = 0;
  
  int nzeCummu = 0;
  int *nzeCummus = (int *)malloc(sizeof(int)*N);
  int *allRowsArray = (int *)malloc(sizeof(int)*(2*nze+N));
  
  for(int i=0; i<N;i++){
    // if(i%100000==0){
    //   printf("i = %d\n", i);
    // }
    allRowNze(i, &(row_arr_pointer_host[i]),&rowNzeCount, rowIndex, colIndex, pairs_cm, pairs_rm, nze, N);
    
    // cudaMalloc(&row_arr_dev, sizeof(int)*rowNzeCount);
    
    nzeCummus[i] = nzeCummu;
    nzeCummu += rowNzeCount+1;
    
    allRowsArray[nzeCummus[i]] = row_arr_pointer_host[i][0];
    
    for(int j= 1 ;j<=rowNzeCount;j++){
      // printf(" %d" ,row_arr_pointer_host[i][j]);
      allRowsArray[j + nzeCummus[i]] = row_arr_pointer_host[i][j];
    }
  }  

  int *nzeCummus_dev;
  checkCuda(cudaMalloc(&nzeCummus_dev, sizeof(int)*N));
  int *allRowsArray_dev;
  checkCuda(cudaMalloc(&allRowsArray_dev, sizeof(int)*(2*nze+N)));

  
  checkCuda(cudaMemcpy(nzeCummus_dev, nzeCummus, sizeof(int)*N, cudaMemcpyHostToDevice));
  checkCuda(cudaMemcpy(allRowsArray_dev, allRowsArray, sizeof(int)*(2*nze+N), cudaMemcpyHostToDevice));
  

  
  


  
  // printf("time_start 2 = %f \n", time_start);
  
  time_end = get_time();
  printf("preprocessing took: %f secs \n", time_end-time_start);
  
  printf("\ninitiating kernel with: ");
  printf("blocks = %d, threads = %d \n",blocks,threads);
  time_start = get_time();

  // triangleSum<<<blocks,threads,sizeof(int)*threads>>>(rowIndex_dev, colIndex_dev, pairs_cm_dev, pairs_rm_dev, nze, N, triangleSum_dev);
  // triangleSum<<<blocks,threads,sizeof(int)*threads>>>(row_arr_pointer_device, pairs_rm_dev, nze, N, triangleSum_dev);
  triangleSum<<<blocks,threads,sizeof(int)*threads>>>(allRowsArray_dev, nzeCummus_dev, pairs_rm_dev, nze, N, triangleSum_dev);
  
  checkCuda( cudaGetLastError() );
  checkCuda(cudaDeviceSynchronize());
  time_end = get_time();
  // printf("time_end = %f \n", time_end);
  checkCuda(cudaMemcpy(triangleSum_host, triangleSum_dev,sizeof(int)*blocks,cudaMemcpyDeviceToHost));  
  checkCuda(cudaFree(triangleSum_dev));

  // printf(" --> sum is: \n");
  // for(int i=0;i<blocks;i++){
  //   printf(" ooo array = %d\n",triangleSum_host[i]);
  // }
  int cudaSum = quickSum(triangleSum_host, blocks);

  int *quickArr = (int *)malloc(sizeof(int)*nze);
  
  for(int i=0;i<nze;i++){
    quickArr[i] = pairs_cm[i].row;
  }
  // int realSum = quickSum(quickArr, nze);
  // int realSum = quickSum(rowIndex, N);
  printf("--> Result is: %d\n \n",cudaSum/3);
  printf(" time: %f seconds\n",time_end-time_start);
  // for(int i=0;i<N;i++){
  //   printf("%d. (%d) \n",i,rowIndex[i]);
  //   // printf("%d. (%d , %d) \n\n",i,pairs_cm[i].col,pairs_cm[i].row);
  // }
  



  // cudaFree(x);
  // cudaFree(y);
  
  return 0;
}


