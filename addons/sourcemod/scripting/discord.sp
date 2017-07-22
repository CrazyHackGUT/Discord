/**
 * =============================================================================
 * [Discord] Core
 * Simpliest library for sending message on Discord Server with Discord WebHook.
 *
 * File: discord.sp
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
#include <textparse>
#include <adt_trie>
#include <ripext>

#pragma newdecls required

Handle g_hWebHooks;         // <-- StringMap
HTTPClient g_hHTTPClient;   // <-- HTTP Client

#include "discord/Constants.sp" // +
#include "discord/Debugger.sp"  // +
#include "discord/Events.sp"    // +
#include "discord/Config.sp"    // +
#include "discord/UTIL.sp"      // +
#include "discord/API.sp"       // +

public Plugin myinfo = {
    url         = PLUGIN_URL,
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    version     = PLUGIN_VERSION,
    description = PLUGIN_DESCRIPTION
};
