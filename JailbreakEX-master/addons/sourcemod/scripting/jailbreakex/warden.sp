 // Credits to eeca for the base of this plugin
// https://github.com/ecca


#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <colorvariables>

#define WARDEN_PREFIX "\x04[JBEX - Warden]\x07F8F8FF"

new gWarden = -1;
new gNoBlock = 0;
new gNoBlockLimit = 0;
new gNoBlockSwitches = 0;

new g_Offset_CollisionGroup = -1;
new Handle:g_fward_onBecome = INVALID_HANDLE;
new Handle:g_fward_onRemove = INVALID_HANDLE;
new bool:LaserUse[MAXPLAYERS + 1];
new const g_lpontcolor[4] =  { 255, 255, 255, 255 };
new g_lbeam;
new g_lpont;

public OnMapStart() {
	g_lbeam = PrecacheModel("materials/sprites/laserbeam.vmt");
	g_lpont = PrecacheModel("materials/sprites/redglow1.vmt");
}
public OnClientPutInServer(client)
{
	LaserUse[client] = false;
}

public Warden_OnPluginStart()
{
	
	LoadTranslations("warden.phrases");
	
	RegConsoleCmd("sm_warden", BecomeWarden);
	RegConsoleCmd("sm_w", BecomeWarden);
	RegConsoleCmd("sm_unwarden", LeaveWarden);
	RegConsoleCmd("sm_uw", LeaveWarden);
	RegConsoleCmd("sm_noblock", ToggleNoblock);
	
	RegAdminCmd("sm_rw", RemoveWarden, ADMFLAG_GENERIC);
	
	CreateConVar("sm_jailbreakex_warden_noblock_limit", "3", "Number of times !noblock can be used by the Warden");
	CreateConVar("sm_jailbreakex_warden_noblock_cooldown", "30.0", "Number of seconds before !noblock can be used again");
	
	HookEvent("round_start", warden_roundStart);
	HookEvent("player_death", warden_playerDeath);
	
	g_Offset_CollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
	
	if (g_Offset_CollisionGroup == -1)
	{
		SetFailState("Unable to find offset for collision groups.");
	}
	
	g_fward_onBecome = CreateGlobalForward("warden_OnWardenCreated", ET_Ignore, Param_Cell);
	g_fward_onRemove = CreateGlobalForward("warden_OnWardenRemoved", ET_Ignore, Param_Cell);
	
}

public Action SetNewWarden(client)
{
	PrintToChatAll("%s %t", WARDEN_PREFIX, "warden_new", client);
	gWarden = client;
	SetEntityRenderColor(client, 0, 0, 255, 255);
	SetClientListeningFlags(client, VOICE_NORMAL);
	Forward_OnWardenCreation(client);
}

public Action:BecomeWarden(client, args)
{
	
	// If there is no Warden
	if (gWarden == -1)
	{
		if (GetClientTeam(client) == COUNTERTERRORIST)
		{
			if (IsPlayerAlive(client))
			{
				SetNewWarden(client);
			}
			else
			{
				PrintToChat(client, "%s %t", WARDEN_PREFIX, "warden_playerdead");
			}
		}
		else
		{
			PrintToChat(client, "%s %t", WARDEN_PREFIX, "warden_ctsonly");
		}
	}
	else
	{
		PrintToChat(client, "%s %t", WARDEN_PREFIX, "warden_exist", gWarden);
	}
	
}

public Action:LeaveWarden(client, args)
{
	if (client == gWarden)
	{
		PrintToChatAll("%s %t", WARDEN_PREFIX, "warden_retire", client);
		gWarden = -1;
		SetEntityRenderColor(client, 255, 255, 255, 255);
	}
	else
	{
		PrintToChat(client, "%s %t", "warden_notwarden");
	}
}

public Action:warden_roundStart(Handle:event, const String:name[], bool:dontbroadcast)
{
	gWarden = -1;
	gNoBlock = 0;
	gNoBlockLimit = GetConVarInt(FindConVar("sm_jailbreakex_warden_noblock_limit"));
	gNoBlockSwitches = 0;
	new numberOfCT = 0;
	new lastCT = 0;
	
	BlockAll();
	
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == COUNTERTERRORIST && IsPlayerAlive(i))
			{
				numberOfCT++;
				lastCT = i;
			}
		}
		
	}
	
	if (numberOfCT == 1 && lastCT != 0)
	{
		SetNewWarden(lastCT);
	}
	
}

public Action:warden_playerDeath(Handle:event, const String:name[], bool:dontbroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new numberOfCT = 0;
	new lastCT = 0;
	
	if (client == gWarden)
	{
		PrintToChatAll("%s %t", WARDEN_PREFIX, "warden_dead");
		SetEntityRenderColor(client, 255, 255, 255, 255);
		gWarden = -1;
	}
	
	for (new i = 1; i < MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == COUNTERTERRORIST && IsPlayerAlive(i))
			{
				numberOfCT++;
				lastCT = i;
			}
		}
		
	}
	
	if (numberOfCT == 1 && lastCT != 0 && lastCT != gWarden)
	{
		SetNewWarden(lastCT);
	}
	
}

public OnClientDisconnect(client)
{
	if (client == gWarden)
	{
		PrintToChatAll("%s %t", WARDEN_PREFIX, "warden_disconnected");
		gWarden = -1;
	}
}

