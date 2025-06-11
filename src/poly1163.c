
#include <inttypes.h>
#include <immintrin.h>
#include <memory.h>
#include <stdio.h>

#include "poly1163.h"

#ifndef DELAYED
#define DELAYED 1
#endif

typedef unsigned __int128 uint128_t;

static inline uint128_t scalar128_mult(uint128_t a, uint128_t b)
{
    uint64_t a0 = (uint64_t)a & ((1L << 58) - 1);
    uint64_t a1 = a >> 58;
    uint64_t b0 = b & ((1L << 58) - 1);
    uint64_t b1 = b >> 58;
    uint64_t res0 = 0;
    uint64_t res1 = 0;

    uint128_t acc;
    uint128_t d[2] = {0};
    uint64_t c;
    uint64_t t;
    acc = ((uint128_t)a0 * b0);
    d[0] += acc;
    t = ((uint64_t)b1 * (3));
    acc = ((uint128_t)a1 * t);
    d[0] += acc;

    acc = ((uint128_t)a0 * b1);
    d[1] += acc;
    acc = ((uint128_t)a1 * b0);
    d[1] += acc;

    c = (uint64_t)((d[0]) >> 58);
    res0 = ((uint64_t)(d[0])) & (((((uint64_t)1) << 58) - 1));
    d[1] += c;
    c = (uint64_t)((d[1]) >> 58);
    res1 = ((uint64_t)(d[1])) & (((((uint64_t)1) << 58) - 1));
    c = ((uint64_t)c * 3);
    res0 += c;
    c = (uint64_t)((res0) >> 58);
    res0 = (res0) & (((((uint64_t)1) << 58) - 1));
    res1 += c;
    return (uint128_t)res0 + (((uint128_t)res1) << 58);
}

static inline uint128_t scalar128_carry(uint128_t a)
{
    uint64_t a0 = a & ((1L << 58) - 1);
    uint64_t a1 = a >> 58;

    uint64_t res0, res1;

    uint64_t c;
    c = (uint64_t)((a0) >> 58);
    res0 = ((uint64_t)(a0)) & (((((uint64_t)1) << 58) - 1));
    a1 += c;
    c = (uint64_t)((a1) >> 58);
    res1 = ((uint64_t)(a1)) & (((((uint64_t)1) << 58) - 1));

    // Reduction happening here
    c = ((uint64_t)c * 3);
    res0 += c;
    c = (uint64_t)((res0) >> 58);
    res0 = (res0) & (((((uint64_t)1) << 58) - 1));
    res1 += c;
    return ((uint128_t)res0) + ((uint128_t)res1 << 58);
}

static inline uint128_t scalar128_reduce(uint128_t a)
{
    a = scalar128_carry(a);
    uint64_t a0 = a & ((1L << 58) - 1);
    uint64_t a1 = a >> 58;

    uint64_t t0, t1;
    uint64_t res0, res1;

    uint64_t c;
    uint64_t mask;
    t0 = a0 + 3;
    c = (uint64_t)((t0) >> 58);
    t0 = ((uint64_t)(t0)) & (((((uint64_t)1) << 58) - 1));
    t1 = a1 + c;
    t1 += -((((uint64_t)1)) << 58);
    mask = (uint64_t)((t1) >> 63); // 1 if there was no carry in tval[1]
    mask += -1;                    // 111111... if there was a carry in tval[1] -> reduce
    t0 = (t0) & (mask);
    t1 = (t1) & (mask);
    mask = ~mask;
    res0 = ((a0) & (mask)) | (t0);
    res1 = ((a1) & (mask)) | (t1);
    return ((uint128_t)res0) + ((uint128_t)res1 << 58);
}

static inline uint128_t load64(const unsigned char* buf, uint64_t len)
{
    uint128_t val = ((*((uint128_t *)(buf))) & ((((uint128_t)1) << (len*8)) - 1));
    val |= (((uint128_t)1) << (len*8));
    return val;
}


static inline void load256(const unsigned char *in, __m256i *msg0, __m256i *msg1, __m256i *msg2, __m256i *msg3)
{
    __m256i lower29_mask = _mm256_set_epi64x((1 << 29) - 1, (1 << 29) - 1, (1 << 29) - 1, (1 << 29) - 1);
    __m256i lower25_mask = _mm256_set_epi64x((1 << 25) - 1, (1 << 25) - 1, (1 << 25) - 1, (1 << 25) - 1);

    __m256i a = _mm256_inserti128_si256(_mm256_loadu_si256((__m256i_u *)(in + 0)), _mm_loadu_si128((__m128i_u *)(in + 14)), 1);
    __m256i b = _mm256_inserti128_si256(_mm256_loadu_si256((__m256i_u *)(in + 2 * 14)), _mm_loadu_si128((__m128i_u *)(in + 3 * 14)), 1);
    *msg0 = _mm256_and_si256(_mm256_unpacklo_epi64(a, b), lower29_mask);
    *msg1 = _mm256_and_si256(_mm256_srli_epi64(_mm256_unpacklo_epi64(a, b), 29), lower29_mask);
    __m256i a_ = _mm256_bsrli_epi128(a, 7);
    __m256i b_ = _mm256_bsrli_epi128(b, 7);
    *msg2 = _mm256_and_si256(_mm256_srli_epi64(_mm256_unpacklo_epi64(a_, b_), 2), lower29_mask);
    *msg3 = _mm256_and_si256(_mm256_srli_epi64(_mm256_unpacklo_epi64(a_, b_), 31), lower25_mask);
    *msg3 = _mm256_or_si256(*msg3, _mm256_set1_epi64x(0x1 << 25)); // Add padbit
}


