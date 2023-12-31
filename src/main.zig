const c = @import("c_imports.zig");
const zlm = @import("zlm");
const std = @import("std");

const Camera = @import("Camera.zig");

const fov = 110.0;
const start_width = 1920;
const start_height = 1080;
const move_speed = 20.0;
const target_fps = 120.0;

var display_width: c_int = start_width;
var display_height: c_int = start_height;
var mouse_x = @as(f32, @floatFromInt(@divFloor(start_width, 2)));
var mouse_y = @as(f32, @floatFromInt(@divFloor(start_height, 2)));

fn mouseCallback(window: ?*c.GLFWwindow, mouse_x_: f64, mouse_y_: f64) callconv(.C) void {
    _ = window;
    mouse_x = @as(f32, @floatCast(mouse_x_));
    mouse_y = @as(f32, @floatCast(mouse_y_));
}

fn framebufferSizeCallback(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    _ = window;
    display_width = width;
    display_height = height;
    c.glViewport(0, 0, width, height);
}

fn errorCallback(err: c_int, description: [*c]const u8) callconv(.C) void {
    _ = err;
    std.debug.panic("Error: {s}\n", .{description});
}

fn glfwGetProcAddressWrapper(proc_name: [*:0]const u8) callconv(.C) ?*anyopaque {
    return @as(?*anyopaque, @constCast(c.glfwGetProcAddress(proc_name)));
}