public Action:RemoveWarden(client, args)
{
	if (gWarden != -1)
	{
		PrintToChatAll("%s %t", WARDEN_PREFIX, "warden_removed", client, gWarden);
		SetEntityRenderColor(gWarden, 255, 255, 255, 255);
		gWarden = -1;
		Forward_OnWardenRemoved(client);
	}
	else
	{
		PrintToChatAll("%s %t", WARDEN_PREFIX, "warden_noexist");
	}
	
	return Plugin_Handled;
	
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if ((buttons & IN_USE))
	{
		if (IsPlayerAlive(client))
		{
			if ((client == gWarden))
			{
				LaserUse[client] = true;
				if (IsClientInGame(client) && LaserUse[client])
				{
					decl Float:m_fOrigin[3], Float:m_fImpact[3];
					GetClientEyePosition(client, m_fOrigin);
					GetClientSightEnd(client, m_fImpact);
					TE_SetupBeamPoints(m_fOrigin, m_fImpact, g_lbeam, 0, 0, 0, 0.1, 0.12, 0.0, 1, 0.0, { 0, 255, 0, 255 }, 0);
					TE_SendToAll();
					TE_SetupGlowSprite(m_fImpact, g_lpont, 0.1, 0.25, g_lpontcolor[3]);
					TE_SendToAll();
				}
			}
		}
	}
	else if (!(buttons & IN_USE))
	{
		LaserUse[client] = false;
	}
	return Plugin_Continue;
}

stock GetClientSightEnd(client, Float:out[3])
{
	decl Float:m_fEyes[3];
	decl Float:m_fAngles[3];
	GetClientEyePosition(client, m_fEyes);
	GetClientEyeAngles(client, m_fAngles);
	TR_TraceRayFilter(m_fEyes, m_fAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceRayDontHitPlayers);
	if (TR_DidHit())
		TR_GetEndPosition(out);
}

public bool:TraceRayDontHitPlayers(entity, mask, any:data)
{
	if (0 < entity <= MaxClients)
		return false;
	return true;
}

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
	
	if (gWarden == client)
	{
		if (IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == COUNTERTERRORIST)
		{
			if (!StrEqual(command, "say_team"))
			{	
					if (!CheckCommandAccess(client, "sm_say", ADMFLAG_CHAT))
					{
						PrintToChatAll("\x0700008B[Warden] \x0700BFFF%N \x07000000: \x07FFC0CB%s", client, sArgs);
						LogAction(client, -1, "[Warden] %N : %s", client, sArgs);
						return Plugin_Handled;					
					}
					else 
					{
						if (sArgs[0] != '@')
						{
							PrintToChatAll("\x0700008B[Warden] \x0700BFFF%N \x07000000: \x07FFC0CB%s", client, sArgs);
							LogAction(client, -1, "[Warden] %N : %s", client, sArgs);
							return Plugin_Handled;
						}
					}
			}
			else
			{
				for (new i = 1; i <= MaxClients; i++)
				{
					if (IsValidClient(i) && GetClientTeam(i) == COUNTERTERRORIST)
					{
						if (sArgs[0] != '@')
						{
						PrintToChat(i, "\x01(Counter-Terrorist) \x0700008B[Warden] \x0700BFFF%N \x07000000: \x07FFC0CB%s", client, sArgs);
						LogAction(client, -1, "[Warden] %N : %s", client, sArgs);
						}
					}
				}
				return Plugin_Handled;
			}
		}
		else
        {
            PrintToChatAll("\x0700008B[Warden] \x0700BFFF%N \x01: %s", client, sArgs);
            LogAction(client, -1, "[Warden] %N : %s", client, sArgs);
            return Plugin_Handled;
        }   
	}
	
	return Plugin_Continue;
}

public Action:ToggleNoblock(client, args)
{
    if(client == gWarden) 
    {
        if(gNoBlockLimit == 0)
        {
            PrintToChat(client, "%s Noblock toggle is disabled!", WARDEN_PREFIX);
            return Plugin_Handled;
        }
        if(gNoBlockSwitches >= gNoBlockLimit)
        {
            PrintToChat(client, "%s Noblock has already been used %d times!", WARDEN_PREFIX, gNoBlockSwitches);
            return Plugin_Handled;
        }
        if(!gNoBlock) 
        {
            UnBlockAll();
            PrintToChatAll("%s Noblock has been enabled!", WARDEN_PREFIX);
            gNoBlock = 1;
        }
        else 
        {
            BlockAll();
            PrintToChatAll("%s Noblock has been disabled!", WARDEN_PREFIX);
            gNoBlock = 0;
            gNoBlockSwitches++;
        }
    }
    else 
    {
        PrintToChat(client, "%s Only the Warden can toggle NoBlock!", WARDEN_PREFIX);
    }

    return Plugin_Continue;

}

public Action:UnBlockAll()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntData(i, g_Offset_CollisionGroup, 2, 4, true);
		}
	}
}

public Action:BlockAll()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			SetEntData(i, g_Offset_CollisionGroup, 5, 4, true);
		}
	}
}


public Forward_OnWardenCreation(client)
{
	Call_StartForward(g_fward_onBecome);
	Call_PushCell(client);
	Call_Finish();
	
}

public Forward_OnWardenRemoved(client)
{
	Call_StartForward(g_fward_onRemove);
	Call_PushCell(client);
	Call_Finish();
}

public bool:IsValidClient(client)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client))
		return false;
	
	return true;
} 