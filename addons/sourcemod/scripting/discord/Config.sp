/**
 * =============================================================================
 * [Discord] Core
 * Simpliest library for sending message on Discord Server with Discord WebHook.
 *
 * File: discord/Config.sp
 * Role: Reader for config file.
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

void Discord_Reload() {
    static char szConfig[PLATFORM_MAX_PATH];
    if (!szConfig[0]) {
        BuildPath(Path_SM, szConfig, sizeof(szConfig), "configs/Discord.cfg");
    }

    DebugMessage("Discord_Reload(): Started.")

    if (!FileExists(szConfig)) {
        Discord_Generate(szConfig);
    }

    ClearTrie(g_hWebHooks);
    DebugMessage("Discord_Reload(): Cleared existing WebHooks.")

    Handle hSMC = SMC_CreateParser();
    SMC_SetReaders(hSMC, SMC_ns, SMC_kv, SMC_es);

    SMCError eResult = SMC_ParseFile(hSMC, szConfig);
    delete hSMC;

    if (eResult == SMCError_Okay) {
        g_bFirstConfigLoad = true;
        return;
    }

    SetFailState("Couldn't parse configuration file %s, error code %d", szConfig, eResult);
}

void Discord_Generate(const char[] szConfig) {
    DebugMessage("Discord_Generate(): Started. We generate content for file %s.", szConfig)
    Handle hFile = OpenFile(szConfig, "wt");
    if (hFile == null) {
        SetFailState("Couldn't create Discord Config example: %s", szConfig);
        return;
    }

    WriteFileLine(hFile, "// This is configuration example for Discord API");
    WriteFileLine(hFile, "// If you need add your own webhook for another plugin / module, just add:");
    WriteFileLine(hFile, "// \"mymodule\"  \"mywebhook\"");
    WriteFileLine(hFile, "// Without \"//\"");
    WriteFileLine(hFile, "//");
    WriteFileLine(hFile, "// Generated automatically %d, because configuration file not found", GetTime());
    WriteFileLine(hFile, "\"Discord\"");
    WriteFileLine(hFile, "{");
    WriteFileLine(hFile, "    \"default\"  \"\" // <-- put default webhook here. also you can remove this key-value pair.");
    WriteFileLine(hFile, "}");
    CloseHandle(hFile);

    DebugMessage("Discord_Generate(): Done. Closed File resource %x.", hFile)
}

public SMCResult SMC_ns(Handle hSMC, const char[] szName, bool bOptQuotes) {}
public SMCResult SMC_es(Handle hSMC) {}
public SMCResult SMC_kv(Handle hSMC, const char[] szKey, const char[] szValue, bool bKeyQuotes, bool bValueQuotes) {
    DebugMessage("SMC_kv(): Key %s, Value %s", szKey, szValue)
    return UTIL_AddWebHook(szKey, szValue, true) ? SMCParse_Continue : SMCParse_HaltFail;
}
