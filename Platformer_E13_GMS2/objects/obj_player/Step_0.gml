/// @description Player step — input, physics, and movement.

var dt = delta_time / 1000000;   // microseconds → seconds

// ---- Read input ----
input_x = keyboard_check(vk_right) - keyboard_check(vk_left);
input_y = keyboard_check(vk_down)  - keyboard_check(vk_up);

var jump_key = keyboard_check(ord("Z")) || keyboard_check(vk_space);
if (jump_key && !jump_key_prev) {
    player_on_jump_down();
}
if (!jump_key && jump_key_prev) {
    player_on_jump_up();
}
jump_key_prev = jump_key;

// ---- Physics ----
player_calculate_velocity(dt);
player_handle_wall_sliding(dt);

// ---- Move ----
controller2d_move(vel_x * dt, vel_y * dt, input_x, input_y, false);

// ---- Velocity correction after collision ----
if (col_above || col_below) {
    if (col_sliding_down_max_slope) {
        // GMS2 Y-down: col_slope_normal_y is negative for upward normals.
        // Equivalent to Unity: velocity.y += slopeNormal.y * -gravity * dt
        // With GMS2 sign convention: vel_y += col_slope_normal_y * grav * dt
        vel_y += col_slope_normal_y * grav * dt;
    } else {
        vel_y = 0;
    }
}
