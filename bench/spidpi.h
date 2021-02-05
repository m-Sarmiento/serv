#ifndef SPIDPI_H_
#define SPIDPI_H_

#include <svdpi.h>

#ifdef __cplusplus
extern "C" {
#endif

struct spidpi_ctx;

/**
 * Constructor: Create and initialize spidpi context object
 *
 * Call from a initial block.
 *
 * @return an initialized struct spidpi_ctx context object
 */
void *spidpi_create(const char* name, int listen_port);

/**
 * Destructor: Close all connections and free all resources
 *
 * Call from a finish block.
 *
 * @param ctx_void  a struct spidpi_ctx context object
 */
void spidpi_close(void *ctx_void);

/**
 * Drive SPI signals
 *
 * Call this function from the simulation at every clock tick to read/write
 * from/to the SPI signals.
 *
 * @param ctx_void  a struct spidpi_ctx context object
 * @param sck       SPI clock signal
 * @param copi      SPI controller output peripheral input
 * @param cs        SPI chip select  (active low)
 * @param nrst      SPI reset signal (active low)
 * @param cipo      SPI controller input peripheral output
 */
void spidpi_tick(void *ctx_void, svBit *sck, svBit *csn, svBit *mosi,
                  svBit *rst_n, const svBit miso);

#ifdef __cplusplus
}  // extern "C"
#endif
#endif  // SPIDPI_H_
