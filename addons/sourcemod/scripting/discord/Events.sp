/**
 * =============================================================================
 * [Discord] Core
 * Simpliest library for sending message on Discord Server with Discord WebHook.
 *
 * File: discord/Events.sp
 * Role: Handling all SourceMod standart events.
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

public APLRes AskPluginLoad2(Handle hMySelf, bool bLate, char[] szError, int iErrMax) {
  DebugMessage("AskPluginLoad2(): Called.")

  // Starting and ending for messages.
  CreateNative("Discord_IsMessageProcessing",   API_IsMessageProcessing);
  CreateNative("Discord_CancelMessage",         API_CancelMessage);
  CreateNative("Discord_StartMessage",          API_StartMessage);
  CreateNative("Discord_EndMessage",            API_EndMessage);

  // Setting parameters for message.
  CreateNative("Discord_SetUsername",           API_SetUsername);
  CreateNative("Discord_SetAvatar",             API_SetAvatar); 

  // Content.
  CreateNative("Discord_SetTimestamp",          API_SetTimestamp);
  CreateNative("Discord_SetContent",            API_SetContent);
  CreateNative("Discord_SetColor",              API_SetColor);
  CreateNative("Discord_SetTitle",              API_SetTitle);
  CreateNative("Discord_SetDescription",        API_SetDescription);
  CreateNative("Discord_AddField",              API_AddField);

  // WebHooks.
  CreateNative("Discord_WebHookExists",         API_WebHookExists);
  CreateNative("Discord_ReloadConfig",          API_ReloadConfig);
  CreateNative("Discord_BindWebHook",           API_BindWebHook);

  // Author.
  CreateNative("Discord_SetAuthorImage",        API_SetAuthorImage);
  CreateNative("Discord_SetAuthorName",         API_SetAuthorName);
  CreateNative("Discord_SetAuthorURL",          API_SetAuthorURL);

  // Footer.
  CreateNative("Discord_SetFooterImage",        API_SetFooterImage);
  CreateNative("Discord_SetFooterText",         API_SetFooterText);

  // Images.
  CreateNative("Discord_SetThumbnail",          API_SetThumbnail);
  CreateNative("Discord_SetImage",              API_SetImage);

  RegPluginLibrary("discord_extended");
}

public void OnPluginStart() {
  DebugMessage("OnPluginStart(): Called.")

  RegServerCmd("sm_reloaddiscord", Cmd_ReloadDiscord);
  g_hWebHooks = CreateTrie();

  DebugMessage("Discord Extended Library initialized (version " ... PLUGIN_VERSION ... ", build date "... __DATE__ ... " " ... __TIME__ ... ")")
}

public void OnMapStart() {
  DebugMessage("OnMapStart()")
  Discord_Reload();
}

public Action Cmd_ReloadDiscord(int iArgs) {
  DebugMessage("Cmd_ReloadDiscord()")
  Discord_Reload();
  return Plugin_Handled;
}

public void OnNextTick(any data) {
  DebugMessage("OnNextTick()")
  Discord_CancelMessage();
}

public void OnRequestComplete(HTTPResponse Response, DataPack hPack, const char[] szError) {
  if (szError[0] != 0) {
    LogError("Error received when processing webhook: %s", szError);
    CreateTimer(30.0, OnRetryRequest, hPack);
    return;
  }

  hPack.Reset();
  CloseHandle(hPack.ReadCell());
  delete hPack;

  DebugMessage("OnRequestComplete(): Status %d", Response.Status)

#if defined DEBUG_MODE
  JSON hJSON = Response.Data;
  if (hJSON) {
    UTIL_JSONDUMP(hJSON);
    CloseHandle(hJSON);
  }
#endif
}

DataTimer(OnRetryRequest) {
  ResetPack(data);
  char szConfigName[32];

  JSONObject hRequest = ReadPackCell(data);
  ReadPackString(data, SZF(szConfigName));

  HTTPRequest hHttpRequest = UTIL_NewRequest(szConfigName, view_as<bool>(ReadPackCell(data)));
  if (!hHttpRequest)
  {
    hRequest.Close();
    CloseHandle(data);
    return;
  }

  hHttpRequest.Post(hRequest, OnRequestComplete, data);
}