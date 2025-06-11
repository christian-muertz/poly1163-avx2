
.section .rodata
.align 32
mask29:
    .quad 0x1FFFFFFF, 0x1FFFFFFF, 0x1FFFFFFF, 0x1FFFFFFF
mask25:
    .quad 0x1FFFFFF, 0x1FFFFFF, 0x1FFFFFF, 0x1FFFFFF
padbit:
    .quad 0x2000000, 0x2000000, 0x2000000, 0x2000000

.text

#                           RDI          RSI         RDX
# core(const unsigned char* in, uint64_t len, State* state);
.globl core
core:
          
# Load hash from opaque
vmovdqa 0(%rdx),%ymm5
vmovdqa 32(%rdx),%ymm6
vmovdqa 64(%rdx),%ymm7
vmovdqa 96(%rdx),%ymm8

# Check if there is even something to process
cmp    $335,%rsi
jbe    .Return

# Load mask29
vmovdqa mask29(%rip),%ymm15


.p2align 5
.Loop_24x14:

# ##################################
# HASH = HASH * KEY24
# ##################################
# T0 = h2 s2 + h0 r0 + h3 s1 + h1 s3 
# T1 = h2 s3 + h1 r0 + h0 r1         + h3 s2
# T2 = h2 r0         + h1 r1 + h3 s3 + h0 r2
# T3 = h2 r1 + h3 r0         + h0 r3 + h1 r2

VPBROADCASTQ 1248(%rdx), %ymm0                 
VPBROADCASTQ 1280(%rdx), %ymm1                 
VPBROADCASTQ 1312(%rdx), %ymm2                 
VPBROADCASTQ 1408(%rdx), %ymm3                 
VPBROADCASTQ 1440(%rdx), %ymm4                 

VPMULUDQ %ymm7,%ymm3,%ymm9                           # T0 = hash2 * s2                      
VPMULUDQ %ymm7,%ymm4,%ymm10                           # T1 = hash2 * s3                      
VPMULUDQ %ymm7,%ymm0,%ymm11                           # T2 = hash2 * r0                      
VPMULUDQ %ymm7,%ymm1,%ymm12                           # T3 = hash2 * r1                      

VPMULUDQ 1376(%rdx),%ymm8,%ymm13                                 
VPADDQ %ymm13,%ymm9,%ymm9                               # T0 += hash3 * s1               
VPMULUDQ %ymm1,%ymm5,%ymm13                                                         
VPADDQ %ymm10,%ymm13,%ymm10                               # T1 += hash0 * r1               
VPMULUDQ %ymm1,%ymm6,%ymm13                                                         
VPADDQ %ymm13,%ymm11,%ymm11                               # T2 += hash1 * r1               

VPMULUDQ %ymm4,%ymm6,%ymm13                                                         
VPADDQ %ymm13,%ymm9,%ymm9                               # T0 += hash1 * s3               
VPMULUDQ %ymm4,%ymm8,%ymm13                                                         
VPADDQ %ymm13,%ymm11,%ymm11                               # T2 += hash3 * s3               
VPMULUDQ 1344(%rdx),%ymm5,%ymm13                                                      
VPADDQ %ymm12,%ymm13,%ymm12                               # T3 += hash0 * r3                

VPMULUDQ %ymm0,%ymm5,%ymm13                                                          
VPADDQ %ymm9,%ymm13,%ymm9                               # T0 += hash0 * r0                
VPMULUDQ %ymm0,%ymm6,%ymm13                                                          
VPADDQ %ymm13,%ymm10,%ymm10                               # T1 += hash1 * r0                
VPMULUDQ %ymm0,%ymm8,%ymm13                                                          
VPADDQ %ymm13,%ymm12,%ymm12                               # T3 += hash3 * r0                

VPMULUDQ %ymm2,%ymm5,%ymm13                                                          
VPADDQ %ymm11,%ymm13,%ymm11                               # T2 += hash0 * r2                
                                                                                         
VPMULUDQ %ymm2,%ymm6,%ymm13                                                          
VPADDQ %ymm13,%ymm12,%ymm12                               # T3 += hash1 * r2                
VPMULUDQ %ymm3,%ymm8,%ymm13                                                          
VPADDQ %ymm13,%ymm10,%ymm10                               # T1 += hash3 * s2                

# ##################################
# HASH += MSG * KEY20
# ##################################

VMOVDQU 0(%rdi),%ymm1                                     # Load in[0:14]                  
VINSERTI128 $1,14(%rdi),%ymm1,%ymm1                        # Load in[14:28]                
VMOVDQU 28(%rdi),%ymm4                              # Load in[28:42]                     
VINSERTI128 $1,42(%rdi),%ymm4,%ymm4                   # Load in[42:56]                     
VPUNPCKLQDQ %ymm4,%ymm1,%ymm0                                                             
VPSRLDQ $7,%ymm1,%ymm1                                                                      
VPSRLDQ $7,%ymm4,%ymm4                                                                      
VPSRLQ $29,%ymm0,%ymm2                                                              
VPAND  %ymm0,%ymm15,%ymm0                                                         
VPAND  %ymm2,%ymm15,%ymm2                                                         
VPUNPCKLQDQ %ymm4,%ymm1,%ymm7                                                             
VPSRLQ $31,%ymm7,%ymm8                                                              
VPSRLQ $2,%ymm7,%ymm7                                                               
VPAND  %ymm7,%ymm15,%ymm7                                                         
VPSRLQ $4,%ymm15,%ymm1                                                                  
VPAND  %ymm1,%ymm8,%ymm8                                                              
VPADDQ padbit(%rip),%ymm8,%ymm8                                                     

