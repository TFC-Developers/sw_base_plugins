#include "include/global"
#include "include/sql_playerdata"
#include "include/sql_tquery"
#include "include/sql_dbqueries"
#include <messages>


#define STATUSICON 81
#define STATUS_ARG 1
#define RED_ARG 5
#define GREEN_ARG 6
#define BLUE_ARG 7


new Array: g_PlayerData = Invalid_Array;
new bool:g_bHasColoredConcsHud[33];


public plugin_natives()
{
	set_task(60.0, "task_increase_playtime", _, _, _, "b");					//increase playtime in database every 60 seconds
	register_library("api_player");											//register plugin as library
}


public plugin_init() 
{
	RegisterPlugin();	
	g_PlayerData = ArrayCreate(ePlayerStruct_t);							//create global array of playerdata
	//register_message(get_user_msgid("SayText"), "Handle_SayText");			//register message SayText
	register_clcmd("say", "Handle_Say");							//register command /stats
	register_clcmd("say_team", "Handle_Say");								//register command /top
	register_forward(FM_ClientUserInfoChanged, "Forward_ClientUserInfoChanged") //register forward ClientUserInfoChanged
	//register_message( STATUSICON, "nade_color" );
}

public plugin_end() 
{
	task_increase_playtime();												//increase playtime in database before unloading
	ArrayDestroy(g_PlayerData);												//destroy global array of playerdata

	for (new i = 1; i <= get_maxplayers(); i++) {							//cycle through all players
		if (is_connected_user(i)) {											//if player is connected
			sql_insertserverlog(i,"mapchange");								//log player disconnect
		}
	}
}

public Handle_GetCommonname(iPluign, iParams) {
	new id = get_param(1); 													// Get the first parameter
	new szSteamID[64]; get_user_authid(id, szSteamID, charsmax(szSteamID));	// Get the player's authid
	new szQuery[512]; formatex(szQuery, charsmax(szQuery), sql_get_common_name, szSteamID);	// Create the query string INSERT
	new Data[1]; Data[0] = id;													// Create the data array to pass to the query which contains the player's id
	api_SQLAddThreadedQuery(szQuery,"Handle_GetCommonname", QUERY_NOT_DISPOSABLE, PRIORITY_HIGH, Data, 1);	// Add the query to the queue
	return PLUGIN_HANDLED;
}

public Handle_GetCommonname_Results(Query, Error, Data[], Rows) {
	new id = Data[0];															// Get the player's id

}

public Forward_ClientUserInfoChanged(id, Buffer)
{
	if (!is_user_connected(id))
	{
		return FMRES_IGNORED
	}

	new sOldName[MAX_NAME_LEN]; get_user_name(id, sOldName, charsmax(sOldName))
	new sNewName[MAX_NAME_LEN]; engfunc(EngFunc_InfoKeyValue, Buffer, "name", sNewName, charsmax(sNewName))	
	//only call when old and new name mismatch
	if (!equal(sOldName, sNewName))
	{	
		sql_insertserverlog_data(id, "namechange", sNewName);
		new szSteamID[64]; get_user_authid(id, szSteamID, charsmax(szSteamID));										// Get the player's authid
		new szQuery[512]; formatex(szQuery, charsmax(szQuery), sql_updatenamequery, szSteamID, sNewName);			// Create the query string INSERT
		new Data[1]; Data[0] = id;																					// Create the data array to pass to the query which contains the player's id
		api_SQLAddThreadedQuery(szQuery,"Handle_UpdateName", QUERY_NOT_DISPOSABLE, PRIORITY_NORMAL, Data, 1);			// Add the query to the queue
	}


	return FMRES_IGNORED
}

