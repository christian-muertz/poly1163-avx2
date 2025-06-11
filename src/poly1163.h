#ifndef _POLY_H_
#define _POLY_H_

#include <stdlib.h>

typedef struct {
    void* opaque;
} POLY1163_CTX;

void poly1163_init(POLY1163_CTX* ctx, unsigned char *key);

void poly1163_update(POLY1163_CTX* ctx, unsigned char *data, size_t len);

void poly1163_finalize(POLY1163_CTX* ctx, void* out);

#endif