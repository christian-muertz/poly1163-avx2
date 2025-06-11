#include <stdio.h>
#include <stdlib.h>

#include <getopt.h>

#include <math.h>
#include <string.h>
#include <ctype.h>

#include <openssl/sha.h>
#include <stdbool.h>

#include "./rdtsc.h"
#include "../src/poly1163.h"
#include "../src/chacha20_poly1163.h"

#include <sodium.h>

int compare_doubles(const void *a, const void *b)
{
    double arg1 = *(const double *)a;
    double arg2 = *(const double *)b;
    return (arg1 > arg2) - (arg1 < arg2);
}

typedef struct
{
    size_t count;
    double sum;
    double mean;
    double m2;
    double stdev;

    double *measurements;
} Measurement;

void measurement_init(Measurement *measurement, size_t count)
{
    measurement->count = 0;
    measurement->sum = 0;
    measurement->mean = 0;
    measurement->m2 = 0;
    measurement->stdev = 0;
    measurement->measurements = malloc(sizeof(double) * count);
}

void measurement_add(Measurement *measurement, double value)
{
    measurement->measurements[measurement->count] = value;
    measurement->count++;
    measurement->sum += value;

    double delta = value - measurement->mean;
    measurement->mean += delta / measurement->count;
    double delta2 = value - measurement->mean;
    measurement->m2 += delta * delta2;

    measurement->stdev = measurement->m2 / (measurement->count - 1);
}

void measurement_sort(Measurement *measurement)
{
    qsort(measurement->measurements, measurement->count, sizeof(double), compare_doubles);
}

void measurement_print(char *name, Measurement *measurement)
{
    printf("[%s] Average = %lf\n", name, measurement->mean);
    printf("[%s] Stdev = %lf\n", name, measurement->stdev);
    printf("[%s] 10 Percentile = %lf\n", name, measurement->measurements[measurement->count / 10]);
    printf("[%s] 50 Percentile = %lf\n", name, measurement->measurements[measurement->count / 2]);
    printf("[%s] 90 Percentile = %lf\n", name, measurement->measurements[9 * measurement->count / 10]);
    printf("[%s] Min = %lf\n", name, measurement->measurements[0]);
    printf("[%s] Max = %lf\n", name, measurement->measurements[measurement->count - 1]);
    printf("[%s] Raw = ", name);
    for (size_t i = 0; i < measurement->count; i++)
    {
        printf("%f,", measurement->measurements[i]);
    }
    printf("\n");
}

#define measure(measurement, block)                   \
    {                                                 \
        __asm__ volatile("" ::: "memory");            \
        uint64_t start = start_tsc();                 \
        block;                                        \
        uint64_t cycles = stop_tsc(start);            \
        __asm__ volatile("" ::: "memory");            \
        measurement_add(measurement, (double)cycles); \
    }

#define SIZE 128000
#define ITERS 10000

int main()
{
    if (sodium_init() < 0)
    {
        fprintf(stderr, "libsodium init failed\n");
        return EXIT_FAILURE;
    }

    uint8_t plaintext[SIZE];
    uint8_t ciphertext[SIZE];
    uint8_t tag[16];

    uint8_t key[32];
    uint8_t nonce[12];

    randombytes_buf(plaintext, SIZE);
    randombytes_buf(key, 32);
    randombytes_buf(nonce, 12);

    {
        Measurement measurement;
        measurement_init(&measurement, ITERS);

        for (size_t i = 0; i < ITERS; i++) {
            measure(&measurement, {
                chacha20_poly1163_encrypt(key, nonce, (uint8_t *)plaintext, SIZE, (uint8_t *)NULL, 0, ciphertext, tag);
            });
        }

        measurement_sort(&measurement);

        printf("ChaCha20-Poly1305: \n");
        printf("10 Percentile = %lf\n", (double)measurement.measurements[measurement.count / 10] / SIZE);
        printf("50 Percentile = %lf\n", (double)measurement.measurements[measurement.count / 2] / SIZE);
        printf("90 Percentile = %lf\n", (double)measurement.measurements[9 * measurement.count / 10] / SIZE);
        printf("Min = %lf\n", (double)measurement.measurements[0] / SIZE);
        printf("Max = %lf\n", (double)measurement.measurements[measurement.count - 1] / SIZE);
    }

    printf("==========================\n");

    {
        Measurement measurement;
        measurement_init(&measurement, ITERS);

        for (size_t i = 0; i < ITERS; i++)
        {
            POLY1163_CTX ctx;
            measure(&measurement, {
                poly1163_init(&ctx, key);
                poly1163_update(&ctx, plaintext, SIZE);
                poly1163_finalize(&ctx, tag);
            });
        }

        measurement_sort(&measurement);

        printf("Poly1163: \n");
        printf("10 Percentile = %lf\n", (double)measurement.measurements[measurement.count / 10] / SIZE);
        printf("50 Percentile = %lf\n", (double)measurement.measurements[measurement.count / 2] / SIZE);
        printf("90 Percentile = %lf\n", (double)measurement.measurements[9 * measurement.count / 10] / SIZE);
        printf("Min = %lf\n", (double)measurement.measurements[0] / SIZE);
        printf("Max = %lf\n", (double)measurement.measurements[measurement.count - 1] / SIZE);
    }
}