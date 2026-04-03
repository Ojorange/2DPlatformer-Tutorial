/// @description Math utilities — Unity-style helpers for GML.

/// @function smooth_damp(current, target, current_vel, smooth_time, dt)
/// @desc    Unity SmoothDamp equivalent. Returns struct { value, velocity }.
function smooth_damp(current, target, current_vel, smooth_time, dt) {
    smooth_time  = max(0.0001, smooth_time);
    var omega    = 2.0 / smooth_time;
    var x        = omega * dt;
    var exp_val  = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x);
    var change   = current - target;
    var orig_to  = target;
    var temp     = (current_vel + omega * change) * dt;
    var new_vel  = (current_vel - omega * temp) * exp_val;
    var new_val  = target + (change + temp) * exp_val;

    // Overshoot correction
    if ((orig_to - current > 0.0) == (new_val > orig_to)) {
        new_val = orig_to;
        new_vel = (new_val - orig_to) / max(dt, 0.00001);
    }
    return { value: new_val, velocity: new_vel };
}

/// @function sign0(val)
/// @desc Returns -1, 0, or 1 (matches C# Mathf.Sign behaviour for zero).
function sign0(val) {
    if (val > 0) return  1;
    if (val < 0) return -1;
    return 0;
}

/// @function vec2_angle_from_up(nx, ny)
/// @desc Angle in degrees between a 2D normal and world-up (0,-1 in GMS2 Y-down).
///       Equivalent to Unity's Vector2.Angle(normal, Vector2.up) but for Y-down coords.
function vec2_angle_from_up(nx, ny) {
    // In GMS2 Y-down, world-up = (0,-1).  dot = nx*0 + ny*(-1) = -ny.
    var d = clamp(-ny, -1.0, 1.0);
    return arccos(d) * (180.0 / pi);
}

/// @function vec2_distance(ax, ay, bx, by)
function vec2_distance(ax, ay, bx, by) {
    return sqrt((bx - ax) * (bx - ax) + (by - ay) * (by - ay));
}
