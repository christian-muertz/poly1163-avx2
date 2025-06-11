import click

IN = '%rdi'
LEN = '%rsi'
STATE = '%rdx'
STATE_KEY_POWERS=4*32

OUT0, OUT1, OUT2, OUT3 = '%rdx', '%rcx', '%r8', '%r9'

RM_0, RM_1, RM_2, SM_2, SM_3 = '%ymm0', '%ymm1', '%ymm2', '%ymm3', '%ymm4'

A = RM_1
B = SM_3

RA_0 = '%ymm5'
RA_1 = '%ymm1'
RA_2 = '%ymm6'
SA_2 = '%ymm3'
SA_3 = '%ymm4'

HASH0 = '%ymm5'
HASH1 = '%ymm6'
HASH2 = '%ymm7'
HASH3 = '%ymm8'

MSGA0 = RM_0
MSGA1 = RM_2
MSGA2 = '%ymm7'
MSGA3 = '%ymm8'

T0 = '%ymm9'
T1 = '%ymm10'
T2 = '%ymm11'
T3 = '%ymm12'

MSGB0 = HASH0
MSGB1 = HASH1
MSGB2 = HASH2
MSGB3 = HASH3

TEMP1 = '%ymm13'
TEMP2 = '%ymm14'

MASK29 = '%ymm15'

