#include "poly1163.h"
#include "chacha20_poly1163.h"
#include <stdint.h>
#include <memory.h>

void ChaCha20_8x(unsigned char *out, const unsigned char *inp, size_t len, const unsigned int key[8], const unsigned int counter[4]);

uint64_t zero[] = {0,0,0,0};

int chacha20_poly1163_encrypt(
    const uint8_t *key,
    const uint8_t *nonce,
    const uint8_t *plaintext, size_t plaintext_len,
    const uint8_t *aad, size_t aad_len,
    uint8_t *ciphertext,
    uint8_t *tag
) {
    // Compute OTK & Initialize Poly1163 MAC
    uint8_t otk[32];
    uint32_t iv[] = {0,0,0,0};
    memcpy(iv + 1, nonce, 12);
    ChaCha20_8x((unsigned char*) otk, (unsigned char*) zero, 32, (unsigned int*) key, iv);

    POLY1163_CTX mac_ctx;
    poly1163_init(&mac_ctx, (unsigned char*) otk);

    // Encrypt plaintext
    iv[0] = 1;
    ChaCha20_8x(ciphertext, plaintext, plaintext_len, (unsigned int*) key, iv);

    // Compute tag
    poly1163_update(&mac_ctx, (unsigned char*) aad, aad_len);
    poly1163_update(&mac_ctx, (unsigned char*) ciphertext, plaintext_len);
    poly1163_update(&mac_ctx, (unsigned char*) &aad_len, 8);
    poly1163_update(&mac_ctx, (unsigned char*) &plaintext_len, 8);

    // Output tag
    poly1163_finalize(&mac_ctx, tag);

    return 0;
}

void chacha20_poly1163_decrypt(
    const uint8_t *key,
    const uint8_t *nonce,
    const uint8_t *ciphertext, size_t ciphertext_len,
    const uint8_t *aad, size_t aad_len,
    const uint8_t *tag,
    uint8_t *plaintext
) {}