public sql_serverlog_detailed(id, const name[], const ip[], action_type[]) {
	new szHostname[64];  get_cvar_string("hostname", szHostname, 63);										// Get the hostname
	new szMapName[64];  get_mapname(szMapName, charsmax(szMapName));										// Get the mapname
	new szSteamID[64]; get_user_authid(id, szSteamID, charsmax(szSteamID));									// Get the player's authid
	new szQuery[512]; formatex(szQuery, charsmax(szQuery), sql_serverlog, szSteamID, ip, name, szHostname, szMapName, action_type, szSteamID);				// Create the query string INSERT
	new Data[1]; Data[0] = id;																				// Create the data array to pass to the query which contains the player's id
	api_SQLAddThreadedQuery(szQuery,"Handle_ServerLog", QUERY_NOT_DISPOSABLE, PRIORITY_NORMAL, Data, 1);		// Add the query to the queue

}
public sql_insertserverlog(id, action_type[]) {
	new szHostname[64];  get_cvar_string("hostname", szHostname, 63);										// Get the hostname
	new szMapName[64];  get_mapname(szMapName, charsmax(szMapName));										// Get the mapname
	new szSteamID[64]; get_user_authid(id, szSteamID, charsmax(szSteamID));									// Get the player's authid
	new szIP[64]; get_user_ip(id, szIP, charsmax(szIP),1);													// Get the player's ip
	new szName[64]; get_user_name(id, szName, charsmax(szName));											// Get the player's name
	new szQuery[512]; formatex(szQuery, charsmax(szQuery), sql_serverlog, szSteamID, szIP, szName, szHostname, szMapName, action_type, szSteamID);				// Create the query string INSERT
	new Data[1]; Data[0] = id;																				// Create the data array to pass to the query which contains the player's id
	api_SQLAddThreadedQuery(szQuery,"Handle_ServerLog", QUERY_NOT_DISPOSABLE, PRIORITY_NORMAL, Data, 1);		// Add the query to the queue
}
public sql_insertserverlog_data(id, action_type[], data[]) {
	new szHostname[64];  get_cvar_string("hostname", szHostname, 63);										// Get the hostname
	new szMapName[64];  get_mapname(szMapName, charsmax(szMapName));										// Get the mapname
	new szSteamID[64]; get_user_authid(id, szSteamID, charsmax(szSteamID));									// Get the player's authid
	new szIP[64]; get_user_ip(id, szIP, charsmax(szIP),1);													// Get the player's ip
	new szName[64]; get_user_name(id, szName, charsmax(szName));											// Get the player's name
	new szQuery[512]; formatex(szQuery, charsmax(szQuery), sql_serverlogdata, szSteamID, szIP, szName, szHostname, szMapName, action_type, data, szSteamID);				// Create the query string INSERT
	new Data[1]; Data[0] = id;																				// Create the data array to pass to the query which contains the player's id
	api_SQLAddThreadedQuery(szQuery,"Handle_ServerLog", QUERY_NOT_DISPOSABLE, PRIORITY_NORMAL, Data, 1);		// Add the query to the queue
}
public client_disconnect(id) {

	new Buffer[ePlayerStruct_t];
	for(new i = 0; i < ArraySize(g_PlayerData); i++)
	{
		ArrayGetArray(g_PlayerData, i, Buffer);
		if (Buffer[mPD_iPlayerID] == id) { 
			DebugPrintLevel(0,"Removing player %d from array at index %d", id, i);
			ArrayDeleteItem(g_PlayerData, i);
		 }
		 //remove his data from the array

	}
	sql_insertserverlog(id,"disconnect");																			//log player disconnect
	
}
public client_putinserver(id)
{
	if (!is_connected_user(id) || is_user_hltv(id)) { return PLUGIN_HANDLED; }								// Ignore bots and HLTV and unconnected players
	sql_insertserverlog(id,"connect");																		//log player putinserver
	new sAuthid[MAX_AUTHID_LEN]; get_user_authid(id, sAuthid, charsmax(sAuthid));							// Get the authid of the player
	new szName[64]; get_user_name(id, szName, charsmax(szName));											// Get the name of the player
	if (equal(sAuthid, "STEAM_ID_PENDING")) { return PLUGIN_CONTINUE; }										// Ignore players who are not yet authenticated
	new Data[1]; Data[0] = id;																				// Create the data array to pass to the query which contains the player's id
	new szQuery[512]; formatex(szQuery, charsmax(szQuery), sql_insertplayer, sAuthid, szName);				// Create the query string INSERT 	
	api_SQLAddThreadedQuery(szQuery,"Handle_ConnectQuery", QUERY_NOT_DISPOSABLE, PRIORITY_HIGH, Data, 1);	// Add the query to the queue
	sql_updatenickname(id);																					// Update the player's nickname

	g_bHasColoredConcsHud[id] = false;																		// Set the player's colored concs hud to false
	return PLUGIN_HANDLED;
}
public Handle_ConnectQuery(iFailState, Handle:hQuery, sError[], iError, Data[], iLen, Float:fQueueTime, iQueryIdent) 
{
	new id; if (iLen > 0) { id = Data[0]; } 																// Get the player's id from the data array
	if (!is_connected_user(id)) { return PLUGIN_HANDLED; }													// Seems like the player disconnected before the query finished
	new szAuthid[MAX_AUTHID_LEN]; get_user_authid(id, szAuthid, charsmax(szAuthid));						// Get the player's authid
	new szQuery[512]; formatex(szQuery, charsmax(szQuery), sql_loadplayer, szAuthid);						// Create the query string SELECT *
	api_SQLAddThreadedQuery(szQuery,"Handle_ConnectQuery2", QUERY_NOT_DISPOSABLE, PRIORITY_HIGH, Data, 1);	// Add the query to the queue
	return PLUGIN_HANDLED;	
}
public Handle_ConnectQuery2(iFailState, Handle:hQuery, sError[], iError, Data[], iLen, Float:fQueueTime, iQueryIdent)
{
	new id; if (iLen > 0) { id = Data[0]; } 						// Get the player's id from the data array
	if (!is_connected_user(id)) { return PLUGIN_HANDLED; }			// Seems like the player disconnected before the query finished

	new szName[64]; get_user_name(id, szName, charsmax(szName));	// Get the player's name
	if(SQLCheckThreadedError(iFailState, hQuery, sError, iError)) 
	{
		WarningLog("Failed to load player data for <%s> from database", szName)
		return PLUGIN_HANDLED;
	}

	if (SQL_NumResults(hQuery) > 0)									// check if we have any results and use first row
	{										
		new Buffer[ePlayerStruct_t];
		if (SQL_FieldNameToNum(hQuery,"id") >= 0) { Buffer[mPD_iPlayerID] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"id")); }
		if (SQL_FieldNameToNum(hQuery,"steamid") >= 0) { SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"steamid"),Buffer[mPD_szSteamID],charsmax(Buffer[mPD_szSteamID])); }
		if (SQL_FieldNameToNum(hQuery,"userlevel") >= 0) { Buffer[mPD_iPlayerLevel] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"userlevel")); }
		if (SQL_FieldNameToNum(hQuery,"firstnick") >= 0) { SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"firstnick"),Buffer[mPD_szFirstName],charsmax(Buffer[mPD_szFirstName])); }
		if (SQL_FieldNameToNum(hQuery,"created_at") >= 0) { SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"created_at"),Buffer[mPD_szFirstSeen],charsmax(Buffer[mPD_szFirstSeen])); }
		if (SQL_FieldNameToNum(hQuery,"userflags") >= 0) { Buffer[mPD_iPlayerFlags] = SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"userflags")); }
		if (SQL_FieldNameToNum(hQuery,"totaltime") >= 0) { SQL_ReadResult(hQuery, SQL_FieldNameToNum(hQuery,"totaltime"),Buffer[mPD_ftTime]); }
		Buffer[mPD_iPlayerID] = id;
		Buffer[mPD_ftLastPTUpdate] = get_gametime();
		internal_pusharray(Buffer);

	} else	{ DebugPrintLevel(0, "No results found for <%s>", szName); }
	

	return PLUGIN_HANDLED;
}

