/// @description Moving platform logic — mirrors Unity PlatformController.cs.
/// Operates on the calling instance (obj_platform).
/// GMS2 Y-down coordinate system.

/// @function platform_ease(t)
/// Ease function used for smooth waypoint-to-waypoint movement.
function platform_ease(t) {
    var a = ease_amount + 1;
    return power(t, a) / (power(t, a) + power(1 - t, a));
}

/// @function platform_calculate_movement(dt)
/// @desc Mirrors CalculatePlatformMovement(). Returns { vx, vy }.
function platform_calculate_movement(dt) {
    if (current_time < next_move_time) {
        return { vx: 0, vy: 0 };
    }

    from_wp_index = from_wp_index mod array_length(global_waypoints_x);
    var to_index  = (from_wp_index + 1) mod array_length(global_waypoints_x);

    var fx = global_waypoints_x[from_wp_index];
    var fy = global_waypoints_y[from_wp_index];
    var tx = global_waypoints_x[to_index];
    var ty = global_waypoints_y[to_index];

    var dist_between = vec2_distance(fx, fy, tx, ty);
    pct_between      = clamp(pct_between + dt * platform_speed / dist_between, 0, 1);

    var eased = platform_ease(pct_between);
    var new_x = lerp(fx, tx, eased);
    var new_y = lerp(fy, ty, eased);

    if (pct_between >= 1) {
        pct_between   = 0;
        from_wp_index++;

        if (!cyclic) {
            if (from_wp_index >= array_length(global_waypoints_x) - 1) {
                from_wp_index = 0;
                // Reverse waypoint arrays (mirrors System.Array.Reverse)
                var n = array_length(global_waypoints_x);
                for (var i = 0; i < n div 2; i++) {
                    var tmp_x = global_waypoints_x[i];
                    var tmp_y = global_waypoints_y[i];
                    global_waypoints_x[i]       = global_waypoints_x[n - 1 - i];
                    global_waypoints_y[i]       = global_waypoints_y[n - 1 - i];
                    global_waypoints_x[n-1-i]   = tmp_x;
                    global_waypoints_y[n-1-i]   = tmp_y;
                }
            }
        }
        next_move_time = current_time + wait_time;
    }

    return { vx: new_x - x, vy: new_y - y };
}

/// @function platform_calculate_passenger_movement(vx, vy)
/// @desc Mirrors CalculatePassengerMovement(). Populates passenger_list.
function platform_calculate_passenger_movement(vx, vy) {
    passenger_list = [];
    var moved_ids  = [];   // tracks instance IDs already processed

    var dir_x = sign0(vx);
    var dir_y = sign0(vy);

    // --- Vertically moving platform ---
    if (vy != 0) {
        var rl = abs(vy) + SKIN_WIDTH;
        for (var i = 0; i < v_ray_count; i++) {
            var ry = (dir_y == 1) ? origins.bottom_left_y : origins.top_left_y;
            var rx = origins.top_left_x + v_ray_spacing * i;

            var hit = do_raycast(rx, ry, 0, dir_y, rl);
            // Only care about passenger objects (not solid geometry)
            if (hit.hit && hit.distance != 0) {
                var pid = hit.inst;
                if (object_is_ancestor(pid.object_index, par_solid)) continue; // skip terrain
                if (!object_is_ancestor(pid.object_index, obj_player) && pid.object_index != obj_player) continue;

                var already = false;
                for (var k = 0; k < array_length(moved_ids); k++) {
                    if (moved_ids[k] == pid) { already = true; break; }
                }
                if (!already) {
                    array_push(moved_ids, pid);
                    var push_x = (dir_y == 1) ? vx : 0;
                    var push_y = vy - (hit.distance - SKIN_WIDTH) * dir_y;
                    array_push(passenger_list, {
                        inst:               pid,
                        push_x:             push_x,
                        push_y:             push_y,
                        standing_on_platform: (dir_y == 1),
                        move_before_platform: true
                    });
                }
            }
        }
    }

    // --- Horizontally moving platform ---
    if (vx != 0) {
        var rl = abs(vx) + SKIN_WIDTH;
        for (var i = 0; i < h_ray_count; i++) {
            var rx = (dir_x == -1) ? origins.bottom_left_x : origins.bottom_right_x;
            var ry = origins.bottom_left_y - h_ray_spacing * i;

            var hit = do_raycast(rx, ry, dir_x, 0, rl);
            if (hit.hit && hit.distance != 0) {
                var pid = hit.inst;
                if (object_is_ancestor(pid.object_index, par_solid)) continue;
                if (!object_is_ancestor(pid.object_index, obj_player) && pid.object_index != obj_player) continue;

                var already = false;
                for (var k = 0; k < array_length(moved_ids); k++) {
                    if (moved_ids[k] == pid) { already = true; break; }
                }
                if (!already) {
                    array_push(moved_ids, pid);
                    var push_x = vx - (hit.distance - SKIN_WIDTH) * dir_x;
                    var push_y = -SKIN_WIDTH;
                    array_push(passenger_list, {
                        inst:               pid,
                        push_x:             push_x,
                        push_y:             push_y,
                        standing_on_platform: false,
                        move_before_platform: true
                    });
                }
            }
        }
    }

    // --- Passengers riding on top (horizontal/downward platform) ---
    if (dir_y == -1 || (vy == 0 && vx != 0)) {
        var rl = SKIN_WIDTH * 2;
        for (var i = 0; i < v_ray_count; i++) {
            // Cast upward from top edge (short ray to detect standing passengers)
            var rx = origins.top_left_x + v_ray_spacing * i;
            var ry = origins.top_left_y;

            var hit = do_raycast(rx, ry, 0, -1, rl);
            if (hit.hit && hit.distance != 0) {
                var pid = hit.inst;
                if (object_is_ancestor(pid.object_index, par_solid)) continue;
                if (!object_is_ancestor(pid.object_index, obj_player) && pid.object_index != obj_player) continue;

                var already = false;
                for (var k = 0; k < array_length(moved_ids); k++) {
                    if (moved_ids[k] == pid) { already = true; break; }
                }
                if (!already) {
                    array_push(moved_ids, pid);
                    array_push(passenger_list, {
                        inst:               pid,
                        push_x:             vx,
                        push_y:             vy,
                        standing_on_platform: true,
                        move_before_platform: false
                    });
                }
            }
        }
    }
}

/// @function platform_move_passengers(before_platform)
/// @desc Mirrors MovePassengers(). Moves passengers before or after platform.
function platform_move_passengers(before_platform) {
    for (var i = 0; i < array_length(passenger_list); i++) {
        var p = passenger_list[i];
        if (p.move_before_platform == before_platform) {
            with (p.inst) {
                controller2d_move(p.push_x, p.push_y, 0, 0, p.standing_on_platform);
            }
        }
    }
}
