
.section .rodata
.align 32
mask29:
    .quad 0x1FFFFFFF, 0x1FFFFFFF, 0x1FFFFFFF, 0x1FFFFFFF
mask25:
    .quad 0x1FFFFFF, 0x1FFFFFF, 0x1FFFFFF, 0x1FFFFFF
padbit:
    .quad 0x2000000, 0x2000000, 0x2000000, 0x2000000

.globl core
.text

#                           RDI          RSI         RDX
# core(const unsigned char* in, uint64_t len, State* state);
core:
vmovdqa 0(%rdx),%ymm5
vmovdqa 32(%rdx),%ymm6
vmovdqa 64(%rdx),%ymm7
vmovdqa 96(%rdx),%ymm8

cmp    $55,%rsi
jbe    .Return

vmovdqa mask29(%rip),%ymm15                     # Load mask29

.p2align 5

    .Loop_4x14:           
vpbroadcastq 160(%rdx),%ymm10
vpmuludq 256(%rdx),%ymm8,%ymm4
vpmuludq %ymm10,%ymm5,%ymm3
vmovdqu 0(%rdi),%ymm13
vpbroadcastq 192(%rdx),%ymm2
vpbroadcastq 320(%rdx),%ymm12
vpbroadcastq 128(%rdx),%ymm14
vpmuludq %ymm7,%ymm12,%ymm9
vpaddq %ymm9,%ymm3,%ymm1
vpbroadcastq 288(%rdx),%ymm0
vpmuludq %ymm7,%ymm0,%ymm9
sub $56,%rsi
vpmuludq %ymm7,%ymm10,%ymm3
vpmuludq %ymm7,%ymm14,%ymm7
vpaddq %ymm4,%ymm9,%ymm4
vpmuludq %ymm12,%ymm6,%ymm11
vpmuludq %ymm10,%ymm6,%ymm9
vpmuludq %ymm12,%ymm8,%ymm12
vpaddq %ymm11,%ymm4,%ymm11
vmovdqu 28(%rdi),%ymm10
vpmuludq 224(%rdx),%ymm5,%ymm4
vpaddq %ymm9,%ymm7,%ymm7
vpmuludq %ymm14,%ymm5,%ymm9
vinserti128 $1,14(%rdi),%ymm13,%ymm13
vinserti128 $1,42(%rdi),%ymm10,%ymm10
vpaddq %ymm3,%ymm4,%ymm4
vpmuludq %ymm14,%ymm6,%ymm3
vpmuludq %ymm0,%ymm8,%ymm0
vpaddq %ymm3,%ymm1,%ymm3
vpaddq %ymm11,%ymm9,%ymm1
vpsrlq $29,%ymm1,%ymm9
vpmuludq %ymm14,%ymm8,%ymm14
vpmuludq %ymm2,%ymm5,%ymm5
vpaddq %ymm12,%ymm7,%ymm12
vpaddq %ymm0,%ymm3,%ymm8
vpunpcklqdq %ymm10,%ymm13,%ymm3
vpmuludq %ymm2,%ymm6,%ymm6
vpaddq %ymm8,%ymm9,%ymm0
vpsrldq $7,%ymm13,%ymm7
lea 56(%rdi),%rdi
vpsrlq $29,%ymm0,%ymm8
vpsrldq $7,%ymm10,%ymm13
vpunpcklqdq %ymm13,%ymm7,%ymm7
vpaddq %ymm12,%ymm5,%ymm12
vpsrlq $4,%ymm15,%ymm11
vpsrlq $29,%ymm3,%ymm5
vpaddq %ymm14,%ymm4,%ymm2
vpaddq %ymm12,%ymm8,%ymm12
vpsrlq $29,%ymm12,%ymm9
vpsrlq $31,%ymm7,%ymm4
vpand %ymm5,%ymm15,%ymm14
vpaddq %ymm6,%ymm2,%ymm2
vpand %ymm15,%ymm1,%ymm13
vpsrlq $2,%ymm7,%ymm8
vpaddq %ymm2,%ymm9,%ymm5
vpsrlq $29,%ymm5,%ymm2
vpaddq %ymm2,%ymm13,%ymm9
vpaddq %ymm2,%ymm2,%ymm6
vpand %ymm15,%ymm0,%ymm10
vpand %ymm15,%ymm12,%ymm13
vpaddq %ymm6,%ymm9,%ymm7
vpand %ymm3,%ymm15,%ymm3
vpsrlq $29,%ymm7,%ymm0
vpaddq %ymm10,%ymm0,%ymm2
vpand %ymm8,%ymm15,%ymm1
vpand %ymm11,%ymm4,%ymm9
vpand %ymm15,%ymm5,%ymm8
vpaddq %ymm2,%ymm14,%ymm6
vpand %ymm15,%ymm7,%ymm14
vpaddq %ymm13,%ymm1,%ymm7
vpaddq padbit(%rip),%ymm9,%ymm0
vpaddq %ymm14,%ymm3,%ymm5
vpaddq %ymm8,%ymm0,%ymm8       
    ja .Loop_4x14           
        


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

