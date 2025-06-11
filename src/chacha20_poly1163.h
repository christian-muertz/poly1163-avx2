#ifndef _AEAD_H_
#define _AEAD_H_

#include <stdlib.h>
#include <stdint.h>

int chacha20_poly1163_encrypt(
    const uint8_t *key,
    const uint8_t *nonce,
    const uint8_t *plaintext, size_t plaintext_len,
    const uint8_t *aad, size_t aad_len,
    uint8_t *ciphertext,
    uint8_t *tag
);

void chacha20_poly1163_decrypt(
    const uint8_t *key,
    const uint8_t *nonce,
    const uint8_t *ciphertext, size_t ciphertext_len,
    const uint8_t *aad, size_t aad_len,
    const uint8_t *tag,
    uint8_t *plaintext
);

#endif