def finalize(DELAYED):
    STATE_KEY_FINALIZE=STATE_KEY_POWERS + DELAYED*7*32
    res = ""
    res += f"""
.globl finalize_asm
finalize_asm:

vmovdqa 0({STATE}),{HASH0}
vmovdqa 32({STATE}),{HASH1}
vmovdqa 64({STATE}),{HASH2}
vmovdqa 96({STATE}),{HASH3}

vmovdqa mask29(%rip),{MASK29}                     # Load mask29

# Do Loop_4x
# TODO skip loop if remaining < 4*14
cmp ${4*14},{LEN}
jb .Finalize_Fix

{loop(1, label="Finalize_Loop")}

.Finalize_Fix:

# HASH = HASH * KEY_FINALIZE

vmovdqa {STATE_KEY_FINALIZE+32*0}({STATE}), {RM_0}                   # LOAD R0                                                     
vmovdqa {STATE_KEY_FINALIZE+32*1}({STATE}), {RM_1}                   # LOAD R1
vmovdqa {STATE_KEY_FINALIZE+32*2}({STATE}), {RM_2}                   # LOAD R2                           
vmovdqa {STATE_KEY_FINALIZE+32*5}({STATE}), {SM_2}                   # LOAD S2
vmovdqa {STATE_KEY_FINALIZE+32*6}({STATE}), {SM_3}                   # LOAD S3       

VPMULUDQ {HASH2},{SM_2},{T0}                                               # T0 = hash2 * s2                      # !!H*K8!!
VPMULUDQ {HASH2},{SM_3},{T1}                                               # T1 = hash2 * s3                      # !!H*K8!!
VPMULUDQ {HASH2},{RM_0},{T2}                                               # T2 = hash2 * r0                      # !!H*K8!!
VPMULUDQ {HASH2},{RM_1},{T3}                                               # T3 = hash2 * r1                      # !!H*K8!!

VPMULUDQ {STATE_KEY_FINALIZE+32*4}({STATE}),{HASH3},{TEMP1}                                                      # !!H*K8!!
VPADDQ {TEMP1},{T0},{T0}                               # T0 += hash3 * s1                # !!H*K8!!
VPMULUDQ {RM_1},{HASH0},{TEMP1}                                                          # !!H*K8!!
VPADDQ {T1},{TEMP1},{T1}                               # T1 += hash0 * r1                # !!H*K8!!
VPMULUDQ {RM_1},{HASH1},{TEMP1}                                                          # !!H*K8!!
VPADDQ {TEMP1},{T2},{T2}                               # T2 += hash1 * r1                # !!H*K8!!

VPMULUDQ {SM_3},{HASH1},{TEMP1}                                                          # !!H*K8!!
VPADDQ {TEMP1},{T0},{T0}                               # T0 += hash1 * s3                # !!H*K8!!
VPMULUDQ {SM_3},{HASH3},{TEMP1}                                                          # !!H*K8!!
VPADDQ {TEMP1},{T2},{T2}                               # T2 += hash3 * s3                # !!H*K8!!
VPMULUDQ {STATE_KEY_FINALIZE+32*3}({STATE}),{HASH0},{TEMP1}                                                      # !!H*K8!!
VPADDQ {T3},{TEMP1},{T3}                               # T3 += hash0 * r3                # !!H*K8!!

VPMULUDQ {RM_0},{HASH0},{TEMP1}                                                          # !!H*K8!!           
VPADDQ {T0},{TEMP1},{T0}                               # T0 += hash0 * r0                # !!H*K8!!
VPMULUDQ {RM_0},{HASH1},{TEMP1}                                                          # !!H*K8!!   
VPADDQ {TEMP1},{T1},{T1}                               # T1 += hash1 * r0                # !!H*K8!!
VPMULUDQ {RM_0},{HASH3},{TEMP1}                                                          # !!H*K8!!   
VPADDQ {TEMP1},{T3},{T3}                               # T3 += hash3 * r0                # !!H*K8!!

VPMULUDQ {RM_2},{HASH0},{TEMP1}                                                          # !!H*K8!!
VPADDQ {T2},{TEMP1},{T2}                               # T2 += hash0 * r2                # !!H*K8!!
                                                                                        
VPMULUDQ {RM_2},{HASH1},{TEMP1}                                                          # !!H*K8!!
VPADDQ {TEMP1},{T3},{T3}                               # T3 += hash1 * r2                # !!H*K8!!
VPMULUDQ {SM_2},{HASH3},{TEMP1}                                                          # !!H*K8!!
VPADDQ {TEMP1},{T1},{T1}                               # T1 += hash3 * s2                # !!H*K8!!             

vmovdqa {T0}, {HASH0}
vmovdqa {T1}, {HASH1}
vmovdqa {T2}, {HASH2}
vmovdqa {T3}, {HASH3}

# TODO Do special finish 
# - Shift remaining to align with standard loading
# - Load remaining into MSG
# - Do multiplication with starting values T0,...,T3

# ########################################################################
# Propagate the carry
# ########################################################################  
                                                     
# hash0 -> hash1
VPSRLQ $29,{HASH0},{TEMP1}                                                              # !!CARRY!!
VPADDQ {HASH1},{TEMP1},{HASH1}                                                          # !!CARRY!!
VPAND {MASK29},{HASH0},{HASH0}                                                          # !!CARRY!!

# hash1 -> hash2
VPSRLQ $29,{HASH1},{TEMP1}                                                              # !!CARRY!!
VPADDQ {HASH2},{TEMP1},{HASH2}                                                          # !!CARRY!!
VPAND {MASK29},{HASH1},{HASH1}                                                          # !!CARRY!!

# hash2 -> hash3
VPSRLQ $29,{HASH2},{TEMP1}                                                              # !!CARRY!!  
VPADDQ {HASH3},{TEMP1},{HASH3}                                                          # !!CARRY!!
VPAND {MASK29},{HASH2},{HASH2}                                                          # !!CARRY!!
                
# hash3 -> hash0
VPSRLQ $29,{HASH3},{TEMP1}                                                              # !!CARRY!!
VPADDQ {TEMP1},{TEMP1},{TEMP2}                                                          # !!CARRY!!
VPADDQ {TEMP1},{HASH0},{HASH0}                                                          # !!CARRY!!
VPADDQ {TEMP2},{HASH0},{HASH0}                                                          # !!CARRY!!
VPAND {MASK29},{HASH3},{HASH3}                                                          # !!CARRY!!

# hash0 -> hash1
VPSRLQ $29,{HASH0},{TEMP1}                                                               # !!CARRY!!
VPADDQ {HASH1},{TEMP1},{HASH1}                                                          # !!CARRY!!                                                      
VPAND {MASK29},{HASH0},{HASH0}                                                          # !!CARRY!!

vmovdqa {HASH0},0({STATE})
vmovdqa {HASH1},32({STATE})
vmovdqa {HASH2},64({STATE})
vmovdqa {HASH3},96({STATE})


ret
    """
    return res