# ########################################################################
# HASH = HASH * KEY4
# ########################################################################
# T0 = h2 s2 + h0 r0 + h3 s1 + h1 s3 
# T1 = h2 s3 + h1 r0 + h0 r1         + h3 s2
# T2 = h2 r0         + h1 r1 + h3 s3 + h0 r2
# T3 = h2 r1 + h3 r0         + h0 r3 + h1 r2

VPBROADCASTQ 128(%rdx), %ymm0                   # LOAD R0                                                     
VPBROADCASTQ 160(%rdx), %ymm1                   # LOAD R1
VPBROADCASTQ 192(%rdx), %ymm2                   # LOAD R2                           
VPBROADCASTQ 288(%rdx), %ymm3                   # LOAD S2
VPBROADCASTQ 320(%rdx), %ymm4                   # LOAD R3                              

vpmuludq %ymm7,%ymm3,%ymm9                           # T0 = hash2 * s2                      # !!H*K8!!
vpmuludq %ymm7,%ymm4,%ymm10                           # T1 = hash2 * s3                      # !!H*K8!!
vpmuludq %ymm7,%ymm0,%ymm11                           # T2 = hash2 * r0                      # !!H*K8!!
vpmuludq %ymm7,%ymm1,%ymm12                           # T3 = hash2 * r1                      # !!H*K8!!

vpmuludq 256(%rdx),%ymm8,%ymm13                                                      # !!H*K8!!
vpaddq %ymm13,%ymm9,%ymm9                               # T0 += hash3 * s1                # !!H*K8!!
vpmuludq %ymm1,%ymm5,%ymm13                                                          # !!H*K8!!
vpaddq %ymm10,%ymm13,%ymm10                               # T1 += hash0 * r1                # !!H*K8!!
vpmuludq %ymm1,%ymm6,%ymm13                                                          # !!H*K8!!
vpaddq %ymm13,%ymm11,%ymm11                               # T2 += hash1 * r1                # !!H*K8!!

vpmuludq %ymm4,%ymm6,%ymm13                                                          # !!H*K8!!
vpaddq %ymm13,%ymm9,%ymm9                               # T0 += hash1 * s3                # !!H*K8!!
vpmuludq %ymm4,%ymm8,%ymm13                                                          # !!H*K8!!
vpaddq %ymm13,%ymm11,%ymm11                               # T2 += hash3 * s3                # !!H*K8!!
vpmuludq 224(%rdx),%ymm5,%ymm13                                                      # !!H*K8!!
vpaddq %ymm12,%ymm13,%ymm12                               # T3 += hash0 * r3                # !!H*K8!!

vpmuludq %ymm0,%ymm5,%ymm13                                                          # !!H*K8!!           
vpaddq %ymm9,%ymm13,%ymm9                               # T0 += hash0 * r0                # !!H*K8!!
vpmuludq %ymm0,%ymm6,%ymm13                                                          # !!H*K8!!   
vpaddq %ymm13,%ymm10,%ymm10                               # T1 += hash1 * r0                # !!H*K8!!
vpmuludq %ymm0,%ymm8,%ymm13                                                          # !!H*K8!!   
vpaddq %ymm13,%ymm12,%ymm12                               # T3 += hash3 * r0                # !!H*K8!!

vpmuludq %ymm2,%ymm5,%ymm13                                                          # !!H*K8!!
vpaddq %ymm11,%ymm13,%ymm11                               # T2 += hash0 * r2                # !!H*K8!!
                                                                                         
vpmuludq %ymm2,%ymm6,%ymm13                                                          # !!H*K8!!
vpaddq %ymm13,%ymm12,%ymm12                               # T3 += hash1 * r2                # !!H*K8!!
vpmuludq %ymm3,%ymm8,%ymm13                                                          # !!H*K8!!
vpaddq %ymm13,%ymm10,%ymm10                               # T1 += hash3 * s2                # !!H*K8!!                                                     


# ########################################################################
# Propagate the carry
# ########################################################################  
                                                     

    vmovdqu 0(%rdi),%ymm1                              # Load in[56:70]                  # !!MSGB!!

