/// @description Player physics helpers — mirrors Unity Player.cs.
/// Operates on the calling instance (obj_player).
/// GMS2 Y-down: vel_y > 0 = falling, vel_y < 0 = jumping/rising.

/// @function player_calculate_velocity(dt)
function player_calculate_velocity(dt) {
    var target_vx  = input_x * move_speed;
    var accel_time = col_below ? acceleration_time_grounded : acceleration_time_airborne;
    var sd         = smooth_damp(vel_x, target_vx, velocity_x_smoothing, accel_time, dt);
    vel_x                = sd.value;
    velocity_x_smoothing = sd.velocity;

    // Gravity: positive in GMS2 (downward acceleration)
    vel_y += grav * dt;
}

/// @function player_handle_wall_sliding(dt)
function player_handle_wall_sliding(dt) {
    // In GMS2, wall is to the LEFT if col_left (normal points right), etc.
    wall_dir_x  = col_left ? -1 : 1;
    wall_sliding = false;

    // GMS2 Y-down: vel_y > 0 means falling
    if ((col_left || col_right) && !col_below && vel_y > 0) {
        wall_sliding = true;

        // Clamp downward speed while wall-sliding
        if (vel_y > wall_slide_speed_max) {
            vel_y = wall_slide_speed_max;
        }

        if (time_to_wall_unstick > 0) {
            velocity_x_smoothing = 0;
            vel_x = 0;
            if (input_x != wall_dir_x && input_x != 0) {
                time_to_wall_unstick -= dt;
            } else {
                time_to_wall_unstick = wall_stick_time;
            }
        } else {
            time_to_wall_unstick = wall_stick_time;
        }
    }
}

/// @function player_on_jump_down()
/// Called when jump key is PRESSED.
function player_on_jump_down() {
    if (wall_sliding) {
        if (wall_dir_x == input_x) {
            // Wall-climb jump
            vel_x = -wall_dir_x * wall_jump_climb_x;
            vel_y = -wall_jump_climb_y;  // upward = negative y in GMS2
        } else if (input_x == 0) {
            // Wall-off jump
            vel_x = -wall_dir_x * wall_jump_off_x;
            vel_y = -wall_jump_off_y;
        } else {
            // Wall-leap jump
            vel_x = -wall_dir_x * wall_leap_x;
            vel_y = -wall_leap_y;
        }
    }

    if (col_below) {
        if (col_sliding_down_max_slope) {
            // Jump off steep slope only if not pressing into the slope
            if (input_x != -sign(col_slope_normal_x)) {
                // In GMS2 Y-down: slope_normal_y is negative for upward normals
                vel_y = max_jump_vel * col_slope_normal_y;   // already negative → upward
                vel_x = max_jump_vel * col_slope_normal_x;
            }
        } else {
            vel_y = -max_jump_vel;  // upward = negative y in GMS2
        }
    }
}

/// @function player_on_jump_up()
/// Called when jump key is RELEASED (variable-height jump).
function player_on_jump_up() {
    // GMS2 Y-down: "still rising fast" → vel_y < -min_jump_vel (very negative)
    if (vel_y < -min_jump_vel) {
        vel_y = -min_jump_vel;
    }
}