void print_int128(__int128 num)
{
    if (num == 0)
    {
        putchar('0');
        return;
    }

    char buffer[40]; // Sufficient for a 128-bit integer
    int i = 0;
    int is_negative = 0;

    if (num < 0)
    {
        is_negative = 1;
        num = -num;
    }

    while (num > 0)
    {
        buffer[i++] = '0' + (num % 10);
        num /= 10;
    }

    if (is_negative)
    {
        putchar('-');
    }

    while (i > 0)
    {
        putchar(buffer[--i]);
    }
}

void print_binary8(uint8_t val)
{
    for (int i = 7; i >= 0; i--)
    {
        putchar((val & (1 << i)) ? '1' : '0');
    }
}


void print_m256i_binary(__m256i var)
{
    uint8_t vals[32];                          // 256 bits = 32 x 8-bit values
    _mm256_storeu_si256((__m256i *)vals, var); // Store in memory

    for (int i = 0; i < 32; i++)
    {
        print_binary8(vals[i]); // Print each byte in binary
        putchar(' ');           // Separate bytes for readability
    }

    printf("\n");
}


inline void print_limbs_combined(__m256i a0, __m256i a1, __m256i a2, __m256i a3, const int index) {
    uint64_t hash_a_0 = _mm256_extract_epi64(a0, index);
    uint64_t hash_a_1 = _mm256_extract_epi64(a1, index);
    uint64_t hash_a_2 = _mm256_extract_epi64(a2, index);
    uint64_t hash_a_3 = _mm256_extract_epi64(a3, index);
    uint128_t hash_a_128 = (hash_a_0) + (((uint128_t) hash_a_1) << 29) + (((uint128_t) hash_a_2) << 2*29) + (((uint128_t) hash_a_3) << 3*29);

    print_int128(hash_a_128); printf("\n");
}

inline void print_limbs_single(__m256i a0, __m256i a1, __m256i a2, __m256i a3, const int index) {
    uint64_t hash_a_0 = _mm256_extract_epi64(a0, index);
    uint64_t hash_a_1 = _mm256_extract_epi64(a1, index);
    uint64_t hash_a_2 = _mm256_extract_epi64(a2, index);
    uint64_t hash_a_3 = _mm256_extract_epi64(a3, index);

    printf("a0=0x%lx a1=0x%lx a2=0x%lx a3=0x%lx\n", hash_a_0, hash_a_1, hash_a_2, hash_a_3);
}

void mac_setup() {}

typedef struct
{
    __m256i hash[4];                // the four hash limbs
    __m256i key_powers[DELAYED][7]; // r^4, r^8, ...
    __m256i keys_finalize[7];       // [r^4, r^2, r^3, r^1] <- one _m256i
    uint128_t key;
    uint128_t blind;
    uint8_t buf[DELAYED * 56];
    size_t remaining;
} __attribute__((aligned(32), packed)) Opaque;

