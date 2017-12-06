/**
 * =============================================================================
 * [Discord] Core
 * Simpliest library for sending message on Discord Server with Discord WebHook.
 *
 * File: discord/Constants.sp
 * Role: Storage for all constants values.
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

#define PLUGIN_DESCRIPTION  "Simpliest library for sending message on Discord Server with Discord WebHook"
#define PLUGIN_VERSION      "1.0.2"
#define PLUGIN_AUTHOR       "CrazyHackGUT aka Kruzya"
#define PLUGIN_NAME         "[Discord] Core"
#define PLUGIN_URL          "https://kruzefag.ru/"

#define PMP                 PLATFORM_MAX_PATH
#define MPL                 MAXPLAYERS
#define MCL                 MaxClients

#define SGT(%0)             SetGlobalTransTarget(%0)
#define CID(%0)             GetClientOfUserId(%0)
#define CUD(%0)             GetClientUserId(%0)
#define SZF(%0)             %0, sizeof(%0)

// Enable this, if you have problems with sending messages
// #define DEBUG_MODE