public internal_pusharray( Buffer[ePlayerStruct_t] ) {
	ArrayPushArray(g_PlayerData, Buffer);
	DebugPrintLevel(0, "PlayerData for %d (%s) added to array", Buffer[mPD_iPlayerID], Buffer[mPD_szFirstName]);
	//dump_playerdata(Buffer[mPD_iPlayerID]);
}

stock dump_sqldata(Handle:hQuery) {
        new iColumns = SQL_NumColumns(hQuery); 
        DebugPrintLevel(0, "---------------------------------");
		DebugPrintLevel(0, "SQL_NumResults: %d", SQL_NumResults(hQuery));
        if (iColumns == 0) { DebugPrintLevel(0, "No columns found."); return; }
        new szColumns[256];
        for(new i = 0; i < iColumns; i++)
        {
            SQL_FieldNumToName(hQuery, i, szColumns, charsmax(szColumns));
            new szValue[256];
            SQL_ReadResult(hQuery, i, szValue, charsmax(szValue));
            DebugPrintLevel(0, "Column %d (%s) = %s", i, szColumns, szValue);  
        }
        DebugPrintLevel(0, "---------------------------------");
}

stock dump_playerdata(id) {
	new szName[64]; get_user_name(id, szName, charsmax(szName));				// Get the player's name
	new szSteamID[64]; get_user_authid(id, szSteamID, charsmax(szSteamID));		// Get the player's authid	
	new Buffer[ePlayerStruct_t];
	//find the player in the array based on id
	for(new i = 0; i < ArraySize(g_PlayerData); i++)
	{
		ArrayGetArray(g_PlayerData, i, Buffer);
		if (Buffer[mPD_iPlayerID] == id) { 
			DebugPrintLevel(0,"---------------------------------");
			DebugPrintLevel(0,"Found player %d (%s) in array at index %d", id, szName, i);
			DebugPrintLevel(0,"PlayerData for %d (%s) in array", Buffer[mPD_iPlayerID], Buffer[mPD_szFirstName]);
			DebugPrintLevel(0,"---------------------------------");
			DebugPrintLevel(0,"mPD_iPlayerID: %d", Buffer[mPD_iPlayerID]);
			DebugPrintLevel(0,"mPD_iPlayerFlags: %d", Buffer[mPD_iPlayerFlags]);
			DebugPrintLevel(0,"mPD_iPlayerLevel: %d", Buffer[mPD_iPlayerLevel]);
			DebugPrintLevel(0,"mPD_szFirstName: %s", Buffer[mPD_szFirstName]);
			DebugPrintLevel(0,"mPD_szFirstSeen: %s", Buffer[mPD_szFirstSeen]);
			DebugPrintLevel(0,"mPD_szSteamID: %s", Buffer[mPD_szSteamID]);
			DebugPrintLevel(0,"mPD_ftTime: %f", Buffer[mPD_ftTime]);
			DebugPrintLevel(0,"---------------------------------");

		 }
	}

}

