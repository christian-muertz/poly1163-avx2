#include <stdio.h>
#include <stdlib.h>

#include <getopt.h>

#include <math.h>
#include <string.h>
#include <ctype.h>

#include <openssl/sha.h>
#include <stdbool.h>

#include "../src/poly1163.h"

void print_hex(const unsigned char *data, size_t len) {
    for (size_t i = 0; i < len; i++) {
        printf("%02X ", data[i]); 
    }
    printf("\n");
}

int main() {
    uint8_t key[] = {
        0x3A, 0x7F, 0xC2, 0x1D, 0x55, 0x9B, 0xE0, 0x4C, 
        0x8A, 0x2E, 0x73, 0x6D, 0xF1, 0x90, 0x12, 0x38, 
        0xA4, 0xB6, 0x05, 0xE9, 0xD7, 0x30, 0x19, 0xCB, 
        0x84, 0xFE, 0x6A, 0x41, 0x97, 0x20, 0xDA, 0x11
    };

    uint8_t data[] = "Hello World!";

    uint8_t tag[16]; 

    POLY1163_CTX ctx;
    poly1163_init(&ctx, key);
    poly1163_update(&ctx, data, 1024);
    poly1163_finalize(&ctx, tag);

    printf("Key: "); print_hex(key, 32);
    printf("Data: "); print_hex(data, 12);
    printf("Tag: "); print_hex(tag, 16);
}