def loop(delay, label=None):
    label = label if label is not None else f'.Loop_{4*delay}x14'
    res = f'''
.p2align 5
{label}:

# ##################################
# HASH = HASH * KEY{delay*4}
# ##################################
# T0 = h2 s2 + h0 r0 + h3 s1 + h1 s3 
# T1 = h2 s3 + h1 r0 + h0 r1         + h3 s2
# T2 = h2 r0         + h1 r1 + h3 s3 + h0 r2
# T3 = h2 r1 + h3 r0         + h0 r3 + h1 r2

VPBROADCASTQ {STATE_KEY_POWERS+(delay-1)*7*32+32*0}({STATE}), {RM_0}                 
VPBROADCASTQ {STATE_KEY_POWERS+(delay-1)*7*32+32*1}({STATE}), {RM_1}                 
VPBROADCASTQ {STATE_KEY_POWERS+(delay-1)*7*32+32*2}({STATE}), {RM_2}                 
VPBROADCASTQ {STATE_KEY_POWERS+(delay-1)*7*32+32*5}({STATE}), {SM_2}                 
VPBROADCASTQ {STATE_KEY_POWERS+(delay-1)*7*32+32*6}({STATE}), {SM_3}                 

VPMULUDQ {HASH2},{SM_2},{T0}                           # T0 = hash2 * s2                      
VPMULUDQ {HASH2},{SM_3},{T1}                           # T1 = hash2 * s3                      
VPMULUDQ {HASH2},{RM_0},{T2}                           # T2 = hash2 * r0                      
VPMULUDQ {HASH2},{RM_1},{T3}                           # T3 = hash2 * r1                      

VPMULUDQ {STATE_KEY_POWERS+(delay-1)*7*32+32*4}({STATE}),{HASH3},{TEMP1}                                 
VPADDQ {TEMP1},{T0},{T0}                               # T0 += hash3 * s1               
VPMULUDQ {RM_1},{HASH0},{TEMP1}                                                         
VPADDQ {T1},{TEMP1},{T1}                               # T1 += hash0 * r1               
VPMULUDQ {RM_1},{HASH1},{TEMP1}                                                         
VPADDQ {TEMP1},{T2},{T2}                               # T2 += hash1 * r1               

VPMULUDQ {SM_3},{HASH1},{TEMP1}                                                         
VPADDQ {TEMP1},{T0},{T0}                               # T0 += hash1 * s3               
VPMULUDQ {SM_3},{HASH3},{TEMP1}                                                         
VPADDQ {TEMP1},{T2},{T2}                               # T2 += hash3 * s3               
VPMULUDQ {STATE_KEY_POWERS+(delay-1)*7*32+32*3}({STATE}),{HASH0},{TEMP1}                                                      
VPADDQ {T3},{TEMP1},{T3}                               # T3 += hash0 * r3                

VPMULUDQ {RM_0},{HASH0},{TEMP1}                                                          
VPADDQ {T0},{TEMP1},{T0}                               # T0 += hash0 * r0                
VPMULUDQ {RM_0},{HASH1},{TEMP1}                                                          
VPADDQ {TEMP1},{T1},{T1}                               # T1 += hash1 * r0                
VPMULUDQ {RM_0},{HASH3},{TEMP1}                                                          
VPADDQ {TEMP1},{T3},{T3}                               # T3 += hash3 * r0                

VPMULUDQ {RM_2},{HASH0},{TEMP1}                                                          
VPADDQ {T2},{TEMP1},{T2}                               # T2 += hash0 * r2                
                                                                                         
VPMULUDQ {RM_2},{HASH1},{TEMP1}                                                          
VPADDQ {TEMP1},{T3},{T3}                               # T3 += hash1 * r2                
VPMULUDQ {SM_2},{HASH3},{TEMP1}                                                          
VPADDQ {TEMP1},{T1},{T1}                               # T1 += hash3 * s2                
'''
    for iter in range(1,delay):
        res += f'''
# ##################################
# HASH += MSG * KEY{(4*delay - 4*iter)}
# ##################################

VMOVDQU {(iter-1)*4*14}({IN}),{A}                                     # Load in[0:14]                  
VINSERTI128 $1,{(iter-1)*4*14+14}({IN}),{A},{A}                        # Load in[14:28]                
VMOVDQU {(iter-1)*4*14+28}({IN}),{B}                              # Load in[28:42]                     
VINSERTI128 $1,{(iter-1)*4*14+42}({IN}),{B},{B}                   # Load in[42:56]                     
VPUNPCKLQDQ {B},{A},{MSGA0}                                                             
VPSRLDQ $7,{A},{A}                                                                      
VPSRLDQ $7,{B},{B}                                                                      
VPSRLQ $29,{MSGA0},{MSGA1}                                                              
VPAND  {MSGA0},{MASK29},{MSGA0}                                                         
VPAND  {MSGA1},{MASK29},{MSGA1}                                                         
VPUNPCKLQDQ {B},{A},{MSGA2}                                                             
VPSRLQ $31,{MSGA2},{MSGA3}                                                              
VPSRLQ $2,{MSGA2},{MSGA2}                                                               
VPAND  {MSGA2},{MASK29},{MSGA2}                                                         
VPSRLQ $4,{MASK29},{A}                                                                  
VPAND  {A},{MSGA3},{MSGA3}                                                              
VPADDQ padbit(%rip),{MSGA3},{MSGA3}                                                     

# Start multiply with key
VPBROADCASTQ {STATE_KEY_POWERS+(delay-iter-1)*7*32+32*0}({STATE}), {RA_0}                                      
VPBROADCASTQ {STATE_KEY_POWERS+(delay-iter-1)*7*32+32*1}({STATE}), {RA_1}
VPBROADCASTQ {STATE_KEY_POWERS+(delay-iter-1)*7*32+32*2}({STATE}), {RA_2}                                                          
VPBROADCASTQ {STATE_KEY_POWERS+(delay-iter-1)*7*32+32*5}({STATE}), {SA_2}     
VPBROADCASTQ {STATE_KEY_POWERS+(delay-iter-1)*7*32+32*6}({STATE}), {SA_3}

VPMULUDQ {RA_0},{MSGA0},{TEMP1}                           # T0 = msg0 * r0              
VPADDQ {TEMP1},{T0},{T0}                                                                
VPMULUDQ {RA_1},{MSGA0},{TEMP1}                           # T1 = msg0 * r1              
VPADDQ {TEMP1},{T1},{T1}                                                                
VPMULUDQ {RA_2},{MSGA0},{TEMP1}                           # T2 = msg0 * r2              
VPADDQ {TEMP1},{T2},{T2}                                                                
VPMULUDQ {STATE_KEY_POWERS+(delay-iter-1)*7*32+32*3}({STATE}),{MSGA0},{TEMP1}                   
VPADDQ {TEMP1},{T3},{T3}                                                                

VPMULUDQ {SA_3},{MSGA1},{TEMP1}                                                         
VPADDQ {TEMP1},{T0},{T0}                               # T0 += msg1 * s3                
VPMULUDQ {RA_0},{MSGA1},{TEMP1}                                                         
VPADDQ {TEMP1},{T1},{T1}                               # T1 += msg1 * r0                
VPMULUDQ {RA_1},{MSGA1},{TEMP1}                                                         
VPADDQ {TEMP1},{T2},{T2}                               # T2 += msg1 * r1                
VPMULUDQ {RA_2},{MSGA1},{TEMP1}                                                         
VPADDQ {TEMP1},{T3},{T3}                               # T3 += msg1 * r2                

VPMULUDQ {MSGA2},{SA_2},{TEMP1}                                                         
VPADDQ {TEMP1},{T0},{T0}                               # T0 += msg2 * s2                
VPMULUDQ {MSGA2},{SA_3},{TEMP1}                                                         
VPADDQ {TEMP1},{T1},{T1}                               # T1 += msg2 * s3                
VPMULUDQ {MSGA2},{RA_0},{TEMP1}                                                         
VPADDQ {TEMP1},{T2},{T2}                               # T2 += msg2 * r0                
VPMULUDQ {MSGA2},{RA_1},{TEMP1}                                                         
VPADDQ {TEMP1},{T3},{T3}                               # T3 += msg2 * r1                

VPMULUDQ {STATE_KEY_POWERS+(delay-iter-1)*7*32+32*4}({STATE}),{MSGA3},{TEMP1}                                                    
VPADDQ {TEMP1},{T0},{T0}                               # T0 += msg3 * s1                
VPMULUDQ {SA_2},{MSGA3},{TEMP1}                                                         
VPADDQ {TEMP1},{T1},{T1}                               # T1 += msg3 * s2                
VPMULUDQ {SA_3},{MSGA3},{TEMP1}                                                         
VPADDQ {TEMP1},{T2},{T2}                               # T2 += msg3 * s3                
VPMULUDQ {RA_0},{MSGA3},{TEMP1}                                                         
VPADDQ {TEMP1},{T3},{T3}                               # T3 += msg3 * r0                
'''

    res+=f'''

# ##################################
# Propagate the carry
# ##################################
                                                     
# hash0 -> hash1
VPSRLQ $29,{T0},{TEMP1}                                                             
VPADDQ {T1},{TEMP1},{T1}                                                          
VPAND {MASK29},{T0},{T0}                                                          

# hash1 -> hash2
VPSRLQ $29,{T1},{TEMP1}                                                            
VPADDQ {T2},{TEMP1},{T2}                                                          
VPAND {MASK29},{T1},{T1}                                                          

# hash2 -> hash3
VPSRLQ $29,{T2},{TEMP1}                                                        
VPADDQ {T3},{TEMP1},{T3}                                                       
VPAND {MASK29},{T2},{T2}                                                       

# hash3 -> hash0
VPSRLQ $29,{T3},{TEMP1}                                                            
VPADDQ {TEMP1},{TEMP1},{TEMP2}                                                     
VPADDQ {TEMP1},{T0},{T0}                                                          
VPADDQ {TEMP2},{T0},{T0}                                                          
VPAND {MASK29},{T3},{T3}                                                         
    
# hash0 -> hash1
VPSRLQ $29,{T0},{TEMP1}                                                               
VPADDQ {T1},{TEMP1},{T1}                                                          
VPAND {MASK29},{T0},{T0}           

# ##################################
# LOADING MSG
# ##################################

VMOVDQU {(delay-1)*4*14}({IN}),{A}                              
VINSERTI128 $1,{(delay-1)*4*14+14}({IN}),{A},{A}             
VMOVDQU {(delay-1)*4*14+28}({IN}),{B}                        
VINSERTI128 $1,{(delay-1)*4*14+42}({IN}),{B},{B}             
VPUNPCKLQDQ {B},{A},{MSGB0}                                  
VPSRLDQ $7,{A},{A}                                           
VPSRLDQ $7,{B},{B}                                           
VPSRLQ $29,{MSGB0},{MSGB1}                                   
VPAND  {MSGB0},{MASK29},{MSGB0}                              
VPUNPCKLQDQ {B},{A},{MSGB2}                                  
VPAND  {MSGB1},{MASK29},{MSGB1}                              
VPSRLQ $31,{MSGB2},{MSGB3}                                   
VPSRLQ $2,{MSGB2},{MSGB2}                                    
VPAND  {MSGB2},{MASK29},{MSGB2}                              
VPSRLQ $4,{MASK29},{A}                                       
VPAND  {A},{MSGB3},{MSGB3}                                   
VPADDQ padbit(%rip),{MSGB3},{MSGB3}                          

# ##################################
# HASH += MSG
# ##################################

VPADDQ {T0},{MSGB0},{HASH0} 
VPADDQ {T1},{MSGB1},{HASH1} 
VPADDQ {T2},{MSGB2},{HASH2} 
VPADDQ {T3},{MSGB3},{HASH3} 

# ##################################
                                                  
lea    {delay*4*14}({IN}),{IN}
sub    ${delay*4*14},{LEN}
ja     {label}
'''
    return res

@click.command()
@click.option('--delay', '-d', type=int)
def cli(delay):
    DELAYED = delay

    print(f'''
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
vmovdqa 0({STATE}),{HASH0}
vmovdqa 32({STATE}),{HASH1}
vmovdqa 64({STATE}),{HASH2}
vmovdqa 96({STATE}),{HASH3}

# Check if there is even something to process
cmp    ${DELAYED*4*14 - 1},{LEN}
jbe    .Return

# Load mask29
vmovdqa mask29(%rip),{MASK29}

{loop(DELAYED)}

.Return:
vmovdqa {HASH0},0({STATE})
vmovdqa {HASH1},32({STATE})
vmovdqa {HASH2},64({STATE})
vmovdqa {HASH3},96({STATE})
ret  

{finalize(DELAYED)}

''')

if __name__ == '__main__':
    cli()