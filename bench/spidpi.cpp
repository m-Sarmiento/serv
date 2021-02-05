// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "spidpi.h"
#include "tcp_server.h"

#include <assert.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

struct spidpi_ctx {
  // Server context
  struct tcp_server_ctx *sock;
  // Signals
  uint8_t sck;
  uint8_t csn;
  uint8_t mosi;
  uint8_t miso;
  uint8_t rst_n;
};

/**
 * Reset the spi signals to a "dongle unplugged" state
 */
static void reset_spi_signals(struct spidpi_ctx *ctx) {
  assert(ctx);

  ctx->sck = 0;
  ctx->csn = 0;
  ctx->mosi = 0;

  // rst_n is pulled down (reset active) by default
  ctx->rst_n = 0;
}

/**
 * Update the spi signals in the context structure
 */
static void update_spi_signals(struct spidpi_ctx *ctx) {
  assert(ctx);

  /*
   * Documentation pointer:
   * The remote_bitbang protocol implemented below is documented in the OpenOCD
   * source tree at doc/manual/spi/drivers/remote_bitbang.txt, or online at
   * https://repo.or.cz/openocd.git/blob/HEAD:/doc/manual/spi/drivers/remote_bitbang.txt
   */

  // read a command byte
  char cmd;
  if (!tcp_server_read(ctx->sock, &cmd)) {
    return;
  }

  bool act_send_resp = false;
  bool act_quit = false;

  // parse received command byte
  if (cmd >= '0' && cmd <= '7') {
    // spi write
    char cmd_bit = cmd - '0';
    ctx->mosi = (cmd_bit >> 0) & 0x1;
    ctx->csn = (cmd_bit >> 1) & 0x1;
    ctx->sck = (cmd_bit >> 2) & 0x1;
  } else if (cmd >= 'r' && cmd <= 'u') {
    // spi reset (active high from OpenOCD)
    char cmd_bit = cmd - 'r';
    ctx->rst_n = !((cmd_bit >> 0) & 0x1);
  } else if (cmd == 'R') {
    // spi read
    act_send_resp = true;
  } else if (cmd == 'B') {
    // printf("%s: BLINK ON!\n", ctx->display_name);
  } else if (cmd == 'b') {
    // printf("%s: BLINK OFF!\n", ctx->display_name);
  } else if (cmd == 'Q') {
    // quit (client disconnect)
    act_quit = true;
  } else {
    fprintf(stderr,
            "spi DPI Protocol violation detected: unsupported command %c\n",
            cmd);
    exit(1);
  }

  // send miso as response
  if (act_send_resp) {
    char tdo_ascii = ctx->miso + '0';
    tcp_server_write(ctx->sock, tdo_ascii);
  }

  if (act_quit) {
    printf("spi DPI: Remote disconnected.\n");
    tcp_server_client_close(ctx->sock);
  }
}

void *spidpi_create(const char *display_name, int listen_port) {
  struct spidpi_ctx *ctx =
      (struct spidpi_ctx *)calloc(1, sizeof(struct spidpi_ctx));
  assert(ctx);

  // Create socket
  ctx->sock = tcp_server_create(display_name, listen_port);

  reset_spi_signals(ctx);

  printf(
      "\n"
      "spi: Virtual spi interface %s is listening on port %d.\n",
      display_name, listen_port);

  return (void *)ctx;
}

void spidpi_close(void *ctx_void) {
  struct spidpi_ctx *ctx = (struct spidpi_ctx *)ctx_void;
  if (!ctx) {
    return;
  }
  tcp_server_close(ctx->sock);
  free(ctx);
}

void spidpi_tick(void *ctx_void, svBit *sck, svBit *csn, svBit *mosi,
                  svBit *rst_n, const svBit miso) {
  struct spidpi_ctx *ctx = (struct spidpi_ctx *)ctx_void;

  ctx->miso = miso;

  // TODO: Evaluate moving this functionality into a separate thread
  if (ctx) {
    update_spi_signals(ctx);
  }

  *mosi = ctx->mosi;
  *csn = ctx->csn;
  *sck = ctx->sck;
  *rst_n = ctx->rst_n;
}
