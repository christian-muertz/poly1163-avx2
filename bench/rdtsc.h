#define INT64 unsigned long long
#define INT32 unsigned int
#define CPU_FREQ 2700000000

#if defined(__x86_64__)

#define VOLATILE __volatile__
#define ASM __asm__

#define COUNTER_LO(a) ((a).int32.lo)
#define COUNTER_HI(a) ((a).int32.hi)
#define COUNTER_VAL(a) ((a).int64)

#define COUNTER(a) \
	((unsigned long long)COUNTER_VAL(a))

#define COUNTER_DIFF(a, b) \
	(COUNTER(a) - COUNTER(b))

/* ==================== GNU C and possibly other UNIX compilers ===================== */

typedef union
{
	INT64 int64;
	struct
	{
		INT32 lo, hi;
	} int32;
} tsc_counter;

#define RDTSC(cpu_c) \
	ASM VOLATILE("rdtsc" : "=a"((cpu_c).int32.lo), "=d"((cpu_c).int32.hi))

#define RDTSCP(cpu_c) \
	ASM VOLATILE("rdtscp" : "=a"((cpu_c).int32.lo), "=d"((cpu_c).int32.hi) :: "%rcx")

#define CPUID() \
	ASM VOLATILE("cpuid" : : "a"(0) : "bx", "cx", "dx")

#define LFENCE() \
	ASM VOLATILE ("lfence" ::: "memory");

static inline INT64 start_tsc(void)
{
	tsc_counter start;
	CPUID();
	RDTSC(start);
	return COUNTER_VAL(start);
}

static inline INT64 stop_tsc(INT64 start)
{
	tsc_counter end;
	RDTSCP(end);
	CPUID();
	return COUNTER_VAL(end) - start;
}
#else

static inline INT64 start_tsc(void)
{
	return 0;
}

static inline INT64 stop_tsc(INT64 start)
{
	return 1;
}

#endif