# Start multiply with key
VPBROADCASTQ 1024(%rdx), %ymm5                                      
VPBROADCASTQ 1056(%rdx), %ymm1
VPBROADCASTQ 1088(%rdx), %ymm6                                                          
VPBROADCASTQ 1184(%rdx), %ymm3     
VPBROADCASTQ 1216(%rdx), %ymm4

VPMULUDQ %ymm5,%ymm0,%ymm13                           # T0 = msg0 * r0              
VPADDQ %ymm13,%ymm9,%ymm9                                                                
VPMULUDQ %ymm1,%ymm0,%ymm13                           # T1 = msg0 * r1              
VPADDQ %ymm13,%ymm10,%ymm10                                                                
VPMULUDQ %ymm6,%ymm0,%ymm13                           # T2 = msg0 * r2              
VPADDQ %ymm13,%ymm11,%ymm11                                                                
VPMULUDQ 1120(%rdx),%ymm0,%ymm13                   
VPADDQ %ymm13,%ymm12,%ymm12                                                                

VPMULUDQ %ymm4,%ymm2,%ymm13                                                         
VPADDQ %ymm13,%ymm9,%ymm9                               # T0 += msg1 * s3                
VPMULUDQ %ymm5,%ymm2,%ymm13                                                         
VPADDQ %ymm13,%ymm10,%ymm10                               # T1 += msg1 * r0                
VPMULUDQ %ymm1,%ymm2,%ymm13                                                         
VPADDQ %ymm13,%ymm11,%ymm11                               # T2 += msg1 * r1                
VPMULUDQ %ymm6,%ymm2,%ymm13                                                         
VPADDQ %ymm13,%ymm12,%ymm12                               # T3 += msg1 * r2                

VPMULUDQ %ymm7,%ymm3,%ymm13                                                         
VPADDQ %ymm13,%ymm9,%ymm9                               # T0 += msg2 * s2                
VPMULUDQ %ymm7,%ymm4,%ymm13                                                         
VPADDQ %ymm13,%ymm10,%ymm10                               # T1 += msg2 * s3                
VPMULUDQ %ymm7,%ymm5,%ymm13                                                         
VPADDQ %ymm13,%ymm11,%ymm11                               # T2 += msg2 * r0                
VPMULUDQ %ymm7,%ymm1,%ymm13                                                         
VPADDQ %ymm13,%ymm12,%ymm12                               # T3 += msg2 * r1                

VPMULUDQ 1152(%rdx),%ymm8,%ymm13                                                    
VPADDQ %ymm13,%ymm9,%ymm9                               # T0 += msg3 * s1                
VPMULUDQ %ymm3,%ymm8,%ymm13                                                         
VPADDQ %ymm13,%ymm10,%ymm10                               # T1 += msg3 * s2                
VPMULUDQ %ymm4,%ymm8,%ymm13                                                         
VPADDQ %ymm13,%ymm11,%ymm11                               # T2 += msg3 * s3                
VPMULUDQ %ymm5,%ymm8,%ymm13                                                         
VPADDQ %ymm13,%ymm12,%ymm12                               # T3 += msg3 * r0                

# ##################################
# HASH += MSG * KEY16
# ##################################

VMOVDQU 56(%rdi),%ymm1                                     # Load in[0:14]                  
VINSERTI128 $1,70(%rdi),%ymm1,%ymm1                        # Load in[14:28]                
VMOVDQU 84(%rdi),%ymm4                              # Load in[28:42]                     
VINSERTI128 $1,98(%rdi),%ymm4,%ymm4                   # Load in[42:56]                     
VPUNPCKLQDQ %ymm4,%ymm1,%ymm0                                                             
VPSRLDQ $7,%ymm1,%ymm1                                                                      
VPSRLDQ $7,%ymm4,%ymm4                                                                      
VPSRLQ $29,%ymm0,%ymm2                                                              
VPAND  %ymm0,%ymm15,%ymm0                                                         
VPAND  %ymm2,%ymm15,%ymm2                                                         
VPUNPCKLQDQ %ymm4,%ymm1,%ymm7                                                             
VPSRLQ $31,%ymm7,%ymm8                                                              
VPSRLQ $2,%ymm7,%ymm7                                                               
VPAND  %ymm7,%ymm15,%ymm7                                                         
VPSRLQ $4,%ymm15,%ymm1                                                                  
VPAND  %ymm1,%ymm8,%ymm8                                                              
VPADDQ padbit(%rip),%ymm8,%ymm8                                                     

# Start multiply with key
VPBROADCASTQ 800(%rdx), %ymm5                                      
VPBROADCASTQ 832(%rdx), %ymm1
VPBROADCASTQ 864(%rdx), %ymm6                                                          
VPBROADCASTQ 960(%rdx), %ymm3     
VPBROADCASTQ 992(%rdx), %ymm4

