#include "inc_cdb"
#include "inc_pgsql"

void main() {

	object oKilled = GetLastPlayerDied();
	object oKiller = GetLastDamager(oKilled);

	if ( !GetIsPC(oKilled) || !GetIsPC(oKiller) )
		return;

	int nIDKilled = GetCharacterID(oKilled),
		nIDKiller = GetCharacterID(oKiller);

	pQ("insert into pc_kills (killer_id, killee_id, area_resref) values('" +
		IntToString(nIDKiller) + "', '" + IntToString(nIDKilled) + "', " +
		pE(GetResRef(GetArea(oKilled))) + ");");
}