Opaque global_opaque;
void poly1163_init(POLY1163_CTX *ctx, unsigned char *key)
{
    ctx->opaque = &global_opaque;
    Opaque *opaque = (Opaque *)ctx->opaque;

    uint128_t key_power1_128 = *((uint128_t *)key) & (((uint128_t)1 << 112) - 1);
    uint128_t key_power2_128 = scalar128_mult(key_power1_128, key_power1_128);
    uint128_t key_power3_128 = scalar128_mult(key_power1_128, key_power2_128);
    uint128_t key_power4_128 = scalar128_mult(key_power2_128, key_power2_128);

    // r^4
    uint32_t r4_0_32 = key_power4_128 & ((1L << 29) - 1);
    uint32_t r4_1_32 = (key_power4_128 >> 29) & ((1L << 29) - 1);
    uint32_t r4_2_32 = (key_power4_128 >> 2 * 29) & ((1L << 29) - 1);
    uint32_t r4_3_32 = (key_power4_128 >> 3 * 29) & ((1L << 29) - 1);
    __m256i r4_0 = _mm256_set1_epi64x(r4_0_32);
    __m256i r4_1 = _mm256_set1_epi64x(r4_1_32);
    __m256i r4_2 = _mm256_set1_epi64x(r4_2_32);
    __m256i r4_3 = _mm256_set1_epi64x(r4_3_32);
    __m256i s4_1 = _mm256_set1_epi64x(3 * r4_1_32);
    __m256i s4_2 = _mm256_set1_epi64x(3 * r4_2_32);
    __m256i s4_3 = _mm256_set1_epi64x(3 * r4_3_32);
    opaque->key_powers[0][0] = r4_0;
    opaque->key_powers[0][1] = r4_1;
    opaque->key_powers[0][2] = r4_2;
    opaque->key_powers[0][3] = r4_3;
    opaque->key_powers[0][4] = s4_1;
    opaque->key_powers[0][5] = s4_2;
    opaque->key_powers[0][6] = s4_3;

    uint128_t last_key_power = key_power4_128;
    for (int i = 1; i < DELAYED; i++)
    {
        uint128_t key_power = scalar128_mult(key_power4_128, last_key_power);
        last_key_power = key_power;

        uint32_t r4_0_32 = key_power & ((1L << 29) - 1);
        uint32_t r4_1_32 = (key_power >> 29) & ((1L << 29) - 1);
        uint32_t r4_2_32 = (key_power >> 2 * 29) & ((1L << 29) - 1);
        uint32_t r4_3_32 = (key_power >> 3 * 29) & ((1L << 29) - 1);

        __m256i r4_0 = _mm256_set1_epi64x(r4_0_32);
        __m256i r4_1 = _mm256_set1_epi64x(r4_1_32);
        __m256i r4_2 = _mm256_set1_epi64x(r4_2_32);
        __m256i r4_3 = _mm256_set1_epi64x(r4_3_32);
        __m256i s4_1 = _mm256_set1_epi64x(3 * r4_1_32);
        __m256i s4_2 = _mm256_set1_epi64x(3 * r4_2_32);
        __m256i s4_3 = _mm256_set1_epi64x(3 * r4_3_32);

        opaque->key_powers[i][0] = r4_0;
        opaque->key_powers[i][1] = r4_1;
        opaque->key_powers[i][2] = r4_2;
        opaque->key_powers[i][3] = r4_3;
        opaque->key_powers[i][4] = s4_1;
        opaque->key_powers[i][5] = s4_2;
        opaque->key_powers[i][6] = s4_3;
    }

    // Finalization keys
    uint32_t r1_0_32 = key_power1_128 & ((1L << 29) - 1);
    uint32_t r1_1_32 = (key_power1_128 >> 29) & ((1L << 29) - 1);
    uint32_t r1_2_32 = (key_power1_128 >> 2 * 29) & ((1L << 29) - 1);
    uint32_t r1_3_32 = (key_power1_128 >> 3 * 29) & ((1L << 29) - 1);

    uint32_t r2_0_32 = key_power2_128 & ((1L << 29) - 1);
    uint32_t r2_1_32 = (key_power2_128 >> 29) & ((1L << 29) - 1);
    uint32_t r2_2_32 = (key_power2_128 >> 2 * 29) & ((1L << 29) - 1);
    uint32_t r2_3_32 = (key_power2_128 >> 3 * 29) & ((1L << 29) - 1);

    uint32_t r3_0_32 = key_power3_128 & ((1L << 29) - 1);
    uint32_t r3_1_32 = (key_power3_128 >> 29) & ((1L << 29) - 1);
    uint32_t r3_2_32 = (key_power3_128 >> 2 * 29) & ((1L << 29) - 1);
    uint32_t r3_3_32 = (key_power3_128 >> 3 * 29) & ((1L << 29) - 1);

    opaque->keys_finalize[0] = _mm256_set_epi64x(r1_0_32, r3_0_32, r2_0_32, r4_0_32);
    opaque->keys_finalize[1] = _mm256_set_epi64x(r1_1_32, r3_1_32, r2_1_32, r4_1_32);
    opaque->keys_finalize[2] = _mm256_set_epi64x(r1_2_32, r3_2_32, r2_2_32, r4_2_32);
    opaque->keys_finalize[3] = _mm256_set_epi64x(r1_3_32, r3_3_32, r2_3_32, r4_3_32);
    opaque->keys_finalize[4] = _mm256_set_epi64x(3 * r1_1_32, 3 * r3_1_32, 3 * r2_1_32, 3 * r4_1_32);
    opaque->keys_finalize[5] = _mm256_set_epi64x(3 * r1_2_32, 3 * r3_2_32, 3 * r2_2_32, 3 * r4_2_32);
    opaque->keys_finalize[6] = _mm256_set_epi64x(3 * r1_3_32, 3 * r3_3_32, 3 * r2_3_32, 3 * r4_3_32);

    opaque->blind = *((uint128_t *)(key + 16));
    opaque->hash[0] = _mm256_setzero_si256();
    opaque->hash[1] = _mm256_setzero_si256();
    opaque->hash[2] = _mm256_setzero_si256();
    opaque->hash[3] = _mm256_setzero_si256();
    opaque->remaining = 0;
    opaque->key = key_power1_128;
}