VPMULUDQ %ymm5,%ymm0,%ymm13                           # T0 = msg0 * r0              
VPADDQ %ymm13,%ymm9,%ymm9                                                                
VPMULUDQ %ymm1,%ymm0,%ymm13                           # T1 = msg0 * r1              
VPADDQ %ymm13,%ymm10,%ymm10                                                                
VPMULUDQ %ymm6,%ymm0,%ymm13                           # T2 = msg0 * r2              
VPADDQ %ymm13,%ymm11,%ymm11                                                                
VPMULUDQ 896(%rdx),%ymm0,%ymm13                   
VPADDQ %ymm13,%ymm12,%ymm12                                                                

VPMULUDQ %ymm4,%ymm2,%ymm13                                                         
VPADDQ %ymm13,%ymm9,%ymm9                               # T0 += msg1 * s3                
VPMULUDQ %ymm5,%ymm2,%ymm13                                                         
VPADDQ %ymm13,%ymm10,%ymm10                               # T1 += msg1 * r0                
VPMULUDQ %ymm1,%ymm2,%ymm13                                                         
VPADDQ %ymm13,%ymm11,%ymm11                               # T2 += msg1 * r1                
VPMULUDQ %ymm6,%ymm2,%ymm13                                                         
VPADDQ %ymm13,%ymm12,%ymm12                               # T3 += msg1 * r2                

VPMULUDQ %ymm7,%ymm3,%ymm13                                                         
VPADDQ %ymm13,%ymm9,%ymm9                               # T0 += msg2 * s2                
VPMULUDQ %ymm7,%ymm4,%ymm13                                                         
VPADDQ %ymm13,%ymm10,%ymm10                               # T1 += msg2 * s3                
VPMULUDQ %ymm7,%ymm5,%ymm13                                                         
VPADDQ %ymm13,%ymm11,%ymm11                               # T2 += msg2 * r0                
VPMULUDQ %ymm7,%ymm1,%ymm13                                                         
VPADDQ %ymm13,%ymm12,%ymm12                               # T3 += msg2 * r1                

VPMULUDQ 928(%rdx),%ymm8,%ymm13                                                    
VPADDQ %ymm13,%ymm9,%ymm9                               # T0 += msg3 * s1                
VPMULUDQ %ymm3,%ymm8,%ymm13                                                         
VPADDQ %ymm13,%ymm10,%ymm10                               # T1 += msg3 * s2                
VPMULUDQ %ymm4,%ymm8,%ymm13                                                         
VPADDQ %ymm13,%ymm11,%ymm11                               # T2 += msg3 * s3                
VPMULUDQ %ymm5,%ymm8,%ymm13                                                         
VPADDQ %ymm13,%ymm12,%ymm12                               # T3 += msg3 * r0                

# ##################################
# HASH += MSG * KEY12
# ##################################

VMOVDQU 112(%rdi),%ymm1                                     # Load in[0:14]                  
VINSERTI128 $1,126(%rdi),%ymm1,%ymm1                        # Load in[14:28]                
VMOVDQU 140(%rdi),%ymm4                              # Load in[28:42]                     
VINSERTI128 $1,154(%rdi),%ymm4,%ymm4                   # Load in[42:56]                     
VPUNPCKLQDQ %ymm4,%ymm1,%ymm0                                                             
VPSRLDQ $7,%ymm1,%ymm1                                                                      
VPSRLDQ $7,%ymm4,%ymm4                                                                      
VPSRLQ $29,%ymm0,%ymm2                                                              
VPAND  %ymm0,%ymm15,%ymm0                                                         
VPAND  %ymm2,%ymm15,%ymm2                                                         
VPUNPCKLQDQ %ymm4,%ymm1,%ymm7                                                             
VPSRLQ $31,%ymm7,%ymm8                                                              
VPSRLQ $2,%ymm7,%ymm7                                                               
VPAND  %ymm7,%ymm15,%ymm7                                                         
VPSRLQ $4,%ymm15,%ymm1                                                                  
VPAND  %ymm1,%ymm8,%ymm8                                                              
VPADDQ padbit(%rip),%ymm8,%ymm8                                                     

# Start multiply with key
VPBROADCASTQ 576(%rdx), %ymm5                                      
VPBROADCASTQ 608(%rdx), %ymm1
VPBROADCASTQ 640(%rdx), %ymm6                                                          
VPBROADCASTQ 736(%rdx), %ymm3     
VPBROADCASTQ 768(%rdx), %ymm4

VPMULUDQ %ymm5,%ymm0,%ymm13                           # T0 = msg0 * r0              
VPADDQ %ymm13,%ymm9,%ymm9                                                                
VPMULUDQ %ymm1,%ymm0,%ymm13                           # T1 = msg0 * r1              
VPADDQ %ymm13,%ymm10,%ymm10                                                                
VPMULUDQ %ymm6,%ymm0,%ymm13                           # T2 = msg0 * r2              
VPADDQ %ymm13,%ymm11,%ymm11                                                                
VPMULUDQ 672(%rdx),%ymm0,%ymm13                   
VPADDQ %ymm13,%ymm12,%ymm12                                                                

