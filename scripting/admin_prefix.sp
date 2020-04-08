#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#include <adminmenu>
#include <scp>
#include <clientprefs>
#include <csgo_colors>

#define PLUGIN_NAME 		"Admin Prefix"
#define PLUGIN_AUTHOR 		"1mpulse (Discord -> 1mpulse#6496)"
#define PLUGIN_VERSION 		"1.1.0"

#define AP_CHAT_PREFIX 		"[{LIGHTGREEN}Admin Prefix{DEFAULT}]"
#define AP_MAX_PREFIX		32

enum struct ADM_ENUM
{
	char szPREFIX_Tab[64];
	char szPREFIX_Chat[64];
	char szPREFIXCOLOR[64];
}

enum struct CFG_PREFIX
{
	char sPREFIX[64];
}

TopMenu g_hAdminMenu = null;
Handle g_hPREFIX_Tab, g_hPREFIX_Chat, g_hPREFIXCOLOR;
ADM_ENUM g_iAPInfo[MAXPLAYERS+1];
CFG_PREFIX g_iConfigPrefix[AP_MAX_PREFIX];
int g_iCountPrefix;

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION
};

public void OnPluginStart()
{
	TopMenu hTopMenu;
	if((hTopMenu = GetAdminTopMenu()) != null) OnAdminMenuReady(hTopMenu);
	
	g_hPREFIX_Tab = 		RegClientCookie("ma_ap_PREFIX_Tab", 		"ma_ap_PREFIX_Tab", 		CookieAccess_Protected);
	g_hPREFIX_Chat = 		RegClientCookie("ma_ap_PREFIX_Chat", 		"ma_ap_PREFIX_Chat", 		CookieAccess_Protected);
	g_hPREFIXCOLOR = 		RegClientCookie("ma_ap_PREFIXCOLOR", 		"ma_ap_PREFIXCOLOR", 		CookieAccess_Protected);
	
	HookEvent("player_spawn", 	PlayerSetTag);
	HookEvent("player_team", 	PlayerSetTag, EventHookMode_Post);
	HookEvent("player_death", 	PlayerSetTag);
}

public void OnMapStart()
{
	LoadPluginConfig();
}

public void OnClientPostAdminCheck(int iClient)
{
	if(IsValidClient(iClient))
	{
		GetClientCookie(iClient, g_hPREFIX_Tab, 		g_iAPInfo[iClient].szPREFIX_Tab, 		64);
		GetClientCookie(iClient, g_hPREFIX_Chat, 		g_iAPInfo[iClient].szPREFIX_Chat, 		64);
		GetClientCookie(iClient, g_hPREFIXCOLOR, 		g_iAPInfo[iClient].szPREFIXCOLOR, 		64);
	}
}

public Action PlayerSetTag(Event event, const char[] name, bool dontBroadcast) 
{
	int iClient = GetClientOfUserId(GetEventInt(event, "userid")); 
	if(IsValidClient(iClient) && TrimString(g_iAPInfo[iClient].szPREFIX_Tab) > 0) CS_SetClientClanTag(iClient, g_iAPInfo[iClient].szPREFIX_Tab);
}

public Action:OnChatMessage(&iClient, Handle:recipients, String:name[], String:message[])
{
	if(IsValidClient(iClient))
	{
		if(TrimString(g_iAPInfo[iClient].szPREFIX_Chat) > 0)
		{
			Format(name, MAXLENGTH_NAME, "%s \x03%s", g_iAPInfo[iClient].szPREFIX_Chat, name);
			if(TrimString(g_iAPInfo[iClient].szPREFIXCOLOR) > 0) Format(name, MAXLENGTH_NAME, "%s%s", g_iAPInfo[iClient].szPREFIXCOLOR, name);
			Format(name, MAXLENGTH_NAME, " %s", name);
			ReplaceStringColors(name, MAXLENGTH_NAME);
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

void OpenPluginMainMenu(int iClient)
{
	char szBuffer[128];
	Menu hMenu = new Menu(PluginMainMenu_CallBack);
	hMenu.ExitBackButton = true;
	hMenu.SetTitle("Настройка префикса\n ");
	if(TrimString(g_iAPInfo[iClient].szPREFIX_Tab) > 0) FormatEx(szBuffer, sizeof(szBuffer), "Префикс в таб: %s", g_iAPInfo[iClient].szPREFIX_Tab);
	else FormatEx(szBuffer, sizeof(szBuffer), "Префикс в таб: Выключено");
	hMenu.AddItem("", szBuffer);
	if(TrimString(g_iAPInfo[iClient].szPREFIX_Chat) > 0) FormatEx(szBuffer, sizeof(szBuffer), "Префикс в чате: %s", g_iAPInfo[iClient].szPREFIX_Chat);
	else FormatEx(szBuffer, sizeof(szBuffer), "Префикс в чате: Выключено");
	hMenu.AddItem("", szBuffer);
	if(TrimString(g_iAPInfo[iClient].szPREFIXCOLOR) > 0)
	{
		char sColors[64];
		strcopy(sColors, sizeof(sColors), g_iAPInfo[iClient].szPREFIXCOLOR);
		ReplaceColorsName(sColors, sizeof(sColors));
		FormatEx(szBuffer, sizeof(szBuffer), "Цвет префикса в чате: %s", sColors);
	}
	else FormatEx(szBuffer, sizeof(szBuffer), "Цвет префикса в чате: Выключено");
	hMenu.AddItem("", szBuffer);
	hMenu.Display(iClient, 0);
}

public int PluginMainMenu_CallBack(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack) g_hAdminMenu.Display(iClient, TopMenuPosition_LastCategory);
		}
		case MenuAction_Select:
		{
			switch(iItem)
			{
				case 0: PrefixTabMenu(iClient);
				case 1: PrefixChatMenu(iClient);
				case 2:	PrefixChatColorsMenu(iClient);
			}
		}
	}
}