public task_increase_playtime() {
	new Buffer[ePlayerStruct_t];																	//create buffer
	new Float:fPlayTime;																			//create float for playtime
	for(new i = 0; i < ArraySize(g_PlayerData); i++)												//cycle through all players
	{																			
		ArrayGetArray(g_PlayerData, i, Buffer);
		new szNickname[32]; 														//get playerdata from array
		DebugPrintLevel(0,"Increasing #%d (%s) Player connected at %f",i, Buffer[mPD_szFirstName], Buffer[mPD_ftLastPTUpdate]);					//debug
		fPlayTime = floatsub(get_gametime(),Buffer[mPD_ftLastPTUpdate]);							//get playtime since last update
		new szName[64]; get_user_name(Buffer[mPD_iPlayerID], szName, charsmax(szName));				// Get the player's name
		//DebugPrintLevel(0,"Playtime of %d (%s) increased by %f", Buffer[mPD_iPlayerID], szName, fPlayTime);
		Buffer[mPD_ftLastPTUpdate] = get_gametime();												//update last update time
		sql_UpdateTime(Buffer[mPD_iPlayerID], fPlayTime);											//update playtime in database
		ArraySetArray(g_PlayerData, i, Buffer);														//update playerdata in array
	}
}

public sql_UpdateTime(id, Float:fTime) {
	/*//requires %f/time %s/steamid
new const sql_updatetime[] = "UPDATE players SET totaltime = totaltime + %f WHERE steamid = '%s';"**/
	new szSteamID[64]; get_user_authid(id, szSteamID, charsmax(szSteamID));									// Get the player's authid	
	new szQuery[512]; formatex(szQuery, charsmax(szQuery), sql_updatetime, fTime, szSteamID);				// Create the query string INSERT 	
	new Data[1]; Data[0] = id;																				// Create the data array to pass to the query which contains the player's id
	api_SQLAddThreadedQuery(szQuery,"Handle_UpdateTime", QUERY_NOT_DISPOSABLE, PRIORITY_HIGH, Data, 1);		// Add the query to the queue
	
}

