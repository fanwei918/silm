// A generic script to allow for money collection.

#include "inc_pgsql"
#include "_gen"


void OnCollectboxDisturb(object oGivenByPC, object oItem) {

	string sName = GetLocalString(OBJECT_SELF, "collectbox_name");
	if ( sName == "" ) {
		SendMessageToAllDMs("Collectbox has no name set.");
		return;
	}

    //coin_0100
	if ( GetStringLeft(GetResRef(oItem), 5) != "coin_" ) {
		ToPC("Dieses Objekt passt nicht hier hin ..", oGivenByPC);
		ActionGiveItem(oItem, oGivenByPC);
		return;
	}


	ppP("select text, character from collectboxes where name = ?;");
	ppSs(sName);
	ppQ();
	if (!pF()) {
		SendMessageToAllDMs("Collectbox has no database entry.");
		ActionGiveItem(oItem, oGivenByPC);
		return;
	}

	string sText = pGs(1);

	if ("" == sText) {
			sText = "Ein leises Klimpern erklingt, als die Muenzen am Boden des Sammelgefaesses auftreffen.";
	}
	
	int nMulti = StringToInt(GetStringRight(GetResRef(oItem), 4));
	int nAmount = GetItemStackSize(oItem) * nMulti;

	if ( nAmount > 0 )
		pQ("update collectboxes set value = value+" +
			IntToString(nAmount) + " where name = " + pE(sName) + ";");

	DestroyObject(oItem);
	FloatingTextStringOnCreature(
		sText, oGivenByPC,
	1);

	return;
}