VPMULUDQ %ymm4,%ymm2,%ymm13                                                         
VPADDQ %ymm13,%ymm9,%ymm9                               # T0 += msg1 * s3                
VPMULUDQ %ymm5,%ymm2,%ymm13                                                         
VPADDQ %ymm13,%ymm10,%ymm10                               # T1 += msg1 * r0                
VPMULUDQ %ymm1,%ymm2,%ymm13                                                         
VPADDQ %ymm13,%ymm11,%ymm11                               # T2 += msg1 * r1                
VPMULUDQ %ymm6,%ymm2,%ymm13                                                         
VPADDQ %ymm13,%ymm12,%ymm12                               # T3 += msg1 * r2                

VPMULUDQ %ymm7,%ymm3,%ymm13                                                         
VPADDQ %ymm13,%ymm9,%ymm9                               # T0 += msg2 * s2                
VPMULUDQ %ymm7,%ymm4,%ymm13                                                         
VPADDQ %ymm13,%ymm10,%ymm10                               # T1 += msg2 * s3                
VPMULUDQ %ymm7,%ymm5,%ymm13                                                         
VPADDQ %ymm13,%ymm11,%ymm11                               # T2 += msg2 * r0                
VPMULUDQ %ymm7,%ymm1,%ymm13                                                         
VPADDQ %ymm13,%ymm12,%ymm12                               # T3 += msg2 * r1                

VPMULUDQ 704(%rdx),%ymm8,%ymm13                                                    
VPADDQ %ymm13,%ymm9,%ymm9                               # T0 += msg3 * s1                
VPMULUDQ %ymm3,%ymm8,%ymm13                                                         
VPADDQ %ymm13,%ymm10,%ymm10                               # T1 += msg3 * s2                
VPMULUDQ %ymm4,%ymm8,%ymm13                                                         
VPADDQ %ymm13,%ymm11,%ymm11                               # T2 += msg3 * s3                
VPMULUDQ %ymm5,%ymm8,%ymm13                                                         
VPADDQ %ymm13,%ymm12,%ymm12                               # T3 += msg3 * r0                

# ##################################
# HASH += MSG * KEY8
# ##################################

VMOVDQU 168(%rdi),%ymm1                                     # Load in[0:14]                  
VINSERTI128 $1,182(%rdi),%ymm1,%ymm1                        # Load in[14:28]                
VMOVDQU 196(%rdi),%ymm4                              # Load in[28:42]                     
VINSERTI128 $1,210(%rdi),%ymm4,%ymm4                   # Load in[42:56]                     
VPUNPCKLQDQ %ymm4,%ymm1,%ymm0                                                             
VPSRLDQ $7,%ymm1,%ymm1                                                                      
VPSRLDQ $7,%ymm4,%ymm4                                                                      
VPSRLQ $29,%ymm0,%ymm2                                                              
VPAND  %ymm0,%ymm15,%ymm0                                                         
VPAND  %ymm2,%ymm15,%ymm2                                                         
VPUNPCKLQDQ %ymm4,%ymm1,%ymm7                                                             
VPSRLQ $31,%ymm7,%ymm8                                                              
VPSRLQ $2,%ymm7,%ymm7                                                               
VPAND  %ymm7,%ymm15,%ymm7                                                         
VPSRLQ $4,%ymm15,%ymm1                                                                  
VPAND  %ymm1,%ymm8,%ymm8                                                              
VPADDQ padbit(%rip),%ymm8,%ymm8                                                     

# Start multiply with key
VPBROADCASTQ 352(%rdx), %ymm5                                      
VPBROADCASTQ 384(%rdx), %ymm1
VPBROADCASTQ 416(%rdx), %ymm6                                                          
VPBROADCASTQ 512(%rdx), %ymm3     
VPBROADCASTQ 544(%rdx), %ymm4

VPMULUDQ %ymm5,%ymm0,%ymm13                           # T0 = msg0 * r0              
VPADDQ %ymm13,%ymm9,%ymm9                                                                
VPMULUDQ %ymm1,%ymm0,%ymm13                           # T1 = msg0 * r1              
VPADDQ %ymm13,%ymm10,%ymm10                                                                
VPMULUDQ %ymm6,%ymm0,%ymm13                           # T2 = msg0 * r2              
VPADDQ %ymm13,%ymm11,%ymm11                                                                
VPMULUDQ 448(%rdx),%ymm0,%ymm13                   
VPADDQ %ymm13,%ymm12,%ymm12                                                                

VPMULUDQ %ymm4,%ymm2,%ymm13                                                         
VPADDQ %ymm13,%ymm9,%ymm9                               # T0 += msg1 * s3                
VPMULUDQ %ymm5,%ymm2,%ymm13                                                         
VPADDQ %ymm13,%ymm10,%ymm10                               # T1 += msg1 * r0                
VPMULUDQ %ymm1,%ymm2,%ymm13                                                         
VPADDQ %ymm13,%ymm11,%ymm11                               # T2 += msg1 * r1                
VPMULUDQ %ymm6,%ymm2,%ymm13                                                         
VPADDQ %ymm13,%ymm12,%ymm12                               # T3 += msg1 * r2                

VPMULUDQ %ymm7,%ymm3,%ymm13                                                         
VPADDQ %ymm13,%ymm9,%ymm9                               # T0 += msg2 * s2                
VPMULUDQ %ymm7,%ymm4,%ymm13                                                         
VPADDQ %ymm13,%ymm10,%ymm10                               # T1 += msg2 * s3                
VPMULUDQ %ymm7,%ymm5,%ymm13                                                         
VPADDQ %ymm13,%ymm11,%ymm11                               # T2 += msg2 * r0                
VPMULUDQ %ymm7,%ymm1,%ymm13                                                         
VPADDQ %ymm13,%ymm12,%ymm12                               # T3 += msg2 * r1                