public Handle_UpdateTime(iFailState, Handle:hQuery, sError[], iError, Data[], iLen, Float:fQueueTime, iQueryIdent) 
{
	new id; if (iLen > 0) { id = Data[0]; } 																// Get the player's id from the data array

	new szName[64]; get_user_name(id, szName, charsmax(szName));											// Get the player's name
	if(SQLCheckThreadedError(iFailState, hQuery, sError, iError)) 
	{
		WarningLog("Failed to update playtime for <%s> in database", szName)
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;	
}

public Handle_ServerLog(iFailState, Handle:hQuery, sError[], iError, Data[], iLen, Float:fQueueTime, iQueryIdent) 
{
	new id; if (iLen > 0) { id = Data[0]; } 																// Get the player's id from the data array
	if(SQLCheckThreadedError(iFailState, hQuery, sError, iError)) 
	{
		WarningLog("ServerLog query failed!");
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;	
}


public Handle_Say(id) {
	//get the second argument
	new sArgs[MAX_CHAT_LEN];  read_args(sArgs, charsmax(sArgs));	//get the second argument
	if (strlen(sArgs) <= 2) { return PLUGIN_CONTINUE; }				//empty message
	remove_quotes(sArgs);											//remove quotes
	if (sArgs[0] == '/') { return PLUGIN_CONTINUE; }
	sql_insertserverlog_data(id, "say", sArgs);
	return PLUGIN_CONTINUE
}

public sql_updatenickname(id) {
	new szSteamID[64]; get_user_authid(id, szSteamID, charsmax(szSteamID));										// Get the player's authid
	new szName[64]; get_user_name(id, szName, charsmax(szName));												// Get the player's name
	new szQuery[512]; formatex(szQuery, charsmax(szQuery), sql_updatenamequery, szSteamID, szName);			// Create the query string INSERT
	new Data[1]; Data[0] = id;																					// Create the data array to pass to the query which contains the player's id
	api_SQLAddThreadedQuery(szQuery,"Handle_UpdateName", QUERY_NOT_DISPOSABLE, PRIORITY_HIGH, Data, 1);			// Add the query to the queue
}

public Handle_UpdateName(iFailState, Handle:hQuery, sError[], iError, Data[], iLen, Float:fQueueTime, iQueryIdent) 
{
	new id; if (iLen > 0) { id = Data[0]; } 																		// Get the player's id from the data array
	new szName[64]; get_user_name(id, szName, charsmax(szName));													// Get the player's name
	if(SQLCheckThreadedError(iFailState, hQuery, sError, iError)) 
	{
		WarningLog("Failed to update name for <%s> in database", szName)
		return PLUGIN_HANDLED;
	}
	return PLUGIN_HANDLED;	
}

/*
public nade_color(msg_id, msg_dest, msg_entity) {
	if (g_bHasColoredConcsHud[msg_entity] & ~FLAG_COLCONCHUND) { return; }	//if player doesnt have colored concs hud, return
    if( get_msg_arg_int(STATUS_ARG) ) {

        new red, green, blue;
        red     = random_num( 100, 255 );
        green   = random_num( 100, 255 );
        blue    = random_num( 100, 255 );
        set_msg_arg_int( RED_ARG, ARG_BYTE, red );
        set_msg_arg_int( GREEN_ARG, ARG_BYTE, green );
        set_msg_arg_int( BLUE_ARG, ARG_BYTE, blue );

    }

}
*/

/*
#define FLAG_GLOWCONCS	(1<<8)   // concs will glow
#define FLAG_COLCONCHUND (1<<9)     // concs in his hud will be colored
*/

//create a menu for player preferences
public cmd_prefmenu(id) {
	new szHeader[128];
	formatex(szHeader, charsmax(szHeader), "\\yPreferences menu\n\\wSelect an option");
	new menu = menu_create(szHeader, "menu_playerprefs");
	//new Buffer to retrieve the player's preferences

	new Buffer[ePlayerStruct_t];
	for(new i = 0; i < ArraySize(g_PlayerData); i++)
	{
		ArrayGetArray(g_PlayerData, i, Buffer);
		if (Buffer[mPD_iPlayerID] == id) { 
			break;
		}
	}
	DebugPrintLevel(0, "cmd_prefmenu: %d", Buffer[mPD_iPlayerID]);

	if (Buffer[mPD_iPlayerFlags] & FLAG_COLCONCHUND) {
		menu_additem(menu,"Colored concs (hud): on","1")
	} else {
		menu_additem(menu,"Colored concs (hud): \\roff","1");
	} 
	menu_display(id, menu);
}


public menu_playerprefs(id, menu, item) {
    if( item == MENU_EXIT )
    {
        menu_destroy( menu );
        return PLUGIN_HANDLED;
    }

	new Buffer[ePlayerStruct_t];
	for(new i = 0; i < ArraySize(g_PlayerData); i++)
	{
		ArrayGetArray(g_PlayerData, i, Buffer);
		if (Buffer[mPD_iPlayerID] == id) { 
			break;
		}
	}

    new data[ 6 ], iName[ 64 ];
    new access, callback;
    menu_item_getinfo( menu, item, access, data,5, iName, 63, callback );
    new tempid = str_to_num( data );
    menu_destroy( menu );
    switch( tempid )
    {
        case 1: //noclip
        {
            if  (Buffer[mPD_iPlayerFlags] & FLAG_COLCONCHUND) {
				client_print(id, print_chat, "* Colored concs (hud) off");
				g_bHasColoredConcsHud[id] = false;
				Buffer[mPD_iPlayerFlags] &= ~FLAG_COLCONCHUND;
            } else {
				client_print(id, print_chat, "* Colored concs (hud) on");
				g_bHasColoredConcsHud[id] = true;
				Buffer[mPD_iPlayerFlags] |= FLAG_COLCONCHUND;
            }
	   		cmd_prefmenu(id);
        }
	}
}