#define TEAMBALANCE_PREFIX "\x04[JBEX - TeamBalance]\x07F8F8FF"

public TeamBalance_OnPluginStart()
{
    CreateConVar("sm_jailbreakex_tb_enable", "1", "Enable Team Balance for JailbreakEX");
    CreateConVar("sm_jailbreakex_tb_ratio", "2", "Ratio of T to CT");
    RegConsoleCmd("jointeam", BalanceTeams);
}

public Action:BalanceTeams(client, args)
{
    new teamRatio = GetConVarInt(FindConVar("sm_jailbreakex_tb_ratio"));

    //If the plugin isn't enabled, skip
    if(!GetConVarBool(FindConVar("sm_jailbreakex_tb_enable")))
    {
        return Plugin_Continue;
    }

    // If the client isn't a real person
    if(!client || !IsClientInGame(client) || IsFakeClient(client))
    {
        return Plugin_Continue;
    }

    decl String:teamString[3];
    GetCmdArg(1, teamString, sizeof(teamString));
    new newTeam = StringToInt(teamString);
    new oldTeam = GetClientTeam(client);

    // disable auto-join 
    if (!((newTeam == TERRORIST) || (newTeam == COUNTERTERRORIST) || (newTeam == SPECTATOR)))
	{	

		PrintToChat(client, "%s Auto-Join Disabled", TEAMBALANCE_PREFIX);
		UTIL_TeamMenu(client);
		return Plugin_Handled;	
	}

    if(newTeam == COUNTERTERRORIST && oldTeam != COUNTERTERRORIST)
    {
        new countTs = 0;
        new countCTs = 0;

        for(new i = 1; i < MaxClients; i++)
        {
            if(IsClientInGame(i))
            {
                if(GetClientTeam(i) == TERRORIST)
                {
                    countTs++;
                }
                if(GetClientTeam(i) == COUNTERTERRORIST)
                {
                    countCTs++;
                }
            }
        }



        if((countCTs < (countTs / teamRatio)) || ! countCTs)
        {
            return Plugin_Continue;
        }
        else
        {
            ClientCommand(client, "play ui/freeze_cam.wav");
            PrintToChat(client, "%s Transfer denied, there are enough CTs!", TEAMBALANCE_PREFIX);
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

UTIL_TeamMenu(client)
{
	new clients[1];
	new Handle:bf;
	clients[0] = client;
	bf = StartMessage("VGUIMenu", clients, 1);
	
	if (GetUserMessageType() == UM_Protobuf)
	{
		PbSetString(bf, "name", "team");
		PbSetBool(bf, "show", true);
	}
	else
	{
		BfWriteString(bf, "team"); // panel name
		BfWriteByte(bf, 1); // bShow
		BfWriteByte(bf, 0); // count
	}
	
	EndMessage();
}