VPMULUDQ 480(%rdx),%ymm8,%ymm13                                                    
VPADDQ %ymm13,%ymm9,%ymm9                               # T0 += msg3 * s1                
VPMULUDQ %ymm3,%ymm8,%ymm13                                                         
VPADDQ %ymm13,%ymm10,%ymm10                               # T1 += msg3 * s2                
VPMULUDQ %ymm4,%ymm8,%ymm13                                                         
VPADDQ %ymm13,%ymm11,%ymm11                               # T2 += msg3 * s3                
VPMULUDQ %ymm5,%ymm8,%ymm13                                                         
VPADDQ %ymm13,%ymm12,%ymm12                               # T3 += msg3 * r0                

# ##################################
# HASH += MSG * KEY4
# ##################################

VMOVDQU 224(%rdi),%ymm1                                     # Load in[0:14]                  
VINSERTI128 $1,238(%rdi),%ymm1,%ymm1                        # Load in[14:28]                
VMOVDQU 252(%rdi),%ymm4                              # Load in[28:42]                     
VINSERTI128 $1,266(%rdi),%ymm4,%ymm4                   # Load in[42:56]                     
VPUNPCKLQDQ %ymm4,%ymm1,%ymm0                                                             
VPSRLDQ $7,%ymm1,%ymm1                                                                      
VPSRLDQ $7,%ymm4,%ymm4                                                                      
VPSRLQ $29,%ymm0,%ymm2                                                              
VPAND  %ymm0,%ymm15,%ymm0                                                         
VPAND  %ymm2,%ymm15,%ymm2                                                         
VPUNPCKLQDQ %ymm4,%ymm1,%ymm7                                                             
VPSRLQ $31,%ymm7,%ymm8                                                              
VPSRLQ $2,%ymm7,%ymm7                                                               
VPAND  %ymm7,%ymm15,%ymm7                                                         
VPSRLQ $4,%ymm15,%ymm1                                                                  
VPAND  %ymm1,%ymm8,%ymm8                                                              
VPADDQ padbit(%rip),%ymm8,%ymm8                                                     

# Start multiply with key
VPBROADCASTQ 128(%rdx), %ymm5                                      
VPBROADCASTQ 160(%rdx), %ymm1
VPBROADCASTQ 192(%rdx), %ymm6                                                          
VPBROADCASTQ 288(%rdx), %ymm3     
VPBROADCASTQ 320(%rdx), %ymm4

VPMULUDQ %ymm5,%ymm0,%ymm13                           # T0 = msg0 * r0              
VPADDQ %ymm13,%ymm9,%ymm9                                                                
VPMULUDQ %ymm1,%ymm0,%ymm13                           # T1 = msg0 * r1              
VPADDQ %ymm13,%ymm10,%ymm10                                                                
VPMULUDQ %ymm6,%ymm0,%ymm13                           # T2 = msg0 * r2              
VPADDQ %ymm13,%ymm11,%ymm11                                                                
VPMULUDQ 224(%rdx),%ymm0,%ymm13                   
VPADDQ %ymm13,%ymm12,%ymm12                                                                

VPMULUDQ %ymm4,%ymm2,%ymm13                                                         
VPADDQ %ymm13,%ymm9,%ymm9                               # T0 += msg1 * s3                
VPMULUDQ %ymm5,%ymm2,%ymm13                                                         
VPADDQ %ymm13,%ymm10,%ymm10                               # T1 += msg1 * r0                
VPMULUDQ %ymm1,%ymm2,%ymm13                                                         
VPADDQ %ymm13,%ymm11,%ymm11                               # T2 += msg1 * r1                
VPMULUDQ %ymm6,%ymm2,%ymm13                                                         
VPADDQ %ymm13,%ymm12,%ymm12                               # T3 += msg1 * r2                

VPMULUDQ %ymm7,%ymm3,%ymm13                                                         
VPADDQ %ymm13,%ymm9,%ymm9                               # T0 += msg2 * s2                
VPMULUDQ %ymm7,%ymm4,%ymm13                                                         
VPADDQ %ymm13,%ymm10,%ymm10                               # T1 += msg2 * s3                
VPMULUDQ %ymm7,%ymm5,%ymm13                                                         
VPADDQ %ymm13,%ymm11,%ymm11                               # T2 += msg2 * r0                
VPMULUDQ %ymm7,%ymm1,%ymm13                                                         
VPADDQ %ymm13,%ymm12,%ymm12                               # T3 += msg2 * r1                

VPMULUDQ 256(%rdx),%ymm8,%ymm13                                                    
VPADDQ %ymm13,%ymm9,%ymm9                               # T0 += msg3 * s1                
VPMULUDQ %ymm3,%ymm8,%ymm13                                                         
VPADDQ %ymm13,%ymm10,%ymm10                               # T1 += msg3 * s2                
VPMULUDQ %ymm4,%ymm8,%ymm13                                                         
VPADDQ %ymm13,%ymm11,%ymm11                               # T2 += msg3 * s3                
VPMULUDQ %ymm5,%ymm8,%ymm13                                                         
VPADDQ %ymm13,%ymm12,%ymm12                               # T3 += msg3 * r0                