pub fn main() void {
    if (c.glfwInit() == c.GL_FALSE) {
        std.debug.print("Failed to initialize GLFW\n", .{});
        std.process.exit(1);
    }
    defer c.glfwTerminate();
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MAJOR, 4);
    c.glfwWindowHint(c.GLFW_CONTEXT_VERSION_MINOR, 6);
    c.glfwWindowHint(c.GLFW_OPENGL_PROFILE, c.GLFW_OPENGL_CORE_PROFILE);

    var window = c.glfwCreateWindow(1920, 1080, "rounds3D", null, null); //c.glfwGetPrimaryMonitor(), null);
    if (window == null) {
        std.debug.panic("glfwCreateWindow() failed\n", .{});
    }

    c.glfwMakeContextCurrent(window);
    _ = c.glfwSetErrorCallback(errorCallback);
    _ = c.glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);
    _ = c.glfwSetCursorPosCallback(window, mouseCallback);

    // Capture mouse (lock it to the center of window)
    c.glfwSetInputMode(window, c.GLFW_CURSOR, c.GLFW_CURSOR_DISABLED);

    // Load gl function pointers
    if (c.gladLoadGLLoader(@as(c.GLADloadproc, @ptrCast(&glfwGetProcAddressWrapper))) == 0) {
        std.debug.panic("gladLoadGLLoader() failed\n", .{});
    }

    // Print out graphics being used and OpenGL version
    const renderer = c.glGetString(c.GL_RENDERER);
    const version = c.glGetString(c.GL_VERSION);
    std.debug.print("Renderer: {s}\n", .{renderer});
    std.debug.print("OpenGL version supported: {s}\n", .{version});

    // c.glEnable(c.GL_CULL_FACE);
    c.glEnable(c.GL_DEPTH_TEST);
    c.glDepthFunc(c.GL_LESS);

    var triangle_points = [_]f32{
        0,    0.5,  -1,
        0.5,  -0.5, -1,
        -0.5, -0.5, -1,
    };
    const triangle_colour = [_]f32{ 1.0, 0.0, 0.0, 1.0 };

    var triangle_vbo: c.GLuint = undefined;
    c.glGenBuffers(1, &triangle_vbo);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, triangle_vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(f32) * triangle_points.len, &triangle_points, c.GL_STATIC_DRAW);

    var triangle_vao: c.GLuint = undefined;
    c.glGenVertexArrays(1, &triangle_vao);
    c.glBindVertexArray(triangle_vao);
    c.glEnableVertexAttribArray(0);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, triangle_vbo);
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 0, null);

    var plane_points = [_]f32{ // HACK(caleb): Big triangle
        0.0,    0.0, -250.0,
        500.0,  0.0, 250.0,
        -500.0, 0.0, 250.0,
    };
    const plane_colour = [_]f32{ 0.0, 0.4, 0.0, 1.0 };

    var plane_vbo: c.GLuint = undefined;
    c.glGenBuffers(1, &plane_vbo);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, plane_vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(f32) * plane_points.len, &plane_points, c.GL_STATIC_DRAW);

    var plane_vao: c.GLuint = undefined;
    c.glGenVertexArrays(1, &plane_vao);
    c.glBindVertexArray(plane_vao);
    c.glEnableVertexAttribArray(0);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, plane_vbo);
    c.glVertexAttribPointer(0, 3, c.GL_FLOAT, c.GL_FALSE, 0, null);

    const vertex_shader =
        \\#version 460
        \\in vec3 vp;
        \\uniform mat4 model;
        \\uniform mat4 view;
        \\uniform mat4 projection;
        \\void main() {
        \\    gl_Position = projection * view * model * vec4(vp, 1.0f);
        \\}
    ;
    const fragment_shader =
        \\#version 460
        \\out vec4 frag_colour;
        \\uniform vec4 colour;
        \\void main() {
        \\    frag_colour = colour;
        \\}
    ;
    var vs = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(vs, 1, @as([*c]const [*c]const u8, @ptrCast(&vertex_shader)), null);
    c.glCompileShader(vs);

    var fs = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(fs, 1, @as([*c]const [*c]const u8, @ptrCast(&fragment_shader)), null);
    c.glCompileShader(fs);

    var shader_program = c.glCreateProgram();
    c.glAttachShader(shader_program, fs);
    c.glAttachShader(shader_program, vs);
    c.glLinkProgram(shader_program);

    c.glDeleteShader(vs);
    c.glDeleteShader(fs);

    var last_time: f32 = @floatCast(c.glfwGetTime());
    var prev_mouse_x = mouse_x;
    var prev_mouse_y = mouse_y;
    var camera = Camera{
        .pos = zlm.Vec3.new(0.0, 1.0, 0.0),
        .world_up = zlm.Vec3.new(0.0, 1.0, 0.0),
        .yaw = 0,
        .pitch = 0,
    };
    camera.updateCameraVectors();
    camera.up = zlm.Vec3.normalize(zlm.Vec3.cross(camera.right, camera.forward));

    // TODO(caleb): asset pipeline
    var options = std.mem.zeroes(c.cgltf_options);
    var data: ?*c.cgltf_data = null;
    var result = c.cgltf_parse_file(&options, "floor.glb", &data);
    defer c.cgltf_free(data);

    if (result == c.cgltf_result_success)
        result = c.cgltf_load_buffers(&options, data, "floor.glb");

    if (result == c.cgltf_result_success)
        result = c.cgltf_validate(data);

    std.debug.print("Result: {d}\n", .{result});

    if (result == c.cgltf_result_success) {
        std.debug.print("Type: {d}\n", .{data.?.file_type});
        std.debug.print("Meshes: {d}\n", .{data.?.meshes_count});
    }

    std.debug.print("{s}\n", .{data.?.json});

    // var mesh_index: usize = 0;
    // while (mesh_index < data.?.meshes_count) : (mesh_index += 1) {
    //     var primitive_index: usize = 0;
    //     while (primitive_index < data.?.meshes[mesh_index].primitives_count) : (primitive_index += 1) {
    //         const prim = &data.?.meshes[mesh_index].primitives[primitive_index];
    //         var out: [3]c.cgltf_float = undefined;
    //         _ = c.cgltf_accessor_unpack_floats(prim.indices, &out, out.len);
    //         std.debug.print("{d:.3}\n", .{out});
    //         // switch (prim.type) {
    //         //     c.gl
    //         //     c.cgltf_primitive_type_triangles => {
    //         //     },
    //         //     else => unreachable,
    //         // }
    //     }
    // }

    while (c.glfwWindowShouldClose(window) == 0) {
        const now: f32 = @floatCast(c.glfwGetTime());
        const d_time = now - last_time;
        last_time = now;
        const frame_interval_sec: f32 = 1.0 / target_fps;
        if (d_time < frame_interval_sec)
            std.time.sleep(@intFromFloat(d_time * std.time.ns_per_s));

        var velocity_this_frame = zlm.Vec3.zero;

        c.glfwPollEvents();
        if (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) c.glfwSetWindowShouldClose(window, c.GLFW_TRUE);
        if (c.glfwGetKey(window, c.GLFW_KEY_D) == c.GLFW_PRESS) velocity_this_frame = zlm.Vec3.sub(velocity_this_frame, zlm.Vec3{ .x = move_speed * d_time, .y = 0.0, .z = 0.0 });
        if (c.glfwGetKey(window, c.GLFW_KEY_A) == c.GLFW_PRESS) velocity_this_frame = zlm.Vec3.add(velocity_this_frame, zlm.Vec3{ .x = move_speed * d_time, .y = 0.0, .z = 0.0 });
        if (c.glfwGetKey(window, c.GLFW_KEY_S) == c.GLFW_PRESS) velocity_this_frame = zlm.Vec3.sub(velocity_this_frame, zlm.Vec3{ .x = 0.0, .y = 0.0, .z = move_speed * d_time });
        if (c.glfwGetKey(window, c.GLFW_KEY_W) == c.GLFW_PRESS) velocity_this_frame = zlm.Vec3.add(velocity_this_frame, zlm.Vec3{ .x = 0.0, .y = 0.0, .z = move_speed * d_time });
        if (c.glfwGetKey(window, c.GLFW_KEY_LEFT_CONTROL) == c.GLFW_PRESS) velocity_this_frame = zlm.Vec3.sub(velocity_this_frame, zlm.Vec3{ .x = 0.0, .y = move_speed * d_time, .z = 0.0 });
        if (c.glfwGetKey(window, c.GLFW_KEY_SPACE) == c.GLFW_PRESS) velocity_this_frame = zlm.Vec3.add(velocity_this_frame, zlm.Vec3{ .x = 0.0, .y = move_speed * d_time, .z = 0.0 });

        var d_mouse_x = mouse_x - prev_mouse_x;
        var d_mouse_y = mouse_y - prev_mouse_y;

        camera.processMouseMove(d_mouse_x, d_mouse_y);
        camera.updatePos(velocity_this_frame);

        prev_mouse_x = mouse_x;
        prev_mouse_y = mouse_y;

        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
        c.glUseProgram(shader_program);

        var model = zlm.Mat4.identity;
        var projection = zlm.Mat4.createPerspective(zlm.toRadians(fov), @as(f32, @floatFromInt(@divTrunc(display_width, display_height))), 0.1, 100);
        var view = zlm.Mat4.createLookAt(camera.pos, zlm.Vec3.add(camera.pos, camera.forward), camera.up);
        c.glUniformMatrix4fv(c.glGetUniformLocation(shader_program, "model"), 1, c.GL_FALSE, &model.fields[0][0]);
        c.glUniformMatrix4fv(c.glGetUniformLocation(shader_program, "projection"), 1, c.GL_FALSE, &projection.fields[0][0]);
        c.glUniformMatrix4fv(c.glGetUniformLocation(shader_program, "view"), 1, c.GL_FALSE, &view.fields[0][0]);

        // Draw plane
        c.glUniform4fv(c.glGetUniformLocation(shader_program, "colour"), 1, &plane_colour);
        c.glBindVertexArray(plane_vao);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

        // Draw triangle
        c.glUniform4fv(c.glGetUniformLocation(shader_program, "colour"), 1, &triangle_colour);
        c.glBindVertexArray(triangle_vao);
        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

        c.glfwSwapBuffers(window);
    }

    std.process.cleanExit();
}