# hash0 -> hash1
vpsrlq $29,%ymm9,%ymm13                                                              # !!CARRY!!
    vinserti128 $1,14(%rdi),%ymm1,%ymm1               # Load in[70:84]                      # !!MSGB!!
vpaddq %ymm10,%ymm13,%ymm10                                                          # !!CARRY!!
vpand %ymm15,%ymm9,%ymm9                                                          # !!CARRY!!

    vmovdqu 28(%rdi),%ymm4                              # Load in[84:98]                   # !!MSGB!!

# hash1 -> hash2
vpsrlq $29,%ymm10,%ymm13                                                              # !!CARRY!!
    vinserti128 $1,42(%rdi),%ymm4,%ymm4               # Load in[98:112]                     # !!MSGB!!
vpaddq %ymm11,%ymm13,%ymm11                                                          # !!CARRY!!
vpand %ymm15,%ymm10,%ymm10                                                          # !!CARRY!!

    vpunpcklqdq %ymm4,%ymm1,%ymm5                                                         # !!MSGB!!

# hash2 -> hash3
vpsrlq $29,%ymm11,%ymm13                                                              # !!CARRY!!  
    vpsrldq $7,%ymm1,%ymm1                                                                  # !!MSGB!!
vpaddq %ymm12,%ymm13,%ymm12                                                          # !!CARRY!!
    vpsrldq $7,%ymm4,%ymm4                                                                  # !!MSGB!!
vpand %ymm15,%ymm11,%ymm11                                                          # !!CARRY!!

    vpsrlq $29,%ymm5,%ymm6                                                          # !!MSGB!!                    

# hash3 -> hash0
vpsrlq $29,%ymm12,%ymm13                                                              # !!CARRY!!
    vpand  %ymm5,%ymm15,%ymm5                                                     # !!MSGB!!
vpaddq %ymm13,%ymm13,%ymm14                                                          # !!CARRY!!
    vpunpcklqdq %ymm4,%ymm1,%ymm7                                                         # !!MSGB!!
    
vpaddq %ymm13,%ymm9,%ymm9                                                          # !!CARRY!!

    vpand  %ymm6,%ymm15,%ymm6                                                     # !!MSGB!!
    
vpaddq %ymm14,%ymm9,%ymm9                                                          # !!CARRY!!
    vpsrlq $31,%ymm7,%ymm8                                                          # !!MSGB!!
vpand %ymm15,%ymm12,%ymm12                                                          # !!CARRY!!
    vpsrlq $2,%ymm7,%ymm7                                                           # !!MSGB!!

# hash0 -> hash1
vpsrlq $29,%ymm9,%ymm13                                                               # !!CARRY!!
    vpand  %ymm7,%ymm15,%ymm7                                                     # !!MSGB!!
vpaddq %ymm10,%ymm13,%ymm10                                                          # !!CARRY!!
vpand %ymm15,%ymm9,%ymm9                                                          # !!CARRY!!

    vpsrlq $4,%ymm15,%ymm1                                                              # !!MSGB!!

    vpand  %ymm1,%ymm8,%ymm8                                                          # !!MSGB!!
    vpaddq padbit(%rip),%ymm8,%ymm8                                                 # !!MSGB!!


# ########################################################################
# HASH += MSG
# ########################################################################

# hash += msg
vpaddq %ymm9,%ymm5,%ymm5 # !!OUTPUT=HASH0!!
vpaddq %ymm10,%ymm6,%ymm6 # !!OUTPUT=HASH1!!
vpaddq %ymm11,%ymm7,%ymm7 # !!OUTPUT=HASH2!!                                                      
vpaddq %ymm12,%ymm8,%ymm8 # !!OUTPUT=HASH3!!

# ########################################################################
                                                  
lea    56(%rdi),%rdi
sub    $56,%rsi
ja     Finalize_Loop


.Finalize_Fix:

# HASH = HASH * KEY_FINALIZE

vmovdqa 352(%rdx), %ymm0                   # LOAD R0                                                     
vmovdqa 384(%rdx), %ymm1                   # LOAD R1
vmovdqa 416(%rdx), %ymm2                   # LOAD R2                           
vmovdqa 512(%rdx), %ymm3                   # LOAD S2
vmovdqa 544(%rdx), %ymm4                   # LOAD S3       

vpmuludq %ymm7,%ymm3,%ymm9                                               # T0 = hash2 * s2                      # !!H*K8!!
vpmuludq %ymm7,%ymm4,%ymm10                                               # T1 = hash2 * s3                      # !!H*K8!!
vpmuludq %ymm7,%ymm0,%ymm11                                               # T2 = hash2 * r0                      # !!H*K8!!
vpmuludq %ymm7,%ymm1,%ymm12                                               # T3 = hash2 * r1                      # !!H*K8!!