stock void PrefixTabMenu(int iClient)
{
	Menu hMenu = new Menu(PrefixTabMenu_CallBack);
	hMenu.ExitBackButton = true;
	hMenu.SetTitle("Префикс в таб\nВыберите префикс:\n ");
	hMenu.AddItem("", "Отключить\n ", g_iAPInfo[iClient].szPREFIX_Tab[0] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	for(int i = 0; i < g_iCountPrefix; i++)
	{
		hMenu.AddItem(g_iConfigPrefix[i].sPREFIX, g_iConfigPrefix[i].sPREFIX, StrEqual(g_iConfigPrefix[i].sPREFIX, g_iAPInfo[iClient].szPREFIX_Tab, true) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	hMenu.Display(iClient, 0);
}

public int PrefixTabMenu_CallBack(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack) OpenPluginMainMenu(iClient);
		}
		case MenuAction_Select:
		{
			char szBuffer[64];
			hMenu.GetItem(iItem, szBuffer, sizeof(szBuffer));
			SetClientCookie(iClient, g_hPREFIX_Tab, szBuffer);
			strcopy(g_iAPInfo[iClient].szPREFIX_Tab, 64, szBuffer);
			if(TrimString(szBuffer) > 0) CGOPrintToChat(iClient, "%s {GRAY}Вы установили новый префикс в табе: {LIGHTBLUE}%s", AP_CHAT_PREFIX, szBuffer);
			else CGOPrintToChat(iClient, "%s {GRAY}Вы отключили префикс в табе.", AP_CHAT_PREFIX);
			CS_SetClientClanTag(iClient, g_iAPInfo[iClient].szPREFIX_Tab);
			PrefixTabMenu(iClient);
		}
	}
}

stock void PrefixChatMenu(int iClient)
{
	Menu hMenu = new Menu(PrefixChatMenu_CallBack);
	hMenu.ExitBackButton = true;
	hMenu.SetTitle("Префикс в чате\nВыберите префикс:\n ");
	hMenu.AddItem("", "Отключить\n ", g_iAPInfo[iClient].szPREFIX_Chat[0] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	for(int i = 0; i < g_iCountPrefix; i++)
	{
		hMenu.AddItem(g_iConfigPrefix[i].sPREFIX, g_iConfigPrefix[i].sPREFIX, StrEqual(g_iConfigPrefix[i].sPREFIX, g_iAPInfo[iClient].szPREFIX_Chat, true) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	}
	hMenu.Display(iClient, 0);
}

public int PrefixChatMenu_CallBack(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack) OpenPluginMainMenu(iClient);
		}
		case MenuAction_Select:
		{
			char szBuffer[64];
			hMenu.GetItem(iItem, szBuffer, sizeof(szBuffer));
			SetClientCookie(iClient, g_hPREFIX_Chat, szBuffer);
			strcopy(g_iAPInfo[iClient].szPREFIX_Chat, 64, szBuffer);
			if(TrimString(szBuffer) > 0) CGOPrintToChat(iClient, "%s {GRAY}Вы установили новый префикс в чате: {LIGHTBLUE}%s", AP_CHAT_PREFIX, szBuffer);
			else CGOPrintToChat(iClient, "%s {GRAY}Вы отключили префикс в чате.", AP_CHAT_PREFIX);
			PrefixChatMenu(iClient);
		}
	}
}

