/**
 * =============================================================================
 * [Discord] Core
 * Simpliest library for sending message on Discord Server with Discord WebHook.
 *
 * File: discord/UTIL.sp
 * Role: Helper functions, Message sender.
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

void UTIL_SendMessage(Handle hMap, const char[] szConfigName, bool bAllowedDefault) {
    DebugMessage("UTIL_SendMessage(): Request %x, Config %s, Default %s.", hMap, szConfigName, bAllowedDefault ? "allowed" : "denied")

    char szBuffer[1024];
    Handle hCleanup = CreateArray(4);
    DebugMessage("UTIL_SendMessage(): Created storage for cleanup after work.")

    JSONArray msg = new JSONArray();
    JSONObject hJSmsg = new JSONObject();
    bool bAdd = false;

    PushArrayCell(hCleanup, msg);
    PushArrayCell(hCleanup, hJSmsg);

    // Title
    if (GetTrieString(hMap, "title_url", SZF(szBuffer))) {
        hJSmsg.SetString("url", szBuffer);
        DebugMessage("UTIL_SendMessage(): Installed URL %s", szBuffer)
        bAdd = true;
    }

    if (GetTrieString(hMap, "title", SZF(szBuffer))) {
        hJSmsg.SetString("title", szBuffer);
        DebugMessage("UTIL_SendMessage(): Installed title %s", szBuffer)
        bAdd = true;
    }

    // Color
    int iColor;
    if (GetTrieValue(hMap, "color", iColor)) {
        hJSmsg.SetInt("color", iColor);
        DebugMessage("UTIL_SendMessage(): Installed color %d", iColor)
        bAdd = true;
    }

    // Fields
    Handle hFields;
    if (GetTrieValue(hMap, "fields", hFields)) {
        DebugMessage("UTIL_SendMessage(): Installing fields...")
        bAdd = true;
        JSONArray hArray = new JSONArray();
        PushArrayCell(hCleanup, hArray);

        int iLength = GetArraySize(hFields);
        for (int i; i < iLength; i++) {
            Handle hItem = GetArrayCell(hFields, i);
            JSONObject hJSObj = new JSONObject();
            PushArrayCell(hCleanup, hJSObj);

            szBuffer[0] = 0;
            GetTrieString(hItem, "title", SZF(szBuffer));
            hJSObj.SetString("name", szBuffer);

            szBuffer[0] = 0;
            GetTrieString(hItem, "text", SZF(szBuffer));
            hJSObj.SetString("value", szBuffer);

            bool bShort;
            GetTrieValue(hItem, "short", bShort);
            hJSObj.SetBool("inline", bShort);

#if defined DEBUG_MODE
            UTIL_JSONDUMP(hJSObj);
#endif

            hArray.Push(hJSObj);
        }
        hJSmsg.Set("fields", hArray);
    }

    if (bAdd) {
        msg.Push(hJSmsg);
        DebugMessage("UTIL_SendMessage(): Attachment pushed to core JSON object.")
    }

    JSONObject hJSONRoot = new JSONObject();
    PushArrayCell(hCleanup, hJSONRoot);
    hJSONRoot.Set("embeds", msg);

    // Username, avatar
    if (GetTrieString(hMap, "username", SZF(szBuffer))) {
        hJSONRoot.SetString("username", szBuffer);
        DebugMessage("UTIL_SendMessage(): Installed username %s", szBuffer)
    }

    if (GetTrieString(hMap, "avatar", SZF(szBuffer))) {
        hJSONRoot.SetString("avatar_url", szBuffer);
        DebugMessage("UTIL_SendMessage(): Installed avatar %s", szBuffer)
    }

    // Message
    if (GetTrieString(hMap, "content", SZF(szBuffer))) {
        hJSONRoot.SetString("content", szBuffer);
        DebugMessage("UTIL_SendMessage(): Installed message %s", szBuffer)
    }

    // httpClient.Post(szWebHook);
    if (UTIL_StringMapKeyExists(g_hWebHooks, szConfigName)) {
        GetTrieString(g_hWebHooks, szConfigName, SZF(szBuffer));
    } else if (bAllowedDefault) {
        GetTrieString(g_hWebHooks, "default", SZF(szBuffer));
    } else {
        UTIL_Cleanup(hCleanup);
        DebugMessage("UTIL_SendMessage(): Couldn't found configuration %s. Stopping...", szConfigName)
        ThrowNativeError(SP_ERROR_NATIVE, "Couldn't send message: WebHook not configured.");
        return;
    }

    g_hHTTPClient.Post(szBuffer, hJSONRoot, OnRequestComplete);

#if defined DEBUG_MODE
    DebugMessage("UTIL_SendMessage(): Request sended to webhook %s (%s)", szConfigName, szBuffer)
    UTIL_JSONDUMP(hJSONRoot);
#endif

    UTIL_Cleanup(hCleanup);
}

bool UTIL_StringMapKeyExists(Handle hStringMap, const char[] szKey) {
    DebugMessage("UTIL_StringMapKeyExists(): Started. Map %x, we find %s", hStringMap, szKey)
    Handle hDump = CreateTrieSnapshot(hStringMap);
    DebugMessage("UTIL_StringMapKeyExists(): Created Snapshot %x", hStringMap)
    bool bFound;
    int iLength = TrieSnapshotLength(hDump);

    int iBL = strlen(szKey)+1;
    char[] szBuffer = new char[iBL];

    for (int i; i < iLength; i++) {
        if (bFound) {
            DebugMessage("UTIL_StringMapKeyExists(): SUCCESS")
            break;
        }

        GetTrieSnapshotKey(hDump, i, szBuffer, iBL);
        DebugMessage("UTIL_StringMapKeyExists(): Readed %d key: %s", i, szBuffer)
        bFound = (strcmp(szBuffer, szKey, true) == 0);
    }

    CloseHandle(hDump);
    return bFound;
}

void UTIL_Cleanup(Handle hCleanup) {
    int iLength = GetArraySize(hCleanup);
    DebugMessage("UTIL_Cleanup(): Started. Storage %x, objects %d.", hCleanup, iLength)

    for (int i; i < iLength; i++) {
        Handle hDel = GetArrayCell(hCleanup, i);
        CloseHandle(hDel);
        DebugMessage("UTIL_Cleanup(): Deleted %x.", hDel)
    }

    CloseHandle(hCleanup);
    DebugMessage("UTIL_Cleanup(): Deleted storage %x.", hCleanup)
}

stock void UTIL_JSONDUMP(JSON hJSON) {
    DebugMessage("UTIL_JSONDUMP(): Started. JSON Object %x.", hJSON)

    char szBuffer[16384];
    hJSON.ToString(szBuffer, sizeof(szBuffer)); // JSON_INDENT(2)
    PrintToServer(szBuffer);
}

bool UTIL_AddWebHook(const char[] szWebHookName, const char[] szURL, bool bRewriteIfExists = false) {
    DebugMessage("UTIL_AddWebHook: %s --> %s", szWebHookName, szURL)

    int iNeedPos = StrContains(szURL, "discordapp.com/api/webhooks/", false);
    if (iNeedPos == -1) {
        return false;
    }

    // d i s c o r d a p p .  c  o  m  /  a  p  i  /  w  e  b  h  o  o  k  s  /  *
    // 0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28

    return SetTrieString(g_hWebHooks, szWebHookName, szURL[iNeedPos + 28], bRewriteIfExists);
}