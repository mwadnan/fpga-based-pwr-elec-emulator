//   ==================================================================
//   >>>>>>>>>>>>>>>>>>>>>>> COPYRIGHT NOTICE <<<<<<<<<<<<<<<<<<<<<<<<<
//   ------------------------------------------------------------------
//   Copyright (c) 2006-2011 by Lattice Semiconductor Corporation
//   ------------------------------------------------------------------
//   ALL RIGHTS RESERVED
//
//   IMPORTANT: THIS FILE IS AUTO-GENERATED BY THE LATTICEMICO SYSTEM.
//
//   Permission:
//
//      Lattice Semiconductor grants permission to use this code
//      pursuant to the terms of the Lattice Semiconductor Corporation
//      Open Source License Agreement.
//
//   Disclaimer:
//
//      Lattice Semiconductor provides no warranty regarding the use or
//      functionality of this code. It is the user's responsibility to
//      verify the user�s design for consistency and functionality through
//      the use of formal verification methods.
//
//   --------------------------------------------------------------------
//
//                  Lattice Semiconductor Corporation
//                  5555 NE Moore Court
//                  Hillsboro, OR 97214
//                  U.S.A
//
//                  TEL: 1-800-Lattice (USA and Canada)
//                         503-286-8001 (other locations)
//
//                  web: http://www.latticesemi.com/
//                  email: techsupport@latticesemi.com
//
//   --------------------------------------------------------------------
//
//      Project:           wb_soc_v2
//      File:              wb_soc_v2_inst.v
//      Date:              Di, 27 Aug 2013 22:59:27 MESZ
//      Version:           2.1
//      Targeted Family:   EC
//
//   =======================================================================

// Attn : This file is used for VHDL Wrapper

wb_soc_v2_vhd wb_soc_v2_u ( 
.clk_i(clk_i),
.reset_n(reset_n)
, .uartSIN(uartSIN) // 
, .uartSOUT(uartSOUT) // 
, .gpioPIO_BOTH_IN(gpioPIO_BOTH_IN) // [4-1:0]
, .gpioPIO_BOTH_OUT(gpioPIO_BOTH_OUT) // [4-1:0]
, .slave_passthruclk(slave_passthruclk) // 
, .slave_passthrurst(slave_passthrurst) // 
, .slave_passthruslv_adr(slave_passthruslv_adr) // [32-1:0]
, .slave_passthruslv_master_data(slave_passthruslv_master_data) // [32-1:0]
, .slave_passthruslv_slave_data(slave_passthruslv_slave_data) // [32-1:0]
, .slave_passthruslv_strb(slave_passthruslv_strb) // 
, .slave_passthruslv_cyc(slave_passthruslv_cyc) // 
, .slave_passthruslv_ack(slave_passthruslv_ack) // 
, .slave_passthruslv_err(slave_passthruslv_err) // 
, .slave_passthruslv_rty(slave_passthruslv_rty) // 
, .slave_passthruslv_sel(slave_passthruslv_sel) // [3:0] 
, .slave_passthruslv_we(slave_passthruslv_we) // 
, .slave_passthruslv_bte(slave_passthruslv_bte) // [1:0] 
, .slave_passthruslv_cti(slave_passthruslv_cti) // [2:0] 
, .slave_passthruslv_lock(slave_passthruslv_lock) // 
, .slave_passthruintr_active_high(slave_passthruintr_active_high) // 
);