# ##################################
# Propagate the carry
# ##################################
                                                     
# hash0 -> hash1
VPSRLQ $29,%ymm9,%ymm13                                                             
VPADDQ %ymm10,%ymm13,%ymm10                                                          
VPAND %ymm15,%ymm9,%ymm9                                                          

# hash1 -> hash2
VPSRLQ $29,%ymm10,%ymm13                                                            
VPADDQ %ymm11,%ymm13,%ymm11                                                          
VPAND %ymm15,%ymm10,%ymm10                                                          

# hash2 -> hash3
VPSRLQ $29,%ymm11,%ymm13                                                        
VPADDQ %ymm12,%ymm13,%ymm12                                                       
VPAND %ymm15,%ymm11,%ymm11                                                       

# hash3 -> hash0
VPSRLQ $29,%ymm12,%ymm13                                                            
VPADDQ %ymm13,%ymm13,%ymm14                                                     
VPADDQ %ymm13,%ymm9,%ymm9                                                          
VPADDQ %ymm14,%ymm9,%ymm9                                                          
VPAND %ymm15,%ymm12,%ymm12                                                         
    
# hash0 -> hash1
VPSRLQ $29,%ymm9,%ymm13                                                               
VPADDQ %ymm10,%ymm13,%ymm10                                                          
VPAND %ymm15,%ymm9,%ymm9           

# ##################################
# LOADING MSG
# ##################################

VMOVDQU 280(%rdi),%ymm1                              
VINSERTI128 $1,294(%rdi),%ymm1,%ymm1             
VMOVDQU 308(%rdi),%ymm4                        
VINSERTI128 $1,322(%rdi),%ymm4,%ymm4             
VPUNPCKLQDQ %ymm4,%ymm1,%ymm5                                  
VPSRLDQ $7,%ymm1,%ymm1                                           
VPSRLDQ $7,%ymm4,%ymm4                                           
VPSRLQ $29,%ymm5,%ymm6                                   
VPAND  %ymm5,%ymm15,%ymm5                              
VPUNPCKLQDQ %ymm4,%ymm1,%ymm7                                  
VPAND  %ymm6,%ymm15,%ymm6                              
VPSRLQ $31,%ymm7,%ymm8                                   
VPSRLQ $2,%ymm7,%ymm7                                    
VPAND  %ymm7,%ymm15,%ymm7                              
VPSRLQ $4,%ymm15,%ymm1                                       
VPAND  %ymm1,%ymm8,%ymm8                                   
VPADDQ padbit(%rip),%ymm8,%ymm8                          

# ##################################
# HASH += MSG
# ##################################

VPADDQ %ymm9,%ymm5,%ymm5 
VPADDQ %ymm10,%ymm6,%ymm6 
VPADDQ %ymm11,%ymm7,%ymm7 
VPADDQ %ymm12,%ymm8,%ymm8 

# ##################################
                                                  
lea    336(%rdi),%rdi
sub    $336,%rsi
ja     .Loop_24x14


.Return:
vmovdqa %ymm5,0(%rdx)
vmovdqa %ymm6,32(%rdx)
vmovdqa %ymm7,64(%rdx)
vmovdqa %ymm8,96(%rdx)
ret  


.globl finalize_asm
finalize_asm:

vmovdqa 0(%rdx),%ymm5
vmovdqa 32(%rdx),%ymm6
vmovdqa 64(%rdx),%ymm7
vmovdqa 96(%rdx),%ymm8

vmovdqa mask29(%rip),%ymm15                     # Load mask29

# Do Loop_4x
# TODO skip loop if remaining < 4*14
cmp $56,%rsi
jb .Finalize_Fix


.p2align 5
Finalize_Loop:

# ##################################
# HASH = HASH * KEY4
# ##################################
# T0 = h2 s2 + h0 r0 + h3 s1 + h1 s3 
# T1 = h2 s3 + h1 r0 + h0 r1         + h3 s2
# T2 = h2 r0         + h1 r1 + h3 s3 + h0 r2
# T3 = h2 r1 + h3 r0         + h0 r3 + h1 r2

VPBROADCASTQ 128(%rdx), %ymm0                 
VPBROADCASTQ 160(%rdx), %ymm1                 
VPBROADCASTQ 192(%rdx), %ymm2                 
VPBROADCASTQ 288(%rdx), %ymm3                 
VPBROADCASTQ 320(%rdx), %ymm4                 

VPMULUDQ %ymm7,%ymm3,%ymm9                           # T0 = hash2 * s2                      
VPMULUDQ %ymm7,%ymm4,%ymm10                           # T1 = hash2 * s3                      
VPMULUDQ %ymm7,%ymm0,%ymm11                           # T2 = hash2 * r0                      
VPMULUDQ %ymm7,%ymm1,%ymm12                           # T3 = hash2 * r1                      

VPMULUDQ 256(%rdx),%ymm8,%ymm13                                 
VPADDQ %ymm13,%ymm9,%ymm9                               # T0 += hash3 * s1               
VPMULUDQ %ymm1,%ymm5,%ymm13                                                         
VPADDQ %ymm10,%ymm13,%ymm10                               # T1 += hash0 * r1               
VPMULUDQ %ymm1,%ymm6,%ymm13                                                         
VPADDQ %ymm13,%ymm11,%ymm11                               # T2 += hash1 * r1               

