//::///////////////////////////////////////////////
//:: Turn Off Lock Help
//:: X2_CH_TRAP_OFF.nss
//:: Copyright (c) 2001 Bioware Corp.
//:://////////////////////////////////////////////
//:://////////////////////////////////////////////
//:: Created By: Brent
//:: Created On: June 2003
//:://////////////////////////////////////////////
#include "NW_I0_GENERIC"

void main()
{
    SetAssociateState(NW_ASC_DISARM_TRAPS, FALSE);
}


