const zlm = @import("zlm");

const Self = @This();

pos: zlm.Vec3,
world_up: zlm.Vec3,
yaw: f32,
pitch: f32,

forward: zlm.Vec3 = zlm.Vec3.new(0.0, 0.0, -1.0),
up: zlm.Vec3 = zlm.Vec3.zero,
right: zlm.Vec3 = zlm.Vec3.zero,

move_speed: f32 = 1,
mouse_sens: f32 = 0.1,

pub fn processMouseMove(self: *Self, d_mouse_x: f32, d_mouse_y: f32) void {
    self.yaw += -d_mouse_x * self.mouse_sens;
    self.pitch += -d_mouse_y * self.mouse_sens;
    if (self.pitch > 90.0) self.pitch = 90.0;
    if (self.pitch < -90.0) self.pitch = -90.0;
    self.updateCameraVectors();
}

/// Updates camera's forward, right, and up vectors.
pub fn updateCameraVectors(self: *Self) void {
    // Update forward vector
    self.forward.x = @cos(zlm.toRadians(self.yaw)) * @cos(zlm.toRadians(self.pitch));
    self.forward.y = @sin(zlm.toRadians(self.pitch));
    self.forward.z = @sin(zlm.toRadians(self.yaw)) * @cos(zlm.toRadians(self.pitch));
    self.forward = zlm.Vec3.normalize(self.forward);
    // Re-calculate right and up vector(s)
    self.right = zlm.Vec3.normalize(zlm.Vec3.cross(self.forward, self.world_up));
    self.up = zlm.Vec3.normalize(zlm.Vec3.cross(self.right, self.forward));
}
