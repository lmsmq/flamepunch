#pragma semicolon 1

#define PLUGIN_NAME         "JailbreakEX"
#define PLUGIN_AUTHOR       "Adam Short and Shawn"
#define PLUGIN_DESCRIPTION  "Jailbreak Redone for CS:S"
#define PLUGIN_VERSION      "0.01"
#define PLUGIN_URL          "https://github.com/ashort96/JailbreakEX"


#define SPECTATOR           1
#define TERRORIST           2
#define COUNTERTERRORIST    3


#include <sourcemod>
#include <sdktools>
#include <colorvariables>

#include "jailbreakex/warden.sp"
#include "jailbreakex/ctarmor.sp"
#include "jailbreakex/ctweapon.sp"
#include "jailbreakex/teambalance.sp"
#include "jailbreakex/lastrequest.sp"
public Plugin myinfo = 
{
	name = PLUGIN_NAME, 
	author = PLUGIN_AUTHOR, 
	description = PLUGIN_DESCRIPTION, 
	version = PLUGIN_VERSION, 
	url = PLUGIN_URL
}

public OnPluginStart()
{
	
	Warden_OnPluginStart();
	CTArmor_OnPluginStart();
	CTWeapon_OnPluginStart();
	TeamBalance_OnPluginStart();
	//LastRequest_OnPluginStart();
	
	AutoExecConfig(true, "jailbreakex");
	
}
