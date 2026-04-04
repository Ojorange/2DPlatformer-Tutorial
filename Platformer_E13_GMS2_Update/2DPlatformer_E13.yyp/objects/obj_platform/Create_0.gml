/// @description Moving platform creation.

// ---- Waypoints (local space, in pixels) ----
// Define local waypoints as pairs; converted to world space below.
// Override these in instance creation code or modify directly here.
local_waypoints_x = [0,   0];
local_waypoints_y = [0, -192];   // Move 3 units up (192 px) in GMS2 Y-down → upward = negative

global_waypoints_x = array_create(array_length(local_waypoints_x));
global_waypoints_y = array_create(array_length(local_waypoints_y));
for (var i = 0; i < array_length(local_waypoints_x); i++) {
    global_waypoints_x[i] = x + local_waypoints_x[i];
    global_waypoints_y[i] = y + local_waypoints_y[i];
}

// ---- Platform settings ----
platform_speed = 2 * PIXELS_PER_UNIT;   // pixels/sec
cyclic         = false;
wait_time      = 0.5;                    // seconds between waypoints
ease_amount    = 2;                      // [0, 2]

from_wp_index = 0;
pct_between   = 0;
next_move_time = 0;

// ---- Passenger state ----
passenger_list = [];

// ---- Ray spacing ----
var rs        = rc_calculate_ray_spacing(bbox_left, bbox_top, bbox_right, bbox_bottom);
h_ray_count   = rs.horizontal_ray_count;
v_ray_count   = rs.vertical_ray_count;
h_ray_spacing = rs.horizontal_ray_spacing;
v_ray_spacing = rs.vertical_ray_spacing;
origins       = undefined;

// ---- Timing ----
current_time = 0;
