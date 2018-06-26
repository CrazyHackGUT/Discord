#include <discord_extended>
#pragma newdecls required

public void OnPluginStart() {
  RegConsoleCmd("sm_discord_admins", Cmd_AdminsList);
  RegConsoleCmd("sm_discord_info", Cmd_ServerInfo);
  RegConsoleCmd("sm_discord_me", Cmd_InfoMe);

  RegConsoleCmd("sm_discord_say", Cmd_Say);
}

/**
 * Admins List
 */
public Action Cmd_AdminsList(int iClient, int iArgs) {
  int iAdmins;

  Discord_StartMessage();

  for (int i; ++i <= MaxClients;) {
    if (!IsClientInGame(i) || IsFakeClient(i) || GetUserAdmin(i) == INVALID_ADMIN_ID)
      continue;

    char szBuffer[2][128];

    GetClientName(i, szBuffer[0], sizeof(szBuffer[]));
    GetClientAuthId(i, AuthId_Steam2, szBuffer[1], sizeof(szBuffer[]));
    Discord_AddField(szBuffer[0], szBuffer[1], true);

    iAdmins++;
  }

  if (iAdmins <= 0) {
    Discord_CancelMessage();
    return Plugin_Handled;
  }

  Discord_SetUsername("Admin List");
  Discord_SetContent("Admins count: %d", iAdmins);

  Discord_SetColor(0xff0000); // red
  Discord_SetTitle("", "Admin List");

  Discord_EndMessage("test", true);
  return Plugin_Handled;
}

public Action Cmd_ServerInfo(int iClient, int iArgs) {
  char szBuffer[256];

  Discord_StartMessage();
  Discord_SetUsername("Server Information");
  Discord_SetAvatar("https://4.bp.blogspot.com/-5txFRC9W8g8/WCPO1rcV5kI/AAAAAAAAACw/GBb0uwIkZrUoEtgUs8Bp5J-1hG-iMl0UgCLcB/s1600/i.png");
  Discord_SetColor(0x00ff00); // green
  Discord_SetTitle("", "Server Information");

  // Hostname
  GetConVarString(FindConVar("hostname"), szBuffer, sizeof(szBuffer));
  Discord_AddField("HostName", szBuffer, true);

  // Current map
  GetCurrentMap(szBuffer, sizeof(szBuffer));
  Discord_AddField("Current Map", szBuffer, true);

  // Players
  FormatEx(szBuffer, sizeof(szBuffer), "**%d** / **%d**", GetClientCount(true), MaxClients);
  Discord_AddField("Players", szBuffer, true);

  // Admins count
  FormatEx(szBuffer, sizeof(szBuffer), "**%d**", GetAdminCount());
  Discord_AddField("Admins", szBuffer, true);

  Discord_AddField("Powered by", "Discord Extended Library");
  Discord_EndMessage("test", true);
  return Plugin_Handled;
}

public Action Cmd_InfoMe(int iClient, int iArgs) {
  if (!iClient)
    return Plugin_Handled;

  char szBuffer[256];

  Discord_StartMessage();
  Discord_SetUsername("Player Information");
  Discord_SetColor(0x0000ff); // blue
  Discord_SetTitle("", "%N", iClient);

  // SteamID v2 / v3
  GetClientAuthId(iClient, AuthId_Steam2, szBuffer, sizeof(szBuffer));
  Discord_AddField("SteamID v2", szBuffer, true);

  GetClientAuthId(iClient, AuthId_Steam3, szBuffer, sizeof(szBuffer));
  Discord_AddField("SteamID v3", szBuffer, true);

  // Steam Community ID (64)
  GetClientAuthId(iClient, AuthId_SteamID64, szBuffer, sizeof(szBuffer));
  Discord_AddField("SteamID 64", szBuffer, true);

  // Is admin?
  Discord_AddField("Administrator?", (GetUserAdmin(iClient) == INVALID_ADMIN_ID) ? "No" : "Yes", true);

  Discord_EndMessage("test", true);
  return Plugin_Handled;
}

int GetAdminCount() {
  int res;

  for (int i; ++i <= MaxClients;) {
    if (!IsClientInGame(i) || IsFakeClient(i) || GetUserAdmin(i) == INVALID_ADMIN_ID)
      continue;
    res++;
  }

  return res;
}

public Action Cmd_Say(int iClient, int iArgC) {
  if (iArgC == 0) {
    ReplyToCommand(iClient, "[Discord] Usage: sm_discord_say <text>");
    return Plugin_Handled;
  }

  char szBuffer[256];
  GetClientName(iClient, szBuffer, sizeof(szBuffer));

  Discord_StartMessage();
  Discord_SetTimestamp(GetTime());
  Discord_SetColor(0x6633FF);

  Discord_SetUsername(szBuffer);
  Discord_SetAuthorName(szBuffer);
  Discord_SetAuthorImage("http://clipart-library.com/images/rTLo8LGxc.png");

  {
    int iPos = FormatEx(szBuffer, sizeof(szBuffer), "https://steamcommunity.com/profiles/");
    GetClientAuthId(iClient, AuthId_SteamID64, szBuffer[iPos], sizeof(szBuffer)-iPos);
    Discord_SetAuthorURL(szBuffer);
  }

  GetCmdArgString(szBuffer, sizeof(szBuffer));
  Discord_AddField("Message Text", szBuffer, true);
  Discord_SetFooterText("Sended: via sm_discord_say");
  Discord_EndMessage("test", true);

  return Plugin_Handled;
}