public CTArmor_OnPluginStart()
{
    HookEvent("player_spawn", playerSpawn);
}

public playerSpawn(Handle:event, String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    if(IsPlayerAlive(client) && GetClientTeam(client) == COUNTERTERRORIST)
    {
        SetEntProp(client, PropType:0, "m_ArmorValue", 50);
    }
}