VPMULUDQ %ymm4,%ymm6,%ymm13                                                         
VPADDQ %ymm13,%ymm9,%ymm9                               # T0 += hash1 * s3               
VPMULUDQ %ymm4,%ymm8,%ymm13                                                         
VPADDQ %ymm13,%ymm11,%ymm11                               # T2 += hash3 * s3               
VPMULUDQ 224(%rdx),%ymm5,%ymm13                                                      
VPADDQ %ymm12,%ymm13,%ymm12                               # T3 += hash0 * r3                

VPMULUDQ %ymm0,%ymm5,%ymm13                                                          
VPADDQ %ymm9,%ymm13,%ymm9                               # T0 += hash0 * r0                
VPMULUDQ %ymm0,%ymm6,%ymm13                                                          
VPADDQ %ymm13,%ymm10,%ymm10                               # T1 += hash1 * r0                
VPMULUDQ %ymm0,%ymm8,%ymm13                                                          
VPADDQ %ymm13,%ymm12,%ymm12                               # T3 += hash3 * r0                

VPMULUDQ %ymm2,%ymm5,%ymm13                                                          
VPADDQ %ymm11,%ymm13,%ymm11                               # T2 += hash0 * r2                
                                                                                         
VPMULUDQ %ymm2,%ymm6,%ymm13                                                          
VPADDQ %ymm13,%ymm12,%ymm12                               # T3 += hash1 * r2                
VPMULUDQ %ymm3,%ymm8,%ymm13                                                          
VPADDQ %ymm13,%ymm10,%ymm10                               # T1 += hash3 * s2                


# ##################################
# Propagate the carry
# ##################################
                                                     
# hash0 -> hash1
VPSRLQ $29,%ymm9,%ymm13                                                             
VPADDQ %ymm10,%ymm13,%ymm10                                                          
VPAND %ymm15,%ymm9,%ymm9                                                          

# hash1 -> hash2
VPSRLQ $29,%ymm10,%ymm13                                                            
VPADDQ %ymm11,%ymm13,%ymm11                                                          
VPAND %ymm15,%ymm10,%ymm10                                                          

# hash2 -> hash3
VPSRLQ $29,%ymm11,%ymm13                                                        
VPADDQ %ymm12,%ymm13,%ymm12                                                       
VPAND %ymm15,%ymm11,%ymm11                                                       

# hash3 -> hash0
VPSRLQ $29,%ymm12,%ymm13                                                            
VPADDQ %ymm13,%ymm13,%ymm14                                                     
VPADDQ %ymm13,%ymm9,%ymm9                                                          
VPADDQ %ymm14,%ymm9,%ymm9                                                          
VPAND %ymm15,%ymm12,%ymm12                                                         
    
# hash0 -> hash1
VPSRLQ $29,%ymm9,%ymm13                                                               
VPADDQ %ymm10,%ymm13,%ymm10                                                          
VPAND %ymm15,%ymm9,%ymm9           

# ##################################
# LOADING MSG
# ##################################

VMOVDQU 0(%rdi),%ymm1                              
VINSERTI128 $1,14(%rdi),%ymm1,%ymm1             
VMOVDQU 28(%rdi),%ymm4                        
VINSERTI128 $1,42(%rdi),%ymm4,%ymm4             
VPUNPCKLQDQ %ymm4,%ymm1,%ymm5                                  
VPSRLDQ $7,%ymm1,%ymm1                                           
VPSRLDQ $7,%ymm4,%ymm4                                           
VPSRLQ $29,%ymm5,%ymm6                                   
VPAND  %ymm5,%ymm15,%ymm5                              
VPUNPCKLQDQ %ymm4,%ymm1,%ymm7                                  
VPAND  %ymm6,%ymm15,%ymm6                              
VPSRLQ $31,%ymm7,%ymm8                                   
VPSRLQ $2,%ymm7,%ymm7                                    
VPAND  %ymm7,%ymm15,%ymm7                              
VPSRLQ $4,%ymm15,%ymm1                                       
VPAND  %ymm1,%ymm8,%ymm8                                   
VPADDQ padbit(%rip),%ymm8,%ymm8                          

# ##################################
# HASH += MSG
# ##################################

VPADDQ %ymm9,%ymm5,%ymm5 
VPADDQ %ymm10,%ymm6,%ymm6 
VPADDQ %ymm11,%ymm7,%ymm7 
VPADDQ %ymm12,%ymm8,%ymm8 

# ##################################
                                                  
lea    56(%rdi),%rdi
sub    $56,%rsi
ja     Finalize_Loop


.Finalize_Fix:

# HASH = HASH * KEY_FINALIZE

vmovdqa 1472(%rdx), %ymm0                   # LOAD R0                                                     
vmovdqa 1504(%rdx), %ymm1                   # LOAD R1
vmovdqa 1536(%rdx), %ymm2                   # LOAD R2                           
vmovdqa 1632(%rdx), %ymm3                   # LOAD S2
vmovdqa 1664(%rdx), %ymm4                   # LOAD S3       

