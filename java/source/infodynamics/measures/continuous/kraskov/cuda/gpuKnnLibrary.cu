#include "gpuKnnBF_kernel.cu"
#include <stdio.h>
#include "helperfunctions.cu"

#ifdef __cplusplus
extern "C" {
#endif
int cudaFindKnn(int* h_bf_indexes, float* h_bf_distances, float* h_pointset,
    float* h_query, int kth, int thelier, int nchunks, int pointdim,
    int signallength, unsigned int useMaxNorm) {
  float *d_bf_pointset, *d_bf_query;
  int *d_bf_indexes;
  float *d_bf_distances;

  unsigned int meminputsignalquerypointset= pointdim * signallength * sizeof(float);
  unsigned int mem_bfcl_outputsignaldistances= kth * signallength * sizeof(float);
  unsigned int mem_bfcl_outputsignalindexes = kth * signallength * sizeof(int);

  checkCudaErrors( cudaMalloc( (void**) &(d_bf_query), meminputsignalquerypointset));
  checkCudaErrors( cudaMalloc( (void**) &(d_bf_pointset), meminputsignalquerypointset));
  //GPU output
  checkCudaErrors( cudaMalloc( (void**) &(d_bf_distances), mem_bfcl_outputsignaldistances ));
  checkCudaErrors( cudaMalloc( (void**) &(d_bf_indexes), mem_bfcl_outputsignalindexes ));

  cudaError_t error = cudaGetLastError();
  if(error!=cudaSuccess){
    fprintf(stderr,"%s",cudaGetErrorString(error));
    return 0;
  }

  //Upload input data
  checkCudaErrors( cudaMemcpy(d_bf_query, h_query, meminputsignalquerypointset, cudaMemcpyHostToDevice ));
  checkCudaErrors( cudaMemcpy(d_bf_pointset, h_pointset, meminputsignalquerypointset, cudaMemcpyHostToDevice ));
  error = cudaGetLastError();
  if(error!=cudaSuccess){
    fprintf(stderr,"%s",cudaGetErrorString(error));
    return 0;
  }
  // Kernel parameters
  dim3 threads(1,1,1);
  dim3 grid(1,1,1);
  threads.x = 512;
  grid.x = (signallength-1)/threads.x + 1;
  int memkernel = kth*sizeof(float)*threads.x+\
          kth*sizeof(int)*threads.x;
  int triallength = signallength / nchunks;

  // Pointer to the function used to calculate norms
  normFunction_t *normFunction;
  cudaMalloc( (void **) &normFunction, sizeof(normFunction_t) );
  if (useMaxNorm) {
    cudaMemcpyFromSymbol(normFunction, pMaxNorm, sizeof(normFunction_t));
  } else {
    cudaMemcpyFromSymbol(normFunction, pSquareNorm, sizeof(normFunction_t));
  }

  // Launch kernel
  kernelKNNshared<<<grid.x, threads.x, memkernel>>>(d_bf_query, d_bf_pointset,
      d_bf_indexes, d_bf_distances, pointdim, triallength, signallength, kth,
      thelier, normFunction);

  checkCudaErrors( cudaDeviceSynchronize() );

  //Download result
  checkCudaErrors( cudaMemcpy( h_bf_distances, d_bf_distances, mem_bfcl_outputsignaldistances, cudaMemcpyDeviceToHost) );
  checkCudaErrors( cudaMemcpy( h_bf_indexes, d_bf_indexes, mem_bfcl_outputsignalindexes, cudaMemcpyDeviceToHost) );
  error = cudaGetLastError();
  if(error!=cudaSuccess){
    fprintf(stderr,"%s",cudaGetErrorString(error));
    return 0;
  }

  //Free resources
  checkCudaErrors(cudaFree(d_bf_query));
  checkCudaErrors(cudaFree(d_bf_pointset));
  checkCudaErrors(cudaFree(d_bf_distances));
  checkCudaErrors(cudaFree(d_bf_indexes));
  cudaFree(normFunction);
  // cudaDeviceReset();
  if(error!=cudaSuccess){
    fprintf(stderr,"%s",cudaGetErrorString(error));
    return 0;
  }
  
  return 1;
}
#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
extern "C" {
#endif
int cudaFindKnnSetGPU(int* h_bf_indexes, float* h_bf_distances,
    float* h_pointset, float* h_query, int kth, int thelier, int nchunks,
    int pointdim, int signallength, unsigned int useMaxNorm, int deviceid) {
  cudaSetDevice(deviceid);
  return cudaFindKnn(h_bf_indexes, h_bf_distances, h_pointset, h_query,
      kth, thelier, nchunks, pointdim, signallength, useMaxNorm);
}
#ifdef __cplusplus
}
#endif

/*
 * Range search being radius a vector of length number points in queryset/pointset
 */
#ifdef __cplusplus
extern "C" {
#endif
int cudaFindRSAll(int* h_bf_npointsrange, float* h_pointset, float* h_query,
    float* h_vecradius, int thelier, int nchunks, int pointdim,
    int signallength, unsigned int useMaxNorm) {

  float *d_bf_pointset, *d_bf_query, *d_bf_vecradius;
  int *d_bf_npointsrange;

  unsigned int meminputsignalquerypointset= pointdim * signallength * sizeof(float);
  unsigned int mem_bfcl_outputsignalnpointsrange= signallength * sizeof(int);
      unsigned int mem_bfcl_inputvecradius = signallength * sizeof(float);

  checkCudaErrors( cudaMalloc( (void**) &(d_bf_query), meminputsignalquerypointset));
  checkCudaErrors( cudaMalloc( (void**) &(d_bf_pointset), meminputsignalquerypointset));
  checkCudaErrors( cudaMalloc( (void**) &(d_bf_npointsrange), mem_bfcl_outputsignalnpointsrange ));
    checkCudaErrors( cudaMalloc( (void**) &(d_bf_vecradius), mem_bfcl_inputvecradius ));

    cudaError_t error = cudaGetLastError();
  if(error!=cudaSuccess){
    fprintf(stderr,"%s",cudaGetErrorString(error));
    return 0;
  }
  //Upload input data
  checkCudaErrors( cudaMemcpy(d_bf_query, h_query, meminputsignalquerypointset, cudaMemcpyHostToDevice ));
  checkCudaErrors( cudaMemcpy(d_bf_pointset, h_pointset, meminputsignalquerypointset, cudaMemcpyHostToDevice ));
    checkCudaErrors( cudaMemcpy(d_bf_vecradius, h_vecradius, mem_bfcl_inputvecradius, cudaMemcpyHostToDevice ));

    error = cudaGetLastError();
  if(error!=cudaSuccess){
    fprintf(stderr,"%s",cudaGetErrorString(error));
    return 0;
  }


  // Kernel parameters
  dim3 threads(1,1,1);
  dim3 grid(1,1,1);
  threads.x = 512;
  grid.x = (signallength-1)/threads.x + 1;
  int memkernel = sizeof(int)*threads.x;
  int triallength = signallength / nchunks;

  // Pointer to the function used to calculate norms
  normFunction_t *normFunction;
  cudaMalloc( (void **) &normFunction, sizeof(normFunction_t) );
  if (useMaxNorm) {
    cudaMemcpyFromSymbol(normFunction, pMaxNorm, sizeof(normFunction_t));
  } else {
    cudaMemcpyFromSymbol(normFunction, pSquareNorm, sizeof(normFunction_t));
  }

  // Launch kernel
  kernelBFRSAllshared<<< grid.x, threads.x, memkernel>>>(
          d_bf_query, d_bf_pointset, d_bf_npointsrange, pointdim,
          triallength, signallength, thelier, d_bf_vecradius, normFunction);

  checkCudaErrors(cudaDeviceSynchronize());

  checkCudaErrors( cudaMemcpy( h_bf_npointsrange, d_bf_npointsrange,mem_bfcl_outputsignalnpointsrange, cudaMemcpyDeviceToHost) );


  if(error!=cudaSuccess){
    fprintf(stderr,"%s",cudaGetErrorString(error));
    return 0;
  }

  // Free resources
  checkCudaErrors(cudaFree(d_bf_query));
  checkCudaErrors(cudaFree(d_bf_pointset));
  checkCudaErrors(cudaFree(d_bf_npointsrange));
  checkCudaErrors(cudaFree(d_bf_vecradius));
  checkCudaErrors(cudaFree(normFunction));
  cudaDeviceReset();
  if(error!=cudaSuccess){
    fprintf(stderr,"%s",cudaGetErrorString(error));
    return 0;
  }
  
  return 1;
}
#ifdef __cplusplus
}
#endif

#ifdef __cplusplus
extern "C" {
#endif
int cudaFindRSAllSetGPU(int* h_bf_npointsrange, float* h_pointset,
    float* h_query, float* h_vecradius, int thelier, int nchunks,
    int pointdim, int signallength, unsigned int useMaxNorm, int deviceid) {
  cudaSetDevice(deviceid);
  return cudaFindRSAll(h_bf_npointsrange, h_pointset, h_query, h_vecradius,
      thelier, nchunks, pointdim, signallength, useMaxNorm);
}
#ifdef __cplusplus
}
#endif


#ifdef __cplusplus
extern "C" {
#endif
int findRadiiAlgorithm2(float *radii, const float *data, const int *indexes,
    unsigned int k, unsigned int dim, unsigned int N) {

  unsigned int i, j;

  for (j = 0; j < N; j++) {
    radii[j] = 0.0f;
    for (i = 0; i < k; i++) {
      float d = maxMetricPoints(data + j, data + indexes[j + i*N], dim, N);
      if (d > radii[j]) {
        radii[j] = d;
      }
    }
  }

  return 1;

}
#ifdef __cplusplus
}
#endif



#ifdef __cplusplus
extern "C" {
#endif
int computeSumDigammas(float *sumDiGammas, int *nx, int *ny, unsigned int N) {

  int *d_nx, *d_ny;
  float *d_sumDiGammas;

  checkCudaErrors( cudaMalloc((void **) &d_nx, N * sizeof(int)) );
  checkCudaErrors( cudaMalloc((void **) &d_ny, N * sizeof(int)) );
  checkCudaErrors( cudaMalloc((void **) &d_sumDiGammas, sizeof(float)) );

  checkCudaErrors( cudaMemcpy(d_nx, nx, N*sizeof(int), cudaMemcpyHostToDevice) );
  checkCudaErrors( cudaMemcpy(d_ny, ny, N*sizeof(int), cudaMemcpyHostToDevice) );

  unsigned int threads_per_block = 512;
  dim3 n_blocks, n_threads;
  n_blocks.x = ((N % threads_per_block) != 0) ? (N / threads_per_block + 1) : (N / threads_per_block);
  n_threads.x = threads_per_block;

  printf("blocks = %i, threads = %i\n", n_blocks.x, n_threads.x);

  // reduce6<<<n_blocks, n_threads>>>(d_nx, d_ny, d_sumDiGammas, N);
  reduce1<<<n_blocks, n_threads>>>(d_nx, d_ny, d_sumDiGammas, N);

  checkCudaErrors( cudaDeviceSynchronize() );

  checkCudaErrors( cudaMemcpy(sumDiGammas, d_sumDiGammas, sizeof(float), cudaMemcpyDeviceToHost) );

  cudaFree(d_nx);
  cudaFree(d_ny);
  cudaFree(d_sumDiGammas);

  *sumDiGammas = 0.0;

  return 1;

}
#ifdef __cplusplus
}
#endif

