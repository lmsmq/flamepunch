#include <sourcemod>
#include <sdktools>
#include <cstrike>

new String:tGiveWeaponList[256];
new String:ctGiveWeaponList[256];
new String:tWepList[8][32];
new String:ctWepList[8][32];
new tWepListSize;
new ctWepListSize;

public CTWeapon_OnPluginStart()
{
	
	Format(tGiveWeaponList, sizeof(tGiveWeaponList), "weapon_knife");
	Format(ctGiveWeaponList, sizeof(ctGiveWeaponList), "weapon_knife,weapon_ak47,weapon_usp");
	
	UpdateStartWeapons();	
	
	HookEvent("player_spawn", StartWeapons_Spawn);
}

public StartWeapons_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	StripAllWeapons(client);
		
	new team = GetClientTeam(client);
	switch (team)
	{
		case CS_TEAM_T:
		{
			for (new i = 0; i < tWepListSize; i++)
			{
				GivePlayerItem(client, tWepList[i]);
			}
		}
		case CS_TEAM_CT:
		{
			for (new j = 0; j < ctWepListSize; j++)
			{
				GivePlayerItem(client, ctWepList[j]);
			}
		}
	}
}

void StripAllWeapons(client)
{
	new wep;
	for (new i; i < 4; i++)
	{
		if ((wep = GetPlayerWeaponSlot(client, i)) != -1)
		{
			RemovePlayerItem(client, wep);
			AcceptEntityInput(wep, "Kill");
		}
	}
}

void UpdateStartWeapons()
{

	tWepListSize = ExplodeString(tGiveWeaponList, ",", tWepList, sizeof(tWepList), sizeof(tWepList[]));
	ctWepListSize = ExplodeString(ctGiveWeaponList, ",", ctWepList, sizeof(ctWepList), sizeof(ctWepList[]));
}

