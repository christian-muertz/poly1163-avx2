## 🚀 Highly Optimized Poly1163 and ChaCha20-Poly1163 AVX2 Implementations

This repository contains highly optimized implementations of Poly1163 and ChaCha20-Poly1163 [Link to report]. We provide four variants with different carry delays: Immediate, 2-Delayed, 4-Delayed, and 6-Delayed.

TABLE

## Structure
```
examples/                        ; Examples of how to use Poly1163 and ChaCha20-Poly1163
src/
    poly1163.c                   ; C implementation of the Poly1163 MAC
    chacha20_poly1163.c          ; Full AEAD scheme: ChaCha20-Poly1163
    asm/
        generate.py              ; Generates assembly for various carry delays
        chacha20.s               ; High-performance ChaCha20 implementation from OpenSSL 3.0
        tuned/                   ; Tuned implementations for Immediate, 2-Delay, 4-Delay, and 6-Delay
        untuned/                 ; Raw output from generate.py for various carry delays
    tune/
        tune.py                  ; Tuning script that iteratively tunes an untuned assembly for the current machine
    bench/
        bench.c                  ; Benchmarks Poly1163 and ChaCha20-Poly1163
```