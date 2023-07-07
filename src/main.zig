const c = @cImport({
    @cInclude("glad/glad.h");
    @cInclude("GLFW/glfw3.h");
});
const zlm = @import("zlm");
const std = @import("std");

const fov = 110.0;

fn framebufferSizeCallback(window: ?*c.GLFWwindow, width: c_int, height: c_int) callconv(.C) void {
    _ = window;
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
    _ = c.glfwSetErrorCallback(errorCallback);

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
    _ = c.glfwSetFramebufferSizeCallback(window, framebufferSizeCallback);

    if (c.gladLoadGLLoader(@as(c.GLADloadproc, @ptrCast(&glfwGetProcAddressWrapper))) == 0) {
        std.debug.panic("gladLoadGLLoader() failed\n", .{});
    }

    // Get version info
    const renderer = c.glGetString(c.GL_RENDERER);
    const version = c.glGetString(c.GL_VERSION);
    std.debug.print("Renderer: {s}\n", .{renderer});
    std.debug.print("OpenGL version supported: {s}\n", .{version});

    c.glEnable(c.GL_DEPTH_TEST);
    c.glDepthFunc(c.GL_LESS);

    var points = [_]f32{
        0,    0.5,  -1,
        0.5,  -0.5, -1,
        -0.5, -0.5, -1,
    };

    var vbo: c.GLuint = 0;
    c.glGenBuffers(1, &vbo);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
    c.glBufferData(c.GL_ARRAY_BUFFER, @sizeOf(f32) * points.len, &points, c.GL_STATIC_DRAW);

    var vao: c.GLuint = 0;
    c.glGenVertexArrays(1, &vao);
    c.glBindVertexArray(vao);
    c.glEnableVertexAttribArray(0);
    c.glBindBuffer(c.GL_ARRAY_BUFFER, vbo);
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
        \\void main() {
        \\    frag_colour = vec4(0.5, 0.0, 0.5, 1.0);
        \\}
    ;
    var vs = c.glCreateShader(c.GL_VERTEX_SHADER);
    c.glShaderSource(vs, 1, @as([*c]const [*c]const u8, @ptrCast(&vertex_shader)), null);
    var fs = c.glCreateShader(c.GL_FRAGMENT_SHADER);
    c.glShaderSource(fs, 1, @as([*c]const [*c]const u8, @ptrCast(&fragment_shader)), null);

    var shader_program = c.glCreateProgram();
    c.glAttachShader(shader_program, fs);
    c.glAttachShader(shader_program, vs);
    c.glLinkProgram(shader_program);

    var camera_pos = zlm.Vec3.new(0, 0, 0);
    var camera_target = zlm.Vec3.zero;
    var camera_direction = zlm.Vec3.normalize(zlm.Vec3.sub(camera_pos, camera_target));

    var up = zlm.Vec3.new(0, 1, 0);
    var camera_right = zlm.Vec3.normalize(zlm.Vec3.cross(up, camera_direction));
    var camera_up = zlm.Vec3.cross(camera_direction, camera_right);

    var camera_forward = zlm.Vec3.new(0, 0, -1);

    var model = zlm.Mat4.identity;
    c.glUniformMatrix4fv(c.glGetUniformLocation(shader_program, "model"), 1, c.GL_FALSE, &model.fields[0][0]);

    var projection = zlm.Mat4.createPerspective(zlm.toRadians(fov), 1920 / 1080, 0.1, 100);
    c.glUniformMatrix4fv(c.glGetUniformLocation(shader_program, "projection"), 1, c.GL_FALSE, &projection.fields[0][0]);

    var view = zlm.Mat4.createLookAt(camera_pos, zlm.Vec3.add(camera_pos, camera_forward), camera_up);
    c.glUniformMatrix4fv(c.glGetUniformLocation(shader_program, "view"), 1, c.GL_FALSE, &view.fields[0][0]);

    while (c.glfwWindowShouldClose(window) == 0) {
        c.glfwPollEvents();
        if (c.glfwGetKey(window, c.GLFW_KEY_ESCAPE) == c.GLFW_PRESS) {
            c.glfwSetWindowShouldClose(window, c.GLFW_TRUE);
        }

        c.glClear(c.GL_COLOR_BUFFER_BIT | c.GL_DEPTH_BUFFER_BIT);
        c.glUseProgram(shader_program);
        c.glBindVertexArray(vao);

        c.glDrawArrays(c.GL_TRIANGLES, 0, 3);

        c.glfwSwapBuffers(window);
    }

    std.process.cleanExit();
}
