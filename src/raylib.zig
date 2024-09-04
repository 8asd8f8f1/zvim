const ray = @cImport({
    @cInclude("raylib.h");
});

pub fn main() void {
    const SW = 800;
    const SH = 450;

    ray.InitWindow(SW, SH, "raylib demo");
    defer ray.CloseWindow();

    ray.SetTargetFPS(60);

    while (!ray.WindowShouldClose()) {
        ray.BeginDrawing();
        defer ray.EndDrawing();

        ray.ClearBackground(ray.RAYWHITE);
        ray.DrawText("Hello, World!", 190, 200, 20, ray.LIGHTGRAY);
    }
}