void finalize_asm(uint8_t *, size_t, Opaque *opaque);

void poly1163_finalize(POLY1163_CTX *ctx, void *out)
{
    Opaque *opaque = (Opaque *)ctx->opaque;

    size_t remaining = opaque->remaining % (4 * 14);

    finalize_asm(opaque->buf, opaque->remaining - remaining, opaque);

    // Final adjustments
    int64_t hash_a_0 = _mm256_extract_epi64(opaque->hash[0], 0);
    int64_t hash_a_1 = _mm256_extract_epi64(opaque->hash[1], 0);
    int64_t hash_a_2 = _mm256_extract_epi64(opaque->hash[2], 0);
    int64_t hash_a_3 = _mm256_extract_epi64(opaque->hash[3], 0);
    uint128_t hash_a_128 = (hash_a_0) + (((uint128_t)hash_a_1) << 29) + (((uint128_t)hash_a_2) << 2 * 29) + (((uint128_t)hash_a_3) << 3 * 29);

    int64_t hash_b_0 = _mm256_extract_epi64(opaque->hash[0], 2);
    int64_t hash_b_1 = _mm256_extract_epi64(opaque->hash[1], 2);
    int64_t hash_b_2 = _mm256_extract_epi64(opaque->hash[2], 2);
    int64_t hash_b_3 = _mm256_extract_epi64(opaque->hash[3], 2);
    uint128_t hash_b_128 = (hash_b_0) + (((uint128_t)hash_b_1) << 29) + (((uint128_t)hash_b_2) << 2 * 29) + (((uint128_t)hash_b_3) << 3 * 29);

    int64_t hash_c_0 = _mm256_extract_epi64(opaque->hash[0], 1);
    int64_t hash_c_1 = _mm256_extract_epi64(opaque->hash[1], 1);
    int64_t hash_c_2 = _mm256_extract_epi64(opaque->hash[2], 1);
    int64_t hash_c_3 = _mm256_extract_epi64(opaque->hash[3], 1);
    uint128_t hash_c_128 = (hash_c_0) + (((uint128_t)hash_c_1) << 29) + (((uint128_t)hash_c_2) << 2 * 29) + (((uint128_t)hash_c_3) << 3 * 29);

    int64_t hash_d_0 = _mm256_extract_epi64(opaque->hash[0], 3);
    int64_t hash_d_1 = _mm256_extract_epi64(opaque->hash[1], 3);
    int64_t hash_d_2 = _mm256_extract_epi64(opaque->hash[2], 3);
    int64_t hash_d_3 = _mm256_extract_epi64(opaque->hash[3], 3);
    uint128_t hash_d_128 = (hash_d_0) + (((uint128_t)hash_d_1) << 29) + (((uint128_t)hash_d_2) << 2 * 29) + (((uint128_t)hash_d_3) << 3 * 29);

    uint128_t res = scalar128_reduce(hash_a_128 + hash_b_128 + hash_c_128 + hash_d_128);

    uint8_t *in = opaque->buf + opaque->remaining - remaining;

    while (remaining > 0)
    {
        res += load64(in, remaining >= 14 ? 14 : remaining);
        res = scalar128_mult(res, opaque->key);
        remaining -= remaining >= 14 ? 14 : remaining;
        in += 14;
    }
    res = scalar128_reduce(res);
    res += opaque->blind;

    *((uint128_t *)out) = res;
}

void core(const unsigned char *in, uint64_t len, Opaque *opaque);
void poly1163_update(POLY1163_CTX *ctx, uint8_t *in, size_t len)
{
    Opaque *opaque = (Opaque *)ctx->opaque;

    // Process current remaining
    if (opaque->remaining > 0 && opaque->remaining + len >= DELAYED * 56)
    {
        memcpy(opaque->buf + opaque->remaining, in, DELAYED * 56 - opaque->remaining);

        core(opaque->buf, DELAYED * 56, opaque);

        in += DELAYED * 56 - opaque->remaining;
        len -= DELAYED * 56 - opaque->remaining;
        opaque->remaining = 0;
    }

    size_t remaining = len % (DELAYED * 56);
    if (len - remaining > 0)
        core(in, len - remaining, opaque);

    // Schedule next remaining
    if (remaining > 0)
    {
        memcpy(opaque->buf + opaque->remaining, in + len - remaining, remaining);
        opaque->remaining += remaining;
    }
}
