/// @description Player creation — merges Unity Player.cs + PlayerInput.cs + Controller2D.cs.

// ---- Physics constants (Unity Player.Start equivalents) ----
max_jump_height  = 4 * PIXELS_PER_UNIT;   // 4 Unity units in pixels
min_jump_height  = 1 * PIXELS_PER_UNIT;
time_to_jump_apex = 0.4;  // seconds

// Derived gravity and jump velocities
// Unity: gravity = -(2*maxJumpHeight) / pow(timeToJumpApex, 2)
// GMS2 Y-down: grav is POSITIVE (downward acceleration in pixels/s^2)
grav            = (2 * max_jump_height) / (time_to_jump_apex * time_to_jump_apex);
max_jump_vel    = grav * time_to_jump_apex;
min_jump_vel    = sqrt(2 * grav * min_jump_height);

move_speed                  = 6 * PIXELS_PER_UNIT;   // pixels/sec
acceleration_time_airborne  = 0.2;
acceleration_time_grounded  = 0.1;

// Wall mechanics
wall_slide_speed_max = 3 * PIXELS_PER_UNIT;
wall_stick_time      = 0.25;
time_to_wall_unstick = 0;

// Wall-jump vectors (pixels/sec)
wall_jump_climb_x = 7.5 * PIXELS_PER_UNIT;
wall_jump_climb_y = 16  * PIXELS_PER_UNIT;
wall_jump_off_x   = 8.5 * PIXELS_PER_UNIT;
wall_jump_off_y   = 7   * PIXELS_PER_UNIT;
wall_leap_x       = 18  * PIXELS_PER_UNIT;
wall_leap_y       = 17  * PIXELS_PER_UNIT;

// ---- Runtime velocity / input state ----
vel_x                = 0;
vel_y                = 0;
velocity_x_smoothing = 0;

input_x = 0;
input_y = 0;

wall_sliding = false;
wall_dir_x   = 0;

// ---- Collision state (Controller2D.CollisionInfo equivalent) ----
col_above                  = false;
col_below                  = false;
col_left                   = false;
col_right                  = false;
col_climbing_slope         = false;
col_descending_slope       = false;
col_sliding_down_max_slope = false;
col_slope_angle            = 0;
col_slope_angle_old        = 0;
col_slope_normal_x         = 0;
col_slope_normal_y         = 0;
col_move_amount_old_x      = 0;
col_move_amount_old_y      = 0;
col_face_dir               = 1;
col_falling_through_platform = false;

// Controller2D working variables
move_x         = 0;
move_y         = 0;
player_input_x = 0;
player_input_y = 0;
origins        = undefined;

// ---- Ray spacing (computed from initial bounding box) ----
var rs         = rc_calculate_ray_spacing(bbox_left, bbox_top, bbox_right, bbox_bottom);
h_ray_count    = rs.horizontal_ray_count;
v_ray_count    = rs.vertical_ray_count;
h_ray_spacing  = rs.horizontal_ray_spacing;
v_ray_spacing  = rs.vertical_ray_spacing;

// ---- Jump-key state tracking ----
jump_key_prev = false;
