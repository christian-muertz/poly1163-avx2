# Semester Project - Christian Mürtz

## Highly Optimized Implementation of ChaCha20-Poly1163 for x86_84

The goal of this project is to develop a highly optimized AVX2 implementation of Poly1163 and integrate it with ChaCha20 to form the AEAD scheme ChaCha20-Poly1163. The Poly1163 implementation should ideally achieve significantly better performance than Poly1305 on modern x86 processors while maintaining the same security level. When combined with ChaCha20, it should result in a faster AEAD scheme with similar performance characteristics, making it suitable for use in the internet stack.

### Getting Started

1. Install all python modules (ideally in local venv):
```
python3 -m venv venv
source ./venv/bin/activate
pip3 install -r requirements
```

2. Make sure the following libraries and executables are available:
```
gcc, mold, libsodium, openssl
```

3. Build all executables:
```
make
```

4. Run misc/bench.py or any other evaluation scripts:
```
python3 misc/bench.py
python3 misc/measure.py
python3 misc/plot.py
...
```