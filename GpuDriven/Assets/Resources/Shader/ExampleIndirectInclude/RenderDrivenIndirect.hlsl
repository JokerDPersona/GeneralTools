#ifndef RENDER_DRIVEN_INDIRECT
#define RENDER_DRIVEN_INDIRECT

#pragma multi_compile _ENABLE_GPUDRIVEN _

#ifdef _ENABLE_GPUDRIVEN
        #include "GPUDrivenIndirect.hlsl"
#else
        #include "CPUDrivenIndirect.hlsl"
#endif


#endif