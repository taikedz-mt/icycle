--[[
When user is holding the aux1 key (E):
* if player is sneaking
* and if user is not walking
* then
    * start cycling their inventory (position 1 requirement also allows for sprinting without cycling)
    * at their personally configured speed
--]]

local global_timer = 0
local player_timers = {}
local global_cycle_interval = tonumber(minetest.settings:get("inventory_cycler.default_global_cycle_interval")) or 0.2
local default_player_interval = tonumber(minetest.settings:get("inventory_cycler.default_player_cycle_interval")) or 0.4
local must_stand_still = tonumber(minetest.settings:get("inventory_cycler.must_stand_still")) ~= false

must_stand_still = false

local function player_is_cycling(player)
    local pcon = player:get_player_control()
    local pinv = minetest.get_inventory({type='player', name = player:get_player_name()})
    
    if pcon["aux1"] then -- Holding E
        return (
            not (
                must_stand_still 
                and not (pcon.up or pcon.down or pcon.left or pcon.right) -- stationary
            )
            and pcon.sneak -- sneaking
        )
    end

    return false
end

minetest.register_on_leaveplayer(function(player)
    local playername = player:get_player_name()
    player_timers[playername] = nil
end)

minetest.register_chatcommand("icycler", {
    description = "Configure inventory cycler",
    params = "period <N>",
    func = function(playername, params)
        params = params:split(" ")

        if #params == 2 and params[1] == "period" then
            local newperiod = tonumber(params[2]) or default_player_interval
            player_timers[playername].interval  = newperiod
            minetest.chat_send_player(playername, "Cycle period set to "..tostring(newperiod))
            return
        end

        minetest.chat_send_player(playername, "Invalid request - see /help icycler")
    end,
})

minetest.register_globalstep(function(dtime)
    local cumul_dtime
    global_timer = global_timer + dtime
    if global_timer > global_cycle_interval then
        cumul_dtime = global_timer
        global_timer = 0
    else
        return
    end

    local all_players = minetest.get_connected_players()

    for _,player in ipairs(all_players) do
        local playername = player:get_player_name()

        if player_timers[playername] == nil then
            player_timers[playername] = {timer=0, interval=default_player_interval}
        end

        player_timers[playername].timer = player_timers[playername].timer + cumul_dtime

        if player_timers[playername].timer > player_timers[playername].interval then
            player_timers[playername].timer = 0

            if player_is_cycling(player) then
                inventory_cycler:upward(player:get_player_name())
            end
        end
    end
end)