VPMULUDQ %ymm7,%ymm3,%ymm9                                               # T0 = hash2 * s2                      # !!H*K8!!
VPMULUDQ %ymm7,%ymm4,%ymm10                                               # T1 = hash2 * s3                      # !!H*K8!!
VPMULUDQ %ymm7,%ymm0,%ymm11                                               # T2 = hash2 * r0                      # !!H*K8!!
VPMULUDQ %ymm7,%ymm1,%ymm12                                               # T3 = hash2 * r1                      # !!H*K8!!

VPMULUDQ 1600(%rdx),%ymm8,%ymm13                                                      # !!H*K8!!
VPADDQ %ymm13,%ymm9,%ymm9                               # T0 += hash3 * s1                # !!H*K8!!
VPMULUDQ %ymm1,%ymm5,%ymm13                                                          # !!H*K8!!
VPADDQ %ymm10,%ymm13,%ymm10                               # T1 += hash0 * r1                # !!H*K8!!
VPMULUDQ %ymm1,%ymm6,%ymm13                                                          # !!H*K8!!
VPADDQ %ymm13,%ymm11,%ymm11                               # T2 += hash1 * r1                # !!H*K8!!

VPMULUDQ %ymm4,%ymm6,%ymm13                                                          # !!H*K8!!
VPADDQ %ymm13,%ymm9,%ymm9                               # T0 += hash1 * s3                # !!H*K8!!
VPMULUDQ %ymm4,%ymm8,%ymm13                                                          # !!H*K8!!
VPADDQ %ymm13,%ymm11,%ymm11                               # T2 += hash3 * s3                # !!H*K8!!
VPMULUDQ 1568(%rdx),%ymm5,%ymm13                                                      # !!H*K8!!
VPADDQ %ymm12,%ymm13,%ymm12                               # T3 += hash0 * r3                # !!H*K8!!

VPMULUDQ %ymm0,%ymm5,%ymm13                                                          # !!H*K8!!           
VPADDQ %ymm9,%ymm13,%ymm9                               # T0 += hash0 * r0                # !!H*K8!!
VPMULUDQ %ymm0,%ymm6,%ymm13                                                          # !!H*K8!!   
VPADDQ %ymm13,%ymm10,%ymm10                               # T1 += hash1 * r0                # !!H*K8!!
VPMULUDQ %ymm0,%ymm8,%ymm13                                                          # !!H*K8!!   
VPADDQ %ymm13,%ymm12,%ymm12                               # T3 += hash3 * r0                # !!H*K8!!

VPMULUDQ %ymm2,%ymm5,%ymm13                                                          # !!H*K8!!
VPADDQ %ymm11,%ymm13,%ymm11                               # T2 += hash0 * r2                # !!H*K8!!
                                                                                        
VPMULUDQ %ymm2,%ymm6,%ymm13                                                          # !!H*K8!!
VPADDQ %ymm13,%ymm12,%ymm12                               # T3 += hash1 * r2                # !!H*K8!!
VPMULUDQ %ymm3,%ymm8,%ymm13                                                          # !!H*K8!!
VPADDQ %ymm13,%ymm10,%ymm10                               # T1 += hash3 * s2                # !!H*K8!!             

vmovdqa %ymm9, %ymm5
vmovdqa %ymm10, %ymm6
vmovdqa %ymm11, %ymm7
vmovdqa %ymm12, %ymm8

# TODO Do special finish 
# - Shift remaining to align with standard loading
# - Load remaining into MSG
# - Do multiplication with starting values T0,...,T3

# ########################################################################
# Propagate the carry
# ########################################################################  
                                                     
# hash0 -> hash1
VPSRLQ $29,%ymm5,%ymm13                                                              # !!CARRY!!
VPADDQ %ymm6,%ymm13,%ymm6                                                          # !!CARRY!!
VPAND %ymm15,%ymm5,%ymm5                                                          # !!CARRY!!

# hash1 -> hash2
VPSRLQ $29,%ymm6,%ymm13                                                              # !!CARRY!!
VPADDQ %ymm7,%ymm13,%ymm7                                                          # !!CARRY!!
VPAND %ymm15,%ymm6,%ymm6                                                          # !!CARRY!!

# hash2 -> hash3
VPSRLQ $29,%ymm7,%ymm13                                                              # !!CARRY!!  
VPADDQ %ymm8,%ymm13,%ymm8                                                          # !!CARRY!!
VPAND %ymm15,%ymm7,%ymm7                                                          # !!CARRY!!
                
# hash3 -> hash0
VPSRLQ $29,%ymm8,%ymm13                                                              # !!CARRY!!
VPADDQ %ymm13,%ymm13,%ymm14                                                          # !!CARRY!!
VPADDQ %ymm13,%ymm5,%ymm5                                                          # !!CARRY!!
VPADDQ %ymm14,%ymm5,%ymm5                                                          # !!CARRY!!
VPAND %ymm15,%ymm8,%ymm8                                                          # !!CARRY!!

# hash0 -> hash1
VPSRLQ $29,%ymm5,%ymm13                                                               # !!CARRY!!
VPADDQ %ymm6,%ymm13,%ymm6                                                          # !!CARRY!!                                                      
VPAND %ymm15,%ymm5,%ymm5                                                          # !!CARRY!!

vmovdqa %ymm5,0(%rdx)
vmovdqa %ymm6,32(%rdx)
vmovdqa %ymm7,64(%rdx)
vmovdqa %ymm8,96(%rdx)


ret
    


