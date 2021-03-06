#ifndef GPUKNNLIBRARY_H
#define GPUKNNLIBRARY_H

#ifdef __cplusplus
extern "C" {
#endif
int cudaFindKnn(int* h_bf_indexes, float* h_bf_distances, float* h_pointset,
    float* h_query, int kth, int thelier, int nchunks, int pointdim,
    int signallength, unsigned int useMaxNorm);

int cudaFindKnnSetGPU(int* h_bf_indexes, float* h_bf_distances,
    float* h_pointset, float* h_query, int kth, int thelier, int nchunks,
    int pointdim, int signallength, unsigned int useMaxNorm, int deviceid);

int cudaFindRSAll(int* h_bf_npointsrange, float* h_pointset,
    float* h_query, float* h_vecradius, int thelier, int nchunks,
    int pointdim, int signallength, unsigned int useMaxNorm);

int cudaFindRSAllSetGPU(int* h_bf_npointsrange, float* h_pointset,
    float* h_query, float* h_vecradius, int thelier, int nchunks,
    int pointdim, int signallength, unsigned int useMaxNorm, int deviceid);

int findRadiiAlgorithm2(float *radii, const float *data, const int *indexes,
    unsigned int k, unsigned int dim, unsigned int N);

int computeSumDigammas(float *sumDiGammas, int *nx, int *ny, unsigned int N);

int computeSumDigammasChunks(float *sumDiGammas, int *nx, int *ny,
    int trialLength, int nchunks);

int parallelDigammas(float *digammas, int *nx, int *ny, int signallength);

void device_reset(void);

void gpuWarmUp(void);
#ifdef __cplusplus
}
#endif

#endif

