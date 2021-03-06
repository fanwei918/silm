//::///////////////////////////////////////////////
//:: Intimidate Check Easy - Strength Based
//:: x2_intdtstr_med
//:: Copyright (c) 2001 Bioware Corp.
//:://////////////////////////////////////////////
/*
    Check to see if the character made a medium
    intimidate check. (#24 in the skills.2da), and
    include the PCs strength bonus for this check
*/
//:://////////////////////////////////////////////
//:: Created By: Keith Warner
//:: Created On: Dec 17/02
//:://////////////////////////////////////////////

#include "nw_i0_plot"

int StartingConditional()
{
    return CheckDCStr(DC_MEDIUM, 24, GetPCSpeaker());
}
