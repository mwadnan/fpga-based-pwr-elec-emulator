/****************************************************************************
**
**  Name: MicoPassthru.c
**
**  Description:
**     Implements Slave Passthru functions:
**
**        MicoPassthruInit : Slave Passthru initialization funciton called by 
**                 LatticeDDInit (user-callable)
**        
**
**  $Revision: $
**
** Disclaimer:
**
**   This source code is intended as a design reference which
**   illustrates how these types of functions can be implemented.  It
**   is the user's responsibility to verify their design for
**   consistency and functionality through the use of formal
**   verification methods.  Lattice Semiconductor provides no warranty
**   regarding the use or functionality of this code.
**
** --------------------------------------------------------------------
**
**                     Lattice Semiconductor Corporation
**                     5555 NE Moore Court
**                     Hillsboro, OR 97214
**                     U.S.A
**
**                     TEL: 1-800-Lattice (USA and Canada)
**                          (503)268-8001 (other locations)
**
**                     web:   http://www.latticesemi.com
**                     email: techsupport@latticesemi.com
**
** --------------------------------------------------------------------------
**
**  Change History (Latest changes on top)
**
**  Ver		Date      	Description
** --------------------------------------------------------------------------
**  3.0    	06-04-2010	Added Source
**
**---------------------------------------------------------------------------
*****************************************************************************/
#include "MicoPassthru.h"

/***********************************************************************
 *                                                                     *
 *                                                                     *
 *                                                                     *
 ***********************************************************************/
void MicoPassthruInit (MicoPassthruCtx_t *ctx)
{
    ctx->lookupReg.name = ctx->name;
    ctx->lookupReg.deviceType = "PassthruDevice";
    ctx->lookupReg.priv = ctx;

    MicoRegisterDevice( &(ctx->lookupReg) );
    /* all done */
    return;
}

#ifndef __MICOPASSTHRU_USER_IRQ_HANDLER__
/*
 *****************************************************************************
 * Interrupt handler. Each Slave Passthru instance has it's own default 
 * interrupt handler implementation. If the developer wishes to use his 
 * own interrupt handler, he must define the __MICOPASSTHRU_USER_IRQ_HANDLER__ 
 * preprocessor define.
 *
 * Arguments:
 *    MicoPassthruCtx_t *ctx : Slave Passthru context
 *
 *****************************************************************************
 */
void MicoPassthruISR (MicoPassthruCtx_t *ctx)
{
}
#endif

