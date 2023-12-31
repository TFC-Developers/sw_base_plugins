// code by watch/fm see https://github.com/ben-watch/feckinmad, modified by MrKoala in order to migrate skillzworld 
// from the c++ metamod plugin to amxmodx


#if defined _global_included
  #endinput
#endif
#define _global_included

#pragma ctrlchar '\'
#include <amxmodx>
#include <engine>
#include <fakemeta>

//#define MAX_PLAYERS 18 // depreciated
#define MAX_MAP_LEN 32
#define MAX_NAME_LEN 32
#define MAX_AUTHID_LEN 36
#define MAX_HUDMSG_LEN 480
#define MAX_RESOURCE_LEN 64 // sdk/engine/custom.h
#define MAX_CHAT_LEN 128
#define MAX_CONSOLE_LEN 128
#define MAX_HASH_LEN 34
#define MAX_SERVER_PRINT_LEN 255 // Pretty sure it crashes if more than this because amxx does checks in server_print

stock const FM_FOPEN_WARNING[] = "Failed to open file: \"%s\""
stock const FM_ENT_WARNING[] = "Failed to create entity"
stock const FM_LINE_WARNING[] = "Line #%d in \"%s\" is incomplete"
stock const FM_VAULT_WARNING[] = "Failed to open vault: \"%s\""
stock const FM_LICENSE_WARNING[] = "License key not valid"
stock const FM_FORWARD_WARNING[] = "Failed to create forward: \"%s\""

stock const FM_AMXX_LOCAL_CONFIGS[] = "amxx_configsdir"
stock const FM_AMXX_LOCAL_DATA[] = "amxx_datadir"

#define fm_ValidPlayer(%1) (1<=(%1)<=MAX_PLAYERS)
#define fm_PrintStar(%1) ((%1 == print_chat) ? "* " : "")
#define fm_Comment(%1) (!%1[0] || %1[0] == ';' || %1[0] == '#' || (%1[0] == '/' && %1[1] == '/' ))

#include "include/debug" // A lot of plugins will use this. Also Required for RegisterPlugin() included below
#include "include/stock_registerplugin"  // Every plugin will need this, also need SCRIPT_NAME for fm_WarningLog


stock bool:is_connected_admin(id){return (is_user_connected(id) && (get_user_flags(id) & ADMIN_KICK) && !is_user_bot(id));}
stock bool:is_connected_user(id){return (is_user_connected(id) && !is_user_bot(id));}

stock GetRealPlayerNum()
{
	new iCount
	for (new i = 1, iMaxPlayers = get_maxplayers(); i <= iMaxPlayers; i++)
		if (is_user_connected(i) && !is_user_bot(i) && !is_user_hltv(i))
			iCount++
	return iCount
}

stock bool:equal_vectors(Float:vec1[3], Float:vec2[3]) {
    return (floatround(vec1[0]) == floatround(vec2[0]) && 
            floatround(vec1[1]) == floatround(vec2[1]) && 
            floatround(vec1[2]) == floatround(vec2[2]));
}

stock GetAimEntity(id)
{
	new Float:fPlayerOrigin[3]; pev(id, pev_origin, fPlayerOrigin)
	new Float:fPlayerViewOff[3]; pev(id, pev_view_ofs, fPlayerViewOff)
	new Float:fAngles[3]; pev(id, pev_v_angle, fAngles)

	engfunc(EngFunc_MakeVectors, fAngles)
	global_get(glb_v_forward, fAngles)

	new Float:fEndPos[3]
	for (new i = 0; i < 3; i++)
	{
		fPlayerOrigin[i] += fPlayerViewOff[i] // Calculate view offset from origin
		fEndPos[i] = fPlayerOrigin[i] + (fAngles[i] * 4096.0) // Scale up normalised vector
	}
		
	engfunc(EngFunc_TraceLine, fPlayerOrigin, fEndPos , 0, id, 0) // Run trace
	new iEnt = get_tr2(0, TR_pHit) // Get the entity hit

	return iEnt > 0 ? iEnt : 0
}


stock BuildAMXFilePath(const sFile[], sStringOut[], iStringOutLen, const sLocalDir[])
{
	new sDirectory[64]; get_localinfo(sLocalDir, sDirectory, charsmax(sDirectory))
	formatex(sStringOut, iStringOutLen, "%s/%s", sDirectory, sFile)
}

stock WarningLog(const sFormat[], any:...)
{
	static sMessage[512]; sMessage[0] = '\0'
	vformat(sMessage, charsmax(sMessage), sFormat, 2)

	new sLogFile[32]; get_time("warning_%Y%m%d.log", sLogFile, charsmax(sLogFile))
	log_to_file(sLogFile, "[%s] %s", _SCRIPT_NAME, sMessage)
	return 0
}

stock PlaySound(id, const sSound[])
{
	client_cmd(id, "spk %s", sSound) // "play" plays at an origin so use "spk"
}

stock fm_CommandUsage(id, iCommand, iNum, iClient = 0)
{
	if (read_argc() < iNum)
	{
		new sCommand[32], sInfo[128], iFlag, iLevel
		if (iClient)
		{
			get_clcmd (iCommand, sCommand, charsmax(sCommand), iFlag, sInfo, charsmax(sInfo), iLevel)
		}
		else
		{
			get_concmd(iCommand, sCommand, charsmax(sCommand), iFlag, sInfo, charsmax(sInfo), iLevel)
		}

		console_print(id, "Not enough arguments supplied. Usage: %s %s", sCommand, sInfo)
		return 0
	}
	return 1
}


stock fm_CopyStruc(eStruct1[], eStruct2[], iStructLen)
{
	for (new i = 0; i <= iStructLen; i++)
	{
		eStruct2[i] = eStruct1[i]
	}
}

// Fix for is_str_num not detecting - or + by danielkza
stock bool:is_str_num2(const sString[])
{
	new i = 0, bool:bSigned

	if(sString[0] == '-' || sString[0] == '+')
	{
		bSigned = true
		++i
	}
	
	while (sString[i] && isdigit(sString[i]))
		++i

	return sString[i] == 0 && (!bSigned ? i != 0 : i > 1)
}

stock fm_GetFileNameFromPath(sPath[])
{
	for (new i = strlen(sPath); i >= 0; i--)
		if (sPath[i] == '\\' || sPath[i] == '/')
			return i + 1
	return 0
}

stock fm_FormatPosition(iNum, sPosition[], iLen) 
{
	if (iNum < 11 || iNum > 13)
	{
		switch(iNum % 10)
		{
			case 1: return formatex(sPosition, iLen, "%dst", iNum)
			case 2: return formatex(sPosition, iLen, "%dnd", iNum)
			case 3: return formatex(sPosition, iLen, "%drd", iNum)
		}
	}
	return formatex(sPosition, iLen, "%dth", iNum)
}