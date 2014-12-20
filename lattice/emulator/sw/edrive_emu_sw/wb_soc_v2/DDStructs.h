#ifndef LATTICE_DDINIT_HEADER_FILE
#define LATTICE_DDINIT_HEADER_FILE
#ifdef __cplusplus
extern "C"
{
#endif /* __cplusplus */

#include "LookupServices.h"
#include "LookupServices.h"
#include "LookupServices.h"
/* platform frequency in MHz */
#define MICO32_CPU_CLOCK_MHZ (66666700)

/*Device-driver structure for lm32_top*/
#define LatticeMico32Ctx_t_DEFINED (1)
typedef struct st_LatticeMico32Ctx_t {
    const char*   name;
} LatticeMico32Ctx_t;


/* lm32_top instance LM32*/
extern struct st_LatticeMico32Ctx_t lm32_top_LM32;

/* declare LM32 instance of lm32_top */
extern void LatticeMico32Init(struct st_LatticeMico32Ctx_t*);


/*Device-driver structure for uart_core*/
#define MicoUartCtx_t_DEFINED (1)
typedef struct st_MicoUartCtx_t {
    const char *   name;
    unsigned int   base;
    unsigned char   intrLevel;
    unsigned char   intrAvail;
    unsigned int   baudrate;
    unsigned int   databits;
    unsigned int   stopbits;
    unsigned char   rxBufferSize;
    unsigned char   txBufferSize;
    unsigned char   blockingTx;
    unsigned char   blockingRx;
    unsigned int   fifoenable;
    unsigned char   *rxBuffer;
    unsigned char   *txBuffer;
    DeviceReg_t   lookupReg;
    unsigned char   rxWriteLoc;
    unsigned char   rxReadLoc;
    unsigned char   txWriteLoc;
    unsigned char   txReadLoc;
    unsigned int   timeoutMicroSecs;
    volatile unsigned char   txDataBytes;
    volatile unsigned char   rxDataBytes;
    unsigned int   errors;
    unsigned char   ier;
    void *   prev;
    void *   next;
} MicoUartCtx_t;


/* uart_core instance uart*/
extern struct st_MicoUartCtx_t uart_core_uart;

/* declare uart instance of uart_core */
extern void MicoUartInit(struct st_MicoUartCtx_t*);


/*Device-driver structure for gpio*/
#define MicoGPIOCtx_t_DEFINED (1)
typedef struct st_MicoGPIOCtx_t {
    const char*   name;
    unsigned int   base;
    unsigned int   intrLevel;
    unsigned int   output_only;
    unsigned int   input_only;
    unsigned int   in_and_out;
    unsigned int   tristate;
    unsigned int   data_width;
    unsigned int   input_width;
    unsigned int   output_width;
    unsigned int   intr_enable;
    unsigned int   wb_data_size;
    DeviceReg_t   lookupReg;
    void *   prev;
    void *   next;
} MicoGPIOCtx_t;


/* gpio instance gpio*/
extern struct st_MicoGPIOCtx_t gpio_gpio;

/* declare gpio instance of gpio */
extern void MicoGPIOInit(struct st_MicoGPIOCtx_t*);


/*Device-driver structure for slave_passthru*/
#define MicoPassthruCtx_t_DEFINED (1)
typedef struct st_MicoPassthruCtx_t {
    const char*   name;
    unsigned int   base;
    unsigned int   intrLevel;
    DeviceReg_t   lookupReg;
    void *   prev;
    void *   next;
} MicoPassthruCtx_t;


/* slave_passthru instance slave_passthru*/
extern struct st_MicoPassthruCtx_t slave_passthru_slave_passthru;

/* declare slave_passthru instance of slave_passthru */
extern void MicoPassthruInit(struct st_MicoPassthruCtx_t*);

extern int main();



#ifdef __cplusplus
}
#endif /* __cplusplus */
#endif