vpmuludq 480(%rdx),%ymm8,%ymm13                                                      # !!H*K8!!
vpaddq %ymm13,%ymm9,%ymm9                               # T0 += hash3 * s1                # !!H*K8!!
vpmuludq %ymm1,%ymm5,%ymm13                                                          # !!H*K8!!
vpaddq %ymm10,%ymm13,%ymm10                               # T1 += hash0 * r1                # !!H*K8!!
vpmuludq %ymm1,%ymm6,%ymm13                                                          # !!H*K8!!
vpaddq %ymm13,%ymm11,%ymm11                               # T2 += hash1 * r1                # !!H*K8!!

vpmuludq %ymm4,%ymm6,%ymm13                                                          # !!H*K8!!
vpaddq %ymm13,%ymm9,%ymm9                               # T0 += hash1 * s3                # !!H*K8!!
vpmuludq %ymm4,%ymm8,%ymm13                                                          # !!H*K8!!
vpaddq %ymm13,%ymm11,%ymm11                               # T2 += hash3 * s3                # !!H*K8!!
vpmuludq 448(%rdx),%ymm5,%ymm13                                                      # !!H*K8!!
vpaddq %ymm12,%ymm13,%ymm12                               # T3 += hash0 * r3                # !!H*K8!!

vpmuludq %ymm0,%ymm5,%ymm13                                                          # !!H*K8!!           
vpaddq %ymm9,%ymm13,%ymm9                               # T0 += hash0 * r0                # !!H*K8!!
vpmuludq %ymm0,%ymm6,%ymm13                                                          # !!H*K8!!   
vpaddq %ymm13,%ymm10,%ymm10                               # T1 += hash1 * r0                # !!H*K8!!
vpmuludq %ymm0,%ymm8,%ymm13                                                          # !!H*K8!!   
vpaddq %ymm13,%ymm12,%ymm12                               # T3 += hash3 * r0                # !!H*K8!!

vpmuludq %ymm2,%ymm5,%ymm13                                                          # !!H*K8!!
vpaddq %ymm11,%ymm13,%ymm11                               # T2 += hash0 * r2                # !!H*K8!!
                                                                                        
vpmuludq %ymm2,%ymm6,%ymm13                                                          # !!H*K8!!
vpaddq %ymm13,%ymm12,%ymm12                               # T3 += hash1 * r2                # !!H*K8!!
vpmuludq %ymm3,%ymm8,%ymm13                                                          # !!H*K8!!
vpaddq %ymm13,%ymm10,%ymm10                               # T1 += hash3 * s2                # !!H*K8!!             

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
vpsrlq $29,%ymm5,%ymm13                                                              # !!CARRY!!
vpaddq %ymm6,%ymm13,%ymm6                                                          # !!CARRY!!
vpand %ymm15,%ymm5,%ymm5                                                          # !!CARRY!!

# hash1 -> hash2
vpsrlq $29,%ymm6,%ymm13                                                              # !!CARRY!!
vpaddq %ymm7,%ymm13,%ymm7                                                          # !!CARRY!!
vpand %ymm15,%ymm6,%ymm6                                                          # !!CARRY!!

# hash2 -> hash3
vpsrlq $29,%ymm7,%ymm13                                                              # !!CARRY!!  
vpaddq %ymm8,%ymm13,%ymm8                                                          # !!CARRY!!
vpand %ymm15,%ymm7,%ymm7                                                          # !!CARRY!!
                
# hash3 -> hash0
vpsrlq $29,%ymm8,%ymm13                                                              # !!CARRY!!
vpaddq %ymm13,%ymm13,%ymm14                                                          # !!CARRY!!
vpaddq %ymm13,%ymm5,%ymm5                                                          # !!CARRY!!
vpaddq %ymm14,%ymm5,%ymm5                                                          # !!CARRY!!
vpand %ymm15,%ymm8,%ymm8                                                          # !!CARRY!!

# hash0 -> hash1
vpsrlq $29,%ymm5,%ymm13                                                               # !!CARRY!!
vpaddq %ymm6,%ymm13,%ymm6                                                          # !!CARRY!!                                                      
vpand %ymm15,%ymm5,%ymm5                                                          # !!CARRY!!

vmovdqa %ymm5,0(%rdx)
vmovdqa %ymm6,32(%rdx)
vmovdqa %ymm7,64(%rdx)
vmovdqa %ymm8,96(%rdx)


ret
    


