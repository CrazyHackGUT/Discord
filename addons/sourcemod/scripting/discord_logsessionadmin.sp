/**
 * =============================================================================
 * [Discord] SourceBans
 * Relaying all bans/comm punishments in Discord Server.
 *
 * File: discord_report.sp
 * Role: -
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

#include <discord_extended>

#pragma newdecls required
#pragma semicolon 1

Handle  g_hRequiredAdminFlags;
int     g_iRequiredAdminFlags;

public Plugin myinfo = {
  description = "Messages about disconnect admins from server",
  version     = "1.0",
  author      = "CrazyHackGUT aka Kruzya",
  name        = "[Discord] Admin Session Log",
  url         = "https://github.com/CrazyHackGUT/Discord"
};

stock const char g_szWebhook[] = "AdminLogging";

public void OnPluginStart() {
  g_hRequiredAdminFlags = CreateConVar("sm_discord_logadmflags", "b", "Required admin flags for logging session time (example: abcde)");
  HookConVarChange(g_hRequiredAdminFlags, OnFlagsChanged);

  AutoExecConfig(true, "admsessionlog", "discord");
}

public void OnConfigsExecuted() {
  OnFlagsChanged(g_hRequiredAdminFlags, NULL_STRING, NULL_STRING);
}

public void OnFlagsChanged(Handle hConVar, const char[] szOV, const char[] szNV) {
  char szFlags[32];
  GetConVarString(hConVar, szFlags, sizeof(szFlags));

  g_iRequiredAdminFlags = ReadFlagString(szFlags);
}

public void OnClientDisconnect(int iClient) {
  if (IsFakeClient(iClient) || !((GetUserFlagBits(iClient) & g_iRequiredAdminFlags) == g_iRequiredAdminFlags))
    return;

  Discord_StartMessage();
  Discord_SetUsername("Admin Logging");
  Discord_SetTitle(NULL_STRING, "Admin disconnected from server");

  // Add table.
  char szBody[2][128];
  GetClientAuthId(iClient, AuthId_SteamID64, szBody[0], sizeof(szBody[]));
  GetClientName(iClient, szBody[1], sizeof(szBody[]));
  Format(szBody[0], sizeof(szBody[]), "[**%s**](https://steamcommunity.com/profiles/%s/)", szBody[1], szBody[0]);
  Discord_AddField("Administrator", szBody[0], true);

  UTIL_FormatTime(RoundFloat(GetClientTime(iClient)), szBody[0], sizeof(szBody[]));
  Discord_AddField("Session length", szBody[0], true);
  Discord_EndMessage(g_szWebhook, true);
}

void UTIL_FormatTime(int iTime, char[] szBuffer, int iMaxLength) {
  int days = iTime / (60 * 60 * 24);
  int hours = (iTime - (days * (60 * 60 * 24))) / (60 * 60);
  int minutes = (iTime - (days * (60 * 60 * 24)) - (hours * (60 * 60))) / 60;
  int seconds = iTime % 60;

  int len;

  szBuffer[0] = 0;

  if (days)
    len += FormatEx(szBuffer[len], iMaxLength - len, "%d %s", days, "days");

  if (hours)
    len += FormatEx(szBuffer[len], iMaxLength - len, "%s%d %s", days ? " " : "", hours, "hours");

  if (minutes)
    len += FormatEx(szBuffer[len], iMaxLength - len, "%s%d %s", (days || hours) ? " " : "", minutes, "minutes");

  if (seconds)
    FormatEx(szBuffer[len], iMaxLength - len, "%s%d %s", (days || hours || minutes) ? " " : "", seconds, "seconds");
}