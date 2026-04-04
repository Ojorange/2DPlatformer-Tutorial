/// @description Camera follow step — mirrors Unity CameraFollow.LateUpdate().

if (!instance_exists(target)) exit;

var dt = delta_time / 1000000;

// ---- Update focus area (mirrors FocusArea.Update) ----
var p_left   = target.bbox_left;
var p_right  = target.bbox_right;
var p_top    = target.bbox_top;
var p_bottom = target.bbox_bottom;

var shift_x = 0;
if      (p_left  < fa_left)  shift_x = p_left  - fa_left;
else if (p_right > fa_right) shift_x = p_right - fa_right;
fa_left   += shift_x;
fa_right  += shift_x;

var shift_y = 0;
if      (p_top    < fa_top)    shift_y = p_top    - fa_top;
else if (p_bottom > fa_bottom) shift_y = p_bottom - fa_bottom;
fa_top    += shift_y;
fa_bottom += shift_y;

fa_centre_x = (fa_left + fa_right) / 2;
fa_centre_y = (fa_top  + fa_bottom) / 2;
fa_vel_x    = shift_x;
fa_vel_y    = shift_y;

// ---- Look-ahead logic ----
if (fa_vel_x != 0) {
    look_ahead_dir_x = sign(fa_vel_x);
    var player_inp_x = target.input_x;
    if (sign(player_inp_x) == sign(fa_vel_x) && player_inp_x != 0) {
        look_ahead_stopped  = false;
        target_look_ahead_x = look_ahead_dir_x * look_ahead_dst_x;
    } else {
        if (!look_ahead_stopped) {
            look_ahead_stopped  = true;
            // Partial snap back: Unity's /4 approximation
            target_look_ahead_x = current_look_ahead_x
                + (look_ahead_dir_x * look_ahead_dst_x - current_look_ahead_x) / 4;
        }
    }
}

var sd_x = smooth_damp(current_look_ahead_x, target_look_ahead_x,
                        smooth_look_velocity_x, look_smooth_time_x, dt);
current_look_ahead_x   = sd_x.value;
smooth_look_velocity_x = sd_x.velocity;

// ---- Camera position ----
var focus_x = fa_centre_x + current_look_ahead_x;

// GMS2 Y-down: vertical_offset moves camera DOWN (positive = down)
// In Unity it was upward; flip to keep player near lower third of screen
var target_focus_y = fa_centre_y - vertical_offset;

var cam   = view_camera[0];
var cur_y = camera_get_view_y(cam);

var sd_y = smooth_damp(cur_y, target_focus_y, smooth_velocity_y, vertical_smooth_time, dt);
var focus_y      = sd_y.value;
smooth_velocity_y = sd_y.velocity;

var view_w = camera_get_view_width(cam);
var view_h = camera_get_view_height(cam);

camera_set_view_pos(cam,
    focus_x - view_w / 2,
    focus_y - view_h / 2
);