stock void PrefixChatColorsMenu(int iClient)
{
	char szBuf[64];
	strcopy(szBuf, sizeof(szBuf), g_iAPInfo[iClient].szPREFIXCOLOR);
	ReplaceColorsName(szBuf, sizeof(szBuf));
	Menu hMenu = new Menu(PrefixChatColorsMenu_CallBack);
	hMenu.ExitBackButton = true;
	hMenu.SetTitle("Цвет префикса в чате\nВыберите цвет:\n ");
	hMenu.AddItem("", 				"Отключить\n ", g_iAPInfo[iClient].szPREFIXCOLOR[0] ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED);
	hMenu.AddItem("{DEFAULT}", 		"Белый", StrEqual(szBuf, "Белый", true) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	hMenu.AddItem("{TEAM}", 		"Командный", StrEqual(szBuf, "Командный", true) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	hMenu.AddItem("{GREEN}",		"Зеленый", StrEqual(szBuf, "Зеленый", true) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	hMenu.AddItem("{RED}",			"Красный", StrEqual(szBuf, "Красный", true) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	hMenu.AddItem("{LIME}",			"Лайм", StrEqual(szBuf, "Лайм", true) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	hMenu.AddItem("{LIGHTGREEN}",	"Светло-Зеленый", StrEqual(szBuf, "Светло-Зеленый", true) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	hMenu.AddItem("{LIGHTRED}",		"Светло-Красный", StrEqual(szBuf, "Светло-Красный", true) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	hMenu.AddItem("{GRAY}",			"Серый", StrEqual(szBuf, "Серый", true) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	hMenu.AddItem("{LIGHTOLIVE}",	"Светло-Оливковый", StrEqual(szBuf, "Светло-Оливковый", true) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	hMenu.AddItem("{OLIVE}",		"Оливковый", StrEqual(szBuf, "Оливковый", true) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	hMenu.AddItem("{PURPLE}",		"Фиолетовый", StrEqual(szBuf, "Фиолетовый", true) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	hMenu.AddItem("{LIGHTBLUE}",	"Голубой", StrEqual(szBuf, "Голубой", true) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	hMenu.AddItem("{BLUE}",			"Синий", StrEqual(szBuf, "Синий", true) ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT);
	hMenu.Display(iClient, 0);
}

public int PrefixChatColorsMenu_CallBack(Menu hMenu, MenuAction action, int iClient, int iItem)
{
	switch(action)
	{
		case MenuAction_End: delete hMenu;
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack) OpenPluginMainMenu(iClient);
		}
		case MenuAction_Select:
		{
			char szBuffer[64];
			hMenu.GetItem(iItem, szBuffer, sizeof(szBuffer));
			SetClientCookie(iClient, g_hPREFIXCOLOR, szBuffer);
			strcopy(g_iAPInfo[iClient].szPREFIXCOLOR, 64, szBuffer);
			if(TrimString(szBuffer) > 0) CGOPrintToChat(iClient, "%s {GRAY}Вы установили свой цвет.", AP_CHAT_PREFIX);
			else CGOPrintToChat(iClient, "%s {GRAY}Вы отключили цвет префикса в чате.", AP_CHAT_PREFIX);
			PrefixChatColorsMenu(iClient);
		}
	}
}

public void OnAdminMenuReady(Handle aTopMenu)
{
	TopMenu hTopMenu = TopMenu.FromHandle(aTopMenu);
	if (hTopMenu == g_hAdminMenu) return;
	g_hAdminMenu = hTopMenu;
	TopMenuObject hMyCategory = g_hAdminMenu.AddCategory("sm_ma_ap_category", TopMenuCallBack, "sm_ma_ap", ADMFLAG_GENERIC, "Управление префиксом");
	if (hMyCategory != INVALID_TOPMENUOBJECT)
	{
		g_hAdminMenu.AddItem("sm_ma_ap_menu_item", MenuCallBack1, hMyCategory, "sm_ma_ap_menu", ADMFLAG_GENERIC, "Настройка префикса");
		g_hAdminMenu.AddItem("sm_ma_ap_reload_cfg_item", MenuCallBack2, hMyCategory, "sm_ma_ap_reload_cfg", ADMFLAG_ROOT, "Перезагрузить CFG");
	}
}

public void TopMenuCallBack(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] sBuffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, maxlength, "Управление префиксом");
		case TopMenuAction_DisplayTitle: FormatEx(sBuffer, maxlength, "Управление префиксом");
	}
}

public void MenuCallBack1(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] sBuffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, maxlength, "Настройка префикса");
		case TopMenuAction_SelectOption: OpenPluginMainMenu(iClient);
	}
}

public void MenuCallBack2(TopMenu hMenu, TopMenuAction action, TopMenuObject object_id, int iClient, char[] sBuffer, int maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption: FormatEx(sBuffer, maxlength, "Перезагрузить конфиг");
		case TopMenuAction_SelectOption:
		{
			LoadPluginConfig();
			CGOPrintToChat(iClient, "%s {GRAY}Вы перезагрузили конфиг плагина.", AP_CHAT_PREFIX);
		}
	}
}

stock void ReplaceStringColors(char[] sMessage, int iMaxLen)
{
	ReplaceString(sMessage, iMaxLen, "{DEFAULT}",		"\x01", false);
	ReplaceString(sMessage, iMaxLen, "{TEAM}",			"\x03", false);
	ReplaceString(sMessage, iMaxLen, "{GREEN}",			"\x04", false);
	ReplaceString(sMessage, iMaxLen, "{RED}",			"\x02", false);
	ReplaceString(sMessage, iMaxLen, "{LIME}",			"\x05", false);
	ReplaceString(sMessage, iMaxLen, "{LIGHTGREEN}",	"\x06", false);
	ReplaceString(sMessage, iMaxLen, "{LIGHTRED}",		"\x07", false);
	ReplaceString(sMessage, iMaxLen, "{GRAY}",			"\x08", false);
	ReplaceString(sMessage, iMaxLen, "{LIGHTOLIVE}",	"\x09", false);
	ReplaceString(sMessage, iMaxLen, "{OLIVE}",			"\x10", false);
	ReplaceString(sMessage, iMaxLen, "{PURPLE}",		"\x0E", false);
	ReplaceString(sMessage, iMaxLen, "{LIGHTBLUE}",		"\x0B", false);
	ReplaceString(sMessage, iMaxLen, "{BLUE}",			"\x0C", false);
}

stock void ReplaceColorsName(char[] sColor, int iMaxLen)
{
	ReplaceString(sColor, iMaxLen, "{DEFAULT}",			"Белый", 			false);
	ReplaceString(sColor, iMaxLen, "{TEAM}",			"Командный", 		false);
	ReplaceString(sColor, iMaxLen, "{GREEN}",			"Зеленый", 			false);
	ReplaceString(sColor, iMaxLen, "{RED}",				"Красный", 			false);
	ReplaceString(sColor, iMaxLen, "{LIME}",			"Лайм", 			false);
	ReplaceString(sColor, iMaxLen, "{LIGHTGREEN}",		"Светло-Зеленый", 	false);
	ReplaceString(sColor, iMaxLen, "{LIGHTRED}",		"Светло-Красный", 	false);
	ReplaceString(sColor, iMaxLen, "{GRAY}",			"Серый", 			false);
	ReplaceString(sColor, iMaxLen, "{LIGHTOLIVE}",		"Светло-Оливковый", false);
	ReplaceString(sColor, iMaxLen, "{OLIVE}",			"Оливковый", 		false);
	ReplaceString(sColor, iMaxLen, "{PURPLE}",			"Фиолетовый", 		false);
	ReplaceString(sColor, iMaxLen, "{LIGHTBLUE}",		"Голубой", 			false);
	ReplaceString(sColor, iMaxLen, "{BLUE}",			"Синий", 			false);
}

stock bool IsValidClient(int iClient)
{
	if(iClient && IsClientInGame(iClient) && !IsFakeClient(iClient))
	{
		if(((GetUserFlagBits(iClient) & ADMFLAG_GENERIC) || (GetUserFlagBits(iClient) & ADMFLAG_ROOT)) && GetUserAdmin(iClient) != INVALID_ADMIN_ID) return true;
	}
	return false;
}

stock void LoadPluginConfig()
{
	g_iCountPrefix = 0;
	char szFile[255];
	BuildPath(Path_SM, szFile, sizeof(szFile), "configs/ap_list.ini");
	File hFile = OpenFile(szFile, "r");
	if(hFile)
	{
		char text[752];
		while(!hFile.EndOfFile() && hFile.ReadLine(text, sizeof(text)))
		{
			if(TrimString(text) > 0 && text[0] != '/')
			{
				strcopy(g_iConfigPrefix[g_iCountPrefix].sPREFIX, 64, text);
				g_iCountPrefix++;
			}
		}
		delete hFile;
	}
}