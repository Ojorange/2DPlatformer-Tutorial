/// @description Slope going down-left (/).  Inherits par_solid.
/// Surface normal points up-right in GMS2: (+cos, -sin) for a 45-degree slope.
event_inherited();
var angle_deg = 45;  // Adjust per instance if needed
surf_normal_x =  cos(angle_deg * (pi / 180));
surf_normal_y = -sin(angle_deg * (pi / 180));
